import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfleetmanager/l10n.dart';
import 'package:myfleetmanager/services/registration_reader.dart';
import 'package:myfleetmanager/widgets/ocr_review.dart';

void main() {
  test('valore proposto senza le etichette del libretto', () {
    expect(RegistrationReader.propose('plate', '(A) XY123ZW   1'), 'XY123ZW');
    expect(RegistrationReader.propose('reg', '(B) 14.03.2019'), '14/03/2019');
    expect(RegistrationReader.propose('vin', '(E) ZAR 952000H1234567'), 'ZAR952000H1234567');
    expect(RegistrationReader.propose('power', '(P.2) 096,00 (P.3) GASOL'), '96');
    expect(RegistrationReader.propose('cc', 'P.1 1598,00'), '1598');
    expect(RegistrationReader.propose('tyres', '225/50 R17 94W (A1) 205/60R16 92V'), '225/50 R17 94W; 205/60 R16 92V');
    final d = RegistrationData();
    expect(RegistrationReader.apply(d, 'power', 'abc'), false);
    expect(RegistrationReader.apply(d, 'reg', '31/02/2019'), false);
    expect(RegistrationReader.apply(d, 'power', '96'), true);
    expect(d.powerKw, '96');
  });

  testWidgets('testo selezionato, assegnato e salvato', (tester) async {
    await tester.runAsync(() => L10n.load('it'));
    const raw = 'CARTA DI CIRCOLAZIONE\n(A) XY123ZW   1\n(P.2) 096,00 (P.3) GASOL';
    final data = RegistrationData();
    Set<String>? result;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showOcrReview(context, data, raw),
            child: const Text('apri'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('apri'));
    await tester.pumpAndSettle();
    expect(find.text(tr('ocr.none')), findsOneWidget);

    await tester.tap(find.text(tr('ocr.rawText')));
    await tester.pumpAndSettle();
    final editable = tester.state<EditableTextState>(find.byType(EditableText));
    final text = editable.textEditingValue.text;
    final start = text.indexOf('(P.2)');
    editable.userUpdateTextEditingValue(
      editable.textEditingValue.copyWith(selection: TextSelection(baseOffset: start, extentOffset: start + 12)),
      SelectionChangedCause.longPress,
    );
    await tester.pump();
    editable.showToolbar();
    await tester.pumpAndSettle();
    await tester.tap(find.text(tr('ocr.assign')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(tr('tech.power')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '96'), findsOneWidget);
    await tester.tap(find.text(tr('common.ok')).last);
    await tester.pumpAndSettle();

    expect(find.byType(SelectableText), findsNothing);
    expect(data.powerKw, '96');
    final tile = tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, '96'));
    expect(tile.value, true);

    await tester.tap(find.text(tr('ocr.apply')));
    await tester.pumpAndSettle();
    expect(result, {'power'});
  });
}
