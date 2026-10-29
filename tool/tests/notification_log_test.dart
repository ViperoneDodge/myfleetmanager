import 'package:flutter_test/flutter_test.dart';
import 'package:myfleetmanager/models.dart';
import 'package:myfleetmanager/services/group_watch.dart';
import 'package:myfleetmanager/services/notification_log.dart';

Vehicle car(String id, {String name = 'Panda', int at = 100, String by = 'Marco', String uid = 'u-marco'}) =>
    Vehicle(id: id, name: name, plate: 'AA000AA', updatedAt: at, updatedBy: by, updatedByUid: uid);

void main() {
  test('parti cambiate tra due versioni del veicolo', () {
    final a = car('v1');
    final b = a.copy()
      ..oil = '5W-30'
      ..deadlines.first.date = DateTime(2027, 3, 1);
    b.maintenance.add(MaintenanceRecord(date: DateTime(2026, 10, 1), items: {'oil'}));
    expect(changedParts(a, b), ['tech', 'deadlines', 'maintenance']);
    expect(changedParts(a, a.copy()), isEmpty);
    expect(changedParts(null, b), isEmpty);
    expect(changedParts(a, a.copy()..name = 'Panda 4x4'), ['details']);
  });

  test('voci cambiate, nuove e schede da segnare', () {
    final a = car('v1');
    final m = MaintenanceRecord(date: DateTime(2026, 10, 1), items: {'oil'});
    final b = a.copy()
      ..oil = '5W-30'
      ..notes = 'Gomme invernali in garage'
      ..deadlines.first.date = DateTime(2027, 3, 1);
    b.maintenance.add(m);
    final items = changedItems(a, b);
    expect(items, {
      'deadline:${a.deadlines.first.id}': 'edited',
      'maint:${m.id}': 'new',
      'tech:oil': 'edited',
      'details:notes': 'edited',
    });
    expect(changedItems(null, b), isEmpty);
    final log = NotificationLog();
    log.addActivity(LogEntry(ts: 1, kind: LogKind.edited, groupId: 'g', vehicleId: 'v1', who: 'Marco', items: {'maint:${m.id}': 'new'}));
    log.addActivity(LogEntry(ts: 2, kind: LogKind.edited, groupId: 'g', vehicleId: 'v1', who: 'Marco', items: {'maint:${m.id}': 'edited', 'tech:oil': 'edited'}));
    log.addActivity(LogEntry(ts: 3, kind: LogKind.edited, groupId: 'g', vehicleId: 'v1', who: 'Giulia', parts: ['deadlines']));
    final ch = log.changesFor('v1')!;
    expect(ch.state('maint:${m.id}'), 'new');
    expect(ch.who, ['Marco', 'Giulia']);
    expect(ch.ts, 3);
    expect(ch.tabs, {1, 2});
    expect(VehicleChanges([LogEntry(ts: 1, kind: LogKind.edited, parts: ['deadlines', 'tech'])]).tabs, {0, 1});
    log.markRead(ch.ids.toSet());
    expect(log.changesFor('v1'), isNull);
    expect(NotificationLog.fromJson(NotificationLog(entries: [LogEntry(ts: 1, kind: LogKind.edited, items: {'tech:oil': 'edited'})]).toJson())
        .entries.single.items, {'tech:oil': 'edited'});
  });

  test('modifiche dello stesso veicolo unite finché non lette', () {
    final log = NotificationLog();
    log.addActivity(LogEntry(ts: 1, kind: LogKind.edited, groupId: 'g', group: 'Famiglia', vehicleId: 'v1', vehicle: 'Panda', who: 'Marco', parts: ['maintenance']));
    log.addActivity(LogEntry(ts: 5, kind: LogKind.edited, groupId: 'g', group: 'Famiglia', vehicleId: 'v1', vehicle: 'Panda', who: 'Marco', parts: ['deadlines']));
    expect(log.entries.length, 1);
    expect(log.entries.single.parts, ['deadlines', 'maintenance']);
    expect(log.entries.single.ts, 5);
    expect(log.changedUnread('v1'), isTrue);
    log.addActivity(LogEntry(ts: 6, kind: LogKind.edited, groupId: 'g', vehicleId: 'v1', who: 'Giulia'));
    expect(log.entries.length, 2);
    log.markRead({log.entries.first.id});
    log.addActivity(LogEntry(ts: 9, kind: LogKind.edited, groupId: 'g', vehicleId: 'v1', who: 'Marco'));
    expect(log.entries.length, 3);
    expect(log.unread, 2);
    expect(log.unreadOfGroup('g').first.ts, 9);
  });

  test('pallino finché la notifica non è letta o cancellata', () {
    final log = NotificationLog();
    log.addActivity(LogEntry(ts: 1, kind: LogKind.added, groupId: 'g', vehicleId: 'v1', who: 'Marco'));
    log.addReminder(2, 'Revisione', 'Panda', 'v2');
    expect(log.changedUnread('v1'), isTrue);
    expect(log.changedUnread('v2'), isFalse);
    log.markAllRead();
    expect(log.changedUnread('v1'), isFalse);
    log.addActivity(LogEntry(ts: 3, kind: LogKind.edited, groupId: 'g', vehicleId: 'v1', who: 'Marco'));
    expect(log.changedUnread('v1'), isTrue);
    log.delete({for (final e in log.entries) if (!e.read) e.id});
    expect(log.changedUnread('v1'), isFalse);
  });

  test('promemoria registrati una volta sola, storico salvato e riletto', () {
    final log = NotificationLog(reminderSince: 7);
    log.addReminder(10, 'Revisione tra 7 giorni', 'Panda (AA000AA)', 'v1');
    log.addReminder(10, 'Revisione tra 7 giorni', 'Panda (AA000AA)', 'v1');
    log.addMessage('Novità', 'Versione 2.1.8', 20);
    expect(log.entries.length, 2);
    final back = NotificationLog.fromJson(log.toJson());
    expect(back.reminderSince, 7);
    expect(back.sorted.map((e) => e.kind), [LogKind.message, LogKind.reminder]);
    expect(back.sorted.last.title, 'Revisione tra 7 giorni');
    expect(NotificationLog.fromJson(null).entries, isEmpty);
    expect(stableHash('abc'), stableHash('abc'));
  });

  test('attività dei gruppi con le parti cambiate, mai le proprie', () {
    final old = car('v1', at: 50);
    final remote = [
      old.copy()
        ..updatedAt = 200
        ..oil = '0W-20',
      car('v2', name: 'Ducato', at: 210, by: 'Giulia', uid: 'u-giulia'),
      car('v3', at: 220, by: 'Io', uid: 'me'),
      car('v4', at: 10),
    ];
    final acts = findActivities(
      groupId: 'g',
      groupName: 'Famiglia',
      me: 'me',
      myName: 'Io',
      since: 100,
      remote: remote,
      existed: (id) => id == 'v1' || id == 'v3',
      previous: (id) => id == 'v1' ? old : null,
    );
    expect(acts.map((a) => a.kind), [LogKind.edited, LogKind.added]);
    expect(acts.first.parts, ['tech']);
    expect(acts.first.groupId, 'g');
    expect(acts.last.vehicle, 'Ducato');
  });
}
