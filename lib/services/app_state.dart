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

  /// Veicolo del parco personale ("I miei").
  bool isPersonal(Vehicle v) => v.fleetId == null || v.fleetId == data.personalFleetId;

  List<Vehicle> get myVehicles => vehicles.where(isPersonal).toList();

  List<Vehicle> groupVehicles(String groupId) =>
      vehicles.where((v) => v.fleetId == groupId).toList();

  /// Nome del parco a cui appartiene il veicolo.
  String fleetLabel(Vehicle v) =>
      isPersonal(v) ? 'I miei veicoli' : (data.groupById(v.fleetId)?.name ?? 'Famiglia');

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
    final now = DateTime.now().millisecondsSinceEpoch;
    v.updatedAt = now;
    v.updatedBy = session?.displayName ?? '';
    if (v.fleetId == data.personalFleetId) v.fleetId = null;
    final i = data.vehicles.indexWhere((x) => x.id == v.id);
    if (i >= 0 && data.vehicles[i].fleetId != v.fleetId && isCloud) {
      // Spostato in un altro parco: il vecchio viene eliminato per gli altri,
      // il veicolo prosegue con un nuovo identificativo nel nuovo parco.
      final old = data.vehicles[i];
      final tomb = old.copy()
        ..deleted = true
        ..photoB64 = null
        ..documents = []
        ..updatedAt = now;
      data.vehicles[i] = tomb;
      _pushIfCloud(tomb);
      final moved = Vehicle.fromJson(v.toJson())..id = newId();
      moved.fleetId = v.fleetId;
      data.vehicles.add(moved);
      v = moved;
    } else if (i >= 0) {
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

  // ---------------- Sincronizzazione e nuclei familiari ----------------

  String? _fleetOf(Vehicle v) => v.fleetId ?? data.personalFleetId;

  void _pushIfCloud(Vehicle v) {
    final f = _fleetOf(v);
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
    if (data.personalFleetId == null) {
      try {
        data.personalFleetId = await sync.ensurePersonal(s);
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
    final s = session;
    final personal = data.personalFleetId;
    if (s == null || personal == null) return;
    sync.start(
      session: s,
      personalId: personal,
      localVehicles: (fleetId) => data.vehicles.where((v) => _fleetOf(v) == fleetId).toList(),
      onVehicles: _mergeRemote,
      onGroups: _onGroups,
    );
  }

  void _onGroups(List<FleetGroup> groups) {
    data.groups = groups;
    final valid = {data.personalFleetId, ...groups.map((g) => g.id)};
    // Veicoli di nuclei da cui si è usciti (o eliminati): tolti dal telefono.
    final gone = data.vehicles
        .where((v) => v.fleetId != null && !valid.contains(v.fleetId))
        .toList();
    for (final v in gone) {
      for (final d in v.documents) {
        _deleteDocFile(d);
      }
      data.vehicles.remove(v);
    }
    syncStatus = SyncStatus.online;
    _persist();
    _scheduleNotifications();
    notifyListeners();
  }

  void _mergeRemote(String fleetId, List<Vehicle> remote, bool fromServer) {
    var changed = false;
    final personal = fleetId == data.personalFleetId;
    for (final r in remote) {
      r.fleetId = personal ? null : fleetId;
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
    if (fromServer && syncStatus != SyncStatus.online) {
      syncStatus = SyncStatus.online;
      changed = true;
    }
    if (changed) {
      _persist();
      _scheduleNotifications();
      notifyListeners();
    }
  }

  Future<FleetGroup> createGroup(String name) async {
    final g = await sync.createGroup(session!, name);
    if (data.groupById(g.id) == null) data.groups.add(g);
    await _persist();
    notifyListeners();
    return g;
  }

  Future<FleetGroup> joinGroup(String code) async {
    final g = await sync.joinGroup(session!, code);
    if (data.groupById(g.id) == null) data.groups.add(g);
    await _persist();
    notifyListeners();
    return g;
  }

  Future<void> leaveGroup(String id) async {
    await sync.leaveGroup(session!, id);
    _onGroups(data.groups.where((g) => g.id != id).toList());
  }

  Future<void> deleteGroup(String id) async {
    await sync.deleteGroup(id);
    _onGroups(data.groups.where((g) => g.id != id).toList());
  }

  Future<void> removeMember(String groupId, String uid) async {
    await sync.removeMember(groupId, uid);
  }

  Future<void> renameGroup(String id, String name) async {
    await sync.renameGroup(id, name);
    data.groupById(id)?.name = name;
    await _persist();
    notifyListeners();
  }
}
