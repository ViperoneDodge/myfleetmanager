import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../l10n.dart';
import '../models.dart';
import '../platform.dart';
import 'notification_log.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const String logPayload = 'log';

  static final ValueNotifier<bool> openLog = ValueNotifier(false);

  Future<void> init() async {
    if (kIsWeb) return;
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
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (r) {
        if (r.payload == logPayload) openLog.value = true;
      },
    );
    try {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true && launch?.notificationResponse?.payload == logPayload) {
        openLog.value = true;
      }
    } catch (_) {}
    final a = _android;
    if (a != null) {
      await a.createNotificationChannel(AndroidNotificationChannel(
        'scadenze',
        tr('channel.deadlines'),
        description: tr('channel.deadlinesDesc'),
        importance: Importance.high,
      ));
      await a.createNotificationChannel(AndroidNotificationChannel(
        'famiglia',
        tr('channel.family'),
        description: tr('channel.familyDesc'),
        importance: Importance.high,
      ));
    }
    _ready = true;
  }

  Future<void> refreshChannels() async {
    if (kIsWeb) return;
    if (!_ready) return;
    final a = _android;
    if (a == null) return;
    await a.createNotificationChannel(AndroidNotificationChannel(
      'scadenze',
      tr('channel.deadlines'),
      description: tr('channel.deadlinesDesc'),
      importance: Importance.high,
    ));
    await a.createNotificationChannel(AndroidNotificationChannel(
      'famiglia',
      tr('channel.family'),
      description: tr('channel.familyDesc'),
      importance: Importance.high,
    ));
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => isAndroid
      ? _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      : null;

  Future<({bool enabled, bool exact})> status() async {
    await init();
    final a = _android;
    if (a == null) return (enabled: true, exact: true);
    bool enabled = true;
    bool exact = true;
    try {
      enabled = await a.areNotificationsEnabled() ?? true;
    } catch (_) {}
    try {
      exact = await a.canScheduleExactNotifications() ?? true;
    } catch (_) {}
    return (enabled: enabled, exact: exact);
  }

  Future<void> requestExactAlarms() async {
    if (kIsWeb) return;
    await init();
    try {
      await _android?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  Future<AndroidScheduleMode> _mode() async => (await status()).exact
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  Future<void> requestPermission() async {
    if (kIsWeb) return;
    await init();
    if (isAndroid) {
      try {
        await _android?.requestNotificationsPermission();
      } catch (_) {}
    } else if (isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static String offsetLabel(int days) {
    switch (days) {
      case 30:
        return tr('notify.before30');
      case 7:
        return tr('notify.before7');
      case 1:
        return tr('notify.before1');
      case 0:
        return tr('notify.before0');
      default:
        return tr('notify.beforeDays', {'n': days});
    }
  }

  static String _whenLabel(int days) {
    switch (days) {
      case 30:
        return tr('notify.in30');
      case 7:
        return tr('notify.in7');
      case 1:
        return tr('notify.in1');
      default:
        return tr('notify.inDays', {'n': days});
    }
  }

  static NotificationDetails get _details => NotificationDetails(
    android: AndroidNotificationDetails(
      'scadenze',
      tr('channel.deadlines'),
      channelDescription: tr('channel.deadlinesDesc'),
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFF0257C3),
    ),
    iOS: const DarwinNotificationDetails(),
  );

  static NotificationDetails get _familyDetails => NotificationDetails(
    android: AndroidNotificationDetails(
      'famiglia',
      tr('channel.family'),
      channelDescription: tr('channel.familyDesc'),
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFF0257C3),
    ),
    iOS: const DarwinNotificationDetails(),
  );

  static List<_Pending> reminders(List<Vehicle> vehicles, NotifySettings s) {
    final items = <_Pending>[];
    final fmt = DateFormat('dd/MM/yyyy');

    for (final v in vehicles.where((v) => !v.deleted)) {
      final vName = v.name.isEmpty ? v.plate : '${v.name} (${v.plate})';
      final buckets = <String, ({tz.TZDateTime when, int off, DateTime due, List<String> what})>{};
      for (final d in v.activeDeadlines) {
        final due = d.dueDate!;
        for (final off in s.offsets) {
          final day = DateTime(due.year, due.month, due.day - off);
          final when = tz.TZDateTime(tz.local, day.year, day.month, day.day, s.hour, s.minute);
          final key = '${when.millisecondsSinceEpoch}|$off';
          buckets.putIfAbsent(key, () => (when: when, off: off, due: due, what: <String>[])).what.add(d.dueLabel);
        }
      }
      for (final b in buckets.values) {
        if (b.what.length == 1) {
          final title = b.off == 0
              ? tr('notify.titleToday', {'what': b.what.first})
              : tr('notify.titleSoon', {'what': b.what.first, 'when': _whenLabel(b.off)});
          items.add(_Pending(
              b.when, title, tr('notify.body', {'vehicle': vName, 'date': fmt.format(b.due)}), v.id));
        } else {
          final list = '${b.what.sublist(0, b.what.length - 1).join(', ')} ${tr('notify.and')} ${b.what.last}';
          final body = b.off == 0
              ? tr('notify.groupToday', {'what': list})
              : tr('notify.titleSoon', {'what': list, 'when': _whenLabel(b.off)});
          items.add(_Pending(b.when, vName, '$body · ${fmt.format(b.due)}', v.id));
        }
      }
    }
    return items;
  }

  Future<List<({int when, String title, String body, String vehicleId})>> firedReminders(
      List<Vehicle> vehicles, NotifySettings s, int since, int now) async {
    if (kIsWeb) return [];
    await init();
    return [
      for (final p in reminders(vehicles, s))
        if (p.when.millisecondsSinceEpoch > since && p.when.millisecondsSinceEpoch <= now)
          (when: p.when.millisecondsSinceEpoch, title: p.title, body: p.body, vehicleId: p.vehicleId),
    ];
  }

  static const int _maxDeadlineId = 99999;
  static const int _testId = 900001;

  Future<int> rescheduleAll(List<Vehicle> vehicles, NotifySettings s) async {
    if (kIsWeb) return 0;
    await init();
    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (final p in pending) {
        if (p.id > 0 && p.id <= _maxDeadlineId) await _plugin.cancel(p.id);
      }
    } catch (_) {
      await _plugin.cancelAll();
    }
    final mode = await _mode();
    final now = tz.TZDateTime.now(tz.local);
    final items = reminders(vehicles, s).where((p) => p.when.isAfter(now)).toList();
    items.sort((a, b) => a.when.compareTo(b.when));
    final max = isIOS ? 60 : 400;
    var id = 1;
    for (final p in items.take(max)) {
      try {
        await _plugin.zonedSchedule(
          id++,
          p.title,
          p.body,
          p.when,
          _details,
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: logPayload,
        );
      } catch (_) {}
    }
    return id - 1;
  }

  Future<void> scheduleTest(Duration delay) async {
    if (kIsWeb) return;
    await init();
    final when = tz.TZDateTime.now(tz.local).add(delay);
    await _plugin.zonedSchedule(
      _testId,
      tr('notify.testTitle'),
      tr('notify.testBody'),
      when,
      _details,
      androidScheduleMode: await _mode(),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showRemote(String? title, String? body) async {
    if (kIsWeb) return;
    await init();
    await _plugin.show(
      100000 + DateTime.now().millisecondsSinceEpoch % 800000,
      title ?? 'MyFleetManager',
      body,
      _familyDetails,
      payload: logPayload,
    );
  }

  static int groupNotificationId(String groupId) => 300000 + stableHash(groupId) % 100000;

  Future<void> showGroup(String groupId, String groupName, List<LogEntry> unread) async {
    if (kIsWeb) return;
    await init();
    final id = groupNotificationId(groupId);
    if (unread.isEmpty) {
      try {
        await _plugin.cancel(id);
      } catch (_) {}
      return;
    }
    final lines = unread.take(6).map((e) => e.line).toList();
    final body = unread.length == 1 ? lines.first : tr('groupAct.many', {'n': unread.length});
    await _plugin.show(
      id,
      groupName,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'famiglia',
          tr('channel.family'),
          channelDescription: tr('channel.familyDesc'),
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF0257C3),
          onlyAlertOnce: true,
          number: unread.length,
          styleInformation: InboxStyleInformation(
            lines,
            contentTitle: groupName,
            summaryText: unread.length > lines.length ? '+${unread.length - lines.length}' : null,
          ),
        ),
        iOS: DarwinNotificationDetails(threadIdentifier: groupId),
      ),
      payload: logPayload,
    );
  }

  Future<void> showTest() async {
    if (kIsWeb) return;
    await init();
    await _plugin.show(
      0,
      tr('notify.activeTitle'),
      tr('notify.activeBody'),
      _details,
    );
  }
}

class _Pending {
  final tz.TZDateTime when;
  final String title;
  final String body;
  final String vehicleId;
  _Pending(this.when, this.title, this.body, this.vehicleId);
}
