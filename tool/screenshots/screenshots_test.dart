import 'dart:async';
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
import 'package:myfleetmanager/screens/maintenance_screen.dart';
import 'package:myfleetmanager/screens/notifications_screen.dart';
import 'package:myfleetmanager/screens/pro_screen.dart';
import 'package:myfleetmanager/screens/settings_screen.dart';
import 'package:myfleetmanager/screens/vehicle_detail_screen.dart';
import 'package:myfleetmanager/screens/vehicle_edit_screen.dart';
import 'package:myfleetmanager/services/app_state.dart';
import 'package:myfleetmanager/services/notification_log.dart';
import 'package:myfleetmanager/services/pdf_export.dart';
import 'package:myfleetmanager/theme.dart';
import 'package:myfleetmanager/widgets/common.dart';

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
    final r = MaintenanceRecord(
        date: DateTime(2025 - i, 3 + i, 12), km: 85000 - i * 15000, items: {'oil', 'oilFilter', if (i.isEven) 'airFilter'}, notes: i == 0 ? 'Officina Bianchi' : '');
    if (i < 3) {
      r.part('oil')
        ..code = '5W-30 · 4,5 L'
        ..cents = 5800;
      r.part('oilFilter')
        ..code = 'Mann HU 7008 z'
        ..cents = 1450;
      if (i.isEven) {
        r.part('airFilter')
          ..code = 'Mann C 27 009'
          ..cents = 2290;
      }
      if (i == 0) r.parts.add(MaintPart(name: 'Spazzole tergicristallo', code: 'Bosch A 863 S', cents: 3100));
      r.labor = 6000 - i * 1000;
    }
    x.maintenance.add(r);
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
  final giulia = v('g1', 'Giulia', 'GD452RT', VehicleType.auto, DateTime(2019, 3, 14), [269, 298, 9, 40], maint: 4)
    ..vin = 'ZAR952000H1234567'
    ..tyres = '205/55 R16 91V'
    ..powerKw = '96'
    ..engineCc = '1598'
    ..fuel = 'diesel'
    ..oil = '5W-30 ACEA C3'
    ..battery = '12V 70Ah 680A AGM'
    ..plugs = 'Bosch 0 250 202 142'
    ..filters = 'Mann HU 7008 z\nMann C 27 009\nMann CUK 2939';
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
        setMoneyLocale(lang == 'it' ? 'it_IT' : 'en_IE');
        setupData();
      });
      testWidgets('screens', (tester) async {
        await tester.runAsync(loadFonts);
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 2.625;
        addTearDown(tester.view.reset);
        debugDisableShadows = false;

        await shot(tester, const HomeScreen(), '01_vehicles');
        appState.sync.problems['groups'] = TimeoutException('groups');
        appState.sync.problems['save:FAM7Q2K9XW'] = TimeoutException('save');
        await shot(tester, const HomeScreen(), '01b_sync_problem', then: () async {
          await tester.tap(find.text('!!'));
        });
        appState.sync.problems.clear();
        final now = DateTime.now();
        int at(int daysAgo, int h, int m) => DateTime(now.year, now.month, now.day - daysAgo, h, m).millisecondsSinceEpoch;
        final it = L10n.code == 'it';
        appState.log = NotificationLog(entries: [
          LogEntry(ts: at(0, 8, 42), kind: LogKind.edited, groupId: 'FAM7Q2K9XW', group: it ? 'Famiglia' : 'Family', vehicleId: 'g1', vehicle: 'Giulia', who: 'Marco', parts: ['deadlines', 'maintenance']),
          LogEntry(ts: at(0, 8, 5), kind: LogKind.added, groupId: 'FAM7Q2K9XW', group: it ? 'Famiglia' : 'Family', vehicleId: 'g3', vehicle: 'Vespa GTS', who: 'Giulia'),
          LogEntry(ts: at(0, 7, 20), kind: LogKind.edited, groupId: 'FAM7Q2K9XW', group: it ? 'Famiglia' : 'Family', vehicleId: 'g2', vehicle: 'Panda', who: 'Giulia', parts: ['documents'], read: true),
          LogEntry(ts: at(1, 21, 10), kind: LogKind.deleted, groupId: 'FAM7Q2K9XW', group: it ? 'Famiglia' : 'Family', vehicleId: 'x', vehicle: 'Punto', who: 'Marco', read: true),
          LogEntry(ts: at(1, 9, 0), kind: LogKind.reminder, title: it ? 'Revisione tra 7 giorni' : 'Inspection in 7 days', body: 'Giulia (GD452RT)', vehicleId: 'g1', read: true),
        ]);
        await shot(tester, const HomeScreen(), '11_bell');
        await shot(tester, const NotificationsScreen(), '11b_notifications');
        await shot(tester, const NotificationsScreen(), '11c_select', then: () async {
          await tester.longPress(find.textContaining('Marco').first);
          await tester.pumpAndSettle();
          await tester.tap(find.textContaining('Vespa GTS').first);
        });
        final gv = appState.vehicleById('g1')!;
        appState.log = NotificationLog(entries: [
          LogEntry(ts: at(0, 8, 42), kind: LogKind.edited, groupId: 'FAM7Q2K9XW', group: it ? 'Famiglia' : 'Family', vehicleId: 'g1', vehicle: 'Giulia', who: 'Marco', parts: ['tech', 'deadlines', 'maintenance'], items: {
            'deadline:${gv.deadlines.first.id}': 'edited',
            'maint:${gv.maintenanceSorted.first.id}': 'new',
            'tech:oil': 'edited',
          }),
        ]);
        await shot(tester, const NotificationsScreen(), '12d_from_bell', then: () async {
          await tester.tap(find.textContaining('Marco').first);
          await tester.pumpAndSettle();
          await tester.pump(const Duration(milliseconds: 600));
        });
        detailTab.value = 0;
        await shot(tester, const VehicleDetailScreen(vehicleId: 'g1'), '12_changes', then: () async {
          await tester.drag(find.byType(Scrollable).first, const Offset(0, -560));
        });
        detailTab.value = 1;
        await shot(tester, const VehicleDetailScreen(vehicleId: 'g1'), '12b_changes_tech');
        detailTab.value = 2;
        await shot(tester, const VehicleDetailScreen(vehicleId: 'g1'), '12c_changes_maint');
        detailTab.value = 0;
        appState.log = NotificationLog();
        await shot(tester, const VehicleDetailScreen(vehicleId: 'g1'), '02_vehicle');
        detailTab.value = 1;
        await shot(tester, const VehicleDetailScreen(vehicleId: 'g1'), '02b_tech');
        detailTab.value = 2;
        await shot(tester, const VehicleDetailScreen(vehicleId: 'g1'), '02c_maint');
        await shot(tester, MaintenanceEditScreen(vehicleId: 'g1', record: appState.vehicleById('g1')!.maintenanceSorted.first),
            '02d_maint_edit');
        await shot(tester, MaintenanceEditScreen(vehicleId: 'g1', record: appState.vehicleById('g1')!.maintenanceSorted.first),
            '02e_maint_part', then: () async {
          await tester.tap(find.text(tr('maint.oil')));
        });
        detailTab.value = 0;
        await shot(tester, const HomeScreen(), '03_deadlines', then: () async {
          await tester.tap(find.text(tr('tab.deadlines')).last);
        });
        await shot(tester, const HomeScreen(), '04_groups', then: () async {
          await tester.tap(find.text(tr('tab.family')).last);
        });
        await shot(tester, const HomeScreen(), '04b_groups_pdf', then: () async {
          await tester.tap(find.text(tr('tab.family')).last);
          await tester.pumpAndSettle();
          await tester.tap(find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.picture_as_pdf_outlined)));
        });
        await shot(tester, const GroupScreen(groupId: 'FAM7Q2K9XW'), '05_roles');
        await shot(tester, VehicleEditScreen(vehicle: appState.vehicleById('g1')!.copy()), '06_edit', then: () async {
          await tester.drag(find.byType(ListView).first, const Offset(0, -520));
        });
        await shot(tester, VehicleEditScreen(vehicle: appState.vehicleById('g1')!.copy()), '06b_power', then: () async {
          await tester.scrollUntilVisible(find.text('${tr('tech.powerName')} (kW / ${tr('unit.cv')})'), 300,
              scrollable: find.byType(Scrollable).first);
          await Scrollable.ensureVisible(tester.element(find.text('${tr('tech.powerName')} (kW / ${tr('unit.cv')})')), alignment: 0.25);
        });
        await shot(tester, VehicleEditScreen(vehicle: appState.vehicleById('g3')!.copy()..tyres = ''), '06c_moto_tyres', then: () async {
          await tester.scrollUntilVisible(find.text(tr('tyre.rearOne')), 300, scrollable: find.byType(Scrollable).first);
          await Scrollable.ensureVisible(tester.element(find.text(tr('tyre.frontOne'))), alignment: 0.3);
        });
        await shot(tester, const VehicleDetailScreen(vehicleId: 'g1'), '07_ocr', then: () async {
          final ctx = tester.element(find.byType(VehicleDetailScreen));
          final rows = [
            (tr('edit.plate'), 'GD452RT'),
            (tr('vehicle.regDate'), '14/03/2019'),
            (tr('tech.vin'), 'ZAR952000H1234567'),
            (tr('tech.tyres'), '205/55 R16 91V'),
            (tr('tech.power'), '96'),
            (tr('tech.engine'), '1598'),
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
        await shot(tester, const SettingsScreen(), '08b_units', then: () async {
          await tester.scrollUntilVisible(find.text(tr('units.title')), 300,
              scrollable: find.byType(Scrollable).first);
          await Scrollable.ensureVisible(tester.element(find.text(tr('units.title'))), alignment: 0.15);
        });
        await shot(tester, const ProScreen(), '09_pro');
        debugDisableShadows = true;
      });
    });
  }
}
