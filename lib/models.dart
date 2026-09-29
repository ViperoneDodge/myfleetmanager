import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

String newId([int length = 16]) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final r = Random.secure();
  return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
}

enum VehicleType { auto, moto }

VehicleType vehicleTypeFrom(String? s) =>
    s == 'moto' ? VehicleType.moto : VehicleType.auto;

enum DeadlineKind { insurance, inspection, service, custom }

DeadlineKind deadlineKindFrom(String? s) {
  switch (s) {
    case 'insurance':
      return DeadlineKind.insurance;
    case 'inspection':
      return DeadlineKind.inspection;
    case 'service':
      return DeadlineKind.service;
    default:
      return DeadlineKind.custom;
  }
}

String deadlineKindDefaultLabel(DeadlineKind k) {
  switch (k) {
    case DeadlineKind.insurance:
      return 'Assicurazione';
    case DeadlineKind.inspection:
      return 'Revisione';
    case DeadlineKind.service:
      return 'Tagliando';
    case DeadlineKind.custom:
      return 'Personalizzata';
  }
}

class Deadline {
  String id;
  DeadlineKind kind;
  String label;

  /// Per assicurazione/revisione/personalizzate: data di scadenza.
  /// Per il tagliando: data dell'ULTIMO tagliando.
  DateTime? date;

  /// Solo tagliando: ogni quanti mesi va rifatto (0 = nessun promemoria).
  int intervalMonths;

  /// L'utente sceglie quali scadenze monitorare.
  bool enabled;

  Deadline({
    String? id,
    required this.kind,
    String? label,
    this.date,
    this.intervalMonths = 0,
    this.enabled = true,
  })  : id = id ?? newId(8),
        label = label ?? deadlineKindDefaultLabel(kind);

  /// Data in cui scatta la scadenza (usata per notifiche e colori).
  DateTime? get dueDate {
    if (date == null) return null;
    if (kind == DeadlineKind.service) {
      if (intervalMonths <= 0) return null;
      final d = date!;
      return DateTime(d.year, d.month + intervalMonths, d.day);
    }
    return date;
  }

  String get dueLabel =>
      kind == DeadlineKind.service ? 'Prossimo tagliando' : label;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'label': label,
        'date': date?.toIso8601String(),
        'intervalMonths': intervalMonths,
        'enabled': enabled,
      };

  factory Deadline.fromJson(Map<String, dynamic> j) => Deadline(
        id: j['id'] as String?,
        kind: deadlineKindFrom(j['kind'] as String?),
        label: j['label'] as String?,
        date: j['date'] == null ? null : DateTime.tryParse(j['date'] as String),
        intervalMonths: (j['intervalMonths'] as num?)?.toInt() ?? 0,
        enabled: j['enabled'] as bool? ?? true,
      );

  Deadline copy() => Deadline.fromJson(toJson());
}

class Vehicle {
  String id;
  VehicleType type;
  String name;
  String plate;

  /// Foto compressa (JPEG) in base64: salvata in locale e sincronizzata.
  String? photoB64;
  List<Deadline> deadlines;
  String notes;
  int updatedAt;
  String updatedBy;
  bool deleted;

  Uint8List? _photoCache;
  String? _photoCacheKey;

  Vehicle({
    String? id,
    this.type = VehicleType.auto,
    this.name = '',
    this.plate = '',
    this.photoB64,
    List<Deadline>? deadlines,
    this.notes = '',
    int? updatedAt,
    this.updatedBy = '',
    this.deleted = false,
  })  : id = id ?? newId(),
        deadlines = deadlines ?? defaultDeadlines(),
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  static List<Deadline> defaultDeadlines() => [
        Deadline(kind: DeadlineKind.insurance),
        Deadline(kind: DeadlineKind.inspection),
        Deadline(kind: DeadlineKind.service, intervalMonths: 12),
      ];

  Uint8List? get photoBytes {
    if (photoB64 == null || photoB64!.isEmpty) return null;
    if (_photoCacheKey != photoB64) {
      try {
        _photoCache = base64Decode(photoB64!);
      } catch (_) {
        _photoCache = null;
      }
      _photoCacheKey = photoB64;
    }
    return _photoCache;
  }

  /// Scadenze attive con data, ordinate dalla più vicina.
  List<Deadline> get activeDeadlines {
    final list = deadlines
        .where((d) => d.enabled && d.dueDate != null)
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return list;
  }

  Deadline? get nextDeadline {
    final a = activeDeadlines;
    return a.isEmpty ? null : a.first;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'plate': plate,
        'photoB64': photoB64,
        'deadlines': deadlines.map((d) => d.toJson()).toList(),
        'notes': notes,
        'updatedAt': updatedAt,
        'updatedBy': updatedBy,
        'deleted': deleted,
      };

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: j['id'] as String?,
        type: vehicleTypeFrom(j['type'] as String?),
        name: j['name'] as String? ?? '',
        plate: j['plate'] as String? ?? '',
        photoB64: j['photoB64'] as String?,
        deadlines: (j['deadlines'] as List?)
                ?.map((e) => Deadline.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        notes: j['notes'] as String? ?? '',
        updatedAt: (j['updatedAt'] as num?)?.toInt() ?? 0,
        updatedBy: j['updatedBy'] as String? ?? '',
        deleted: j['deleted'] as bool? ?? false,
      );

  Vehicle copy() => Vehicle.fromJson(toJson());
}

class NotifySettings {
  /// Giorni di anticipo: 30 = 1 mese, 7 = 1 settimana, 1 = 1 giorno, 0 = il giorno stesso.
  Set<int> offsets;
  int hour;
  int minute;

  NotifySettings({Set<int>? offsets, this.hour = 9, this.minute = 0})
      : offsets = offsets ?? {30, 7, 1};

  Map<String, dynamic> toJson() => {
        'offsets': offsets.toList(),
        'hour': hour,
        'minute': minute,
      };

  factory NotifySettings.fromJson(Map<String, dynamic>? j) {
    if (j == null) return NotifySettings();
    return NotifySettings(
      offsets: ((j['offsets'] as List?) ?? [30, 7, 1])
          .map((e) => (e as num).toInt())
          .toSet(),
      hour: (j['hour'] as num?)?.toInt() ?? 9,
      minute: (j['minute'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Dati di un utente salvati sul telefono.
class UserData {
  List<Vehicle> vehicles;
  NotifySettings notify;
  String? fleetId;
  String? fleetName;

  UserData({
    List<Vehicle>? vehicles,
    NotifySettings? notify,
    this.fleetId,
    this.fleetName,
  })  : vehicles = vehicles ?? [],
        notify = notify ?? NotifySettings();

  Map<String, dynamic> toJson() => {
        'vehicles': vehicles.map((v) => v.toJson()).toList(),
        'notify': notify.toJson(),
        'fleetId': fleetId,
        'fleetName': fleetName,
      };

  factory UserData.fromJson(Map<String, dynamic> j) => UserData(
        vehicles: (j['vehicles'] as List?)
                ?.map((e) => Vehicle.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        notify: NotifySettings.fromJson(
            j['notify'] == null ? null : Map<String, dynamic>.from(j['notify'] as Map)),
        fleetId: j['fleetId'] as String?,
        fleetName: j['fleetName'] as String?,
      );
}

enum AccountMode { local, cloud }

class Session {
  final AccountMode mode;

  /// Locale: username. Cloud: uid Firebase.
  final String key;
  final String displayName;
  final String? email;

  Session({
    required this.mode,
    required this.key,
    required this.displayName,
    this.email,
  });

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'key': key,
        'displayName': displayName,
        'email': email,
      };

  static Session? fromJson(Map<String, dynamic>? j) {
    if (j == null || j['key'] == null) return null;
    return Session(
      mode: j['mode'] == 'cloud' ? AccountMode.cloud : AccountMode.local,
      key: j['key'] as String,
      displayName: j['displayName'] as String? ?? '',
      email: j['email'] as String?,
    );
  }

  /// Nome del file dati (un file per account).
  String get storageKey =>
      '${mode.name}_${key.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}';
}
