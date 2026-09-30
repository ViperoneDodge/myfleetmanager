import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../l10n.dart';
import '../models.dart';
import '../theme.dart';
import 'auth_service.dart';
import 'local_store.dart';
import 'notification_service.dart';
import 'pro_service.dart';
import 'push_service.dart';
import 'sync_service.dart';

enum SyncStatus { off, connecting, online, offline }

class AppState extends ChangeNotifier {
  final LocalStore store = LocalStore();
  late final AuthService auth = AuthService(store);
  final NotificationService notifications = NotificationService();
  final SyncService sync = SyncService();
  final PushService push = PushService();
  final ProService pro = ProService();

  // ---------------- Versione Pro ----------------

  /// Veicoli (personali) gestibili con la versione gratuita.
  static const int freeVehicleLimit = 3;

  /// Codice riservato allo sviluppo: sblocca la Pro senza acquisto.
  static const String _devCode = 'PIPPOPUZZA';

  /// Acquisto confermato dal Play Store (ricordato sul telefono).
  bool purchasedPro = false;

  /// Pro sbloccata con il codice sviluppatore.
  bool devPro = false;

  bool get isPro => purchasedPro || devPro;

  /// Furgoni, camion e rimorchi sono riservati alla Pro.
  static bool isProType(VehicleType t) =>
      t == VehicleType.furgone || t == VehicleType.camion || t == VehicleType.rimorchio;

  /// Con la versione gratuita si possono avere al massimo [freeVehicleLimit] veicoli propri.
  bool get canAddVehicle => isPro || myVehicles.length < freeVehicleLimit;

  bool unlockDev(String code) {
    if (code.trim().toUpperCase() != _devCode) return false;
    devPro = true;
    _writeSettings();
    notifyListeners();
    return true;
  }

  void disableDev() {
    devPro = false;
    _writeSettings();
    notifyListeners();
  }

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
      isPersonal(v) ? tr('fleet.mine') : (data.groupById(v.fleetId)?.name ?? tr('family.defaultName'));

  Vehicle? vehicleById(String id) {
    for (final v in data.vehicles) {
      if (v.id == id && !v.deleted) return v;
    }
    return null;
  }

  /// Lingua scelta nelle impostazioni (null = come il telefono).
  String? langPref;

  Future<void> init() async {
    final settings = await store.readSettings();
    theme = ThemeSettings.fromJson(settings);
    langPref = settings?['lang'] as String?;
    purchasedPro = settings?['pro'] == true;
    devPro = settings?['devPro'] == true;
    notifyListeners();
    // Acquisti: verifica/ripristino in background (non blocca l'avvio).
    pro.init(
      onOwned: () {
        if (!purchasedPro) {
          purchasedPro = true;
          _writeSettings();
        }
      },
      onChanged: notifyListeners,
    );
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
    if (session != null) {
      // Dopo l'intro: chiede il permesso notifiche (Android 13+) se non è già stato dato.
      // Prima veniva chiesto solo al login, quindi chi aggiornava l'app restava senza.
      Future.delayed(const Duration(seconds: 3), () async {
        try {
          await notifications.requestPermission();
        } catch (_) {}
        _scheduleNotifications();
      });
    }
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
      startPush();
    }
  }

  /// Registra il telefono per le notifiche push (solo account online).
  Future<void> startPush() async {
    final s = session;
    if (s == null || s.mode != AccountMode.cloud || !auth.cloudAvailable) return;
    await push.start(s.key, onForeground: (title, body) {
      notifications.showRemote(title, body);
    });
    notifyListeners();
  }

  Future<void> logout() async {
    sync.stop();
    _retry?.cancel();
    if (isCloud) await push.stop();
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

  /// Sposta un veicolo in un altro parco (nucleo familiare o "I miei").
  /// [fleetId] null = parco personale.
  Future<void> moveVehicle(String id, String? fleetId) async {
    final v = vehicleById(id);
    if (v == null) return;
    final moved = v.copy()..fleetId = fleetId;
    await saveVehicle(moved);
  }

  // ---------------- Storico manutenzioni ----------------

  /// Salva un intervento. Con [asService] aggiorna anche la data
  /// dell'ultimo tagliando (e quindi il promemoria del prossimo).
  Future<void> saveMaintenance(String vehicleId, MaintenanceRecord r,
      {bool asService = false}) async {
    final v = vehicleById(vehicleId);
    if (v == null) return;
    final i = v.maintenance.indexWhere((m) => m.id == r.id);
    if (i >= 0) {
      v.maintenance[i] = r;
    } else {
      v.maintenance.add(r);
    }
    if (asService) {
      for (final d in v.deadlines) {
        if (d.kind == DeadlineKind.service && (d.date == null || !r.date.isBefore(d.date!))) {
          d.date = DateTime(r.date.year, r.date.month, r.date.day);
          d.enabled = true;
        }
      }
    }
    await saveVehicle(v);
  }

  Future<void> deleteMaintenance(String vehicleId, String recordId) async {
    final v = vehicleById(vehicleId);
    if (v == null) return;
    v.maintenance.removeWhere((m) => m.id == recordId);
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
    await _writeSettings();
  }

  Future<void> _writeSettings() => store.writeSettings({
        ...theme.toJson(),
        if (langPref != null) 'lang': langPref,
        'pro': purchasedPro,
        'devPro': devPro,
      });

  /// Cambia lingua ([code] null = automatica, come il telefono).
  Future<void> setLanguage(String? code) async {
    langPref = code;
    await L10n.load(L10n.resolve(code));
    notifyListeners();
    await _writeSettings();
    // Le notifiche già programmate vengono riscritte nella nuova lingua.
    _scheduleNotifications();
    try {
      await notifications.refreshChannels();
    } catch (_) {}
  }

  // ---------------- Passaggio da account locale ad account online ----------------

  /// Passa all'account online [cloud] senza uscire. Con [bringVehicles] i veicoli
  /// dell'account locale (con documenti e impostazioni notifiche) vengono copiati
  /// nel parco personale online. L'account locale resta sul telefono intatto.
  Future<int> switchToCloud(Session cloud, {required bool bringVehicles}) async {
    final old = session;
    final oldData = data;
    final target = await store.readUserData(cloud);
    var copied = 0;
    if (bringVehicles && old != null && old.mode == AccountMode.local) {
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final v in oldData.vehicles.where((v) => !v.deleted)) {
        if (target.vehicles.any((x) => x.id == v.id)) continue;
        final c = v.copy()
          ..fleetId = null
          ..updatedAt = now
          ..updatedBy = cloud.displayName
          ..documents = [];
        // I file dei documenti vengono duplicati: i due account restano indipendenti.
        for (final d in v.documents) {
          try {
            final src = await documentFile(d);
            if (!await src.exists()) continue;
            final dot = d.fileName.lastIndexOf('.');
            final ext = dot >= 0 ? d.fileName.substring(dot + 1) : 'jpg';
            final nd = VehicleDocument(name: d.name, fileName: '', kind: d.kind, size: d.size);
            nd.fileName = '${c.id}_${nd.id}.$ext';
            await src.copy((await documentFile(nd)).path);
            c.documents.add(nd);
          } catch (_) {}
        }
        target.vehicles.add(c);
        copied++;
      }
      target.notify = oldData.notify;
    }
    await store.writeUserData(cloud, target);
    sync.stop();
    _retry?.cancel();
    syncStatus = SyncStatus.off;
    await store.writeSession(cloud);
    await _open(cloud);
    notifications.requestPermission();
    notifyListeners();
    return copied;
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
    if (isCloud) {
      if (!push.registered) startPush();
      await _startSync();
    }
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
