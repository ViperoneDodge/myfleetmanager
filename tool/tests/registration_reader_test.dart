import 'package:flutter_test/flutter_test.dart';
import 'package:myfleetmanager/services/registration_reader.dart';

void main() {
  test('libretto nuovo formato', () {
    const t = '''REPUBBLICA ITALIANA
CARTA DI CIRCOLAZIONE
A) GD 452 RT
B) 14/03/2019
C.2.1) ROSSI
D.1) ALFA ROMEO
D.3) GIULIA
E) ZFA31200000987O54
J) M1
P.1) 1598
P.2) 132
P.3) GASOLIO
Pneumatici: 225/45 R18 95W 255/40 R18 99W
I) 18/03/2019''';
    final d = RegistrationReader.parse(t);
    expect(d.plate, 'GD452RT');
    expect(d.registrationDate, DateTime(2019, 3, 14));
    expect(d.vin, 'ZFA31200000987054');
    expect(d.tyres, '225/45 R18 95W; 255/40 R18 99W');
    expect(d.powerKw, '132');
    expect(d.engineCc, '1598');
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
CARTA DI CIRCOLAZIONE CZ 0000000
N° A900000XX00 (A) GD452RT
(B) 14.03.2019
(C.2.1) ROSSI
(C.2.2) MARIO
NATO IL 03.03.1980 (XXXXXX80C03X000X)
A CITTA' (XX)
(C.2.3) VIA ROMA 1
N° A900000XX00 (A) GD452RT
(D.1) ALFA ROMEO
(D.2) 952 AEA2 5
(D.3) GIULIA
(E) ZAR952000H1234567
(F.2) 2020 (F.3) 3620 (G)
(I) 20.06.2024
(J) M1
(O.1) 1600 (O.2)
(P.1) 1598,00 (P.2)110,00 (P.3)GASOL
(P.5) 12345678
RAPPORTO POTENZA/TARA = 72,368 KW/T
DATA 06.12.2022 (XXXX0000000)
ELENCO PNEUMATICI AMMESSI
225/50 R17 94W (A1)
225/40 R19 89W (A2)''';
    final d = RegistrationReader.parse(t);
    expect(d.plate, 'GD452RT');
    expect(d.registrationDate, DateTime(2019, 3, 14));
    expect(d.vin, 'ZAR952000H1234567');
    expect(d.powerKw, '110');
    expect(d.engineCc, '1598');
    expect(d.tyres, '225/50 R17 94W; 225/40 R19 89W');
  });
  test('senza etichetta B, salta la data di nascita', () {
    final d = RegistrationReader.parse('NATO IL 03.03.1980 A CITTA IMMATRICOLAZIONE 14.03.2019 (I) 20.06.2024');
    expect(d.registrationDate, DateTime(2019, 3, 14));
  });
  test('libretto moto Kawasaki', () {
    const t = '''CARTA DI CIRCOLAZIONE - PARTE I AV 0000000
N° M000000XX00 (A) DZ48163
(B) 21.04.2008
(C.2.1) BIANCHI
NATO IL 11.11.1975
A CITTA (XX)
N° M000000XX00 (A) DZ48163
(D.1) KAWASAKI HEAVY INDUSTRIES LTD
ER650A
(D.3) ER-6N
(E) JKAER650AAA012345
(F.2) 376 (F.3) (G)
(I) 21.04.2008
(J) L3
(P.1) 649 (P.2) 053,00 (P.3) BENZ
(P.5) ER650AE
(U.1) 94 (U.2) 4250
PNEUMATICI:
ANTERIORI 120/70 ZR17 M/C 58W
SEGUE PNEUMATICI: POSTERIORI 160/60
ZR17 M/C 69W''';
    final d = RegistrationReader.parse(t);
    expect(d.plate, 'DZ48163');
    expect(d.registrationDate, DateTime(2008, 4, 21));
    expect(d.vin, 'JKAER650AAA012345');
    expect(d.powerKw, '53');
    expect(d.engineCc, '649');
    expect(d.tyres, '120/70 ZR17 58W; 160/60 ZR17 69W');
  });
  test('ordine OCR a colonne e intestazione ingannevole', () {
    const t = '''COMUNITA EUROPEAMINISTERODEL
REPUBBLICA ITALIANA
(D.1)
(D.2)
(D.3)
(E)
(F.1)
ALFA ROMEO
952 AEA2 5
GIULIA
ZAR952000H 1234567
(P.1) 1598,00 (P.2)096,00''';
    final d = RegistrationReader.parse(t);
    expect(d.vin, 'ZAR952000H1234567');
    expect(d.powerKw, '96');
  });
  test('telaio moto con O al posto di 0, lontano da (E)', () {
    const t = '(E)\n(F.1)\n(I) 21.04.2008\nJKAER65OAAAO12345\nPARTE I AV 0000000';
    expect(RegistrationReader.parse(t).vin, 'JKAER650AAA012345');
  });
  test('vuoto', () => expect(RegistrationReader.parse('ciao').isEmpty, true));
}
