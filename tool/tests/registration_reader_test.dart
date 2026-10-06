import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:myfleetmanager/services/registration_reader.dart';

void main() {
  test('libretto italiano: solo campi con etichetta UE', () {
    const t = '''CARTA DI CIRCOLAZIONE CZ 0000000
N° A900000XX00   (A) GD452RT   1
(B) 14.03.2019
(C.2.1) ROSSI
NATO IL 03.03.1980
(D.1) ALFA ROMEO
(E) ZAR952000H1234567
(I) 20.06.2024
(P.1) 1598,00 (P.2)096,00 (P.3)GASOL
225/50 R17 94W (A1)''';
    final d = RegistrationReader.parse(t);
    expect(d.plate, 'GD452RT');
    expect(d.registrationDate, DateTime(2019, 3, 14));
    expect(d.vin, 'ZAR952000H1234567');
    expect(d.engineCc, '1598');
    expect(d.powerKw, '96');
  });

  test('moto: targa corta, O letta al posto di 0 nel telaio', () {
    const t = '''N° M000000XX00 (A) DZ48163
(B) 21.04.2008
(E) JKAER65OAAAO12345
(P.1) 649 (P.2) 053,00 (P.3) BENZ''';
    final d = RegistrationReader.parse(t);
    expect(d.plate, 'DZ48163');
    expect(d.registrationDate, DateTime(2008, 4, 21));
    expect(d.vin, 'JKAER650AAA012345');
    expect(d.engineCc, '649');
    expect(d.powerKw, '53');
  });

  test('B letta come 8 e telaio spezzato da spazi', () {
    final d = RegistrationReader.parse('(8) 01/02/2015\n(E) WVW ZZZ1K Z5W 012345');
    expect(d.registrationDate, DateTime(2015, 2, 1));
    expect(d.vin, 'WVWZZZ1KZ5W012345');
  });

  test('senza etichette non indovina nulla', () {
    const t = 'targa AB12345 immatricolata il 03.04.2010 telaio ZDM1RC4K0AB012345 kw 75 cilindrata 1198 cm3 '
        'COMUNITA EUROPEA MINISTERO DELLE INFRASTRUTTURE NATO IL 01.01.1970';
    expect(RegistrationReader.parse(t).isEmpty, true);
  });

  test('etichette diverse non vengono confuse (C.2.1, J.1, A1)', () {
    final d = RegistrationReader.parse('(C.2.1) BIANCHI\n(J.1) AUTOVETTURA\n205/60 R16 92V (A1)');
    expect(d.isEmpty, true);
  });

  test('Germania: codici senza parentesi, P.2/P.4', () {
    const t = '''ZULASSUNGSBESCHEINIGUNG TEIL I
A   M-AB 1234
B   14.03.2019
E   WVWZZZ1KZ5W012345
P.1   1598
P.2/P.4   85/5000
P.3   BENZIN''';
    final d = RegistrationReader.parse(t);
    expect(d.plate, 'MAB1234');
    expect(d.registrationDate, DateTime(2019, 3, 14));
    expect(d.vin, 'WVWZZZ1KZ5W012345');
    expect(d.engineCc, '1598');
    expect(d.powerKw, '85');
  });

  test('Francia: codici con il punto', () {
    const t = '''CERTIFICAT D'IMMATRICULATION
A. AB-123-CD   B. 14/03/2019
E. VF1RFB00X12345678
P.1 1461   P.2 85   P.3 GO''';
    final d = RegistrationReader.parse(t);
    expect(d.plate, 'AB123CD');
    expect(d.registrationDate, DateTime(2019, 3, 14));
    expect(d.vin, 'VF1RFB00X12345678');
    expect(d.engineCc, '1461');
    expect(d.powerKw, '85');
  });

  test('Spagna: due punti e targa numeri-lettere', () {
    const t = 'A: 1234 BCD\nB: 14/03/2019\nE: VSSZZZ6JZ9R012345\nP.1: 1390\nP.2: 63';
    final d = RegistrationReader.parse(t);
    expect(d.plate, '1234BCD');
    expect(d.registrationDate, DateTime(2019, 3, 14));
    expect(d.vin, 'VSSZZZ6JZ9R012345');
    expect(d.engineCc, '1390');
    expect(d.powerKw, '63');
  });

  test('etichetta a fine riga con valore nella riga sotto', () {
    final d = RegistrationReader.parse('E\nTMBJJ7NE8K0012345\nB\n2019-03-14');
    expect(d.vin, 'TMBJJ7NE8K0012345');
    expect(d.registrationDate, DateTime(2019, 3, 14));
  });

  test('lettere isolate nel testo non diventano dati', () {
    final d = RegistrationReader.parse("NATO IL 03.03.1980\nA CITTA' (XX)\nE ROSSI MARIO\nVIA ROMA 1 A ASTI");
    expect(d.isEmpty, true);
  });

  test('righe ricostruite dalla posizione (colonne separate)', () {
    Rect r(double x, double y, double w) => Rect.fromLTWH(x, y, w, 20);
    final text = RegistrationReader.layoutLines([
      (text: '(D.1)', box: r(700, 140, 60)),
      (text: '(E)', box: r(700, 318, 40)),
      (text: '(P.1)', box: r(700, 770, 60)),
      (text: '(P.2)', box: r(990, 771, 60)),
      (text: 'ALFA ROMEO', box: r(870, 141, 170)),
      (text: 'ZAR952000H1234567', box: r(835, 320, 290)),
      (text: '1598,00', box: r(780, 768, 100)),
      (text: '096,00', box: r(1060, 772, 90)),
      (text: '(B) 14.03.2019', box: r(80, 400, 230)),
      (text: 'NATO IL 03.03.1980', box: r(75, 572, 300)),
    ]);
    final d = RegistrationReader.parse(text);
    expect(d.vin, 'ZAR952000H1234567');
    expect(d.registrationDate, DateTime(2019, 3, 14));
    expect(d.engineCc, '1598');
    expect(d.powerKw, '96');
  });
}
