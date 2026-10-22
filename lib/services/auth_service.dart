import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../firebase_config.dart';
import '../l10n.dart';
import '../models.dart';
import 'local_store.dart';
import '../platform.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  final LocalStore store;
  AuthService(this.store);

  bool get cloudAvailable => FirebaseConfig.isConfigured && Firebase.apps.isNotEmpty;

  String? get currentUid => cloudAvailable ? FirebaseAuth.instance.currentUser?.uid : null;

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
    if (u.length < 3) throw AuthException(tr('auth.userShort'));
    if (password.length < 4) throw AuthException(tr('auth.passShort'));
    final accounts = await store.readAccounts();
    if (accounts.containsKey(u)) throw AuthException(tr('auth.userExists'));
    final salt = newId(16);
    accounts[u] = {'salt': salt, 'hash': _hash(password, salt), 'display': username.trim()};
    await store.writeAccounts(accounts);
    return Session(mode: AccountMode.local, key: u, displayName: username.trim());
  }

  Future<Session> loginLocal(String username, String password) async {
    final u = _normUser(username);
    final accounts = await store.readAccounts();
    final a = accounts[u];
    if (a == null) throw AuthException(tr('auth.userNotFound'));
    final m = Map<String, dynamic>.from(a as Map);
    if (_hash(password, m['salt'] as String) != m['hash']) {
      throw AuthException(tr('auth.wrongPass'));
    }
    return Session(
        mode: AccountMode.local, key: u, displayName: (m['display'] as String?) ?? u);
  }

  Session _fromUser(User user) => Session(
        mode: AccountMode.cloud,
        key: user.uid,
        displayName: user.email ?? tr('auth.user'),
        email: user.email,
      );

  String _firebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return tr('auth.invalidEmail');
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return tr('auth.badCredentials');
      case 'email-already-in-use':
        return tr('auth.emailInUse');
      case 'weak-password':
        return tr('auth.weakPass');
      case 'network-request-failed':
        return tr('auth.network');
      case 'operation-not-allowed':
        return tr('auth.emailDisabled');
      case 'too-many-requests':
        return tr('auth.tooMany');
      case 'user-disabled':
        return tr('auth.userDisabled');
      default:
        return tr('auth.generic', {'code': e.code});
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

  Future<void> resetPassword(String email) async {
    try {
      try {
        await FirebaseAuth.instance.setLanguageCode(L10n.code);
      } catch (_) {}
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
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

  Future<Session> loginGoogle() async {
    if (kIsWeb) {
      try {
        final c = await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
        return _fromUser(c.user!);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'popup-closed-by-user' || e.code == 'cancelled-popup-request') {
          throw AuthException(tr('auth.googleCancelled'));
        }
        throw AuthException(_firebaseError(e));
      }
    }
    try {
      final g = _google();
      try {
        await g.signOut();
      } catch (_) {}
      final account = await g.signIn();
      if (account == null) throw AuthException(tr('auth.googleCancelled'));
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
      throw AuthException(tr('auth.googleFailed', {'error': e}));
    }
  }

  bool cloudSessionValid(Session s) {
    if (!cloudAvailable) return false;
    final u = FirebaseAuth.instance.currentUser;
    return u != null && u.uid == s.key;
  }

  bool get appleAvailable => cloudAvailable && isIOS;

  static String _nonce([int length = 32]) {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final r = Random.secure();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<Session> loginApple() async {
    try {
      final raw = _nonce();
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: sha256.convert(utf8.encode(raw)).toString(),
      );
      final cred = OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        rawNonce: raw,
        accessToken: apple.authorizationCode,
      );
      final c = await FirebaseAuth.instance.signInWithCredential(cred);
      final user = c.user!;
      final name = [apple.givenName, apple.familyName].whereType<String>().join(' ').trim();
      if (name.isNotEmpty && (user.displayName ?? '').isEmpty) {
        await user.updateDisplayName(name);
        await user.reload();
      }
      return _fromUser(FirebaseAuth.instance.currentUser ?? user);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) throw AuthException(tr('auth.appleCancelled'));
      throw AuthException(tr('auth.appleFailed', {'error': e.message}));
    } on FirebaseAuthException catch (e) {
      throw AuthException(_firebaseError(e));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(tr('auth.appleFailed', {'error': e}));
    }
  }

  Future<void> _revokeApple(User u) async {
    if (!isIOS || !u.providerData.any((p) => p.providerId == 'apple.com')) return;
    try {
      final apple = await SignInWithApple.getAppleIDCredential(scopes: const []);
      await FirebaseAuth.instance.revokeTokenWithAuthorizationCode(apple.authorizationCode);
    } catch (_) {}
  }

  Future<void> deleteCloudAccount() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    await _revokeApple(u);
    try {
      await u.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') throw AuthException(tr('account.relogin'));
      throw AuthException(_firebaseError(e));
    }
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
