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
        final titles = [tr('fleet.mine'), tr('tab.family'), tr('tab.deadlines')];
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
    final all = appState.vehicles.where(appState.isPersonal).toList();
    final list = _filter == null ? all : all.where((v) => v.type == _filter).toList();
    final hasGroupVehicles = appState.vehicles.any((v) => !appState.isPersonal(v));
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
                if (all.isEmpty && hasGroupVehicles) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.groups_outlined),
                    label: Text(tr('home.groupsHint')),
                    onPressed: () => setState(() => _tab = 1),
                  ),
                ],
              ]),
            ),
          ...list.map((v) => VehicleCard(
                vehicle: v,
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
    final groups = <({Vehicle v, List<Deadline> ds})>[];
    for (final v in appState.activeVehicles) {
      final ds = v.activeDeadlines.toList()..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
      if (ds.isNotEmpty) groups.add((v: v, ds: ds));
    }
    groups.sort((a, b) => a.ds.first.dueDate!.compareTo(b.ds.first.dueDate!));
    if (groups.isEmpty) {
      return Center(child: Text(tr('deadlines.empty')));
    }
    final showFleet = appState.isCloud && appState.data.groups.isNotEmpty;
    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(6, 8, 10, 24),
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final g = groups[i];
        final name = g.v.name.isEmpty ? g.v.plate : g.v.name;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            InkWell(
              onTap: () => _openDetail(g.v),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Row(children: [
                  VehicleAvatar(vehicle: g.v, size: 44),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: handFont, fontSize: 22)),
                      if (showFleet)
                        Text(appState.fleetLabel(g.v),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    ]),
                  ),
                ]),
              ),
            ),
            const Divider(height: 1),
            for (var k = 0; k < g.ds.length; k++) ...[
              if (k > 0) Divider(height: 1, indent: 12, endIndent: 12, color: scheme.outlineVariant),
              InkWell(
                onTap: () => _openDetail(g.v),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(g.ds[k].dueLabel,
                              maxLines: 1,
                              softWrap: false,
                              style: const TextStyle(fontFamily: handFont, fontSize: 19)),
                        ),
                        Text(fmtDate(g.ds[k].dueDate),
                            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(due: g.ds[k].dueDate!, compact: true, twoLines: true),
                  ]),
                ),
              ),
            ],
          ]),
        );
      },
    );
  }
}
