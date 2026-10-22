import 'package:flutter_test/flutter_test.dart';
import 'package:myfleetmanager/services/tyres.dart';

void main() {
  test('misure trovate nel testo letto', () {
    const t = '''225/50 R17 94W; 225/40 R19 89W; 255/35 R 19 92W;
225/45R18 91W  255/40 ZR18 95W  205/60 R16 92V (A1)
195/70 R15C 104/102R   120/70 ZR17 M/C (58W)   1598,00 (P.2)096,00''';
    expect(TyreSet.findSizes(t), [
      '225/50 R17 94W',
      '225/40 R19 89W',
      '255/35 R19 92W',
      '225/45 R18 91W',
      '255/40 ZR18 95W',
      '205/60 R16 92V',
      '195/70 R15C 104/102R',
      '120/70 ZR17 58W',
    ]);
  });

  test('divisione di base per cerchio', () {
    final sets = TyreSet.byRim(
      ['225/50 R17 94W', '225/40 R19 89W', '255/35 R19 92W', '205/60 R16 92V'],
      (r) => 'Cerchio $r',
    );
    expect(TyreSet.format(sets),
        'Cerchio 16: 205/60 R16 92V\nCerchio 17: 225/50 R17 94W\nCerchio 19: 225/40 R19 89W; 255/35 R19 92W');
    expect(TyreSet.format(TyreSet.byRim(['205/55 R16 91V', '195/65 R16 92H'], (r) => 'Cerchio $r')),
        '205/55 R16 91V; 195/65 R16 92H');
  });

  test('gruppi salvati e riletti, testo vecchio senza gruppi', () {
    final sets = TyreSet.parse('Anteriori: 225/40 R19 89W\nPosteriori: 255/35 R19 92W; 255/40 R18 95W');
    expect(sets.map((s) => s.label), ['Anteriori', 'Posteriori']);
    expect(sets[1].sizeList, ['255/35 R19 92W', '255/40 R18 95W']);
    final old = TyreSet.parse('225/50 R17 94W; 225/40\nR19 89W');
    expect(old.length, 1);
    expect(old.first.label, '');
    expect(TyreSet.format([TyreSet(label: 'Inv: estive', sizes: '205/55 R16;;'), TyreSet(label: 'x', sizes: ' ')]),
        'Inv  estive: 205/55 R16');
  });

  test('moto: anteriore e posteriore già pronti', () {
    expect(TyreSet.blank(true, 'Anteriore', 'Posteriore').map((s) => s.label), ['Anteriore', 'Posteriore']);
    expect(TyreSet.blank(false, 'Anteriore', 'Posteriore').single.label, '');
    expect(TyreSet.isBlank(TyreSet.blank(true, 'A', 'P')), isTrue);
    expect(TyreSet.isBlank([TyreSet(label: 'A', sizes: '120/70 ZR17')]), isFalse);
    final saved = TyreSet.parse('Anteriori: 120/70 ZR17 58W\nPosteriori: 180/55 ZR17 73W');
    expect(TyreSet.isBlank(saved), isFalse);
    expect(TyreSet.parse(TyreSet.format(saved)).map((s) => s.label), ['Anteriori', 'Posteriori']);
  });
}
