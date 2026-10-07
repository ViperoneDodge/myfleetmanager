import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfleetmanager/widgets/group_qr.dart';

void main() {
  test('codice letto dal QR', () {
    expect(codeFromQr(groupQrData('AB23CD45EF')), 'AB23CD45EF');
    expect(codeFromQr(' ab23cd45ef '), 'AB23CD45EF');
    expect(codeFromQr('myfleetmanager:join:AB23CD45EF'), 'AB23CD45EF');
    expect(groupQrData('AB23CD45EF'), startsWith('https://'));
    expect(codeFromQr('https://example.com/qualcosa'), null);
    expect(codeFromQr(null), null);
  });

  testWidgets('QR con logo al centro', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Center(child: RepaintBoundary(child: GroupQr(code: 'AB23CD45EF')))),
      ));
      await precacheImage(const AssetImage('assets/gian_trip_logo.png'), tester.element(find.byType(GroupQr)));
    });
    await tester.pumpAndSettle();
    await expectLater(find.byType(GroupQr), matchesGoldenFile('out/group_qr.png'));
  });
}
