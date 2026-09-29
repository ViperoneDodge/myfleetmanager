import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models.dart';

/// Notifiche programmate sul telefono: funzionano senza internet.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Rome'));
    }
    const android = AndroidInitializationSettings('@drawable/ic_stat_notify');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    _ready = true;
  }

  Future<void> requestPermission() async {
    await init();
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static String offsetLabel(int days) {
    switch (days) {
      case 30:
        return '1 mese prima';
      case 7:
        return '1 settimana prima';
      case 1:
        return '1 giorno prima';
      case 0:
        return 'Il giorno della scadenza';
      default:
        return '$days giorni prima';
    }
  }

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'scadenze',
      'Scadenze veicoli',
      channelDescription: 'Promemoria per assicurazione, revisione, tagliando e altre scadenze',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF0257C3),
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Cancella e riprogramma tutte le notifiche in base ai veicoli attuali.
  Future<int> rescheduleAll(List<Vehicle> vehicles, NotifySettings s) async {
    await init();
    await _plugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    final items = <_Pending>[];
    final fmt = DateFormat('dd/MM/yyyy');

    for (final v in vehicles.where((v) => !v.deleted)) {
      for (final d in v.activeDeadlines) {
        final due = d.dueDate!;
        for (final off in s.offsets) {
          final day = DateTime(due.year, due.month, due.day - off);
          final when = tz.TZDateTime(tz.local, day.year, day.month, day.day, s.hour, s.minute);
          if (!when.isAfter(now)) continue;
          final vName = v.name.isEmpty ? v.plate : '${v.name} (${v.plate})';
          final title = off == 0
              ? '${d.dueLabel} scade oggi'
              : '${d.dueLabel}: scadenza ${offsetLabel(off).replaceAll(' prima', '')}';
          items.add(_Pending(when, title, '$vName · scade il ${fmt.format(due)}'));
        }
      }
    }
    items.sort((a, b) => a.when.compareTo(b.when));
    // iOS accetta al massimo 64 notifiche programmate: teniamo le più vicine.
    final max = Platform.isIOS ? 60 : 400;
    var id = 1;
    for (final p in items.take(max)) {
      try {
        await _plugin.zonedSchedule(
          id++,
          p.title,
          p.body,
          p.when,
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {}
    }
    return id - 1;
  }

  Future<void> showTest() async {
    await init();
    await _plugin.show(
      0,
      'Notifiche attive',
      'Riceverai i promemoria delle scadenze dei tuoi veicoli.',
      _details,
    );
  }
}

class _Pending {
  final tz.TZDateTime when;
  final String title;
  final String body;
  _Pending(this.when, this.title, this.body);
}
