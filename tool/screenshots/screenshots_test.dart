import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfleetmanager/l10n.dart';
import 'package:myfleetmanager/main.dart';
import 'package:myfleetmanager/models.dart';
import 'package:myfleetmanager/screens/family_screen.dart';
import 'package:myfleetmanager/screens/home_screen.dart';
import 'package:myfleetmanager/screens/pro_screen.dart';
import 'package:myfleetmanager/screens/settings_screen.dart';
import 'package:myfleetmanager/screens/vehicle_detail_screen.dart';
import 'package:myfleetmanager/screens/vehicle_edit_screen.dart';
import 'package:myfleetmanager/services/app_state.dart';
import 'package:myfleetmanager/services/pdf_export.dart';
import 'package:myfleetmanager/widgets/common.dart';
import 'package:myfleetmanager/theme.dart';

const me = 'demo-me';

Future<void> loadFonts() async {
  final sdk = Platform.environment['FLUTTER_ROOT']!;
  Future<void> f(String family, List<String> files) async {
    final l = FontLoader(family);
    for (final p in files) {
      final b = File(p).readAsBytesSync();
      l.addFont(Future.value(ByteData.view(b.buffer)));
    }
    await l.load();
  }

  final m = '$sdk/bin/cache/artifacts/material_fonts';
  await f('Roboto', ['$m/Roboto-Regular.ttf', '$m/Roboto-Medium.ttf', '$m/Roboto-Bold.ttf']);
  await f('MaterialIcons', ['$m/MaterialIcons-Regular.otf']);
  await f('PatrickHand', ['assets/fonts/PatrickHand-Regular.ttf']);
}

Vehicle v(String id, String name, String plate, VehicleType t, DateTime reg, List<int> days,
    {String? fleet, String createdBy = me, int maint = 0}) {
  final now = DateTime.now();
  final x = Vehicle(id: id, name: name, plate: plate, type: t, registrationDate: reg, fleetId: fleet, createdBy: createdBy, createdAt: 1);
  for (var i = 0; i < x.deadlines.length && i < days.length; i++) {
    final d = x.deadlines[i];
    if (d.kind == DeadlineKind.service) {
      d.date = now.add(Duration(days: days[i] - 365));
    } else {
      d.date = now.add(Duration(days: days[i]));
    }
    d.enabled = true;
  }
  for (var i = 0; i < maint; i++) {
    x.maintenance.add(MaintenanceRecord(
        date: DateTime(2025 - i, 3 + i, 12), km: 85000 - i * 15000, items: {'oil', 'oilFilter', if (i.isEven) 'airFilter'}, notes: i == 0 ? 'Officina Bianchi' : ''));
  }
  return x;
}

void setupData() {
  appState.session = Session(mode: AccountMode.cloud, key: me, displayName: 'Marco Rossi', email: 'marco.rossi@example.com');
  appState.purchasedPro = true;
  appState.loading = false;
  appState.syncStatus = SyncStatus.online;
  final fam = FleetGroup(id: 'FAM7Q2K9XW', name: 'Famiglia Rossi', ownerUid: me, members: {
    me: 'marco.rossi@example.com',
    'u2': 'giulia.rossi@example.com',
    'u3': 'luca.rossi@example.com',
  }, admins: {me}, viewers: {'u3'});
  final work = FleetGroup(id: 'WRK4M8T2PZ', name: 'Officina Bianchi', ownerUid: 'u9', members: {
    'u9': 'paolo.bianchi@example.com',
    me: 'marco.rossi@example.com',
  });
  final giulia = v('g1', 'Giulia', 'FK387AG', VehicleType.auto, DateTime(2017, 5, 17), [269, 298, 9, 40], maint: 4)
    ..vin = 'ZARFAEBN7H7556012'
    ..tyres = '225/45 R18 95W; 255/40 R18 99W'
    ..powerKw = '132'
    ..engineCc = '2143';
  appState.data = UserData(
    personalFleetId: me,
    groups: [fam, work],
    vehicles: [
      giulia,
      v('g2', 'Panda', 'EZ512LM', VehicleType.auto, DateTime(2012, 2, 3), [-3, 120, 60, 200]),
      v('g3', 'Vespa GTS', 'AB12345', VehicleType.moto, DateTime(2019, 4, 1), [45, 160, 330, 210]),
      v('g4', 'Ducato', 'GH204KT', VehicleType.furgone, DateTime(2021, 9, 9), [12, 75, 190, 300], fleet: work.id, createdBy: 'u9', maint: 2),
      v('g5', 'Daily', 'FT771BR', VehicleType.camion, DateTime(2018, 6, 6), [90, 5, 220, 25], fleet: work.id, createdBy: 'u9'),
      v('g6', 'Carrello', 'XA239PL', VehicleType.rimorchio, DateTime(2015, 1, 1), [150, 240, 400], fleet: fam.id),
      v('g7', 'Fiesta', 'GA118ZD', VehicleType.auto, DateTime(2020, 10, 10), [33, 70, 500, 90], fleet: fam.id, createdBy: 'u2'),
    ],
  );
}

Future<void> precacheAll(WidgetTester tester) async {
  final ctx = tester.element(find.byType(Scaffold).first);
  await tester.runAsync(() async {
    for (final t in VehicleType.values) {
      await precacheImage(AssetImage('assets/vehicles/${t.name}.png'), ctx);
    }
    await precacheImage(const AssetImage('assets/gian_trip_logo.png'), ctx);
    for (final e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> shot(WidgetTester tester, Widget home, String name, {Future<void> Function()? then}) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(ListenableBuilder(
    listenable: appState,
    builder: (_, __) => MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale(L10n.code),
      supportedLocales: const [Locale('en'), Locale('it')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(appState.theme, Brightness.light),
      home: home,
    ),
  ));
  await tester.pumpAndSettle();
  await precacheAll(tester);
  if (then != null) {
    await then();
    await tester.pumpAndSettle();
    await precacheAll(tester);
  }
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('out/${L10n.code}/$name.png'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  appState = AppState();
  debugDefaultTargetPlatformOverride = null;
  for (final lang in ['en', 'it']) {
    group(lang, () {
      setUp(() async {
        await L10n.load(lang);
        setupData();
      });
      testWidgets('screens', (tester) async {
        await tester.runAsync(loadFonts);
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 2.625;
        addTearDown(tester.view.reset);
        debugDisableShadows = false;

        await shot(tester, const HomeScreen(), '01_vehicles');
        await shot(tester, const VehicleDetailScreen(vehicleId: 'g1'), '02_vehicle');
        await shot(tester, const HomeScreen(), '03_deadlines', then: () async {
          await tester.tap(find.text(tr('tab.deadlines')).last);
        });
        await shot(tester, const HomeScreen(), '04_groups', then: () async {
          await tester.tap(find.text(tr('tab.family')).last);
        });
        await shot(tester, const GroupScreen(groupId: 'FAM7Q2K9XW'), '05_roles');
        await shot(tester, VehicleEditScreen(vehicle: appState.vehicleById('g1')!.copy()), '06_edit', then: () async {
          await tester.drag(find.byType(ListView).first, const Offset(0, -520));
        });
        await shot(tester, const VehicleDetailScreen(vehicleId: 'g1'), '07_ocr', then: () async {
          final ctx = tester.element(find.byType(VehicleDetailScreen));
          final rows = [
            (tr('edit.plate'), 'FK387AG'),
            (tr('vehicle.regDate'), '17/05/2017'),
            (tr('tech.vin'), 'ZARFAEBN7H7556012'),
            (tr('tech.tyres'), '225/45 R18 95W; 255/40 R18 99W'),
            (tr('tech.power'), '132'),
            (tr('tech.engine'), '2143'),
          ];
          showDialog<void>(
            context: ctx,
            builder: (c) => AlertDialog(
              title: Text(tr('ocr.found')),
              content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('ocr.foundHint'), style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  ...rows.map((r) => CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: true,
                        onChanged: (_) {},
                        title: Text(r.$2),
                        subtitle: Text(r.$1),
                      )),
                ]),
              ),
              actions: [
                TextButton(onPressed: () {}, child: Text(tr('common.cancel'))),
                FilledButton(onPressed: () {}, child: Text(tr('ocr.apply'))),
              ],
            ),
          );
        });
        await tester.runAsync(() async {
          final bytes = await PdfExport.build(title: tr('fleet.mine'), vehicles: appState.myVehicles);
          File('tool/screenshots/out/${L10n.code}/pdf.pdf').writeAsBytesSync(bytes);
        });
        await shot(tester, const SettingsScreen(), '08_settings');
        await shot(tester, const ProScreen(), '09_pro');
        debugDisableShadows = true;
      });
    });
  }
}
