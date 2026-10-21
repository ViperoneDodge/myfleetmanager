import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';

import '../platform.dart';

Future<void> startAppCheck() async {
  if (!isMobile || Firebase.apps.isEmpty) return;
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
    );
  } catch (_) {}
}
