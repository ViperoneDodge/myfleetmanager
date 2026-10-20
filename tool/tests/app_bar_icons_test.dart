import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfleetmanager/theme.dart';

class _Tick extends ChangeNotifier {
  void tick() => notifyListeners();
}

Color? _color(WidgetTester tester, IconData icon) => tester
    .widget<RichText>(find.descendant(of: find.byIcon(icon), matching: find.byType(RichText)))
    .text
    .style
    ?.color;

void main() {
  testWidgets('icone della barra sempre bianche quando l\'app si aggiorna', (tester) async {
    final tick = _Tick();
    final settings = ThemeSettings();
    await tester.pumpWidget(ListenableBuilder(
      listenable: tick,
      builder: (_, __) => MaterialApp(
        theme: cachedTheme(settings, Brightness.light),
        home: Scaffold(
          appBar: AppBar(actions: [
            const Icon(Icons.cloud_done),
            IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
          ]),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      tick.tick();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(_color(tester, Icons.cloud_done), Colors.white);
      expect(_color(tester, Icons.settings), Colors.white);
    }
  });

  test('tema riutilizzato finché le impostazioni non cambiano', () {
    final a = cachedTheme(ThemeSettings(palette: 1), Brightness.light);
    expect(identical(a, cachedTheme(ThemeSettings(palette: 1), Brightness.light)), isTrue);
    expect(identical(a, cachedTheme(ThemeSettings(palette: 1), Brightness.dark)), isFalse);
    expect(identical(a, cachedTheme(ThemeSettings(palette: 2), Brightness.light)), isFalse);
  });
}
