import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;

import '../l10n.dart';
import '../models.dart';

/// Errore con messaggio già pronto da mostrare all'utente.
class FleetException implements Exception {
  final String message;
  FleetException(this.message);
  @override
  String toString() => message;
}

/// Traduce gli errori di Firestore in messaggi comprensibili.
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

/// Sincronizzazione online con Firestore.
///
/// Struttura:
///  fleets/{uid}              parco personale dell'utente (personal: true)
///  fleets/{codice}           nucleo familiare condiviso (il codice è l'invito)
///  fleets/{id}/vehicles/{v}  veicoli del parco
///
/// I dati restano sempre salvati in locale; Firestore tiene in coda le modifiche
/// fatte offline e le invia appena torna la connessione.
class SyncService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _fleets => _db.collection('fleets');

  static const Duration _timeout = Duration(seconds: 20);

  StreamSubscription? _groupsSub;
  final Map<String, StreamSubscription> _vehSubs = {};
  final Set<String> _initialPushDone = {};

  /// Crea (se manca) il parco personale. Richiede connessione.
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
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    }).timeout(_timeout);
    return FleetGroup(id: id, name: name, ownerUid: s.key, members: {s.key: email});
  }

  /// Entra in un nucleo familiare con il codice invito.
  Future<FleetGroup> joinGroup(Session s, String code) async {
    final id = code.trim().toUpperCase().replaceAll(' ', '');
    if (id.isEmpty || id == s.key) throw FleetException(tr('family.badCode'));
    final ref = _fleets.doc(id);
    final snap = await ref.get(const GetOptions(source: Source.server)).timeout(_timeout);
    final data = snap.data();
    if (!snap.exists || data == null || data['personal'] == true) {
      throw FleetException(tr('family.badCode'));
    }
    await ref.update({
      'members': FieldValue.arrayUnion([s.key]),
      'memberEmails.${s.key}': s.email ?? s.displayName,
    }).timeout(_timeout);
    return FleetGroup(
      id: id,
      name: (data['name'] as String?) ?? tr('family.defaultName'),
      ownerUid: (data['ownerUid'] as String?) ?? '',
    );
  }

  /// Veicoli (non eliminati) presenti in un gruppo, letti dal server.
  Future<int> countGroupVehicles(String id) async {
    final q = await _fleets
        .doc(id)
        .collection('vehicles')
        .get(const GetOptions(source: Source.server))
        .timeout(_timeout);
    return q.docs.where((d) => d.data()['deleted'] != true).length;
  }

  /// Cancellazione dell'account: elimina i dati online dell'utente.
  /// I gruppi creati da lui vengono eliminati (con i loro veicoli); da quelli
  /// degli altri esce soltanto.
  Future<void> deleteAllData(Session s, List<FleetGroup> groups) async {
    final uid = s.key;
    Future<void> wipe(String fleetId) async {
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
        await leaveGroup(s, g.id).timeout(_timeout);
      }
    }
    await wipe(uid);
    await _fleets.doc(uid).delete().timeout(_timeout);
    await _db.collection('users').doc(uid).delete().timeout(_timeout);
  }

  Future<void> leaveGroup(Session s, String id) => _fleets.doc(id).update({
        'members': FieldValue.arrayRemove([s.key]),
        'memberEmails.${s.key}': FieldValue.delete(),
      });

  Future<void> removeMember(String groupId, String uid) => _fleets.doc(groupId).update({
        'members': FieldValue.arrayRemove([uid]),
        'memberEmails.$uid': FieldValue.delete(),
      });

  Future<void> deleteGroup(String id) => _fleets.doc(id).delete();

  Future<void> renameGroup(String id, String name) => _fleets.doc(id).update({'name': name});

  /// Ascolta: elenco dei miei nuclei + veicoli di ogni parco (personale e nuclei).
  void start({
    required Session session,
    required String personalId,
    required void Function(List<FleetGroup> groups) onGroups,
    required void Function(String fleetId, List<Vehicle> remote, bool fromServer) onVehicles,
    required List<Vehicle> Function(String fleetId) localVehicles,
  }) {
    stop();
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
        ));
      }
      // Aggiorna gli ascolti dei veicoli dei nuclei
      final wanted = {personalId, ...groups.map((g) => g.id)};
      for (final id in _vehSubs.keys.toList()) {
        if (!wanted.contains(id)) {
          _vehSubs.remove(id)?.cancel();
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

  void stop() {
    _groupsSub?.cancel();
    _groupsSub = null;
    for (final s in _vehSubs.values) {
      s.cancel();
    }
    _vehSubs.clear();
    _initialPushDone.clear();
  }
}
