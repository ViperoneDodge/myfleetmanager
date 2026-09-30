import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Inserimento / modifica di un intervento nello storico manutenzioni.
class MaintenanceEditScreen extends StatefulWidget {
  final String vehicleId;

  /// null = nuovo intervento.
  final MaintenanceRecord? record;
  const MaintenanceEditScreen({super.key, required this.vehicleId, this.record});

  @override
  State<MaintenanceEditScreen> createState() => _MaintenanceEditScreenState();
}

class _MaintenanceEditScreenState extends State<MaintenanceEditScreen> {
  late final MaintenanceRecord r =
      widget.record?.copy() ?? MaintenanceRecord(date: DateTime.now());
  late final TextEditingController _km = TextEditingController(text: r.km?.toString() ?? '');
  late final TextEditingController _notes = TextEditingController(text: r.notes);
  bool _asService = false;
  bool _saving = false;

  bool get _isNew => widget.record == null;

  @override
  void dispose() {
    _km.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool _hasService(Vehicle? v) =>
      v != null && v.deadlines.any((d) => d.kind == DeadlineKind.service && d.enabled);

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: r.date,
      firstDate: DateTime(1980),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (d != null) setState(() => r.date = d);
  }

  Future<void> _save() async {
    final kmText = _km.text.trim();
    r.km = kmText.isEmpty ? null : int.tryParse(kmText);
    r.notes = _notes.text.trim();
    if (r.items.isEmpty && r.notes.isEmpty) {
      showSnack(context, 'Seleziona almeno un intervento o scrivi una nota.');
      return;
    }
    setState(() => _saving = true);
    await appState.saveMaintenance(widget.vehicleId, r, asService: _asService);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare l\'intervento?'),
        content: Text('L\'intervento del ${fmtDate(r.date)} verrà tolto dallo storico.'),
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
    if (ok != true) return;
    await appState.deleteMaintenance(widget.vehicleId, r.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final v = appState.vehicleById(widget.vehicleId);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Nuova manutenzione' : 'Manutenzione'),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: 'Elimina',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: NotebookPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 12, 10, 32),
          children: [
            if (v != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  v.name.isEmpty ? v.plate : '${v.name}${v.plate.isEmpty ? '' : ' · ${v.plate}'}',
                  style: TextStyle(fontFamily: handFont, fontSize: 24, color: scheme.primary),
                ),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('Data'),
              trailing: Text(fmtDate(r.date), style: const TextStyle(fontSize: 16)),
              onTap: _pickDate,
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _km,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Chilometri',
                suffixText: 'km',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.speed),
              ),
            ),
            const SizedBox(height: 16),
            Text('Interventi eseguiti', style: Theme.of(context).textTheme.titleMedium),
            ...maintenanceItems.map((k) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(maintenanceItemLabel(k)),
                  value: r.items.contains(k),
                  onChanged: (b) => setState(() {
                    if (b == true) {
                      r.items.add(k);
                    } else {
                      r.items.remove(k);
                    }
                  }),
                )),
            const SizedBox(height: 8),
            TextField(
              controller: _notes,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (officina, costo, altri ricambi…)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            if (_hasService(v)) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Conta come tagliando'),
                subtitle: const Text(
                    'Aggiorna la data dell\'ultimo tagliando e il promemoria del prossimo'),
                value: _asService,
                onChanged: (b) => setState(() => _asService = b),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }
}
