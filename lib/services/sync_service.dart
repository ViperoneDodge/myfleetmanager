import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../l10n.dart';
import '../models.dart';

class FleetException implements Exception {
  final String message;
  FleetException(this.message);
  @override
  String toString() => message;
}

String cloudErrorMessage(Object e) {
  if (e is FleetException) return e.message;
  if (e is TimeoutException) return tr('cloud.offline');
  if (e is FirebaseException) {
    switch (e.code) {
      case 'permission-denied':
        return tr('cloud.permissionDenied');
      case 'not-found':
        return (e.message ?? '').contains('database')
            ? tr('cloud.noDatabase')
            : tr('family.badCode');
      case 'unavailable':
      case 'deadline-exceeded':
        return tr('cloud.offline');
      case 'unauthenticated':
        return tr('cloud.unauthenticated');
      default:
        return tr('cloud.generic', {'code': e.code});
    }
  }
  return tr('cloud.generic', {'code': e.toString()});
}

class SyncService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _fleets => _db.collection('fleets');

  static const Duration _timeout = Duration(seconds: 20);

  StreamSubscription? _groupsSub;
  final Map<String, StreamSubscription> _vehSubs = {};
  final Map<String, StreamSubscription> _docSubs = {};
  void Function(String fleetId, List<Map<String, dynamic>> docs)? _onDocs;
  final Set<String> _initialPushDone = {};

  Future<String> ensurePersonal(Session s) async {
    final ref = _fleets.doc(s.key);
    final snap = await ref.get(const GetOptions(source: Source.server));
    if (!snap.exists) {
      await ref.set({
        'personal': true,
        'name': 'I miei veicoli',
        'ownerUid': s.key,
        'members': [s.key],
        'memberEmails': {s.key: s.email ?? s.displayName},
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
    return s.key;
  }

  Future<FleetGroup> createGroup(Session s, String name) async {
    final id = newId(10);
    final email = s.email ?? s.displayName;
    await _fleets.doc(id).set({
      'personal': false,
      'name': name,
      'ownerUid': s.key,
      'members': [s.key],
      'memberEmails': {s.key: email},
      'admins': [s.key],
      'viewers': [],
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    }).timeout(_timeout);
    return FleetGroup(id: id, name: name, ownerUid: s.key, members: {s.key: email}, admins: {s.key});
  }

  Future<FleetGroup> joinGroup(Session s, String code) async {
    final id = code.trim().toUpperCase().replaceAll(' ', '');
    if (id.isEmpty || id == s.key) throw FleetException(tr('family.badCode'));
    final ref = _fleets.doc(id);
    final snap = await ref.get(const GetOptions(source: Source.server)).timeout(_timeout);
    final data = snap.data();
    if (!snap.exists || data == null || data['personal'] == true) {
      throw FleetException(tr('family.badCode'));
    }
    final already = ((data['members'] as List?) ?? const []).contains(s.key);
    if (!already) {
      await ref.update({
        'members': FieldValue.arrayUnion([s.key]),
        'memberEmails.${s.key}': s.email ?? s.displayName,
        'viewers': FieldValue.arrayUnion([s.key]),
      }).timeout(_timeout);
    }
    return FleetGroup(
      id: id,
      name: (data['name'] as String?) ?? tr('family.defaultName'),
      ownerUid: (data['ownerUid'] as String?) ?? '',
      viewers: already ? {} : {s.key},
    );
  }

  CollectionReference<Map<String, dynamic>> get _pro => _db.collection('pro');

  Future<void> registerPro(Session s, {required String method, required String version}) async {
    final ref = _pro.doc(s.key);
    final snap = await ref.get().timeout(_timeout);
    final now = DateTime.now().millisecondsSinceEpoch;
    final old = snap.data();
    final m = (old?['method'] == 'purchase') ? 'purchase' : method;
    final data = <String, dynamic>{
      'uid': s.key,
      'email': s.email ?? '',
      'name': s.displayName,
      'method': m,
      'active': true,
      'updatedAt': now,
      'appVersion': version,
      'endedReason': null,
    };
    if (old == null) {
      data['since'] = now;
      data['revoked'] = false;
    } else if (old['active'] != true) {
      data['since'] = now;
    }
    await ref.set(data, SetOptions(merge: true)).timeout(_timeout);
  }

  Future<void> endPro(Session s, String reason) async {
    final ref = _pro.doc(s.key);
    final snap = await ref.get().timeout(_timeout);
    final old = snap.data();
    if (old == null || old['method'] == 'purchase') return;
    await ref.set({
      'active': false,
      'endedReason': reason,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true)).timeout(_timeout);
  }

  Future<void> saveProfile(Session s) => _db.collection('users').doc(s.key).set({
        'name': s.displayName,
        'email': s.email ?? '',
        'seenAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true)).timeout(_timeout);

  Stream<List<Map<String, dynamic>>> watchAllUsers() => _db
      .collection('users')
      .snapshots()
      .map((q) => q.docs.map((d) => {...d.data(), 'uid': d.id}..remove('tokens')).toList());

  Stream<List<Map<String, dynamic>>> watchAllFleets() =>
      _fleets.snapshots().map((q) => q.docs.map((d) => {...d.data(), 'id': d.id}).toList());

  Stream<List<Vehicle>> watchAllVehicles() =>
      _db.collectionGroup('vehicles').snapshots().map((q) {
        final out = <Vehicle>[];
        for (final d in q.docs) {
          final fleet = d.reference.parent.parent?.id;
          if (fleet == null) continue;
          try {
            final v = Vehicle.fromJson(d.data())..fleetId = fleet;
            if (!v.deleted) out.add(v);
          } catch (_) {}
        }
        return out;
      });

  Future<void> reassignVehicle(Vehicle v, String toUid,
      {required bool personal, required Session admin}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final from = v.fleetId!;
    final updated = Vehicle.fromJson(v.toJson(includeDocs: false))
      ..createdBy = toUid
      ..updatedAt = now
      ..updatedBy = admin.displayName
      ..updatedByUid = admin.key
      ..documents = [];
    if (!personal) {
      await _fleets
          .doc(from)
          .collection('vehicles')
          .doc(v.id)
          .set(updated.toJson(includeDocs: false))
          .timeout(_timeout);
      return;
    }
    final moved = updated..id = newId();
    final tomb = Vehicle.fromJson(v.toJson(includeDocs: false))
      ..deleted = true
      ..photoB64 = null
      ..updatedAt = now
      ..updatedBy = admin.displayName
      ..updatedByUid = admin.key;
    final batch = _db.batch()
      ..set(_fleets.doc(toUid).collection('vehicles').doc(moved.id), moved.toJson(includeDocs: false))
      ..set(_fleets.doc(from).collection('vehicles').doc(v.id), tomb.toJson(includeDocs: false));
    await batch.commit().timeout(_timeout);
  }

  Future<bool> checkUnlockCode(String code) async {
    if (code.contains('/') || code == '.' || code == '..' || code.length > 100) return false;
    final snap = await _db
        .collection('unlock')
        .doc(code)
        .get(const GetOptions(source: Source.server))
        .timeout(_timeout);
    return snap.exists && snap.data()?['active'] != false;
  }

  Future<bool> isProRevoked(Session s) async {
    final snap = await _pro.doc(s.key).get(const GetOptions(source: Source.server)).timeout(_timeout);
    return snap.data()?['revoked'] == true;
  }

  Stream<Map<String, dynamic>?> watchPro(Session s) =>
      _pro.doc(s.key).snapshots().map((d) => d.data());

  Stream<List<Map<String, dynamic>>> watchAllPro() =>
      _pro.snapshots().map((q) => q.docs.map((d) => {...d.data(), 'uid': d.id}).toList());

  Future<void> revokeDevPro(String uid) => _pro.doc(uid).set({
        'revoked': true,
        'active': false,
        'revokedAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true)).timeout(_timeout);

  Future<void> restoreDevPro(String uid) => _pro.doc(uid).set({
        'revoked': false,
        'revokedAt': null,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true)).timeout(_timeout);

  Future<int> countGroupVehicles(String id) async {
    final q = await _fleets
        .doc(id)
        .collection('vehicles')
        .get(const GetOptions(source: Source.server))
        .timeout(_timeout);
    return q.docs.where((d) => d.data()['deleted'] != true).length;
  }

  Future<void> deleteAllData(Session s, List<FleetGroup> groups) async {
    final uid = s.key;
    Future<void> wipe(String fleetId) async {
      try {
        await deleteDocs(fleetId);
      } catch (_) {}
      final q = await _fleets
          .doc(fleetId)
          .collection('vehicles')
          .get(const GetOptions(source: Source.server))
          .timeout(_timeout);
      for (final d in q.docs) {
        await d.reference.delete().timeout(_timeout);
      }
    }

    for (final g in groups) {
      if (g.ownerUid == uid) {
        await wipe(g.id);
        await _fleets.doc(g.id).delete().timeout(_timeout);
      } else {
        try {
          await deleteDocs(g.id, by: uid);
        } catch (_) {}
        await leaveGroup(s, g.id).timeout(_timeout);
      }
    }
    await wipe(uid);
    await _fleets.doc(uid).delete().timeout(_timeout);
    await _db.collection('users').doc(uid).delete().timeout(_timeout);
    try {
      await _pro.doc(uid).delete().timeout(_timeout);
    } catch (_) {}
  }

  Future<void> leaveGroup(Session s, String id) => _fleets.doc(id).update({
        'members': FieldValue.arrayRemove([s.key]),
        'memberEmails.${s.key}': FieldValue.delete(),
        'viewers': FieldValue.arrayRemove([s.key]),
        'admins': FieldValue.arrayRemove([s.key]),
      });

  Future<void> removeMember(String groupId, String uid) => _fleets.doc(groupId).update({
        'members': FieldValue.arrayRemove([uid]),
        'memberEmails.$uid': FieldValue.delete(),
        'viewers': FieldValue.arrayRemove([uid]),
      });

  Future<void> setRole(String groupId, String uid, GroupRole role) {
    final Map<String, dynamic> change;
    switch (role) {
      case GroupRole.admin:
        change = {'admins': FieldValue.arrayUnion([uid]), 'viewers': FieldValue.arrayRemove([uid])};
        break;
      case GroupRole.editor:
        change = {'admins': FieldValue.arrayRemove([uid]), 'viewers': FieldValue.arrayRemove([uid])};
        break;
      case GroupRole.viewer:
        change = {'admins': FieldValue.arrayRemove([uid]), 'viewers': FieldValue.arrayUnion([uid])};
        break;
    }
    return _fleets.doc(groupId).update(change).timeout(_timeout);
  }

  Future<void> deleteGroup(String id) => _fleets.doc(id).delete();

  Future<void> renameGroup(String id, String name) => _fleets.doc(id).update({'name': name});

  void start({
    required Session session,
    required String personalId,
    required void Function(List<FleetGroup> groups) onGroups,
    required void Function(String fleetId, List<Vehicle> remote, bool fromServer) onVehicles,
    required List<Vehicle> Function(String fleetId) localVehicles,
    required void Function(String fleetId, List<Map<String, dynamic>> docs) onDocs,
  }) {
    stop();
    _onDocs = onDocs;
    _listenVehicles(personalId, onVehicles, localVehicles);
    _groupsSub = _fleets
        .where('members', arrayContains: session.key)
        .snapshots()
        .listen((snap) {
      final groups = <FleetGroup>[];
      for (final d in snap.docs) {
        final data = d.data();
        if (data['personal'] == true) continue;
        final emails = Map<String, dynamic>.from((data['memberEmails'] as Map?) ?? {});
        final members = <String, String>{};
        for (final uid in ((data['members'] as List?) ?? [])) {
          members[uid.toString()] = (emails[uid] ?? uid).toString();
        }
        groups.add(FleetGroup(
          id: d.id,
          name: (data['name'] as String?) ?? tr('family.defaultName'),
          ownerUid: (data['ownerUid'] as String?) ?? '',
          members: members,
          admins: ((data['admins'] as List?) ?? const []).map((e) => e.toString()).toSet(),
          viewers: ((data['viewers'] as List?) ?? const []).map((e) => e.toString()).toSet(),
          shareDocs: data['shareDocs'] == true,
        ));
      }
      final wanted = {personalId, ...groups.map((g) => g.id)};
      for (final id in _vehSubs.keys.toList()) {
        if (!wanted.contains(id)) {
          _vehSubs.remove(id)?.cancel();
          _docSubs.remove(id)?.cancel();
          _initialPushDone.remove(id);
        }
      }
      for (final g in groups) {
        _listenVehicles(g.id, onVehicles, localVehicles);
      }
      if (!snap.metadata.isFromCache) onGroups(groups);
    }, onError: (_) {});
  }

  void _listenVehicles(
    String fleetId,
    void Function(String, List<Vehicle>, bool) onVehicles,
    List<Vehicle> Function(String) localVehicles,
  ) {
    if (_vehSubs.containsKey(fleetId)) return;
    _docSubs[fleetId] = _fleets.doc(fleetId).collection('docs').snapshots().listen((snap) {
      if (snap.metadata.isFromCache && snap.docs.isEmpty) return;
      _onDocs?.call(fleetId, [for (final d in snap.docs) d.data()..['id'] = d.id]);
    }, onError: (_) {});
    _vehSubs[fleetId] = _fleets
        .doc(fleetId)
        .collection('vehicles')
        .snapshots(includeMetadataChanges: true)
        .listen((snap) {
      final remote = <Vehicle>[];
      for (final d in snap.docs) {
        try {
          remote.add(Vehicle.fromJson(d.data())..fleetId = fleetId);
        } catch (_) {}
      }
      final fromServer = !snap.metadata.isFromCache;
      onVehicles(fleetId, remote, fromServer);
      if (fromServer && !_initialPushDone.contains(fleetId)) {
        _initialPushDone.add(fleetId);
        final byId = {for (final r in remote) r.id: r};
        for (final v in localVehicles(fleetId)) {
          final r = byId[v.id];
          if (r == null || v.updatedAt > r.updatedAt) push(fleetId, v);
        }
      }
    }, onError: (_) {});
  }

  void push(String fleetId, Vehicle v) {
    _fleets
        .doc(fleetId)
        .collection('vehicles')
        .doc(v.id)
        .set(v.toJson(includeDocs: false))
        .catchError((_) {});
  }

  CollectionReference<Map<String, dynamic>> _docs(String fleetId) =>
      _fleets.doc(fleetId).collection('docs');

  Future<void> uploadDoc(String fleetId, Map<String, dynamic> meta, String b64) {
    final ref = _docs(fleetId).doc(meta['id'] as String);
    final batch = _db.batch()
      ..set(ref, meta)
      ..set(ref.collection('data').doc('p0'), {'b64': b64});
    return batch.commit().timeout(const Duration(seconds: 60));
  }

  Future<void> renameDoc(String fleetId, String id, String name) =>
      _docs(fleetId).doc(id).update({'name': name}).timeout(_timeout);

  Future<void> deleteDoc(String fleetId, String id) {
    final ref = _docs(fleetId).doc(id);
    final batch = _db.batch()
      ..delete(ref.collection('data').doc('p0'))
      ..delete(ref);
    return batch.commit().timeout(_timeout);
  }

  Future<String?> downloadDoc(String fleetId, String id) async {
    final snap = await _docs(fleetId)
        .doc(id)
        .collection('data')
        .doc('p0')
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 60));
    return snap.data()?['b64'] as String?;
  }

  Future<void> deleteDocs(String fleetId, {String? by}) async {
    Query<Map<String, dynamic>> q = _docs(fleetId);
    if (by != null) q = q.where('by', isEqualTo: by);
    final snap = await q.get(const GetOptions(source: Source.server)).timeout(_timeout);
    for (final d in snap.docs) {
      await deleteDoc(fleetId, d.id);
    }
  }

  Future<void> setShareDocs(String fleetId, bool on) =>
      _fleets.doc(fleetId).update({'shareDocs': on}).timeout(_timeout);

  void stop() {
    _groupsSub?.cancel();
    _groupsSub = null;
    for (final s in _vehSubs.values) {
      s.cancel();
    }
    _vehSubs.clear();
    for (final s in _docSubs.values) {
      s.cancel();
    }
    _docSubs.clear();
    _initialPushDone.clear();
  }
}
