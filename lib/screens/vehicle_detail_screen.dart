import 'package:flutter/material.dart';

import '../main.dart';
import '../models.dart';
import '../widgets/common.dart';
import 'vehicle_edit_screen.dart';

class VehicleDetailScreen extends StatelessWidget {
  final String vehicleId;
  const VehicleDetailScreen({super.key, required this.vehicleId});

  Future<void> _delete(BuildContext context, Vehicle v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare il veicolo?'),
        content: Text('"${v.name.isEmpty ? v.plate : v.name}" e tutte le sue scadenze '
            'verranno eliminati${appState.isCloud ? ' anche per gli altri membri della famiglia' : ''}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await appState.deleteVehicle(v.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final v = appState.vehicleById(vehicleId);
        if (v == null) {
          return Scaffold(
              appBar: AppBar(), body: const Center(child: Text('Veicolo non trovato.')));
        }
        final scheme = Theme.of(context).colorScheme;
        final bytes = v.photoBytes;
        final tracked = v.deadlines.where((d) => d.enabled).toList();
        return Scaffold(
          appBar: AppBar(
            title: Text(v.name.isEmpty ? 'Veicolo' : v.name),
            actions: [
              IconButton(
                tooltip: 'Elimina',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(context, v),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.edit),
            label: const Text('Modifica'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => VehicleEditScreen(vehicle: v.copy()))),
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: scheme.primaryContainer,
                  child: bytes != null
                      ? Image.memory(bytes, fit: BoxFit.cover)
                      : Icon(vehicleIcon(v.type),
                          size: 100, color: scheme.onPrimaryContainer),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(v.name.isEmpty ? 'Senza nome' : v.name,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: scheme.outline),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(v.plate.isEmpty ? '—' : v.plate,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    Icon(vehicleIcon(v.type)),
                    const SizedBox(width: 4),
                    Text(v.type == VehicleType.moto ? 'Moto' : 'Auto'),
                  ]),
                ]),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('Scadenze', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              if (tracked.isEmpty)
                const ListTile(title: Text('Nessuna scadenza monitorata.')),
              ...tracked.map((d) => _deadlineTile(context, d)),
              if (v.notes.trim().isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text('Note', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(v.notes),
                ),
              ],
              if (appState.isCloud && v.updatedBy.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Ultima modifica: ${v.updatedBy} · '
                    '${fmtDate(DateTime.fromMillisecondsSinceEpoch(v.updatedAt))}',
                    style: TextStyle(fontSize: 12, color: scheme.outline),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _deadlineTile(BuildContext context, Deadline d) {
    IconData icon;
    switch (d.kind) {
      case DeadlineKind.insurance:
        icon = Icons.shield_outlined;
        break;
      case DeadlineKind.inspection:
        icon = Icons.fact_check_outlined;
        break;
      case DeadlineKind.service:
        icon = Icons.build_outlined;
        break;
      case DeadlineKind.custom:
        icon = Icons.event_note_outlined;
        break;
    }
    String subtitle;
    if (d.kind == DeadlineKind.service) {
      subtitle = 'Ultimo: ${fmtDate(d.date)}';
      if (d.dueDate != null) {
        subtitle += ' · Prossimo: ${fmtDate(d.dueDate)} (ogni ${d.intervalMonths} mesi)';
      }
    } else {
      subtitle = d.date == null ? 'Data non impostata' : 'Scade il ${fmtDate(d.date)}';
    }
    return ListTile(
      leading: Icon(icon),
      title: Text(d.label),
      subtitle: Text(subtitle),
      trailing: d.dueDate != null ? StatusChip(due: d.dueDate!) : null,
    );
  }
}
