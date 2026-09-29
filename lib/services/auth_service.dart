import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_config.dart';
import '../models.dart';
import 'local_store.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  final LocalStore store;
  AuthService(this.store);

  bool get cloudAvailable => FirebaseConfig.isConfigured;

  // ---------------- Account locale (solo su questo telefono) ----------------

  String _hash(String password, String salt) {
    var bytes = utf8.encode('$salt:$password');
    var digest = sha256.convert(bytes);
    for (var i = 0; i < 5000; i++) {
      digest = sha256.convert([...digest.bytes, ...utf8.encode(salt)]);
    }
    return digest.toString();
  }

  String _normUser(String u) => u.trim().toLowerCase();

  Future<Session> registerLocal(String username, String password) async {
    final u = _normUser(username);
    if (u.length < 3) throw AuthException('Il nome utente deve avere almeno 3 caratteri.');
    if (password.length < 4) throw AuthException('La password deve avere almeno 4 caratteri.');
    final accounts = await store.readAccounts();
    if (accounts.containsKey(u)) throw AuthException('Questo nome utente esiste già su questo telefono.');
    final salt = newId(16);
    accounts[u] = {'salt': salt, 'hash': _hash(password, salt), 'display': username.trim()};
    await store.writeAccounts(accounts);
    return Session(mode: AccountMode.local, key: u, displayName: username.trim());
  }

  Future<Session> loginLocal(String username, String password) async {
    final u = _normUser(username);
    final accounts = await store.readAccounts();
    final a = accounts[u];
    if (a == null) throw AuthException('Utente non trovato su questo telefono.');
    final m = Map<String, dynamic>.from(a as Map);
    if (_hash(password, m['salt'] as String) != m['hash']) {
      throw AuthException('Password errata.');
    }
    return Session(
        mode: AccountMode.local, key: u, displayName: (m['display'] as String?) ?? u);
  }

  // ---------------- Account online (email o Google) ----------------

  Session _fromUser(User user) => Session(
        mode: AccountMode.cloud,
        key: user.uid,
        displayName: user.email ?? 'Utente',
        email: user.email,
      );

  String _firebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email non valida.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email o password non corretti.';
      case 'email-already-in-use':
        return 'Esiste già un account con questa email.';
      case 'weak-password':
        return 'Password troppo debole (minimo 6 caratteri).';
      case 'network-request-failed':
        return 'Serve una connessione internet per il primo accesso online.';
      default:
        return 'Errore di accesso (${e.code}).';
    }
  }

  Future<Session> registerCloud(String email, String password) async {
    try {
      final c = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email.trim(), password: password);
      return _fromUser(c.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_firebaseError(e));
    }
  }

  Future<Session> loginCloud(String email, String password) async {
    try {
      final c = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email.trim(), password: password);
      return _fromUser(c.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_firebaseError(e));
    }
  }

  GoogleSignIn _google() => GoogleSignIn(
        scopes: const ['email'],
        serverClientId: FirebaseConfig.googleWebClientId.isEmpty
            ? null
            : FirebaseConfig.googleWebClientId,
      );

  /// Login Google: all'app viene condiviso solo l'indirizzo email.
  Future<Session> loginGoogle() async {
    try {
      final g = _google();
      final account = await g.signIn();
      if (account == null) throw AuthException('Accesso Google annullato.');
      final auth = await account.authentication;
      final cred = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );
      final c = await FirebaseAuth.instance.signInWithCredential(cred);
      return _fromUser(c.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_firebaseError(e));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Accesso Google non riuscito: $e');
    }
  }

  /// Verifica che la sessione cloud salvata sia ancora valida (funziona offline).
  bool cloudSessionValid(Session s) {
    if (!cloudAvailable) return false;
    final u = FirebaseAuth.instance.currentUser;
    return u != null && u.uid == s.key;
  }

  Future<void> logout(Session? s) async {
    if (s?.mode == AccountMode.cloud && cloudAvailable) {
      try {
        await _google().signOut();
      } catch (_) {}
      await FirebaseAuth.instance.signOut();
    }
  }
}
