import 'package:flutter_test/flutter_test.dart';
import 'package:myfleetmanager/models.dart';
import 'package:myfleetmanager/widgets/common.dart';

void main() {
  test('importi scritti in modi diversi', () {
    expect(parseCents('58,00'), 5800);
    expect(parseCents('58.5'), 5850);
    expect(parseCents('1.250,90'), 125090);
    expect(parseCents('1,250.90'), 125090);
    expect(parseCents('1.250'), 125000);
    expect(parseCents('€ 12'), 1200);
    expect(parseCents(''), isNull);
    expect(parseCents('abc'), isNull);
  });

  test('totale con ricambi, voci libere e manodopera', () {
    final r = MaintenanceRecord(date: DateTime(2026, 10, 14), items: {'oil', 'oilFilter'}, labor: 6000);
    r.part('oil')
      ..code = '5W-30'
      ..cents = 5800;
    r.part('oilFilter').cents = 1450;
    r.part('airFilter').cents = 2290;
    r.parts.add(MaintPart(name: 'Spazzole', cents: 3100));
    expect(r.total, 5800 + 1450 + 3100 + 6000);
    expect(r.labels.length, 3);
    expect(r.labels.last, 'Spazzole');
    expect(MaintenanceRecord(date: DateTime(2026)).total, isNull);
  });

  test('salvati e riletti, compatibili con i dati vecchi', () {
    final r = MaintenanceRecord(date: DateTime(2026, 10, 14), items: {'oil'}, labor: 1000);
    r.part('oil').cents = 4000;
    r.part('airFilter');
    r.parts.add(MaintPart(name: 'Batteria', code: 'AGM 70Ah', cents: 15000));
    r.parts.add(MaintPart());
    final j = r.toJson();
    expect((j['parts'] as List).length, 2);
    final back = MaintenanceRecord.fromJson(j);
    expect(back.total, 4000 + 15000 + 1000);
    expect(back.customParts.single.code, 'AGM 70Ah');
    final old = MaintenanceRecord.fromJson({'id': 'x', 'date': '2020-01-01', 'items': ['oil'], 'notes': ''});
    expect(old.parts, isEmpty);
    expect(old.total, isNull);
    expect(old.toJson().containsKey('parts'), isFalse);
  });

  test('moto senza filtro abitacolo, tranne se già segnato', () {
    expect(maintenanceItemsFor(VehicleType.moto), isNot(contains('cabinFilter')));
    expect(maintenanceItemsFor(VehicleType.auto), contains('cabinFilter'));
    expect(maintenanceItemsFor(null), maintenanceItems);
    expect(maintenanceItemsFor(VehicleType.moto, {'cabinFilter'}), contains('cabinFilter'));
  });
}
