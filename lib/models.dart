import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'l10n.dart';

String newId([int length = 16]) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final r = Random.secure();
  return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
}

enum VehicleType { auto, moto, furgone, camion, rimorchio }

VehicleType vehicleTypeFrom(String? s) {
  for (final t in VehicleType.values) {
    if (t.name == s) return t;
  }
  return VehicleType.auto;
}

String vehicleTypeLabel(VehicleType t) {
  switch (t) {
    case VehicleType.auto:
      return tr('type.car');
    case VehicleType.moto:
      return tr('type.moto');
    case VehicleType.furgone:
      return tr('type.van');
    case VehicleType.camion:
      return tr('type.truck');
    case VehicleType.rimorchio:
      return tr('type.trailer');
  }
}

String vehicleTypePlural(VehicleType t) {
  switch (t) {
    case VehicleType.auto:
      return tr('type.cars');
    case VehicleType.moto:
      return tr('type.motos');
    case VehicleType.furgone:
      return tr('type.vans');
    case VehicleType.camion:
      return tr('type.trucks');
    case VehicleType.rimorchio:
      return tr('type.trailers');
  }
}

/// Documento allegato (libretto, polizza…): il file resta sul telefono.
class VehicleDocument {
  String id;
  String name;

  /// Nome del file nella cartella documenti dell'app.
  String fileName;

  /// 'pdf' oppure 'image'.
  String kind;
  int addedAt;
  int size;

  VehicleDocument({
    String? id,
    required this.name,
    required this.fileName,
    required this.kind,
    int? addedAt,
    this.size = 0,
  })  : id = id ?? newId(10),
        addedAt = addedAt ?? DateTime.now().millisecondsSinceEpoch;

  bool get isPdf => kind == 'pdf';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fileName': fileName,
        'kind': kind,
        'addedAt': addedAt,
        'size': size,
      };

  factory VehicleDocument.fromJson(Map<String, dynamic> j) => VehicleDocument(
        id: j['id'] as String?,
        name: j['name'] as String? ?? tr('doc.default'),
        fileName: j['fileName'] as String? ?? '',
        kind: j['kind'] as String? ?? 'image',
        addedAt: (j['addedAt'] as num?)?.toInt(),
        size: (j['size'] as num?)?.toInt() ?? 0,
      );
}

enum DeadlineKind { insurance, inspection, service, tax, custom }

DeadlineKind deadlineKindFrom(String? s) {
  switch (s) {
    case 'insurance':
      return DeadlineKind.insurance;
    case 'inspection':
      return DeadlineKind.inspection;
    case 'service':
      return DeadlineKind.service;
    case 'tax':
      return DeadlineKind.tax;
    default:
      return DeadlineKind.custom;
  }
}

String deadlineKindDefaultLabel(DeadlineKind k) {
  switch (k) {
    case DeadlineKind.insurance:
      return tr('deadline.insurance');
    case DeadlineKind.inspection:
      return tr('deadline.inspection');
    case DeadlineKind.service:
      return tr('deadline.service');
    case DeadlineKind.tax:
      return tr('deadline.tax');
    case DeadlineKind.custom:
      return tr('deadline.custom');
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

  /// Nome mostrato: le scadenze standard seguono la lingua scelta,
  /// quelle personalizzate mostrano il nome scritto dall'utente.
  String get displayLabel => kind == DeadlineKind.custom ? label : deadlineKindDefaultLabel(kind);

  String get dueLabel => kind == DeadlineKind.service ? tr('deadline.nextService') : displayLabel;

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

/// Voci selezionabili (checkbox) in un intervento di manutenzione.
const List<String> maintenanceItems = [
  'oil',
  'oilFilter',
  'airFilter',
  'cabinFilter',
  'fuelFilter',
];

String maintenanceItemLabel(String k) {
  switch (k) {
    case 'oil':
    case 'oilFilter':
    case 'airFilter':
    case 'cabinFilter':
    case 'fuelFilter':
      return tr('maint.$k');
    default:
      return k;
  }
}

/// Intervento nello storico manutenzioni di un veicolo.
class MaintenanceRecord {
  String id;
  DateTime date;
  int? km;

  /// Chiavi di [maintenanceItems] spuntate.
  Set<String> items;
  String notes;

  MaintenanceRecord({
    String? id,
    required this.date,
    this.km,
    Set<String>? items,
    this.notes = '',
  })  : id = id ?? newId(8),
        items = items ?? <String>{};

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'km': km,
        'items': items.toList(),
        'notes': notes,
      };

  factory MaintenanceRecord.fromJson(Map<String, dynamic> j) => MaintenanceRecord(
        id: j['id'] as String?,
        date: DateTime.tryParse((j['date'] as String?) ?? '') ?? DateTime.now(),
        km: (j['km'] as num?)?.toInt(),
        items: ((j['items'] as List?) ?? const []).map((e) => e.toString()).toSet(),
        notes: j['notes'] as String? ?? '',
      );

  MaintenanceRecord copy() => MaintenanceRecord.fromJson(toJson());
}

class Vehicle {
  String id;
  VehicleType type;
  String name;
  String plate;

  /// Foto compressa (JPEG) in base64: salvata in locale e sincronizzata.
  String? photoB64;
  List<Deadline> deadlines;
  List<VehicleDocument> documents;

  /// Storico manutenzioni (sincronizzato con la famiglia).
  List<MaintenanceRecord> maintenance;
  String notes;
  int updatedAt;
  String updatedBy;

  /// Chi ha fatto l'ultima modifica (uid online o utente locale).
  String updatedByUid;

  /// Chi ha creato il veicolo: conta per il limite della versione gratuita.
  String createdBy;
  bool deleted;

  /// Parco a cui appartiene (null/personale = "I miei"; altrimenti id del nucleo familiare).
  String? fleetId;

  Uint8List? _photoCache;
  String? _photoCacheKey;

  Vehicle({
    String? id,
    this.type = VehicleType.auto,
    this.name = '',
    this.plate = '',
    this.photoB64,
    List<Deadline>? deadlines,
    List<VehicleDocument>? documents,
    List<MaintenanceRecord>? maintenance,
    this.notes = '',
    int? updatedAt,
    this.updatedBy = '',
    this.updatedByUid = '',
    this.createdBy = '',
    this.deleted = false,
    this.fleetId,
  })  : id = id ?? newId(),
        deadlines = deadlines ?? defaultDeadlines(type),
        documents = documents ?? [],
        maintenance = maintenance ?? [],
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  /// Veicoli creati prima della 1.5: aggiunge il bollo (spento, da attivare).
  static List<Deadline> _withTax(List<Deadline> list) {
    if (list.isNotEmpty && !list.any((d) => d.kind == DeadlineKind.tax)) {
      list.add(Deadline(kind: DeadlineKind.tax, enabled: false));
    }
    return list;
  }

  static List<Deadline> defaultDeadlines(VehicleType t) => [
        Deadline(kind: DeadlineKind.insurance),
        Deadline(kind: DeadlineKind.inspection),
        Deadline(
          kind: DeadlineKind.service,
          intervalMonths: 12,
          // I rimorchi non hanno motore: tagliando disattivato di default.
          enabled: t != VehicleType.rimorchio,
        ),
        Deadline(kind: DeadlineKind.tax),
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

  /// Manutenzioni dalla più recente.
  List<MaintenanceRecord> get maintenanceSorted =>
      List.of(maintenance)..sort((a, b) => b.date.compareTo(a.date));

  Deadline? get nextDeadline {
    final a = activeDeadlines;
    return a.isEmpty ? null : a.first;
  }

  /// [includeDocs] = false per la sincronizzazione: i file dei documenti
  /// restano solo sul telefono.
  Map<String, dynamic> toJson({bool includeDocs = true}) => {
        'id': id,
        'type': type.name,
        'name': name,
        'plate': plate,
        'photoB64': photoB64,
        'deadlines': deadlines.map((d) => d.toJson()).toList(),
        if (includeDocs) 'documents': documents.map((d) => d.toJson()).toList(),
        'maintenance': maintenance.map((m) => m.toJson()).toList(),
        'notes': notes,
        'updatedAt': updatedAt,
        'updatedBy': updatedBy,
        'updatedByUid': updatedByUid,
        'createdBy': createdBy,
        'deleted': deleted,
        'fleetId': fleetId,
      };

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: j['id'] as String?,
        type: vehicleTypeFrom(j['type'] as String?),
        name: j['name'] as String? ?? '',
        plate: j['plate'] as String? ?? '',
        photoB64: j['photoB64'] as String?,
        deadlines: _withTax((j['deadlines'] as List?)
                ?.map((e) => Deadline.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            []),
        documents: (j['documents'] as List?)
                ?.map((e) => VehicleDocument.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        maintenance: (j['maintenance'] as List?)
                ?.map((e) => MaintenanceRecord.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        notes: j['notes'] as String? ?? '',
        updatedAt: (j['updatedAt'] as num?)?.toInt() ?? 0,
        updatedBy: j['updatedBy'] as String? ?? '',
        updatedByUid: j['updatedByUid'] as String? ?? '',
        createdBy: j['createdBy'] as String? ?? '',
        deleted: j['deleted'] as bool? ?? false,
        fleetId: j['fleetId'] as String?,
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

/// Nucleo familiare condiviso (parco auto di gruppo).
class FleetGroup {
  final String id;
  String name;
  String ownerUid;

  /// uid -> email dei membri.
  Map<String, String> members;

  FleetGroup({
    required this.id,
    required this.name,
    this.ownerUid = '',
    Map<String, String>? members,
  }) : members = members ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ownerUid': ownerUid,
        'members': members,
      };

  factory FleetGroup.fromJson(Map<String, dynamic> j) => FleetGroup(
        id: j['id'] as String,
        name: j['name'] as String? ?? tr('family.defaultName'),
        ownerUid: j['ownerUid'] as String? ?? '',
        members: Map<String, dynamic>.from((j['members'] as Map?) ?? {})
            .map((k, v) => MapEntry(k, v.toString())),
      );
}

/// Dati di un utente salvati sul telefono.
class UserData {
  List<Vehicle> vehicles;
  NotifySettings notify;

  /// Parco personale online (id = uid dell'utente).
  String? personalFleetId;
  List<FleetGroup> groups;

  UserData({
    List<Vehicle>? vehicles,
    NotifySettings? notify,
    this.personalFleetId,
    List<FleetGroup>? groups,
  })  : vehicles = vehicles ?? [],
        notify = notify ?? NotifySettings(),
        groups = groups ?? [];

  FleetGroup? groupById(String? id) {
    for (final g in groups) {
      if (g.id == id) return g;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'vehicles': vehicles.map((v) => v.toJson()).toList(),
        'notify': notify.toJson(),
        'personalFleetId': personalFleetId,
        'groups': groups.map((g) => g.toJson()).toList(),
      };

  factory UserData.fromJson(Map<String, dynamic> j) => UserData(
        vehicles: (j['vehicles'] as List?)
                ?.map((e) => Vehicle.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        notify: NotifySettings.fromJson(
            j['notify'] == null ? null : Map<String, dynamic>.from(j['notify'] as Map)),
        personalFleetId: j['personalFleetId'] as String?,
        groups: (j['groups'] as List?)
                ?.map((e) => FleetGroup.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
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
