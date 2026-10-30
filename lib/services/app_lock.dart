import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import '../l10n.dart';
import '../platform.dart';

class AppLock {
  static final LocalAuthentication _auth = LocalAuthentication();

  static const Duration grace = Duration(minutes: 1);

  static bool get available => !kIsWeb && (isAndroid || isIOS);

  static Future<bool> supported() async {
    if (!available) return false;
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> unlock() async {
    if (!available) return true;
    try {
      return await _auth.authenticate(
        localizedReason: tr('lock.reason'),
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }

  static bool shouldLock({required bool enabled, required DateTime? awaySince, required DateTime now}) =>
      enabled && awaySince != null && now.difference(awaySince) >= grace;
}
