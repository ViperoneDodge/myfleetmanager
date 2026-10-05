import 'package:flutter_test/flutter_test.dart';
import 'package:myfleetmanager/services/registration_reader.dart';

void main() {
  test('libretto nuovo formato', () {
    const t = '''REPUBBLICA ITALIANA
CARTA DI CIRCOLAZIONE
A) FK 387 AG
B) 17/05/2017
C.2.1) ROSSI
D.1) ALFA ROMEO
D.3) GIULIA
E) ZARFAEBN7H7556O12
J) M1
P.1) 2143
P.2) 132
P.3) GASOLIO
Pneumatici: 225/45 R18 95W 255/40 R18 99W
I) 20/05/2017''';
    final d = RegistrationReader.parse(t);
    expect(d.plate, 'FK387AG');
    expect(d.registrationDate, DateTime(2017, 5, 17));
    expect(d.vin, 'ZARFAEBN7H7556012');
    expect(d.tyres, '225/45 R18 95W; 255/40 R18 99W');
    expect(d.powerKw, '132');
    expect(d.engineCc, '2143');
  });
  test('moto senza etichette', () {
    const t = 'targa AB12345 immatricolata il 03.04.2010 telaio ZDM1RC4K0AB012345 kw 75,5 cilindrata 1198 cm3 120/70 ZR17 58W';
    final d = RegistrationReader.parse(t);
    expect(d.plate, 'AB12345');
    expect(d.registrationDate, DateTime(2010, 4, 3));
    expect(d.vin, 'ZDM1RC4K0AB012345');
    expect(d.powerKw, '75.5');
    expect(d.engineCc, '1198');
    expect(d.tyres, '120/70 ZR17 58W');
  });
  test('libretto Giulia utente', () {
    const t = '''REPUBBLICA ITALIANA
CARTA DI CIRCOLAZIONE CZ 0677049
N° A413178TO25 (A) FK387AG
(B) 17.05.2017
(C.2.1) CAPRIOGLIO
(C.2.2) GIANLUCA
NATO IL 12.05.1986 (CPRGLC86E12D208D)
A CUORGNE' (TO)
(C.2.3) VIA GROMIS 34
N° A413178TO25 (A) FK387AG
(D.1) ALFA ROMEO
(D.2) 952 AEA2 5
(D.3) GIULIA
(E) ZAREAECU6H7553467
(F.2) 2020 (F.3) 3620 (G)
(I) 03.07.2025
(J) M1
(O.1) 1600 (O.2)
(P.1) 2143,00 (P.2)110,00 (P.3)GASOL
(P.5) 55268532
RAPPORTO POTENZA/TARA = 72,368 KW/T
DATA 06.12.2022 (TOBG0DQ1NCB)
ELENCO PNEUMATICI AMMESSI
225/50 R17 94W (A1)
225/40 R19 89W (A2)''';
    final d = RegistrationReader.parse(t);
    expect(d.plate, 'FK387AG');
    expect(d.registrationDate, DateTime(2017, 5, 17));
    expect(d.vin, 'ZAREAECU6H7553467');
    expect(d.powerKw, '110');
    expect(d.engineCc, '2143');
    expect(d.tyres, '225/50 R17 94W; 225/40 R19 89W');
  });
  test('senza etichetta B, salta la data di nascita', () {
    final d = RegistrationReader.parse('NATO IL 12.05.1986 A CUORGNE IMMATRICOLAZIONE 17.05.2017 (I) 03.07.2025');
    expect(d.registrationDate, DateTime(2017, 5, 17));
  });
  test('vuoto', () => expect(RegistrationReader.parse('ciao').isEmpty, true));
}
