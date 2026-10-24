import 'dart:convert';

import '../l10n.dart';
import '../models.dart';

enum LogKind { added, edited, deleted, reminder, message }

const List<String> changeParts = ['details', 'tech', 'deadlines', 'maintenance', 'documents'];

String partLabel(String p) => tr('part.$p');

int stableHash(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0x7fffffff;
  }
  return h;
}

List<String> changedParts(Vehicle? a, Vehicle b) {
  if (a == null) return [];
  String j(Object? o) => jsonEncode(o);
  final out = <String>[];
  if (j([a.name, a.plate, a.type.name, a.registrationDate?.toIso8601String(), a.notes]) !=
      j([b.name, b.plate, b.type.name, b.registrationDate?.toIso8601String(), b.notes])) {
    out.add('details');
  }
  if (j([a.vin, a.tyres, a.powerKw, a.engineCc, a.fuel, a.oil, a.battery, a.plugs, a.filters]) !=
      j([b.vin, b.tyres, b.powerKw, b.engineCc, b.fuel, b.oil, b.battery, b.plugs, b.filters])) {
    out.add('tech');
  }
  if (j(a.deadlines.map((d) => d.toJson()).toList()) != j(b.deadlines.map((d) => d.toJson()).toList())) {
    out.add('deadlines');
  }
  if (j(a.maintenance.map((m) => m.toJson()).toList()) != j(b.maintenance.map((m) => m.toJson()).toList())) {
    out.add('maintenance');
  }
  if (j(a.documents.map((d) => [d.id, d.name]).toList()) != j(b.documents.map((d) => [d.id, d.name]).toList())) {
    out.add('documents');
  }
  return out;
}

class LogEntry {
  String id;
  int ts;
  LogKind kind;
  String groupId;
  String group;
  String vehicleId;
  String vehicle;
  String who;
  List<String> parts;
  String title;
  String body;
  bool read;

  LogEntry({
    String? id,
    required this.ts,
    required this.kind,
    this.groupId = '',
    this.group = '',
    this.vehicleId = '',
    this.vehicle = '',
    this.who = '',
    List<String>? parts,
    this.title = '',
    this.body = '',
    this.read = false,
  })  : id = id ?? newId(12),
        parts = parts ?? [];

  bool get isChange => kind == LogKind.added || kind == LogKind.edited;

  bool get isGroup => kind == LogKind.added || kind == LogKind.edited || kind == LogKind.deleted;

  String get headline {
    final w = who.isEmpty ? tr('groupAct.someone') : who;
    switch (kind) {
      case LogKind.added:
        return tr('groupAct.added', {'who': w, 'vehicle': vehicle});
      case LogKind.edited:
        return tr('groupAct.edited', {'who': w, 'vehicle': vehicle});
      case LogKind.deleted:
        return tr('groupAct.deleted', {'who': w, 'vehicle': vehicle});
      case LogKind.reminder:
      case LogKind.message:
        return title;
    }
  }

  String get detail {
    switch (kind) {
      case LogKind.reminder:
        return [tr('notif.reminder'), if (body.isNotEmpty) body].join(' · ');
      case LogKind.message:
        return body;
      default:
        return [group, if (parts.isNotEmpty) parts.map(partLabel).join(', ')].join(' · ');
    }
  }

  String get line => parts.isEmpty || !isChange ? headline : '$headline (${parts.map(partLabel).join(', ')})';

  Map<String, dynamic> toJson() => {
        'id': id,
        'ts': ts,
        'kind': kind.name,
        if (groupId.isNotEmpty) 'groupId': groupId,
        if (group.isNotEmpty) 'group': group,
        if (vehicleId.isNotEmpty) 'vehicleId': vehicleId,
        if (vehicle.isNotEmpty) 'vehicle': vehicle,
        if (who.isNotEmpty) 'who': who,
        if (parts.isNotEmpty) 'parts': parts,
        if (title.isNotEmpty) 'title': title,
        if (body.isNotEmpty) 'body': body,
        'read': read,
      };

  factory LogEntry.fromJson(Map<String, dynamic> j) => LogEntry(
        id: j['id'] as String?,
        ts: (j['ts'] as num?)?.toInt() ?? 0,
        kind: LogKind.values.firstWhere((k) => k.name == j['kind'], orElse: () => LogKind.message),
        groupId: j['groupId'] as String? ?? '',
        group: j['group'] as String? ?? '',
        vehicleId: j['vehicleId'] as String? ?? '',
        vehicle: j['vehicle'] as String? ?? '',
        who: j['who'] as String? ?? '',
        parts: ((j['parts'] as List?) ?? []).map((e) => e.toString()).toList(),
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        read: j['read'] as bool? ?? false,
      );
}

class NotificationLog {
  static const int maxEntries = 1000;

  List<LogEntry> entries;
  int reminderSince;

  NotificationLog({List<LogEntry>? entries, this.reminderSince = 0}) : entries = entries ?? [];

  List<LogEntry> get sorted => List.of(entries)..sort((a, b) => b.ts.compareTo(a.ts));

  int get unread => entries.where((e) => !e.read).length;

  bool changedUnread(String vehicleId) =>
      entries.any((e) => !e.read && e.isChange && e.vehicleId == vehicleId);

  List<LogEntry> unreadOfGroup(String groupId) =>
      sorted.where((e) => !e.read && e.isGroup && e.groupId == groupId).toList();

  void addActivity(LogEntry e) {
    if (e.isChange) {
      for (final o in entries) {
        if (!o.read && o.isChange && o.vehicleId == e.vehicleId && o.groupId == e.groupId && o.who == e.who) {
          final parts = {...o.parts, ...e.parts};
          o.parts = [for (final p in changeParts) if (parts.contains(p)) p];
          if (e.ts > o.ts) o.ts = e.ts;
          o.vehicle = e.vehicle;
          o.group = e.group;
          return;
        }
      }
    }
    entries.add(e);
    _trim();
  }

  void addReminder(int when, String title, String body, String vehicleId) {
    final id = 'r${stableHash('$when|$title|$body').toRadixString(36)}';
    if (entries.any((e) => e.id == id)) return;
    entries.add(LogEntry(id: id, ts: when, kind: LogKind.reminder, title: title, body: body, vehicleId: vehicleId));
    _trim();
  }

  void addMessage(String title, String body, int ts) {
    entries.add(LogEntry(ts: ts, kind: LogKind.message, title: title, body: body));
    _trim();
  }

  void markRead(Set<String> ids) {
    for (final e in entries) {
      if (ids.contains(e.id)) e.read = true;
    }
  }

  void markAllRead() {
    for (final e in entries) {
      e.read = true;
    }
  }

  void delete(Set<String> ids) => entries.removeWhere((e) => ids.contains(e.id));

  void clear() => entries.clear();

  void _trim() {
    if (entries.length <= maxEntries) return;
    entries = sorted.take(maxEntries).toList();
  }

  Map<String, dynamic> toJson() => {
        'entries': entries.map((e) => e.toJson()).toList(),
        'reminderSince': reminderSince,
      };

  factory NotificationLog.fromJson(Map<String, dynamic>? j) => NotificationLog(
        entries: ((j?['entries'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => LogEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        reminderSince: (j?['reminderSince'] as num?)?.toInt() ?? 0,
      );
}
