import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart' show FirebaseException;

import 'package:flutter/foundation.dart';

import '../l10n.dart';
import '../models.dart';
import '../theme.dart';
import 'auth_service.dart';
import 'local_store.dart';
import 'notification_service.dart';
import 'pro_service.dart';
import 'group_watch.dart';
import 'push_service.dart';
import 'support_service.dart';
import 'update_service.dart';
import '../version.dart';
import 'sync_service.dart';

enum SyncStatus { off, connecting, online, offline }

class AppState extends ChangeNotifier {
  final LocalStore store = LocalStore();
  late final AuthService auth = AuthService(store);
  final NotificationService notifications = NotificationService();
  final SyncService sync = SyncService();
  final PushService push = PushService();

  GroupWatchState watch = GroupWatchState();
  final ProService pro = ProService();

  static const int freeVehicleLimit = 3;

  bool purchasedPro = false;

  bool devPro = false;

  bool get isPro => purchasedPro || devPro || isAdmin;

  static bool isProType(VehicleType t) =>
      t == VehicleType.furgone ||
      t == VehicleType.camion ||
      t == VehicleType.rimorchio ||
      t == VehicleType.agricolo;

  Set<String> get limitedIds {
    if (isPro) return const {};
    final groupOrder = {for (var i = 0; i < data.groups.length; i++) data.groups[i].id: i};
    int fleetRank(Vehicle v) => isMine(v) ? -1 : (groupOrder[v.fleetId] ?? 9999);
    final ordered = data.vehicles.where((v) => !v.deleted).toList()
      ..sort((a, b) {
        final f = fleetRank(a).compareTo(fleetRank(b));
        if (f != 0) return f;
        final c = a.createdAt.compareTo(b.createdAt);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    var active = 0;
    final limited = <String>{};
    for (final v in ordered) {
      if (!isProType(v.type) && active < freeVehicleLimit) {
        active++;
      } else {
        limited.add(v.id);
      }
    }
    return limited;
  }

  bool isLimited(Vehicle v) => limitedIds.contains(v.id);

  List<Vehicle> get activeVehicles {
    final limited = limitedIds;
    return vehicles.where((v) => !limited.contains(v.id)).toList();
  }

  bool get canAddVehicle => isPro || activeVehicles.length < freeVehicleLimit;

  String? devProVersion;

  static const String devOk = 'ok',
      devWrong = 'wrong',
      devNeedCloud = 'cloud',
      devRevoked = 'revoked',
      devOffline = 'offline';

  Future<String> unlockDev(String code) async {
    final c = code.trim().toUpperCase();
    if (c.isEmpty) return devWrong;
    final s = session;
    if (s == null || !isCloud) return devNeedCloud;
    try {
      if (!await sync.checkUnlockCode(c)) return devWrong;
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') return devOffline;
      return devWrong;
    } on TimeoutException {
      return devOffline;
    } catch (_) {
      return devWrong;
    }
    try {
      if (await sync.isProRevoked(s)) return devRevoked;
    } catch (_) {}
    devPro = true;
    devProVersion = appVersion;
    _writeSettings();
    notifyListeners();
    _registerPro('devcode');
    SupportService.notifyDeveloper('MyFleetManager: codice sviluppatore usato da ${s.email ?? s.displayName}', {
      'Utente': s.displayName,
      'Email': s.email ?? '-',
      'UID': s.key,
      'Lingua': L10n.code,
    });
    return devOk;
  }

  void disableDev() {
    devPro = false;
    devProVersion = null;
    _writeSettings();
    notifyListeners();
    _endPro('user');
  }

  static const String adminEmail = 'appmyfleetmanager@gmail.com';

  bool get isAdmin => isCloud && session?.email?.toLowerCase() == adminEmail;

  StreamSubscription? _proSub;

  Future<void> _registerPro(String method) async {
    final s = session;
    if (s == null || !isCloud || isAdmin) return;
    try {
      await sync.registerPro(s, method: method, version: appVersion);
    } catch (_) {}
  }

  Future<void> _endPro(String reason) async {
    final s = session;
    if (s == null || !isCloud || isAdmin) return;
    try {
      await sync.endPro(s, reason);
    } catch (_) {}
  }

  void _watchProEntry() {
    _proSub?.cancel();
    final s = session;
    if (s == null || !isCloud) return;
    _proSub = sync.watchPro(s).listen((entry) {
      if (entry != null && entry['revoked'] == true && devPro) {
        devPro = false;
        devProVersion = null;
        _writeSettings();
        notifyListeners();
      }
    }, onError: (_) {});
    if (!isAdmin) {
      if (purchasedPro) {
        _registerPro('purchase');
      } else if (devPro) {
        _registerPro('devcode');
      }
    }
    if (_devExpiredOnUpdate) {
      _devExpiredOnUpdate = false;
      _endPro('update');
    }
  }

  bool _devExpiredOnUpdate = false;

  bool exactAsked = false;
  bool? _lastExact;

  Future<bool> shouldAskExact() async {
    if (exactAsked || session == null) return false;
    try {
      final st = await notifications.status();
      _lastExact = st.exact;
      return st.enabled && !st.exact;
    } catch (_) {
      return false;
    }
  }

  Future<void> markExactAsked() async {
    exactAsked = true;
    await _writeSettings();
  }

  Future<void> refreshExact() async {
    if (session == null) return;
    try {
      final st = await notifications.status();
      if (_lastExact != null && _lastExact != st.exact) _scheduleNotifications();
      _lastExact = st.exact;
    } catch (_) {}
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

  bool isPersonal(Vehicle v) => v.fleetId == null || v.fleetId == data.personalFleetId;

  bool isMine(Vehicle v) {
    if (!isCloud) return true;
    if (v.createdBy.isNotEmpty) return v.createdBy == session?.key;
    return isPersonal(v);
  }

  GroupRole roleIn(String? fleetId) {
    if (isAdmin || fleetId == null || fleetId == data.personalFleetId) return GroupRole.admin;
    final g = data.groupById(fleetId);
    return g == null ? GroupRole.viewer : g.roleOf(session?.key);
  }

  bool canEdit(Vehicle v) => roleIn(isPersonal(v) ? null : v.fleetId) != GroupRole.viewer;

  bool canAddTo(String? fleetId) => roleIn(fleetId) != GroupRole.viewer;

  bool canManage(FleetGroup g) => isAdmin || g.roleOf(session?.key) == GroupRole.admin;

  static String normalizePlate(String p) => p.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  String? duplicatePlateGroup(Vehicle v, String? fleetId) {
    if (fleetId == null || fleetId == data.personalFleetId) return null;
    final plate = normalizePlate(v.plate);
    if (plate.isEmpty) return null;
    for (final o in vehicles) {
      if (o.id != v.id && o.fleetId == fleetId && normalizePlate(o.plate) == plate) {
        return data.groupById(fleetId)?.name ?? tr('family.defaultName');
      }
    }
    return null;
  }

  Future<void> setRole(FleetGroup g, String uid, GroupRole role) async {
    await sync.setRole(g.id, uid, role);
    g.admins.remove(uid);
    g.viewers.remove(uid);
    if (role == GroupRole.admin) g.admins.add(uid);
    if (role == GroupRole.viewer) g.viewers.add(uid);
    await _persist();
    notifyListeners();
  }

  Future<void> assignOwner(Vehicle v, String uid) async {
    final c = v.copy()..createdBy = uid;
    await saveVehicle(c);
  }

  bool sortNewestFirst = false;

  bool deadlinesSoonOnly = false;

  Future<void> setDeadlinesSoonOnly(bool on) async {
    deadlinesSoonOnly = on;
    notifyListeners();
    await _writeSettings();
  }

  Future<void> setSortNewestFirst(bool on) async {
    sortNewestFirst = on;
    notifyListeners();
    await _writeSettings();
  }

  List<Vehicle> sortedForList(Iterable<Vehicle> list) {
    final out = list.toList()
      ..sort((a, b) {
        final t = a.type.index.compareTo(b.type.index);
        if (t != 0) return t;
        final ra = a.registrationDate, rb = b.registrationDate;
        if (ra != null && rb != null) {
          final c = sortNewestFirst ? rb.compareTo(ra) : ra.compareTo(rb);
          if (c != 0) return c;
        } else if (ra != null) {
          return -1;
        } else if (rb != null) {
          return 1;
        }
        final n = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return n != 0 ? n : a.plate.compareTo(b.plate);
      });
    return out;
  }

  List<Vehicle> get myVehicles => sortedForList(vehicles.where(isMine));

  List<Vehicle> groupVehicles(String groupId) =>
      sortedForList(vehicles.where((v) => v.fleetId == groupId));

  String fleetLabel(Vehicle v) =>
      isPersonal(v) ? tr('fleet.mine') : (data.groupById(v.fleetId)?.name ?? tr('family.defaultName'));

  Vehicle? vehicleById(String id) {
    for (final v in data.vehicles) {
      if (v.id == id && !v.deleted) return v;
    }
    return null;
  }

  String? langPref;

  Future<void> init() async {
    final settings = await store.readSettings();
    theme = ThemeSettings.fromJson(settings);
    langPref = settings?['lang'] as String?;
    purchasedPro = settings?['pro'] == true;
    devPro = settings?['devPro'] == true;
    devProVersion = settings?['devProVersion'] as String?;
    sortNewestFirst = settings?['sortNewest'] == true;
    deadlinesSoonOnly = settings?['deadlinesSoon'] == true;
    exactAsked = settings?['exactAsked'] == true;
    if (devPro && devProVersion != appVersion) {
      devPro = false;
      devProVersion = null;
      _devExpiredOnUpdate = true;
      await _writeSettings();
    }
    notifyListeners();
    pro.init(
      onOwned: () {
        if (!purchasedPro) {
          purchasedPro = true;
          _writeSettings();
        }
        _registerPro('purchase');
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
      Future.delayed(const Duration(seconds: 3), () async {
        try {
          await notifications.requestPermission();
        } catch (_) {}
        _scheduleNotifications();
      });
    }
    UpdateService.instance.start(pushAvailable: auth.cloudAvailable);
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
      sync.saveProfile(s).catchError((_) {});
      await _loadWatch(s);
      _startSync();
      startPush();
      _watchProEntry();
    }
  }

  Future<void> _loadWatch(Session s) async {
    watch = await GroupWatchState.load();
    if (watch.uid != s.key) watch = GroupWatchState(uid: s.key);
    watch.groups = {for (final g in data.groups) g.id: g.name};
    if (isAdmin) {
      if (watch.adminSince == 0) watch.adminSince = DateTime.now().millisecondsSinceEpoch;
    } else {
      watch.adminSince = 0;
    }
    await watch.save();
    await scheduleGroupWatch(_watchNeeded);
    _watchAdmin();
  }

  bool get _watchNeeded => (watch.enabled && watch.groups.isNotEmpty) || watch.adminSince > 0;

  StreamSubscription? _adminSub;

  void _watchAdmin() {
    _adminSub?.cancel();
    _adminSub = null;
    if (!isAdmin) return;
    _adminSub = sync.watchAllPro().listen((entries) async {
      final saved = await GroupWatchState.load();
      final since = saved.adminSince > watch.adminSince ? saved.adminSince : watch.adminSince;
      if (since == 0) return;
      final fresh = newDevUnlocks(entries, since);
      if (fresh.isEmpty) return;
      watch.adminSince = latestUnlock(entries, since);
      await watch.save();
      await showDevUnlocks(notifications, fresh);
    }, onError: (_) {});
  }

  Future<void> _watchChain = Future.value();

  bool get groupAlerts => watch.enabled;

  Future<void> setGroupAlerts(bool on) async {
    watch.enabled = on;
    notifyListeners();
    await watch.save();
    await scheduleGroupWatch(_watchNeeded);
    if (on) notifications.requestPermission();
  }

  Future<void> _checkGroupActivity(
      String fleetId, List<Vehicle> remote, Set<String> existedBefore) async {
    final s = session;
    if (s == null || !isCloud) return;
    final fresh = await GroupWatchState.load();
    if (fresh.uid == s.key) {
      watch.seen = fresh.seen;
      watch.known = fresh.known;
    }
    final since = watch.seen[fleetId];
    var maxTs = since ?? 0;
    for (final r in remote) {
      if (r.updatedAt > maxTs) maxTs = r.updatedAt;
    }
    if (since == null) {
      watch.seen[fleetId] = remote.isEmpty ? DateTime.now().millisecondsSinceEpoch : maxTs;
      for (final r in remote) {
        if (!r.deleted) watch.remember(r.id);
      }
      await watch.save();
      return;
    }
    if (maxTs <= since) return;
    final acts = findActivities(
      groupName: data.groupById(fleetId)?.name ?? tr('family.defaultName'),
      me: s.key,
      myName: s.displayName,
      since: since,
      remote: remote,
      existed: (id) => existedBefore.contains(id) || watch.known.contains(id),
    );
    watch.seen[fleetId] = maxTs;
    for (final r in remote) {
      if (!r.deleted) watch.remember(r.id);
    }
    await watch.save();
    if (watch.enabled && acts.isNotEmpty) {
      await showActivities(notifications, acts);
    }
  }

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
    _proSub?.cancel();
    _proSub = null;
    _adminSub?.cancel();
    _adminSub = null;
    await scheduleGroupWatch(false);
    watch = GroupWatchState();
    await watch.save();
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

  Future<bool> deleteCloudAccount() async {
    final s = session;
    if (s == null || !isCloud) return true;
    sync.stop();
    _retry?.cancel();
    await push.stop();
    try {
      await sync.deleteAllData(s, List.of(data.groups));
    } catch (_) {
      _startSync();
      startPush();
      rethrow;
    }
    var complete = true;
    try {
      await auth.deleteCloudAccount();
    } on AuthException {
      complete = false;
    }
    await store.deleteUserData(s);
    await logout();
    return complete;
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
        await notifications.rescheduleAll(activeVehicles, data.notify);
      } catch (_) {}
    });
  }

  Future<void> saveVehicle(Vehicle v) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    v.updatedAt = now;
    v.updatedBy = session?.displayName ?? '';
    v.updatedByUid = session?.key ?? '';
    if (v.createdBy.isEmpty && vehicleById(v.id) == null) v.createdBy = session?.key ?? '';
    if (v.createdAt == 0 && vehicleById(v.id) == null) {
      v.createdAt = DateTime.now().millisecondsSinceEpoch;
    }
    if (v.fleetId == data.personalFleetId) v.fleetId = null;
    final i = data.vehicles.indexWhere((x) => x.id == v.id);
    if (i >= 0 && data.vehicles[i].fleetId != v.fleetId && isCloud) {
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

  Future<void> moveVehicle(String id, String? fleetId) async {
    final v = vehicleById(id);
    if (v == null) return;
    final moved = v.copy()..fleetId = fleetId;
    await saveVehicle(moved);
  }

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
        if (devProVersion != null) 'devProVersion': devProVersion,
        'sortNewest': sortNewestFirst,
        'deadlinesSoon': deadlinesSoonOnly,
        'exactAsked': exactAsked,
      });

  Future<void> setLanguage(String? code) async {
    langPref = code;
    await L10n.load(L10n.resolve(code));
    notifyListeners();
    await _writeSettings();
    _scheduleNotifications();
    try {
      await notifications.refreshChannels();
    } catch (_) {}
  }

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
          ..updatedByUid = cloud.key
          ..createdBy = cloud.key
          ..documents = [];
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
    if (isCloud) {
      final names = {for (final g in groups) g.id: g.name};
      final had = _watchNeeded;
      watch.groups = names;
      watch.seen.removeWhere((k, _) => !names.containsKey(k));
      watch.save();
      if (had != _watchNeeded) scheduleGroupWatch(_watchNeeded);
    }
    final valid = {data.personalFleetId, ...groups.map((g) => g.id)};
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
    if (!personal) {
      final existed = data.vehicles.where((v) => !v.deleted).map((v) => v.id).toSet();
      final copy = List.of(remote);
      _watchChain = _watchChain
          .then((_) => _checkGroupActivity(fleetId, copy, existed))
          .catchError((_) {});
    }
    for (final r in remote) {
      r.fleetId = personal ? null : fleetId;
      final i = data.vehicles.indexWhere((x) => x.id == r.id);
      if (i < 0) {
        r.documents = [];
        data.vehicles.add(r);
        changed = true;
      } else if (r.updatedAt > data.vehicles[i].updatedAt) {
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
