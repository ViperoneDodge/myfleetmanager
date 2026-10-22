import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n.dart';
import '../main.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class MaintenanceEditScreen extends StatefulWidget {
  final String vehicleId;

  final MaintenanceRecord? record;
  const MaintenanceEditScreen({super.key, required this.vehicleId, this.record});

  @override
  State<MaintenanceEditScreen> createState() => _MaintenanceEditScreenState();
}

class _MaintenanceEditScreenState extends State<MaintenanceEditScreen> {
  late final MaintenanceRecord r =
      widget.record?.copy() ?? MaintenanceRecord(date: DateTime.now());
  late final TextEditingController _km = TextEditingController(text: r.km == null ? '' : kmToShown(r.km!).toString());
  late final TextEditingController _notes = TextEditingController(text: r.notes);
  late final TextEditingController _labor = TextEditingController(text: centsText(r.labor));
  bool _asService = false;
  bool _saving = false;

  bool get _isNew => widget.record == null;

  @override
  void dispose() {
    _km.dispose();
    _notes.dispose();
    _labor.dispose();
    super.dispose();
  }

  bool _hasService(Vehicle? v) =>
      v != null && v.deadlines.any((d) => d.kind == DeadlineKind.service && d.enabled);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inserted = r.insertedOn;
    final last = (inserted != null && inserted.isBefore(today)) ? inserted : today;
    final d = await showDatePicker(
      context: context,
      initialDate: r.date.isAfter(last) ? last : r.date,
      firstDate: DateTime(1980),
      lastDate: last,
    );
    if (d != null) setState(() => r.date = d);
  }

  Future<void> _save() async {
    final kmText = _km.text.trim();
    final shown = int.tryParse(kmText);
    if (r.km == null || shown != kmToShown(r.km!)) r.km = shown == null ? null : shownToKm(shown);
    r.notes = _notes.text.trim();
    r.labor = parseCents(_labor.text);
    if (r.items.isEmpty && r.customParts.isEmpty && r.notes.isEmpty) {
      showSnack(context, tr('maint.needItem'));
      return;
    }
    setState(() => _saving = true);
    await appState.saveMaintenance(widget.vehicleId, r, asService: _asService);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _editPart(MaintPart p, {bool isNew = false}) async {
    final name = TextEditingController(text: p.name);
    final code = TextEditingController(text: p.code);
    final cost = TextEditingController(text: centsText(p.cents));
    final custom = p.custom;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (custom)
            TextField(
              controller: name,
              autofocus: isNew,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: tr('maint.partName'), border: const OutlineInputBorder()),
            )
          else
            Text(p.label, style: const TextStyle(fontFamily: handFont, fontSize: 26)),
          const SizedBox(height: 12),
          TextField(
            controller: code,
            autofocus: !custom,
            decoration: InputDecoration(labelText: tr('maint.partCode'), border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: cost,
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: tr('maint.cost'),
              prefixText: '${moneyFormat.currencySymbol} ',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            if (custom && !isNew)
              TextButton.icon(
                onPressed: () {
                  setState(() => r.parts.remove(p));
                  Navigator.pop(ctx, false);
                },
                icon: const Icon(Icons.delete_outline),
                label: Text(tr('common.remove')),
              ),
            const Spacer(),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('common.ok'))),
          ]),
        ]),
      ),
    );
    if (ok == true && mounted) {
      setState(() {
        if (custom) p.name = name.text.trim();
        p.code = code.text.trim();
        p.cents = parseCents(cost.text);
        if (!custom) r.items.add(p.key);
        if (isNew && p.name.isNotEmpty) r.parts.add(p);
      });
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('maint.deleteTitle')),
        content: Text(tr('maint.deleteBody', {'date': fmtDate(r.date)})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('common.cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('common.delete')),
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
        title: Text(_isNew ? tr('maint.newTitle') : tr('maint.editTitle')),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: tr('common.delete'),
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
              title: Text(tr('maint.date')),
              trailing: Text(fmtDate(r.date), style: const TextStyle(fontSize: 16)),
              onTap: _pickDate,
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _km,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: tr(Units.miles ? 'maint.miles' : 'maint.km'),
                suffixText: distanceUnit,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.speed),
              ),
            ),
            const SizedBox(height: 16),
            Text(tr('maint.items'), style: Theme.of(context).textTheme.titleMedium),
            for (final k in maintenanceItemsFor(v?.type, r.items))
              _PartRow(
                label: maintenanceItemLabel(k),
                part: r.partOf(k),
                checked: r.items.contains(k),
                onCheck: (b) => setState(() => b ? r.items.add(k) : r.items.remove(k)),
                onOpen: () => _editPart(r.part(k)),
              ),
            for (final p in r.customParts)
              _PartRow(
                label: p.name,
                part: p,
                checked: true,
                onCheck: (_) => setState(() => r.parts.remove(p)),
                onOpen: () => _editPart(p),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _editPart(MaintPart(), isNew: true),
                icon: const Icon(Icons.add),
                label: Text(tr('maint.addPart')),
              ),
            ),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: Text(tr('maint.labor'), style: const TextStyle(fontSize: 16))),
              SizedBox(
                width: 130,
                child: TextField(
                  controller: _labor,
                  textAlign: TextAlign.right,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (t) => setState(() => r.labor = parseCents(t)),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixText: '${moneyFormat.currencySymbol} ',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ]),
            if (r.total != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Expanded(
                    child: Text(tr('maint.total'),
                        style: TextStyle(fontFamily: handFont, fontSize: 24, color: scheme.onPrimaryContainer)),
                  ),
                  Text(fmtMoney(r.total!),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: scheme.onPrimaryContainer)),
                ]),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: tr('maint.notesHint'),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            if (_hasService(v)) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr('maint.asService')),
                subtitle: Text(tr('maint.asServiceInfo')),
                value: _asService,
                onChanged: (b) => setState(() => _asService = b),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(tr('common.save')),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartRow extends StatelessWidget {
  final String label;
  final MaintPart? part;
  final bool checked;
  final ValueChanged<bool> onCheck;
  final VoidCallback onOpen;
  const _PartRow({
    required this.label,
    required this.part,
    required this.checked,
    required this.onCheck,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final code = checked ? part?.code ?? '' : '';
    final cents = checked ? part?.cents : null;
    return InkWell(
      onTap: checked ? onOpen : () => onCheck(true),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Checkbox(value: checked, onChanged: (b) => onCheck(b == true)),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 15)),
              if (code.isNotEmpty)
                Text(code, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ]),
          ),
          if (checked) ...[
            Text(cents == null ? '—' : fmtMoney(cents),
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cents == null ? scheme.onSurfaceVariant : null)),
            Icon(Icons.chevron_right, color: scheme.outline),
          ],
        ]),
      ),
    );
  }
}
