import 'dart:ui' show DisplayFeatureType;

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../main.dart';
import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'family_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';
import 'vehicle_detail_screen.dart';
import 'vehicle_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  VehicleType? _filter;

  /// Veicolo aperto nel pannello destro (schermi larghi / pieghevoli aperti).
  String? _selectedId;
  bool _twoPane = false;

  Future<void> _openAdd({String? fleetId}) async {
    if (!await ensureCanAddVehicle(context)) return;
    if (!mounted) return;
    var type = _filter ?? VehicleType.auto;
    if (AppState.isProType(type) && !appState.isPro) type = VehicleType.auto;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => VehicleEditScreen(vehicle: Vehicle(type: type, fleetId: fleetId)),
    ));
  }

  void _openDetail(Vehicle v) {
    if (_twoPane) {
      setState(() => _selectedId = v.id);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => VehicleDetailScreen(vehicleId: v.id),
    ));
  }

  /// Cerniera/piega verticale del pieghevole (libro aperto), se presente.
  static Rect? _verticalHinge(MediaQueryData mq) {
    for (final f in mq.displayFeatures) {
      if (f.type == DisplayFeatureType.cutout) continue;
      final b = f.bounds;
      if (b.height >= b.width && b.left > 120 && b.right < mq.size.width - 120) return b;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final hinge = _verticalHinge(mq);
    final width = mq.size.width;
    _twoPane = hinge != null || width >= 840;
    if (!_twoPane) return _mainScaffold(context);

    // Due pannelli: elenco a sinistra, dettaglio a destra (mai sopra la cerniera).
    final leftWidth = hinge != null ? hinge.left : (width * 0.42).clamp(340.0, 480.0).toDouble();
    final gap = hinge != null ? hinge.width : 0.0;
    final selected = _selectedId == null ? null : appState.vehicleById(_selectedId!);
    return Row(children: [
      SizedBox(width: leftWidth, child: _mainScaffold(context)),
      if (gap > 0) SizedBox(width: gap, child: ColoredBox(color: NotebookColors.of(context).cover)),
      Expanded(
        child: selected == null
            ? _emptyDetail(context)
            : VehicleDetailScreen(
                key: ValueKey(selected.id),
                vehicleId: selected.id,
                embedded: true,
                onClosed: () => setState(() => _selectedId = null),
              ),
      ),
    ]);
  }

  Widget _emptyDetail(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: NotebookPage(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.touch_app_outlined, size: 64, color: scheme.outline),
            const SizedBox(height: 12),
            Text(tr('home.selectVehicle'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: handFont, fontSize: 24)),
          ]),
        ),
      ),
    );
  }

  Widget _syncIcon() {
    if (!appState.isCloud) return const SizedBox.shrink();
    switch (appState.syncStatus) {
      case SyncStatus.online:
        return Tooltip(message: tr('sync.done'), child: const Icon(Icons.cloud_done));
      case SyncStatus.connecting:
        return Tooltip(message: tr('sync.connecting'), child: const Icon(Icons.cloud_sync));
      case SyncStatus.offline:
        return IconButton(
          tooltip: tr('sync.offline'),
          icon: const Icon(Icons.cloud_off),
          onPressed: appState.retrySync,
        );
      case SyncStatus.off:
        return const SizedBox.shrink();
    }
  }

  Widget _mainScaffold(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final titles = [tr('tab.vehicles'), tr('tab.family'), tr('tab.deadlines')];
        Widget body;
        switch (_tab) {
          case 1:
            body = FamilyTab(onOpen: _openDetail, onAdd: (g) => _openAdd(fleetId: g));
            break;
          case 2:
            body = _deadlinesTab();
            break;
          default:
            body = _vehiclesTab();
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(titles[_tab]),
            actions: [
              _syncIcon(),
              IconButton(
                tooltip: tr('settings.title'),
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
            ],
          ),
          body: NotebookPage(child: body),
          floatingActionButton: _tab == 0
              ? FloatingActionButton.extended(
                  onPressed: () => _openAdd(),
                  icon: const Icon(Icons.add),
                  label: Text(tr('common.add')),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: [
              NavigationDestination(
                  icon: const Icon(Icons.garage_outlined),
                  selectedIcon: const Icon(Icons.garage),
                  label: tr('tab.vehicles')),
              NavigationDestination(
                  icon: const Icon(Icons.groups_outlined),
                  selectedIcon: const Icon(Icons.groups),
                  label: tr('tab.family')),
              NavigationDestination(
                  icon: const Icon(Icons.event_outlined),
                  selectedIcon: const Icon(Icons.event),
                  label: tr('tab.deadlines')),
            ],
          ),
        );
      },
    );
  }

  Widget _vehiclesTab() {
    // Elenco principale: i propri veicoli E quelli condivisi nei gruppi.
    final all = appState.vehicles;
    final list = _filter == null ? all : all.where((v) => v.type == _filter).toList();
    // Versione gratuita: oltre i primi 3 tra auto e moto le schede sono in grigio.
    final limited = appState.limitedIds;
    return RefreshIndicator(
      onRefresh: appState.retrySync,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 96),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(tr('filter.all', {'n': all.length})),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
              ),
              ...VehicleType.values.map((t) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      avatar: Icon(vehicleIcon(t), size: 18),
                      label: Text(
                          '${vehicleTypePlural(t)} (${all.where((v) => v.type == t).length})'),
                      selected: _filter == t,
                      onSelected: (_) => setState(() => _filter = t),
                    ),
                  )),
            ]),
          ),
          const SizedBox(height: 8),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Column(children: [
                Icon(Icons.garage_outlined,
                    size: 80, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 12),
                Text(tr('home.empty'),
                    style: const TextStyle(fontSize: 26, fontFamily: handFont)),
                const SizedBox(height: 4),
                Text(tr('home.emptyHint'), textAlign: TextAlign.center),
              ]),
            ),
          ...list.map((v) => VehicleCard(
                vehicle: v,
                badge: appState.isPersonal(v) ? null : appState.fleetLabel(v),
                selected: _twoPane && v.id == _selectedId,
                limited: limited.contains(v.id),
                onTap: () => limited.contains(v.id)
                    ? requirePro(context,
                        reason: tr('pro.reasonLimited', {'n': AppState.freeVehicleLimit}))
                    : _openDetail(v),
                onLongPress: () => moveVehicleSheet(context, v),
              )),
          if (list.isNotEmpty && appState.isCloud && appState.data.groups.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                tr('home.longPressHint'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
              ),
            ),
        ],
      ),
    );
  }

  Widget _deadlinesTab() {
    final items = <({Vehicle v, Deadline d})>[];
    // Solo i veicoli attivi: quelli in grigio non mostrano le scadenze.
    for (final v in appState.activeVehicles) {
      for (final d in v.activeDeadlines) {
        items.add((v: v, d: d));
      }
    }
    items.sort((a, b) => a.d.dueDate!.compareTo(b.d.dueDate!));
    if (items.isEmpty) {
      return Center(child: Text(tr('deadlines.empty')));
    }
    final showFleet = appState.isCloud && appState.data.groups.isNotEmpty;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final it = items[i];
        final name = it.v.name.isEmpty ? it.v.plate : it.v.name;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          leading: VehicleAvatar(vehicle: it.v, size: 44),
          title: Text(it.d.dueLabel,
              style: const TextStyle(fontFamily: handFont, fontSize: 20)),
          subtitle: Text(
              '$name · ${fmtDate(it.d.dueDate)}${showFleet ? '\n${appState.fleetLabel(it.v)}' : ''}'),
          trailing: StatusChip(due: it.d.dueDate!, compact: true),
          onTap: () => _openDetail(it.v),
        );
      },
    );
  }
}
