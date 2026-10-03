import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_update/in_app_update.dart';

/// Aggiornamenti obbligatori tramite il Play Store ("aggiornamento immediato").
///
/// Quando su Google Play è disponibile una versione più recente, all'avvio (e a
/// ogni ritorno nell'app) compare la schermata di aggiornamento di Google, che
/// blocca l'uso dell'app. Se l'utente rifiuta, l'app si chiude.
/// Funziona solo con l'app installata dal Play Store: con l'APK scaricato da
/// GitHub il controllo viene ignorato.
///
/// Notifica "nuova versione": i telefoni sono iscritti all'argomento push
/// [topic]. Dopo aver pubblicato una release, dalla console Firebase
/// (Messaging → Nuova campagna → Notifiche) si invia un messaggio all'argomento
/// "updates" e arriva a tutti, anche ad app chiusa.
class UpdateService with WidgetsBindingObserver {
  static const String topic = 'updates';
  static final UpdateService instance = UpdateService._();
  UpdateService._();

  bool _started = false;
  bool _running = false;
  DateTime? _lastCheck;

  void start({required bool pushAvailable}) {
    if (_started || !Platform.isAndroid) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    if (pushAvailable) {
      FirebaseMessaging.instance.subscribeToTopic(topic).catchError((_) {});
    }
    // Dopo il primo disegno dell'interfaccia (serve una schermata attiva).
    WidgetsBinding.instance.addPostFrameCallback((_) => check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Al ritorno nell'app: al massimo un controllo ogni 30 minuti.
    final last = _lastCheck;
    if (last == null || DateTime.now().difference(last) > const Duration(minutes: 30)) {
      check();
    }
  }

  Future<void> check() async {
    if (_running) return;
    _running = true;
    _lastCheck = DateTime.now();
    try {
      final info = await InAppUpdate.checkForUpdate();
      final available = info.updateAvailability == UpdateAvailability.updateAvailable ||
          info.updateAvailability == UpdateAvailability.developerTriggeredUpdateInProgress;
      if (available && info.immediateUpdateAllowed) {
        final result = await InAppUpdate.performImmediateUpdate();
        if (result == AppUpdateResult.userDeniedUpdate) {
          // Aggiornamento obbligatorio: senza aggiornare l'app si chiude.
          await SystemNavigator.pop();
        }
      }
    } catch (_) {
      // App non installata dal Play Store, offline, ecc.: si continua normalmente.
    } finally {
      _running = false;
    }
  }
}
