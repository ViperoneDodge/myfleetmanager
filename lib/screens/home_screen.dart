import 'package:flutter/material.dart';

import '../main.dart';
import '../models.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';
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

  void _openAdd() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => VehicleEditScreen(vehicle: Vehicle(type: _filter ?? VehicleType.auto)),
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
        final title = appState.isCloud
            ? (appState.data.fleetName ?? 'Il mio parco auto')
            : 'I miei veicoli';
        return Scaffold(
          appBar: AppBar(
            title: Text(title, overflow: TextOverflow.ellipsis),
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
          body: _tab == 0 ? _vehiclesTab() : _deadlinesTab(),
          floatingActionButton: _tab == 0
              ? FloatingActionButton.extended(
                  onPressed: _openAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Aggiungi'),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.garage_outlined), selectedIcon: Icon(Icons.garage), label: 'Veicoli'),
              NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'Scadenze'),
            ],
          ),
        );
      },
    );
  }

  Widget _vehiclesTab() {
    final all = appState.vehicles;
    final list = _filter == null ? all : all.where((v) => v.type == _filter).toList();
    return RefreshIndicator(
      onRefresh: appState.retrySync,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
        children: [
          Wrap(spacing: 8, children: [
            ChoiceChip(
              label: Text('Tutti (${all.length})'),
              selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null),
            ),
            ChoiceChip(
              avatar: const Icon(Icons.directions_car, size: 18),
              label: Text('Auto (${all.where((v) => v.type == VehicleType.auto).length})'),
              selected: _filter == VehicleType.auto,
              onSelected: (_) => setState(() => _filter = VehicleType.auto),
            ),
            ChoiceChip(
              avatar: const Icon(Icons.two_wheeler, size: 18),
              label: Text('Moto (${all.where((v) => v.type == VehicleType.moto).length})'),
              selected: _filter == VehicleType.moto,
              onSelected: (_) => setState(() => _filter = VehicleType.moto),
            ),
          ]),
          const SizedBox(height: 8),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Column(children: [
                Icon(Icons.garage_outlined,
                    size: 80, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 12),
                const Text('Nessun veicolo', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 4),
                const Text('Tocca "Aggiungi" per inserire la prima auto o moto.'),
              ]),
            ),
          ...list.map(_vehicleCard),
        ],
      ),
    );
  }

  Widget _vehicleCard(Vehicle v) {
    final next = v.nextDeadline;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetail(v),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            VehicleAvatar(vehicle: v, size: 64),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(v.name.isEmpty ? 'Senza nome' : v.name,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(vehicleIcon(v.type), size: 16),
                  const SizedBox(width: 4),
                  Text(v.plate.isEmpty ? '—' : v.plate,
                      style: const TextStyle(letterSpacing: 1.2)),
                ]),
                const SizedBox(height: 6),
                if (next != null)
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Text('${next.dueLabel}:', style: const TextStyle(fontSize: 12)),
                      StatusChip(due: next.dueDate!, compact: true),
                    ],
                  )
                else
                  Text('Nessuna scadenza impostata',
                      style: TextStyle(
                          fontSize: 12, color: Theme.of(context).colorScheme.outline)),
              ]),
            ),
            const Icon(Icons.chevron_right),
          ]),
        ),
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
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final it = items[i];
        return ListTile(
          leading: VehicleAvatar(vehicle: it.v, size: 44),
          title: Text(it.d.dueLabel),
          subtitle: Text(
              '${it.v.name.isEmpty ? it.v.plate : it.v.name} · ${fmtDate(it.d.dueDate)}'),
          trailing: StatusChip(due: it.d.dueDate!, compact: true),
          onTap: () => _openDetail(it.v),
        );
      },
    );
  }
}
