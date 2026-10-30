import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show DartPluginRegistrant;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

import '../firebase_config.dart';
import '../l10n.dart';
import '../models.dart';
import 'app_check.dart';
import 'auth_service.dart';
import 'local_store.dart';
import 'notification_log.dart';
import 'notification_service.dart';
import '../platform.dart';

class GroupWatchState {
  String uid;
  bool enabled;

  Map<String, int> seen;

  Map<String, String> groups;

  List<String> known;

  int adminSince;

  GroupWatchState({
    this.uid = '',
    this.enabled = true,
    Map<String, int>? seen,
    Map<String, String>? groups,
    List<String>? known,
    this.adminSince = 0,
  })  : seen = seen ?? {},
        groups = groups ?? {},
        known = known ?? [];

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/group_watch.json');
  }

  static Future<GroupWatchState> load() async {
    if (!isAndroid) return GroupWatchState();
    try {
      final f = await _file();
      if (!await f.exists()) return GroupWatchState();
      final j = Map<String, dynamic>.from(jsonDecode(await f.readAsString()) as Map);
      return GroupWatchState(
        uid: j['uid'] as String? ?? '',
        enabled: j['enabled'] as bool? ?? true,
        seen: Map<String, dynamic>.from((j['seen'] as Map?) ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
        groups: Map<String, dynamic>.from((j['groups'] as Map?) ?? {})
            .map((k, v) => MapEntry(k, v.toString())),
        known: ((j['known'] as List?) ?? []).map((e) => e.toString()).toList(),
        adminSince: (j['adminSince'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return GroupWatchState();
    }
  }

  Future<void> save() async {
    if (!isAndroid) return;
    try {
      final f = await _file();
      final tmp = File('${f.path}.tmp');
      if (known.length > 2000) known = known.sublist(known.length - 2000);
      await tmp.writeAsString(jsonEncode({
        'uid': uid,
        'enabled': enabled,
        'seen': seen,
        'groups': groups,
        'known': known,
        'adminSince': adminSince,
      }), flush: true);
      await tmp.rename(f.path);
    } catch (_) {}
  }

  void remember(String id) {
    if (!known.contains(id)) known.add(id);
  }
}

List<LogEntry> findActivities({
  required String groupId,
  required String groupName,
  required String me,
  required String myName,
  required int since,
  required Iterable<Vehicle> remote,
  required bool Function(String id) existed,
  Vehicle? Function(String id)? previous,
}) {
  final out = <LogEntry>[];
  for (final r in remote) {
    if (r.updatedAt <= since) continue;
    final mine = r.updatedByUid.isNotEmpty ? r.updatedByUid == me : r.updatedBy == myName;
    if (mine) continue;
    final label = r.name.isEmpty ? (r.plate.isEmpty ? tr('vehicle.generic') : r.plate) : r.name;
    final kind = r.deleted
        ? LogKind.deleted
        : existed(r.id)
            ? LogKind.edited
            : LogKind.added;
    if (kind == LogKind.deleted && !existed(r.id)) continue;
    out.add(LogEntry(
      ts: r.updatedAt,
      kind: kind,
      groupId: groupId,
      group: groupName,
      vehicleId: r.id,
      vehicle: label,
      who: r.updatedBy,
      parts: kind == LogKind.edited ? changedParts(previous?.call(r.id), r) : null,
      items: kind == LogKind.edited ? changedItems(previous?.call(r.id), r) : null,
    ));
  }
  return out;
}

Future<void> recordActivities(
  LocalStore store,
  Session session,
  NotificationService n,
  List<LogEntry> acts, {
  bool show = true,
}) async {
  if (acts.isEmpty) return;
  final log = NotificationLog.fromJson(await store.readNotifLog(session));
  for (final a in acts) {
    log.addActivity(a);
  }
  await store.writeNotifLog(session, log.toJson());
  if (!show) return;
  final groups = {for (final a in acts) a.groupId: a.group};
  for (final g in groups.entries) {
    await n.showGroup(g.key, g.value, log.unreadOfGroup(g.key));
  }
}

Future<void> recordReminders(LocalStore store, Session session, NotificationService n, UserData data) async {
  final log = NotificationLog.fromJson(await store.readNotifLog(session));
  final now = DateTime.now().millisecondsSinceEpoch;
  if (log.reminderSince == 0) {
    log.reminderSince = now;
    await store.writeNotifLog(session, log.toJson());
    return;
  }
  final fired = await n.firedReminders(
      data.vehicles.where((v) => !v.deleted).toList(), data.notify, log.reminderSince, now);
  for (final r in fired) {
    log.addReminder(r.when, r.title, r.body, r.vehicleId);
  }
  log.reminderSince = now;
  await store.writeNotifLog(session, log.toJson());
}

List<Map<String, dynamic>> newDevUnlocks(Iterable<Map<String, dynamic>> entries, int since) {
  final out = entries
      .where((e) => e['method'] == 'devcode' && ((e['since'] as num?)?.toInt() ?? 0) > since)
      .toList()
    ..sort((a, b) => ((a['since'] as num?) ?? 0).compareTo((b['since'] as num?) ?? 0));
  return out;
}

int latestUnlock(Iterable<Map<String, dynamic>> entries, int since) {
  var m = since;
  for (final e in entries) {
    final t = (e['since'] as num?)?.toInt() ?? 0;
    if (e['method'] == 'devcode' && t > m) m = t;
  }
  return m;
}

Future<void> showDevUnlocks(NotificationService n, List<Map<String, dynamic>> list) async {
  const title = 'Codice sviluppatore usato';
  if (list.length > 3) {
    await n.showRemote(title, '${list.length} utenti hanno sbloccato la Pro con il codice');
    return;
  }
  for (final e in list) {
    final name = (e['name'] as String?)?.trim() ?? '';
    final email = (e['email'] as String?) ?? '';
    final who = name.isEmpty ? (email.isEmpty ? 'Un utente' : email) : (email.isEmpty ? name : '$name ($email)');
    await n.showRemote(title, '$who ha sbloccato la Pro (versione ${e['appVersion'] ?? '?'})');
  }
}

const String groupWatchTask = 'myfleet-group-watch';

const String groupWatchTestTask = 'myfleet-group-watch-test';

Future<bool> testGroupWatchNow() async {
  if (!isAndroid) return false;
  try {
    await Workmanager().registerOneOffTask(
      groupWatchTestTask,
      groupWatchTask,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> scheduleGroupWatch(bool on) async {
  if (!isAndroid) return;
  try {
    if (on) {
      await Workmanager().registerPeriodicTask(
        groupWatchTask,
        groupWatchTask,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } else {
      await Workmanager().cancelByUniqueName(groupWatchTask);
    }
  } catch (_) {}
}

Future<void> initGroupWatch() async {
  if (!isAndroid) return;
  try {
    await Workmanager().initialize(groupWatchDispatcher);
  } catch (_) {}
}

@pragma('vm:entry-point')
void groupWatchDispatcher() {
  Workmanager().executeTask((task, input) async {
    try {
      await _backgroundCheck();
    } catch (e) {
      try {
        await LocalStore().addWatchLog('errore: ${_short(e)}');
      } catch (_) {}
    }
    return true;
  });
}

String _short(Object e) {
  final t = e.toString().replaceAll('\n', ' ');
  return t.length > 140 ? '${t.substring(0, 140)}…' : t;
}

Future<void> _backgroundCheck() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  final store = LocalStore();
  final w = await GroupWatchState.load();
  final groupsOn = w.enabled && w.groups.isNotEmpty;
  if (w.uid.isEmpty || (!groupsOn && w.adminSince == 0)) {
    await store.addWatchLog(w.uid.isEmpty ? 'fermo: nessun account' : 'fermo: avvisi dei gruppi spenti o nessun gruppo');
    return;
  }

  final settings = await store.readSettings();
  await L10n.load(L10n.resolve(settings?['lang'] as String?));

  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: FirebaseConfig.apiKey,
          appId: FirebaseConfig.appId,
          messagingSenderId: FirebaseConfig.messagingSenderId,
          projectId: FirebaseConfig.projectId,
          storageBucket: FirebaseConfig.storageBucket,
        ),
      );
    }
  }
  await startAppCheck();
  final session0 = await store.readSession();
  var user = await restoredUser();
  if (user == null && session0 != null && session0.key == w.uid) {
    final ok = await silentGoogle(session0);
    await store.addAuthLog(ok ? 'background: accesso Google ripristinato' : 'background: accesso assente ($lastSilent)');
    user = FirebaseAuth.instance.currentUser;
  }
  if (user == null || user.uid != w.uid) {
    await store.addWatchLog(user == null ? 'fermo: accesso Firebase assente' : 'fermo: account Firebase diverso');
    return;
  }

  final session = await store.readSession();
  final localIds = <String>{};
  final localById = <String, Vehicle>{};
  var myName = '';
  UserData? local;
  if (session != null && session.key == w.uid) {
    myName = session.displayName;
    local = await store.readUserData(session);
    localIds.addAll(local.vehicles.where((v) => !v.deleted).map((v) => v.id));
    for (final v in local.vehicles) {
      localById[v.id] = v;
    }
  }

  final db = FirebaseFirestore.instance;
  final acts = <LogEntry>[];
  var unlocks = <Map<String, dynamic>>[];
  if (w.adminSince > 0) {
    try {
      final snap = await db
          .collection('pro')
          .where('since', isGreaterThan: w.adminSince)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 25));
      final entries = snap.docs.map((d) => d.data()).toList();
      unlocks = newDevUnlocks(entries, w.adminSince);
      w.adminSince = latestUnlock(entries, w.adminSince);
    } catch (_) {}
  }
  var checked = 0;
  var skipped = 0;
  final errors = <String>[];
  for (final g in (groupsOn ? w.groups : const <String, String>{}).entries) {
    final since = w.seen[g.key];
    if (since == null) {
      skipped++;
      continue;
    }
    try {
      final snap = await db
          .collection('fleets')
          .doc(g.key)
          .collection('vehicles')
          .where('updatedAt', isGreaterThan: since)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 25));
      final remote = <Vehicle>[];
      for (final d in snap.docs) {
        try {
          remote.add(Vehicle.fromJson(d.data()));
        } catch (_) {}
      }
      acts.addAll(findActivities(
        groupId: g.key,
        groupName: g.value,
        me: w.uid,
        myName: myName,
        since: since,
        remote: remote,
        existed: (id) => localIds.contains(id) || w.known.contains(id),
        previous: (id) => localById[id],
      ));
      var maxTs = since;
      for (final r in remote) {
        maxTs = math.max(maxTs, r.updatedAt);
        if (!r.deleted) w.remember(r.id);
      }
      w.seen[g.key] = maxTs;
      checked++;
    } catch (e) {
      errors.add('${g.value}: ${_short(e)}');
    }
  }
  await store.addWatchLog([
    'gruppi controllati $checked',
    if (skipped > 0) 'mai aperti $skipped',
    'modifiche ${acts.length}',
    ...errors,
  ].join(' · '));
  final latest = await GroupWatchState.load();
  if (latest.uid != w.uid) return;
  final freshUnlocks = latest.adminSince > 0
      ? unlocks.where((e) => ((e['since'] as num?)?.toInt() ?? 0) > latest.adminSince).toList()
      : <Map<String, dynamic>>[];
  if (latest.adminSince > 0 && w.adminSince > latest.adminSince) latest.adminSince = w.adminSince;
  if (!latest.enabled) {
    await latest.save();
    if (freshUnlocks.isNotEmpty) await showDevUnlocks(NotificationService(), freshUnlocks);
    return;
  }
  for (final e in w.seen.entries) {
    latest.seen[e.key] = math.max(latest.seen[e.key] ?? 0, e.value);
  }
  for (final id in w.known) {
    latest.remember(id);
  }
  await latest.save();
  final n = NotificationService();
  if (freshUnlocks.isNotEmpty) await showDevUnlocks(n, freshUnlocks);
  if (session != null && session.key == w.uid) {
    await recordActivities(store, session, n, acts);
    if (local != null) await recordReminders(store, session, n, local);
  }
}
