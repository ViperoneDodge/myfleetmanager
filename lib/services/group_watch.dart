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
import 'local_store.dart';
import 'notification_service.dart';

/// Avvisi sulle attività dei gruppi: quando un ALTRO membro aggiunge,
/// modifica o elimina un veicolo di un gruppo.
///
/// Senza server:
///  - ad app aperta (o rimasta in memoria) l'avviso parte subito, dall'ascolto Firestore;
///  - ad app chiusa Android esegue [groupWatchDispatcher] circa ogni 15 minuti
///    (Android può ritardarlo per risparmiare batteria).
///
/// Lo stato è in group_watch.json, condiviso fra app e controllo in background,
/// così la stessa modifica non viene notificata due volte.
class GroupWatchState {
  String uid;
  bool enabled;

  /// Per ogni gruppo: updatedAt più recente già visto.
  Map<String, int> seen;

  /// Gruppi da controllare (id → nome).
  Map<String, String> groups;

  /// Veicoli già conosciuti (per distinguere "aggiunto" da "modificato").
  List<String> known;

  GroupWatchState({
    this.uid = '',
    this.enabled = true,
    Map<String, int>? seen,
    Map<String, String>? groups,
    List<String>? known,
  })  : seen = seen ?? {},
        groups = groups ?? {},
        known = known ?? [];

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/group_watch.json');
  }

  static Future<GroupWatchState> load() async {
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
      );
    } catch (_) {
      return GroupWatchState();
    }
  }

  Future<void> save() async {
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
      }), flush: true);
      await tmp.rename(f.path);
    } catch (_) {}
  }

  void remember(String id) {
    if (!known.contains(id)) known.add(id);
  }
}

enum GroupAction { added, edited, deleted }

class GroupActivity {
  final String groupName;
  final String who;
  final String vehicle;
  final GroupAction action;
  GroupActivity(this.groupName, this.who, this.vehicle, this.action);

  String get text {
    final w = who.isEmpty ? tr('groupAct.someone') : who;
    switch (action) {
      case GroupAction.added:
        return tr('groupAct.added', {'who': w, 'vehicle': vehicle});
      case GroupAction.edited:
        return tr('groupAct.edited', {'who': w, 'vehicle': vehicle});
      case GroupAction.deleted:
        return tr('groupAct.deleted', {'who': w, 'vehicle': vehicle});
    }
  }
}

/// Modifiche fatte da altri (non da [me]) più recenti di [since].
/// [existed] dice se il veicolo era già conosciuto sul telefono.
List<GroupActivity> findActivities({
  required String groupName,
  required String me,
  required String myName,
  required int since,
  required Iterable<Vehicle> remote,
  required bool Function(String id) existed,
}) {
  final out = <GroupActivity>[];
  for (final r in remote) {
    if (r.updatedAt <= since) continue;
    final mine = r.updatedByUid.isNotEmpty ? r.updatedByUid == me : r.updatedBy == myName;
    if (mine) continue;
    final label = r.name.isEmpty ? (r.plate.isEmpty ? tr('vehicle.generic') : r.plate) : r.name;
    final action = r.deleted
        ? GroupAction.deleted
        : existed(r.id)
            ? GroupAction.edited
            : GroupAction.added;
    // Un veicolo creato ed eliminato fra due controlli: niente da dire.
    if (action == GroupAction.deleted && !existed(r.id)) continue;
    out.add(GroupActivity(groupName, r.updatedBy, label, action));
  }
  return out;
}

/// Mostra gli avvisi: fino a 3 singoli per gruppo, altrimenti un riepilogo.
Future<void> showActivities(NotificationService n, List<GroupActivity> acts) async {
  final byGroup = <String, List<GroupActivity>>{};
  for (final a in acts) {
    byGroup.putIfAbsent(a.groupName, () => []).add(a);
  }
  for (final e in byGroup.entries) {
    if (e.value.length <= 3) {
      for (final a in e.value) {
        await n.showRemote(e.key, a.text);
      }
    } else {
      await n.showRemote(e.key, tr('groupAct.many', {'n': e.value.length}));
    }
  }
}

const String groupWatchTask = 'myfleet-group-watch';

/// Attiva (o disattiva) il controllo periodico ad app chiusa.
Future<void> scheduleGroupWatch(bool on) async {
  if (!Platform.isAndroid) return;
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

/// Da chiamare una volta in main().
Future<void> initGroupWatch() async {
  if (!Platform.isAndroid) return;
  try {
    await Workmanager().initialize(groupWatchDispatcher);
  } catch (_) {}
}

@pragma('vm:entry-point')
void groupWatchDispatcher() {
  Workmanager().executeTask((task, input) async {
    try {
      await _backgroundCheck();
    } catch (_) {}
    return true;
  });
}

Future<void> _backgroundCheck() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  final w = await GroupWatchState.load();
  if (!w.enabled || w.uid.isEmpty || w.groups.isEmpty) return;

  final store = LocalStore();
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
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.uid != w.uid) return;

  // Veicoli già presenti sul telefono (ultimo salvataggio dell'app).
  final session = await store.readSession();
  final localIds = <String>{};
  var myName = '';
  if (session != null && session.key == w.uid) {
    myName = session.displayName;
    final data = await store.readUserData(session);
    localIds.addAll(data.vehicles.where((v) => !v.deleted).map((v) => v.id));
  }

  final db = FirebaseFirestore.instance;
  final acts = <GroupActivity>[];
  for (final g in w.groups.entries) {
    final since = w.seen[g.key];
    if (since == null) continue; // gruppo nuovo: lo inizializza l'app all'apertura
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
        groupName: g.value,
        me: w.uid,
        myName: myName,
        since: since,
        remote: remote,
        existed: (id) => localIds.contains(id) || w.known.contains(id),
      ));
      var maxTs = since;
      for (final r in remote) {
        maxTs = math.max(maxTs, r.updatedAt);
        if (!r.deleted) w.remember(r.id);
      }
      w.seen[g.key] = maxTs;
    } catch (_) {}
  }
  // Rilegge lo stato: l'app potrebbe averlo aggiornato nel frattempo.
  final latest = await GroupWatchState.load();
  if (!latest.enabled || latest.uid != w.uid) return;
  for (final e in w.seen.entries) {
    latest.seen[e.key] = math.max(latest.seen[e.key] ?? 0, e.value);
  }
  for (final id in w.known) {
    latest.remember(id);
  }
  await latest.save();
  if (acts.isNotEmpty) await showActivities(NotificationService(), acts);
}
