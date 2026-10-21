import 'package:flutter_test/flutter_test.dart';
import 'package:myfleetmanager/units.dart';

void main() {
  tearDown(() => Units.load(null));

  test('kW e CV si convertono a vicenda', () {
    expect(kwToCvText('96'), '131');
    expect(kwToCvText('55,5'), '75');
    expect(cvToKwText('131'), '96.4');
    expect(cvToKwText('100'), '73.5');
    expect(kwToCvText(''), '');
    expect(cvToKwText('abc'), '');
  });

  test('potenza mostrata secondo la preferenza', () {
    Units.load({'unitPower': 'kw'});
    expect(fmtPower('96'), '96 kW');
    Units.load({'unitPower': 'cv'});
    expect(fmtPower('96'), endsWith('131 unit.cv'));
    Units.load({'unitPower': 'both'});
    expect(fmtPower('96'), startsWith('96 kW · 131'));
    expect(fmtPower('n.d.'), 'n.d.');
  });

  test('chilometri e miglia', () {
    expect(fmtKm(85000), '85.000 km');
    Units.load({'unitDistance': 'mi'});
    expect(fmtKm(85000), '52.817 mi');
    expect(shownToKm(100), 161);
    expect(kmToShown(shownToKm(100)), 100);
  });

  test('preferenze salvate e rilette, valori sconosciuti ignorati', () {
    Units.load({'unitPower': 'both', 'unitDistance': 'mi', 'unitCurrency': 'GBP'});
    final j = Units.toJson();
    Units.load(null);
    expect(Units.power, 'kw');
    Units.load(j);
    expect([Units.power, Units.distance, Units.currency], ['both', 'mi', 'GBP']);
    Units.load({'unitPower': 'x', 'unitDistance': 'y', 'unitCurrency': 'ZZZ'});
    expect([Units.power, Units.distance, Units.currency], ['kw', 'km', '']);
  });
}
