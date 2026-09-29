import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models.dart';
import '../theme.dart';
import 'auth_service.dart';
import 'local_store.dart';
import 'notification_service.dart';
import 'sync_service.dart';

enum SyncStatus { off, connecting, online, offline }

class AppState extends ChangeNotifier {
  final LocalStore store = LocalStore();
  late final AuthService auth = AuthService(store);
  final NotificationService notifications = NotificationService();
  final SyncService sync = SyncService();

  bool loading = true;
  ThemeSettings theme = ThemeSettings();
  Session? session;
  UserData data = UserData();
  SyncStatus syncStatus = SyncStatus.off;
  List<FleetMember> members = [];
  Timer? _notifyDebounce;
  Timer? _retry;

  bool get isCloud => session?.mode == AccountMode.cloud;

  List<Vehicle> get vehicles {
    final list = data.vehicles.where((v) => !v.deleted).toList();
    list.sort((a, b) {
      final da = a.nextDeadline?.dueDate;
      final db = b.nextDeadline?.dueDate;
      if (da == null && db == null) return a.name.compareTo(b.name);
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return list;
  }

  Vehicle? vehicleById(String id) {
    for (final v in data.vehicles) {
      if (v.id == id && !v.deleted) return v;
    }
    return null;
  }

  Future<void> init() async {
    theme = ThemeSettings.fromJson(await store.readSettings());
    notifyListeners();
    try {
      await notifications.init();
    } catch (_) {}
    var s = await store.readSession();
    if (s != null && s.mode == AccountMode.cloud && !auth.cloudSessionValid(s)) {
      s = null;
    }
    if (s != null) {
      await _open(s);
    }
    loading = false;
    notifyListeners();
  }

  Future<void> login(Session s) async {
    await store.writeSession(s);
    await _open(s);
    notifications.requestPermission();
    notifyListeners();
  }

  Future<void> _open(Session s) async {
    session = s;
    data = await store.readUserData(s);
    _scheduleNotifications();
    if (s.mode == AccountMode.cloud) {
      _startSync();
    }
  }

  Future<void> logout() async {
    sync.stop();
    _retry?.cancel();
    await auth.logout(session);
    await store.writeSession(null);
    session = null;
    data = UserData();
    members = [];
    syncStatus = SyncStatus.off;
    try {
      await notifications.rescheduleAll([], data.notify);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _persist() async {
    final s = session;
    if (s == null) return;
    await store.writeUserData(s, data);
  }

  void _scheduleNotifications() {
    _notifyDebounce?.cancel();
    _notifyDebounce = Timer(const Duration(milliseconds: 800), () async {
      try {
        await notifications.rescheduleAll(data.vehicles, data.notify);
      } catch (_) {}
    });
  }

  // ---------------- Veicoli ----------------

  Future<void> saveVehicle(Vehicle v) async {
    v.updatedAt = DateTime.now().millisecondsSinceEpoch;
    v.updatedBy = session?.displayName ?? '';
    final i = data.vehicles.indexWhere((x) => x.id == v.id);
    if (i >= 0) {
      data.vehicles[i] = v;
    } else {
      data.vehicles.add(v);
    }
    await _persist();
    _pushIfCloud(v);
    _scheduleNotifications();
    notifyListeners();
  }

  Future<void> deleteVehicle(String id) async {
    final i = data.vehicles.indexWhere((x) => x.id == id);
    if (i < 0) return;
    final v = data.vehicles[i];
    for (final d in List.of(v.documents)) {
      await _deleteDocFile(d);
    }
    v.documents.clear();
    v.deleted = true;
    v.photoB64 = null;
    await saveVehicle(v);
  }

  // ---------------- Documenti (restano sul telefono) ----------------

  Future<File> documentFile(VehicleDocument d) async =>
      File('${(await store.docsDir()).path}/${d.fileName}');

  Future<void> addDocument(String vehicleId, String sourcePath, String name) async {
    final i = data.vehicles.indexWhere((x) => x.id == vehicleId);
    if (i < 0) return;
    final src = File(sourcePath);
    final lower = sourcePath.toLowerCase();
    final isPdf = lower.endsWith('.pdf');
    var ext = 'jpg';
    final dot = lower.lastIndexOf('.');
    if (dot >= 0 && lower.length - dot <= 5) ext = lower.substring(dot + 1);
    final doc = VehicleDocument(
      name: name,
      fileName: '',
      kind: isPdf ? 'pdf' : 'image',
    );
    doc.fileName = '${vehicleId}_${doc.id}.$ext';
    final dest = await documentFile(doc);
    await src.copy(dest.path);
    doc.size = await dest.length();
    data.vehicles[i].documents.add(doc);
    await _persist();
    notifyListeners();
  }

  Future<void> renameDocument(String vehicleId, String docId, String name) async {
    final v = vehicleById(vehicleId);
    if (v == null) return;
    for (final d in v.documents) {
      if (d.id == docId) d.name = name;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> removeDocument(String vehicleId, String docId) async {
    final v = vehicleById(vehicleId);
    if (v == null) return;
    final idx = v.documents.indexWhere((d) => d.id == docId);
    if (idx < 0) return;
    await _deleteDocFile(v.documents[idx]);
    v.documents.removeAt(idx);
    await _persist();
    notifyListeners();
  }

  Future<void> _deleteDocFile(VehicleDocument d) async {
    try {
      final f = await documentFile(d);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  // ---------------- Tema ----------------

  Future<void> updateTheme(ThemeSettings t) async {
    theme = t;
    notifyListeners();
    await store.writeSettings(t.toJson());
  }

  Future<void> updateNotify(NotifySettings n) async {
    data.notify = n;
    await _persist();
    _scheduleNotifications();
    notifyListeners();
  }

  // ---------------- Sincronizzazione famiglia ----------------

  void _pushIfCloud(Vehicle v) {
    final f = data.fleetId;
    if (isCloud && f != null) sync.push(f, v);
  }

  Future<void> retrySync() async {
    if (isCloud) await _startSync();
  }

  Future<void> _startSync() async {
    final s = session;
    if (s == null || !auth.cloudAvailable) return;
    _retry?.cancel();
    syncStatus = SyncStatus.connecting;
    notifyListeners();
    if (data.fleetId == null) {
      try {
        final f = await sync.ensureFleet(s);
        data.fleetId = f.id;
        data.fleetName = f.name;
        await _persist();
      } catch (_) {
        // Offline: si lavora in locale e si riprova tra un minuto.
        syncStatus = SyncStatus.offline;
        notifyListeners();
        _retry = Timer(const Duration(minutes: 1), _startSync);
        return;
      }
    }
    _listen();
  }

  void _listen() {
    final f = data.fleetId;
    if (f == null) return;
    sync.start(
      fleetId: f,
      localVehicles: () => List.of(data.vehicles),
      onRemote: _mergeRemote,
      onFleet: (name, m) {
        members = m;
        if (data.fleetName != name) {
          data.fleetName = name;
          _persist();
        }
        final s = session;
        if (s != null && m.isNotEmpty && !m.any((x) => x.uid == s.key)) {
          // Rimosso dal parco familiare: torna a un parco personale.
          data.fleetId = null;
          _persist();
          _startSync();
          return;
        }
        syncStatus = SyncStatus.online;
        notifyListeners();
      },
    );
  }

  void _mergeRemote(List<Vehicle> remote) {
    var changed = false;
    for (final r in remote) {
      final i = data.vehicles.indexWhere((x) => x.id == r.id);
      if (i < 0) {
        r.documents = [];
        data.vehicles.add(r);
        changed = true;
      } else if (r.updatedAt > data.vehicles[i].updatedAt) {
        // I documenti sono solo locali: si conservano quelli del telefono.
        r.documents = data.vehicles[i].documents;
        data.vehicles[i] = r;
        changed = true;
      }
    }
    if (syncStatus != SyncStatus.online) {
      syncStatus = SyncStatus.online;
      changed = true;
    }
    if (changed) {
      _persist();
      _scheduleNotifications();
      notifyListeners();
    }
  }

  String? get inviteCode => data.fleetId;

  Future<void> joinFamily(String code) async {
    final s = session!;
    final f = await sync.joinFleet(s, code, data.fleetId);
    data.fleetId = f.id;
    data.fleetName = f.name;
    // I veicoli già presenti sul telefono vengono aggiunti al parco familiare.
    for (final v in data.vehicles) {
      v.updatedAt = DateTime.now().millisecondsSinceEpoch;
    }
    await _persist();
    _listen();
    notifyListeners();
  }

  Future<void> leaveFamily() async {
    final s = session!;
    final old = data.fleetId;
    if (old == null) return;
    final f = await sync.leaveFleet(s, old);
    data.fleetId = f.id;
    data.fleetName = f.name;
    for (final v in data.vehicles) {
      v.updatedAt = DateTime.now().millisecondsSinceEpoch;
    }
    await _persist();
    _listen();
    notifyListeners();
  }

  Future<void> renameFleet(String name) async {
    final f = data.fleetId;
    if (f == null) return;
    await sync.renameFleet(f, name);
    data.fleetName = name;
    await _persist();
    notifyListeners();
  }
}
