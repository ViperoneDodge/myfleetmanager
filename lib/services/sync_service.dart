import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models.dart';

class FleetMember {
  final String uid;
  final String email;
  final bool owner;
  FleetMember(this.uid, this.email, this.owner);
}

/// Sincronizzazione del parco auto familiare con Firestore.
/// I dati restano sempre salvati in locale; Firestore tiene in coda le modifiche
/// fatte offline e le invia appena torna la connessione.
class SyncService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  StreamSubscription? _vehSub;
  StreamSubscription? _fleetSub;
  bool _initialPushDone = false;

  CollectionReference<Map<String, dynamic>> get _fleets => _db.collection('fleets');

  /// Restituisce il parco auto dell'utente, creandone uno personale se non esiste.
  /// Richiede connessione: se offline lancia un'eccezione e si riproverà più tardi.
  Future<({String id, String name})> ensureFleet(Session s) async {
    final q = await _fleets
        .where('members', arrayContains: s.key)
        .limit(1)
        .get(const GetOptions(source: Source.server));
    if (q.docs.isNotEmpty) {
      final d = q.docs.first;
      return (id: d.id, name: (d.data()['name'] as String?) ?? 'Parco auto');
    }
    return createFleet(s);
  }

  Future<({String id, String name})> createFleet(Session s) async {
    final id = newId(12);
    final name = 'Parco auto di ${s.email ?? s.displayName}';
    await _fleets.doc(id).set({
      'name': name,
      'ownerUid': s.key,
      'members': [s.key],
      'memberEmails': {s.key: s.email ?? s.displayName},
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    return (id: id, name: name);
  }

  /// Entra nel parco auto di un familiare usando il codice invito.
  Future<({String id, String name})> joinFleet(Session s, String code, String? oldFleetId) async {
    final id = code.trim().toUpperCase().replaceAll(' ', '');
    final ref = _fleets.doc(id);
    final snap = await ref.get(const GetOptions(source: Source.server));
    if (!snap.exists) throw Exception('Codice non valido.');
    await ref.update({
      'members': FieldValue.arrayUnion([s.key]),
      'memberEmails.${s.key}': s.email ?? s.displayName,
    });
    if (oldFleetId != null && oldFleetId != id) {
      await _leave(s, oldFleetId);
    }
    return (id: id, name: (snap.data()?['name'] as String?) ?? 'Parco auto');
  }

  Future<void> _leave(Session s, String fleetId) async {
    try {
      await _fleets.doc(fleetId).update({
        'members': FieldValue.arrayRemove([s.key]),
        'memberEmails.${s.key}': FieldValue.delete(),
      });
    } catch (_) {}
  }

  /// Esce dal parco familiare e crea un nuovo parco personale.
  Future<({String id, String name})> leaveFleet(Session s, String fleetId) async {
    await _leave(s, fleetId);
    return createFleet(s);
  }

  Future<void> renameFleet(String fleetId, String name) =>
      _fleets.doc(fleetId).update({'name': name});

  void start({
    required String fleetId,
    required void Function(List<Vehicle> remote) onRemote,
    required List<Vehicle> Function() localVehicles,
    required void Function(String name, List<FleetMember> members) onFleet,
  }) {
    stop();
    _initialPushDone = false;
    final col = _fleets.doc(fleetId).collection('vehicles');
    _vehSub = col.snapshots(includeMetadataChanges: true).listen((snap) {
      final remote = <Vehicle>[];
      for (final d in snap.docs) {
        try {
          remote.add(Vehicle.fromJson(d.data()));
        } catch (_) {}
      }
      onRemote(remote);
      if (!_initialPushDone && !snap.metadata.isFromCache) {
        _initialPushDone = true;
        final remoteById = {for (final r in remote) r.id: r};
        for (final v in localVehicles()) {
          final r = remoteById[v.id];
          if (r == null || v.updatedAt > r.updatedAt) {
            push(fleetId, v);
          }
        }
      }
    }, onError: (_) {});
    _fleetSub = _fleets.doc(fleetId).snapshots().listen((snap) {
      final data = snap.data();
      if (data == null) return;
      final emails = Map<String, dynamic>.from((data['memberEmails'] as Map?) ?? {});
      final owner = data['ownerUid'] as String?;
      final members = ((data['members'] as List?) ?? [])
          .map((e) => e.toString())
          .map((uid) => FleetMember(uid, (emails[uid] ?? uid).toString(), uid == owner))
          .toList();
      onFleet((data['name'] as String?) ?? 'Parco auto', members);
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
    _vehSub?.cancel();
    _fleetSub?.cancel();
    _vehSub = null;
    _fleetSub = null;
  }
}
