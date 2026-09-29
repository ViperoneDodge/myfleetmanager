import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart';
import '../models.dart';
import '../widgets/common.dart';

class VehicleEditScreen extends StatefulWidget {
  /// Riceve una COPIA del veicolo (o uno nuovo): le modifiche si salvano solo con "Salva".
  final Vehicle vehicle;
  const VehicleEditScreen({super.key, required this.vehicle});

  @override
  State<VehicleEditScreen> createState() => _VehicleEditScreenState();
}

class _VehicleEditScreenState extends State<VehicleEditScreen> {
  late final Vehicle v = widget.vehicle;
  late final TextEditingController _name = TextEditingController(text: v.name);
  late final TextEditingController _plate = TextEditingController(text: v.plate);
  late final TextEditingController _notes = TextEditingController(text: v.notes);
  final Map<String, TextEditingController> _labels = {};
  bool _saving = false;

  bool get _isNew => appState.vehicleById(v.id) == null;

  @override
  void dispose() {
    _name.dispose();
    _plate.dispose();
    _notes.dispose();
    for (final c in _labels.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _labelCtrl(Deadline d) =>
      _labels.putIfAbsent(d.id, () => TextEditingController(text: d.label));

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Scatta una foto'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Scegli dalla galleria'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          if (v.photoB64 != null)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Rimuovi foto'),
              onTap: () {
                setState(() => v.photoB64 = null);
                Navigator.pop(ctx);
              },
            ),
        ]),
      ),
    );
    if (source == null) return;
    try {
      final x = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      setState(() => v.photoB64 = base64Encode(bytes));
    } catch (e) {
      if (mounted) showSnack(context, 'Impossibile caricare la foto: $e');
    }
  }

  Future<void> _pickDate(Deadline d) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: d.date ?? now,
      firstDate: DateTime(1980),
      lastDate: DateTime(now.year + 20),
      helpText: d.kind == DeadlineKind.service
          ? 'Data ultimo tagliando'
          : 'Data scadenza: ${d.label}',
    );
    if (picked != null) {
      setState(() {
        d.date = picked;
        d.enabled = true;
      });
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty && _plate.text.trim().isEmpty) {
      showSnack(context, 'Inserisci almeno il nome o la targa.');
      return;
    }
    setState(() => _saving = true);
    v.name = _name.text.trim();
    v.plate = _plate.text.trim().toUpperCase();
    v.notes = _notes.text.trim();
    for (final d in v.deadlines.where((d) => d.kind == DeadlineKind.custom)) {
      final t = _labelCtrl(d).text.trim();
      d.label = t.isEmpty ? 'Scadenza personalizzata' : t;
    }
    await appState.saveVehicle(v);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bytes = v.photoBytes;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Nuovo veicolo' : 'Modifica veicolo'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Salva'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<VehicleType>(
            segments: const [
              ButtonSegment(
                  value: VehicleType.auto, icon: Icon(Icons.directions_car), label: Text('Auto')),
              ButtonSegment(
                  value: VehicleType.moto, icon: Icon(Icons.two_wheeler), label: Text('Moto')),
            ],
            selected: {v.type},
            onSelectionChanged: (s) => setState(() => v.type = s.first),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 220,
                    height: 140,
                    color: scheme.primaryContainer,
                    child: bytes != null
                        ? Image.memory(bytes, fit: BoxFit.cover)
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.add_a_photo, size: 40, color: scheme.onPrimaryContainer),
                            const SizedBox(height: 6),
                            Text('Aggiungi foto',
                                style: TextStyle(color: scheme.onPrimaryContainer)),
                          ]),
                  ),
                ),
                if (bytes != null)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: scheme.surface,
                      child: const Icon(Icons.edit, size: 18),
                    ),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nome (es. Panda di Marco)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.label_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _plate,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Targa',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.pin_outlined),
            ),
          ),
          const SizedBox(height: 24),
          Text('Scadenze da monitorare', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Attiva solo quelle che ti interessano. Riceverai le notifiche secondo le impostazioni.',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          ...v.deadlines.map(_deadlineCard),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => setState(() => v.deadlines.add(Deadline(
                  kind: DeadlineKind.custom,
                  label: '',
                ))),
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi scadenza personalizzata'),
          ),
          const SizedBox(height: 4),
          Text('Es. bollo, gomme invernali, garanzia, cambio cinghia…',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note (facoltative)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
            label: const Text('Salva'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _deadlineCard(Deadline d) {
    final isCustom = d.kind == DeadlineKind.custom;
    final isService = d.kind == DeadlineKind.service;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: isCustom
                  ? TextField(
                      controller: _labelCtrl(d),
                      decoration: const InputDecoration(
                        hintText: 'Nome scadenza (es. Bollo)',
                        isDense: true,
                      ),
                    )
                  : Text(isService ? 'Ultimo tagliando' : d.label,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
            if (isCustom)
              IconButton(
                tooltip: 'Elimina',
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  v.deadlines.remove(d);
                  _labels.remove(d.id)?.dispose();
                }),
              ),
            Switch(
              value: d.enabled,
              onChanged: (b) => setState(() => d.enabled = b),
            ),
          ]),
          if (d.enabled) ...[
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              OutlinedButton.icon(
                onPressed: () => _pickDate(d),
                icon: const Icon(Icons.calendar_month, size: 18),
                label: Text(d.date == null ? 'Scegli data' : fmtDate(d.date)),
              ),
              if (d.date != null && !isService) StatusChip(due: d.date!),
            ]),
            if (isService) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Text('Promemoria prossimo: '),
                DropdownButton<int>(
                  value: const [0, 6, 12, 24].contains(d.intervalMonths) ? d.intervalMonths : 12,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('nessuno')),
                    DropdownMenuItem(value: 6, child: Text('dopo 6 mesi')),
                    DropdownMenuItem(value: 12, child: Text('dopo 12 mesi')),
                    DropdownMenuItem(value: 24, child: Text('dopo 24 mesi')),
                  ],
                  onChanged: (m) => setState(() => d.intervalMonths = m ?? 12),
                ),
              ]),
              if (d.dueDate != null)
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text('Prossimo tagliando: ${fmtDate(d.dueDate)}  ',
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                  StatusChip(due: d.dueDate!, compact: true),
                ]),
            ],
          ],
        ]),
      ),
    );
  }
}
