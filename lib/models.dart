import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'l10n.dart';

String newId([int length = 16]) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final r = Random.secure();
  return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
}

enum VehicleType { auto, moto, furgone, camion, rimorchio, agricolo }

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
    case VehicleType.agricolo:
      return tr('type.tractor');
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
    case VehicleType.agricolo:
      return tr('type.tractors');
  }
}

class VehicleDocument {
  String id;
  String name;

  String fileName;

  String kind;
  int addedAt;
  int size;
  bool cloud;
  String by;
  int cloudSize;

  VehicleDocument({
    String? id,
    required this.name,
    required this.fileName,
    required this.kind,
    int? addedAt,
    this.size = 0,
    this.cloud = false,
    this.by = '',
    this.cloudSize = 0,
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
        'cloud': cloud,
        'by': by,
        'cloudSize': cloudSize,
      };

  factory VehicleDocument.fromJson(Map<String, dynamic> j) => VehicleDocument(
        id: j['id'] as String?,
        name: j['name'] as String? ?? tr('doc.default'),
        fileName: j['fileName'] as String? ?? '',
        kind: j['kind'] as String? ?? 'image',
        addedAt: (j['addedAt'] as num?)?.toInt(),
        size: (j['size'] as num?)?.toInt() ?? 0,
        cloud: j['cloud'] == true,
        by: j['by'] as String? ?? '',
        cloudSize: (j['cloudSize'] as num?)?.toInt() ?? 0,
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

  DateTime? date;

  int intervalMonths;

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

  DateTime? get dueDate {
    if (date == null) return null;
    if (kind == DeadlineKind.service) {
      if (intervalMonths <= 0) return null;
      final d = date!;
      return DateTime(d.year, d.month + intervalMonths, d.day);
    }
    return date;
  }

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

class MaintenanceRecord {
  String id;
  DateTime date;
  int? km;

  Set<String> items;
  String notes;
  int createdAt;

  MaintenanceRecord({
    String? id,
    required this.date,
    this.km,
    Set<String>? items,
    this.notes = '',
    int? createdAt,
  })  : id = id ?? newId(8),
        items = items ?? <String>{},
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'km': km,
        'items': items.toList(),
        'notes': notes,
        'createdAt': createdAt,
      };

  factory MaintenanceRecord.fromJson(Map<String, dynamic> j) => MaintenanceRecord(
        id: j['id'] as String?,
        date: DateTime.tryParse((j['date'] as String?) ?? '') ?? DateTime.now(),
        km: (j['km'] as num?)?.toInt(),
        items: ((j['items'] as List?) ?? const []).map((e) => e.toString()).toSet(),
        notes: j['notes'] as String? ?? '',
        createdAt: (j['createdAt'] as num?)?.toInt() ?? 0,
      );

  DateTime? get insertedOn {
    if (createdAt <= 0) return null;
    final c = DateTime.fromMillisecondsSinceEpoch(createdAt);
    return DateTime(c.year, c.month, c.day);
  }

  MaintenanceRecord copy() => MaintenanceRecord.fromJson(toJson());
}

class Vehicle {
  String id;
  VehicleType type;
  String name;
  String plate;

  String? photoB64;
  List<Deadline> deadlines;
  List<VehicleDocument> documents;

  List<MaintenanceRecord> maintenance;
  String notes;

  DateTime? registrationDate;

  String vin;
  String tyres;
  String powerKw;
  String engineCc;
  int updatedAt;
  String updatedBy;

  String updatedByUid;

  String createdBy;

  int createdAt;
  bool deleted;

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
    this.registrationDate,
    this.vin = '',
    this.tyres = '',
    this.powerKw = '',
    this.engineCc = '',
    int? updatedAt,
    this.updatedBy = '',
    this.updatedByUid = '',
    this.createdBy = '',
    this.createdAt = 0,
    this.deleted = false,
    this.fleetId,
  })  : id = id ?? newId(),
        deadlines = deadlines ?? defaultDeadlines(type),
        documents = documents ?? [],
        maintenance = maintenance ?? [],
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  static List<Deadline> _withTax(List<Deadline> list) {
    if (list.isNotEmpty && !list.any((d) => d.kind == DeadlineKind.tax)) {
      list.add(Deadline(kind: DeadlineKind.tax, enabled: false));
    }
    return list;
  }

  static int _rank(DeadlineKind k) {
    switch (k) {
      case DeadlineKind.insurance:
        return 0;
      case DeadlineKind.tax:
        return 1;
      case DeadlineKind.inspection:
        return 2;
      case DeadlineKind.service:
        return 3;
      case DeadlineKind.custom:
        return 4;
    }
  }

  static List<Deadline> _ordered(List<Deadline> list) {
    final indexed = list.asMap().entries.toList()
      ..sort((a, b) {
        final r = _rank(a.value.kind).compareTo(_rank(b.value.kind));
        return r != 0 ? r : a.key.compareTo(b.key);
      });
    return indexed.map((e) => e.value).toList();
  }

  static List<Deadline> defaultDeadlines(VehicleType t) => [
        Deadline(kind: DeadlineKind.insurance),
        Deadline(kind: DeadlineKind.tax),
        Deadline(kind: DeadlineKind.inspection),
        Deadline(
          kind: DeadlineKind.service,
          intervalMonths: 12,
          enabled: t != VehicleType.rimorchio,
        ),
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

  List<Deadline> get activeDeadlines {
    final list = deadlines
        .where((d) => d.enabled && d.dueDate != null)
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return list;
  }

  List<MaintenanceRecord> get maintenanceSorted =>
      List.of(maintenance)..sort((a, b) => b.date.compareTo(a.date));

  Deadline? get nextDeadline {
    final a = activeDeadlines;
    return a.isEmpty ? null : a.first;
  }

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
        'regDate': registrationDate?.toIso8601String(),
        'vin': vin,
        'tyres': tyres,
        'powerKw': powerKw,
        'engineCc': engineCc,
        'updatedAt': updatedAt,
        'updatedBy': updatedBy,
        'updatedByUid': updatedByUid,
        'createdBy': createdBy,
        'createdAt': createdAt,
        'deleted': deleted,
        'fleetId': fleetId,
      };

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: j['id'] as String?,
        type: vehicleTypeFrom(j['type'] as String?),
        name: j['name'] as String? ?? '',
        plate: j['plate'] as String? ?? '',
        photoB64: j['photoB64'] as String?,
        deadlines: _ordered(_withTax((j['deadlines'] as List?)
                ?.map((e) => Deadline.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [])),
        documents: (j['documents'] as List?)
                ?.map((e) => VehicleDocument.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        maintenance: (j['maintenance'] as List?)
                ?.map((e) => MaintenanceRecord.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        notes: j['notes'] as String? ?? '',
        registrationDate: j['regDate'] == null ? null : DateTime.tryParse(j['regDate'] as String),
        vin: j['vin'] as String? ?? '',
        tyres: j['tyres'] as String? ?? '',
        powerKw: j['powerKw'] as String? ?? '',
        engineCc: j['engineCc'] as String? ?? '',
        updatedAt: (j['updatedAt'] as num?)?.toInt() ?? 0,
        updatedBy: j['updatedBy'] as String? ?? '',
        updatedByUid: j['updatedByUid'] as String? ?? '',
        createdBy: j['createdBy'] as String? ?? '',
        createdAt: (j['createdAt'] as num?)?.toInt() ?? 0,
        deleted: j['deleted'] as bool? ?? false,
        fleetId: j['fleetId'] as String?,
      );

  Vehicle copy() => Vehicle.fromJson(toJson());
}

class NotifySettings {
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

enum GroupRole { admin, editor, viewer }

String groupRoleLabel(GroupRole r) {
  switch (r) {
    case GroupRole.admin:
      return tr('role.admin');
    case GroupRole.editor:
      return tr('role.editor');
    case GroupRole.viewer:
      return tr('role.viewer');
  }
}

class FleetGroup {
  final String id;
  String name;
  String ownerUid;

  Map<String, String> members;

  Set<String> admins;

  Set<String> viewers;

  bool shareDocs;

  FleetGroup({
    required this.id,
    required this.name,
    this.ownerUid = '',
    Map<String, String>? members,
    Set<String>? admins,
    Set<String>? viewers,
    this.shareDocs = false,
  })  : members = members ?? {},
        admins = admins ?? {},
        viewers = viewers ?? {};

  GroupRole roleOf(String? uid) {
    if (uid == null) return GroupRole.viewer;
    if (uid == ownerUid || admins.contains(uid)) return GroupRole.admin;
    if (viewers.contains(uid)) return GroupRole.viewer;
    return GroupRole.editor;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ownerUid': ownerUid,
        'members': members,
        'admins': admins.toList(),
        'viewers': viewers.toList(),
        'shareDocs': shareDocs,
      };

  factory FleetGroup.fromJson(Map<String, dynamic> j) => FleetGroup(
        id: j['id'] as String,
        name: j['name'] as String? ?? tr('family.defaultName'),
        ownerUid: j['ownerUid'] as String? ?? '',
        members: Map<String, dynamic>.from((j['members'] as Map?) ?? {})
            .map((k, v) => MapEntry(k, v.toString())),
        admins: ((j['admins'] as List?) ?? const []).map((e) => e.toString()).toSet(),
        viewers: ((j['viewers'] as List?) ?? const []).map((e) => e.toString()).toSet(),
        shareDocs: j['shareDocs'] == true,
      );
}

class UserData {
  List<Vehicle> vehicles;
  NotifySettings notify;

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

  String get storageKey =>
      '${mode.name}_${key.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}';
}
