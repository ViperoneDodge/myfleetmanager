import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n.dart';
import 'photo_crop_screen.dart';
import '../main.dart';
import '../services/app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'pro_screen.dart';

class VehicleEditScreen extends StatefulWidget {
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
  late final TextEditingController _vin = TextEditingController(text: v.vin);
  late final TextEditingController _tyres = TextEditingController(text: v.tyres);
  late final TextEditingController _power = TextEditingController(text: v.powerKw);
  late final TextEditingController _cc = TextEditingController(text: v.engineCc);
  final Map<String, TextEditingController> _labels = {};
  bool _saving = false;
  late bool _regMissing = !_isNew && v.registrationDate == null;

  bool get _isNew => appState.vehicleById(v.id) == null;

  late final VehicleType _originalType = v.type;

  Future<void> _selectType(VehicleType t) async {
    if (AppState.isProType(t) && t != _originalType && !appState.isPro) {
      final ok = await requirePro(context,
          reason: tr('pro.reasonType', {'type': vehicleTypeLabel(t)}));
      if (!ok || !mounted) return;
    }
    setState(() {
      v.type = t;
      if (_isNew) {
        for (final d in v.deadlines) {
          if (d.kind == DeadlineKind.service) {
            d.enabled = t != VehicleType.rimorchio;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _plate.dispose();
    _notes.dispose();
    _vin.dispose();
    _tyres.dispose();
    _power.dispose();
    _cc.dispose();
    for (final c in _labels.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _labelCtrl(Deadline d) =>
      _labels.putIfAbsent(d.id, () => TextEditingController(text: d.label));

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<Object?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: Text(tr('photo.camera')),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: Text(tr('photo.gallery')),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          if (v.photoBytes != null)
            ListTile(
              leading: const Icon(Icons.crop),
              title: Text(tr('crop.adjust')),
              onTap: () => Navigator.pop(ctx, 'adjust'),
            ),
          if (v.photoB64 != null)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(tr('photo.remove')),
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
      Uint8List? bytes;
      if (source == 'adjust') {
        bytes = v.photoBytes;
      } else if (source is ImageSource) {
        final x = await ImagePicker().pickImage(
          source: source,
          maxWidth: 2048,
          maxHeight: 2048,
          imageQuality: 90,
        );
        if (x == null) return;
        bytes = await x.readAsBytes();
      }
      if (bytes == null || !mounted) return;
      final cropped = await cropPhoto(context, bytes, aspect: 25 / 16, maxSide: 1024, quality: 75);
      if (cropped == null || !mounted) return;
      setState(() => v.photoB64 = base64Encode(cropped));
    } catch (e) {
      if (mounted) showSnack(context, tr('photo.error', {'error': e}));
    }
  }

  Future<void> _pickDate(Deadline d) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isService = d.kind == DeadlineKind.service;
    final last = isService ? today : DateTime(now.year + 20);
    var initial = d.date ?? today;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1980),
      lastDate: last,
      helpText: d.kind == DeadlineKind.service
          ? tr('edit.lastServiceDate')
          : tr('edit.deadlineDate', {'what': d.displayLabel}),
    );
    if (picked != null) {
      setState(() {
        d.date = picked;
        d.enabled = true;
      });
    }
  }

  Future<void> _pickRegistration() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var initial = v.registrationDate ?? today;
    if (initial.isAfter(today)) initial = today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: today,
      initialDatePickerMode: v.registrationDate == null ? DatePickerMode.year : DatePickerMode.day,
      helpText: tr('vehicle.regDate'),
    );
    if (picked != null) {
      setState(() {
        v.registrationDate = picked;
        _regMissing = false;
      });
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty && _plate.text.trim().isEmpty) {
      showSnack(context, tr('edit.needNameOrPlate'));
      return;
    }
    if (v.registrationDate == null) {
      setState(() => _regMissing = true);
      showSnack(context, tr('edit.regDateNeeded'));
      _pickRegistration();
      return;
    }
    if (_isNew && !await ensureCanAddVehicle(context)) return;
    if (!mounted) return;
    if (_isNew && AppState.isProType(v.type) && !appState.isPro) {
      final ok = await requirePro(context,
          reason: tr('pro.reasonType', {'type': vehicleTypeLabel(v.type)}));
      if (!ok || !mounted) return;
    }
    v.plate = _plate.text.trim().toUpperCase();
    final dup = appState.duplicatePlateGroup(v, v.fleetId);
    if (dup != null) {
      showSnack(context, tr('vehicle.plateDuplicate', {'plate': v.plate, 'group': dup}));
      return;
    }
    if (!appState.canAddTo(v.fleetId)) {
      showSnack(context, tr('role.readOnly'));
      return;
    }
    setState(() => _saving = true);
    v.name = _name.text.trim();
    v.notes = _notes.text.trim();
    v.vin = _vin.text.trim().toUpperCase();
    v.tyres = _tyres.text.trim();
    v.powerKw = _power.text.trim();
    v.engineCc = _cc.text.trim();
    for (final d in v.deadlines.where((d) => d.kind == DeadlineKind.custom)) {
      final t = _labelCtrl(d).text.trim();
      d.label = t.isEmpty ? tr('edit.customDefault') : t;
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
        title: Text(_isNew ? tr('edit.newTitle') : tr('edit.editTitle')),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: Text(tr('common.save'), style: const TextStyle(fontFamily: handFont, fontSize: 22)),
          ),
        ],
      ),
      body: NotebookPage(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(10, 14, 12, 16),
        children: [
          Text(tr('edit.type'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: VehicleType.values
                .map((t) => ChoiceChip(
                      avatar: Icon(
                          AppState.isProType(t) && !appState.isPro && t != _originalType
                              ? Icons.lock_outline
                              : vehicleIcon(t),
                          size: 18),
                      label: Text(vehicleTypeLabel(t)),
                      selected: v.type == t,
                      onSelected: (_) => _selectType(t),
                    ))
                .toList(),
          ),
          if (appState.isCloud && appState.data.groups.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(tr('edit.where'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            DropdownButtonFormField<String?>(
              initialValue: appState.data.groupById(v.fleetId) == null ? null : v.fleetId,
              decoration: const InputDecoration(
                filled: true,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder_shared_outlined),
              ),
              items: [
                DropdownMenuItem<String?>(value: null, child: Text(tr('fleet.mine'))),
                ...appState.data.groups
                    .where((g) => g.id == v.fleetId || appState.canAddTo(g.id))
                    .map((g) => DropdownMenuItem<String?>(
                      value: g.id,
                      child: Text(tr('edit.familyPrefix', {'name': g.name}), overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (id) => setState(() => v.fleetId = id),
            ),
          ],
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
                            Text(tr('photo.add'),
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
            decoration: InputDecoration(
              labelText: tr('edit.nameHint'),
              filled: true,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.label_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _plate,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: tr('edit.plate'),
              filled: true,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.pin_outlined),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickRegistration,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              isEmpty: v.registrationDate == null,
              decoration: InputDecoration(
                labelText: '${tr('vehicle.regDate')} *',
                filled: true,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.event_note_outlined),
                suffixIcon: const Icon(Icons.calendar_month),
                errorText: _regMissing ? tr('edit.regDateNeeded') : null,
              ),
              child: Text(v.registrationDate == null ? '' : fmtDate(v.registrationDate)),
            ),
          ),
          const SizedBox(height: 24),
          Text(tr('tech.title'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _techField(_vin, tr('tech.vin'), Icons.qr_code_2, caps: true),
          _techField(_tyres, tr('tech.tyres'), Icons.tire_repair_outlined),
          Row(children: [
            Expanded(child: _techField(_power, tr('tech.power'), Icons.speed, number: true)),
            const SizedBox(width: 10),
            Expanded(child: _techField(_cc, tr('tech.engine'), Icons.settings_outlined, number: true)),
          ]),
          const SizedBox(height: 16),
          Text(tr('edit.deadlinesTitle'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(tr('edit.deadlinesInfo'),
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
            label: Text(tr('edit.addCustom')),
          ),
          const SizedBox(height: 4),
          Text(tr('edit.customExamples'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: tr('edit.notes'),
              filled: true,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
            label: Text(tr('common.save')),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          const SizedBox(height: 24),
        ],
      ),
      ),
    );
  }

  Widget _techField(TextEditingController c, String label, IconData icon,
          {bool caps = false, bool number = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          textCapitalization: caps ? TextCapitalization.characters : TextCapitalization.none,
          keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            isDense: true,
            border: const OutlineInputBorder(),
            prefixIcon: Icon(icon),
          ),
        ),
      );

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
                      decoration: InputDecoration(
                        hintText: tr('edit.customName'),
                        isDense: true,
                      ),
                    )
                  : Text(isService ? tr('edit.lastService') : d.displayLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
            if (isCustom)
              IconButton(
                tooltip: tr('common.delete'),
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
                label: Text(d.date == null ? tr('edit.pickDate') : fmtDate(d.date)),
              ),
              if (d.date != null && !isService) StatusChip(due: d.date!),
            ]),
            if (isService) ...[
              const SizedBox(height: 8),
              Row(children: [
                Text(tr('edit.nextReminder')),
                DropdownButton<int>(
                  value: const [0, 6, 12, 24].contains(d.intervalMonths) ? d.intervalMonths : 12,
                  items: [
                    DropdownMenuItem(value: 0, child: Text(tr('edit.none'))),
                    for (final m in const [6, 12, 24])
                      DropdownMenuItem(value: m, child: Text(tr('edit.afterMonths', {'n': m}))),
                  ],
                  onChanged: (m) => setState(() => d.intervalMonths = m ?? 12),
                ),
              ]),
              if (d.dueDate != null)
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text('${tr('deadline.nextService')}: ${fmtDate(d.dueDate)}  ',
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
