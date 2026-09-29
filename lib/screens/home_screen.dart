import 'package:flutter/material.dart';

import '../main.dart';
import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'family_screen.dart';
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

  void _openAdd({String? fleetId}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => VehicleEditScreen(
        vehicle: Vehicle(type: _filter ?? VehicleType.auto, fleetId: fleetId),
      ),
    ));
  }

  void _openDetail(Vehicle v) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => VehicleDetailScreen(vehicleId: v.id),
    ));
  }

  Widget _syncIcon() {
    if (!appState.isCloud) return const SizedBox.shrink();
    switch (appState.syncStatus) {
      case SyncStatus.online:
        return const Tooltip(message: 'Sincronizzato', child: Icon(Icons.cloud_done));
      case SyncStatus.connecting:
        return const Tooltip(message: 'Connessione…', child: Icon(Icons.cloud_sync));
      case SyncStatus.offline:
        return IconButton(
          tooltip: 'Offline: i dati sono salvati sul telefono. Tocca per riprovare.',
          icon: const Icon(Icons.cloud_off),
          onPressed: appState.retrySync,
        );
      case SyncStatus.off:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        const titles = ['I miei veicoli', 'Famiglia', 'Scadenze'];
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
                tooltip: 'Impostazioni',
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
                  label: const Text('Aggiungi'),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.garage_outlined),
                  selectedIcon: Icon(Icons.garage),
                  label: 'I miei'),
              NavigationDestination(
                  icon: Icon(Icons.family_restroom_outlined),
                  selectedIcon: Icon(Icons.family_restroom),
                  label: 'Famiglia'),
              NavigationDestination(
                  icon: Icon(Icons.event_outlined),
                  selectedIcon: Icon(Icons.event),
                  label: 'Scadenze'),
            ],
          ),
        );
      },
    );
  }

  Widget _vehiclesTab() {
    final all = appState.myVehicles;
    final list = _filter == null ? all : all.where((v) => v.type == _filter).toList();
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
                  label: Text('Tutti (${all.length})'),
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
                const Text('Nessun veicolo',
                    style: TextStyle(fontSize: 26, fontFamily: handFont)),
                const SizedBox(height: 4),
                const Text('Tocca "Aggiungi" per inserire il primo veicolo.',
                    textAlign: TextAlign.center),
              ]),
            ),
          ...list.map((v) => VehicleCard(vehicle: v, onTap: () => _openDetail(v))),
        ],
      ),
    );
  }

  Widget _deadlinesTab() {
    final items = <({Vehicle v, Deadline d})>[];
    for (final v in appState.vehicles) {
      for (final d in v.activeDeadlines) {
        items.add((v: v, d: d));
      }
    }
    items.sort((a, b) => a.d.dueDate!.compareTo(b.d.dueDate!));
    if (items.isEmpty) {
      return const Center(child: Text('Nessuna scadenza impostata.'));
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
