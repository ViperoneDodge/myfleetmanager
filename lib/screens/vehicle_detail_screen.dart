import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';

import '../l10n.dart';
import 'photo_crop_screen.dart';
import '../main.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'maintenance_screen.dart';
import 'pro_screen.dart';
import '../services/registration_reader.dart';
import 'vehicle_edit_screen.dart';

class VehicleDetailScreen extends StatelessWidget {
  final String vehicleId;

  final bool embedded;
  final VoidCallback? onClosed;
  const VehicleDetailScreen({
    super.key,
    required this.vehicleId,
    this.embedded = false,
    this.onClosed,
  });

  Future<void> _delete(BuildContext context, Vehicle v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('vehicle.deleteTitle')),
        content: Text(tr(appState.isCloud ? 'vehicle.deleteBodyCloud' : 'vehicle.deleteBody',
            {'name': v.name.isEmpty ? v.plate : v.name})),
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
    if (ok == true) {
      await appState.deleteVehicle(v.id);
      if (embedded) {
        onClosed?.call();
      } else if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<String?> _askName(BuildContext context, {String initial = ''}) {
    final c = TextEditingController(text: initial);
    final suggestions = [
      tr('doc.registration'),
      tr('doc.policy'),
      tr('doc.inspectionCert'),
      tr('doc.tax'),
      tr('doc.serviceInvoice'),
    ];
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(tr('doc.nameTitle')),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: c,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(border: const OutlineInputBorder(), hintText: tr('doc.nameHint')),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: suggestions
                  .map((s) => ActionChip(
                        label: Text(s),
                        onPressed: () => setSt(() => c.text = s),
                      ))
                  .toList(),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.cancel'))),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim().isEmpty ? tr('doc.default') : c.text.trim()),
              child: Text(tr('common.save')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addDocument(BuildContext context, Vehicle v) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(tr('doc.addTitle'), style: const TextStyle(fontFamily: handFont, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.document_scanner_outlined),
            title: Text(tr('doc.camera')),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(tr('doc.gallery')),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: Text(tr('doc.file')),
            subtitle: Text(tr('doc.fileInfo')),
            onTap: () => Navigator.pop(ctx, 'file'),
          ),
        ]),
      ),
    );
    if (choice == null) return;
    String? path;
    try {
      if (choice == 'file') {
        final res = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        );
        path = res?.files.single.path;
      } else {
        final x = await ImagePicker().pickImage(
          source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 2200,
          maxHeight: 2200,
          imageQuality: 85,
        );
        path = x?.path;
      }
    } catch (e) {
      if (context.mounted) showSnack(context, tr('doc.openError', {'error': e}));
      return;
    }
    if (path == null || !context.mounted) return;
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp')) {
      try {
        final bytes = await File(path).readAsBytes();
        if (!context.mounted) return;
        final cropped = await cropPhoto(context, bytes, maxSide: 2200, quality: 85);
        if (cropped == null || !context.mounted) return;
        final tmp = File('${Directory.systemTemp.path}/doc_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tmp.writeAsBytes(cropped);
        path = tmp.path;
      } catch (e) {
        if (context.mounted) showSnack(context, tr('photo.error', {'error': e}));
        return;
      }
    }
    if (!context.mounted) return;
    final name = await _askName(context, initial: v.documents.isEmpty ? tr('doc.registration') : '');
    if (name == null) return;
    try {
      await appState.addDocument(v.id, path, name);
      if (context.mounted) showSnack(context, tr('doc.saved'));
    } catch (e) {
      if (context.mounted) showSnack(context, tr('doc.saveError', {'error': e}));
    }
  }

  Future<void> _openDocument(BuildContext context, VehicleDocument d) async {
    final f = await appState.documentFile(d);
    if (!await f.exists()) {
      if (context.mounted) showSnack(context, tr('doc.notFound'));
      return;
    }
    if (d.isPdf) {
      final r = await OpenFilex.open(f.path, type: 'application/pdf');
      if (r.type != ResultType.done && context.mounted) {
        showSnack(context, tr('doc.noPdfApp', {'error': r.message}));
      }
    } else if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _ImageViewer(title: d.name, file: f),
      ));
    }
  }

  Future<void> _documentMenu(BuildContext context, Vehicle v, VehicleDocument d) async {
    final a = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: Text(tr('doc.open')),
            onTap: () => Navigator.pop(ctx, 'open'),
          ),
          if (appState.canEdit(v))
            ListTile(
              leading: const Icon(Icons.document_scanner_outlined),
              title: Text(tr('ocr.read')),
              onTap: () => Navigator.pop(ctx, 'ocr'),
            ),
          ListTile(
            leading: const Icon(Icons.drive_file_rename_outline),
            title: Text(tr('doc.rename')),
            onTap: () => Navigator.pop(ctx, 'rename'),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red.shade700),
            title: Text(tr('common.delete')),
            onTap: () => Navigator.pop(ctx, 'delete'),
          ),
        ]),
      ),
    );
    if (!context.mounted) return;
    if (a == 'open') {
      await _openDocument(context, d);
    } else if (a == 'ocr') {
      await _readRegistration(context, v, d);
    } else if (a == 'rename') {
      final n = await _askName(context, initial: d.name);
      if (n != null) await appState.renameDocument(v.id, d.id, n);
    } else if (a == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr('doc.deleteTitle')),
          content: Text(tr('doc.deleteBody', {'name': d.name})),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('common.cancel'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('common.delete'))),
          ],
        ),
      );
      if (ok == true) await appState.removeDocument(v.id, d.id);
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
              appBar: AppBar(automaticallyImplyLeading: !embedded),
              body: NotebookPage(child: Center(child: Text(tr('vehicle.notFound')))));
        }
        final scheme = Theme.of(context).colorScheme;
        final bytes = v.photoBytes;
        final tracked = v.deadlines.where((d) => d.enabled).toList();
        final canEdit = appState.canEdit(v);
        final group = appState.isPersonal(v) ? null : appState.data.groupById(v.fleetId);
        final canAssign = group != null && appState.canManage(group);
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: !embedded,
            title: Text(v.name.isEmpty ? tr('vehicle.generic') : v.name),
            actions: [
              if (canAssign)
                IconButton(
                  tooltip: tr('role.assignOwner'),
                  icon: const Icon(Icons.manage_accounts_outlined),
                  onPressed: () => _assignOwner(context, v, group),
                ),
              if (canEdit)
                IconButton(
                  tooltip: tr('common.delete'),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, v),
                ),
            ],
          ),
          floatingActionButton: !canEdit
              ? null
              : FloatingActionButton.extended(
                  icon: const Icon(Icons.edit),
                  label: Text(tr('common.edit')),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => VehicleEditScreen(vehicle: v.copy()))),
                ),
          body: NotebookPage(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 14, 10, 96),
              children: [
                if (!canEdit)
                  Card(
                    color: scheme.secondaryContainer,
                    child: ListTile(
                      leading: const Icon(Icons.visibility_outlined),
                      title: Text(tr('role.viewer')),
                      subtitle: Text(tr('role.readOnly')),
                    ),
                  ),
                Center(
                  child: Transform.rotate(
                    angle: -0.025,
                    child: Stack(clipBehavior: Clip.none, children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 26),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(1, 3)),
                          ],
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: SizedBox(
                          width: 250,
                          height: 160,
                          child: bytes != null
                              ? Image.memory(bytes, fit: BoxFit.cover)
                              : Container(
                                  color: scheme.primaryContainer,
                                  padding: const EdgeInsets.all(22),
                                  child: VehicleSilhouette(
                                      type: v.type, color: scheme.onPrimaryContainer),
                                ),
                        ),
                      ),
                      Positioned(
                        top: -10,
                        left: 95,
                        child: Transform.rotate(
                          angle: 0.06,
                          child: Container(
                            width: 76,
                            height: 22,
                            color: const Color(0xCCF3E7B3),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 18),
                Text(v.name.isEmpty ? tr('vehicle.noName') : v.name,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black87, width: 1.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(v.plate.isEmpty ? '—' : v.plate,
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              fontSize: 16)),
                    ),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(vehicleIcon(v.type)),
                      const SizedBox(width: 4),
                      Text(vehicleTypeLabel(v.type)),
                    ]),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.event_note_outlined, size: 18),
                      const SizedBox(width: 4),
                      Flexible(child: Text('${tr('vehicle.regDate')}: ${fmtDate(v.registrationDate)}')),
                    ]),
                    if (appState.isCloud && appState.data.groups.isNotEmpty)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(appState.isPersonal(v) ? Icons.person_outline : Icons.groups_outlined,
                            size: 18),
                        const SizedBox(width: 4),
                        Text(appState.fleetLabel(v)),
                      ]),
                  ],
                ),
                const SizedBox(height: 18),
                Text(tr('tech.title'), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                _techRow(context, tr('tech.vin'), v.vin),
                _techRow(context, tr('tech.tyres'), v.tyres),
                _techRow(context, tr('tech.power'), v.powerKw),
                _techRow(context, tr('tech.engine'), v.engineCc),
                const SizedBox(height: 18),
                Text(tr('tab.deadlines'), style: Theme.of(context).textTheme.titleLarge),
                if (tracked.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(tr('vehicle.noTracked')),
                  ),
                ...tracked.map((d) => _deadlineTile(context, d)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: Text(tr('maint.title'), style: Theme.of(context).textTheme.titleLarge)),
                  if (canEdit)
                  TextButton.icon(
                    onPressed: () async {
                      if (await requirePro(context, reason: tr('pro.reasonMaint')) &&
                          context.mounted) {
                        _openMaintenance(context, v, null);
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: Text(tr('common.add')),
                  ),
                ]),
                if (v.maintenance.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(tr('maint.empty'),
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  ),
                ...v.maintenanceSorted.map((m) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(Icons.build_circle_outlined, color: scheme.primary, size: 30),
                        title: Text(
                            '${fmtDate(m.date)}${m.km != null ? ' · ${fmtKm(m.km!)}' : ''}'),
                        subtitle: Text(_maintSummary(m),
                            maxLines: 3, overflow: TextOverflow.ellipsis),
                        onTap: canEdit ? () => _openMaintenance(context, v, m) : null,
                      ),
                    )),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: Text(tr('doc.title'), style: Theme.of(context).textTheme.titleLarge)),
                  TextButton.icon(
                    onPressed: () async {
                      if (await requirePro(context, reason: tr('pro.reasonDocs')) &&
                          context.mounted) {
                        await _addDocument(context, v);
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: Text(tr('common.add')),
                  ),
                ]),
                if (v.documents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(tr('doc.empty'),
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  ),
                ...v.documents.map((d) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          d.isPdf ? Icons.picture_as_pdf : Icons.image_outlined,
                          color: d.isPdf ? Colors.red.shade400 : scheme.primary,
                          size: 30,
                        ),
                        title: Text(d.name),
                        subtitle: Text(
                            '${d.isPdf ? 'PDF' : tr('doc.image')} · ${_size(d.size)} · ${fmtDate(DateTime.fromMillisecondsSinceEpoch(d.addedAt))}'),
                        onTap: () => _openDocument(context, d),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _documentMenu(context, v, d),
                        ),
                      ),
                    )),
                if (appState.isCloud && v.documents.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(tr('doc.localOnly'),
                        style: TextStyle(fontSize: 12, color: scheme.outline)),
                  ),
                if (v.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(tr('vehicle.notes'), style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(v.notes, style: const TextStyle(fontFamily: handFont, fontSize: 20)),
                ],
                if (appState.isCloud && v.updatedBy.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      tr('vehicle.lastEdit', {
                        'who': v.updatedBy,
                        'date': fmtDate(DateTime.fromMillisecondsSinceEpoch(v.updatedAt)),
                      }),
                      style: TextStyle(fontSize: 12, color: scheme.outline),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _techRow(BuildContext context, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 150,
            child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: Text(value.isEmpty ? '—' : value)),
        ]),
      );

  Future<void> _readRegistration(BuildContext context, Vehicle v, VehicleDocument d) async {
    final f = await appState.documentFile(d);
    if (!await f.exists()) {
      if (context.mounted) showSnack(context, tr('doc.notFound'));
      return;
    }
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 18),
          Expanded(child: Text(tr('ocr.reading'))),
        ]),
      ),
    );
    RegistrationData data;
    try {
      data = RegistrationReader.parse(await RegistrationReader.readText(f.path));
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        showSnack(context, tr('ocr.error', {'error': e}));
      }
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    if (data.isEmpty) {
      showSnack(context, tr('ocr.none'));
      return;
    }
    final rows = <({String key, String label, String value})>[
      if (data.plate != null) (key: 'plate', label: tr('edit.plate'), value: data.plate!),
      if (data.registrationDate != null)
        (key: 'reg', label: tr('vehicle.regDate'), value: fmtDate(data.registrationDate)),
      if (data.vin != null) (key: 'vin', label: tr('tech.vin'), value: data.vin!),
      if (data.tyres != null) (key: 'tyres', label: tr('tech.tyres'), value: data.tyres!),
      if (data.powerKw != null) (key: 'power', label: tr('tech.power'), value: data.powerKw!),
      if (data.engineCc != null) (key: 'cc', label: tr('tech.engine'), value: data.engineCc!),
    ];
    final chosen = rows.map((r) => r.key).toSet();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(tr('ocr.found')),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('ocr.foundHint'), style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              ...rows.map((r) => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: chosen.contains(r.key),
                    onChanged: (b) => setSt(() => b == true ? chosen.add(r.key) : chosen.remove(r.key)),
                    title: Text(r.value),
                    subtitle: Text(r.label),
                  )),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('common.cancel'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('ocr.apply'))),
          ],
        ),
      ),
    );
    if (ok != true || chosen.isEmpty) return;
    final c = v.copy();
    if (chosen.contains('plate')) c.plate = data.plate!;
    if (chosen.contains('reg')) c.registrationDate = data.registrationDate;
    if (chosen.contains('vin')) c.vin = data.vin!;
    if (chosen.contains('tyres')) c.tyres = data.tyres!;
    if (chosen.contains('power')) c.powerKw = data.powerKw!;
    if (chosen.contains('cc')) c.engineCc = data.engineCc!;
    final dup = appState.duplicatePlateGroup(c, c.fleetId);
    if (dup != null) {
      if (context.mounted) showSnack(context, tr('vehicle.plateDuplicate', {'plate': c.plate, 'group': dup}));
      return;
    }
    await appState.saveVehicle(c);
    if (context.mounted) showSnack(context, tr('ocr.saved'));
  }

  Future<void> _assignOwner(BuildContext context, Vehicle v, FleetGroup g) async {
    final members = g.members.entries.where((m) => m.key != v.createdBy).toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
    final current = g.members[v.createdBy];
    final picked = await showDialog<MapEntry<String, String>>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(tr('role.pickOwner')),
        children: [
          if (current != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(tr('role.currentOwner', {'name': current}),
                  style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
            ),
          ...members.map((m) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, m),
                child: Row(children: [
                  const Icon(Icons.person_outline, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(m.value)),
                ]),
              )),
        ],
      ),
    );
    if (picked == null || !context.mounted) return;
    final name = v.name.isEmpty ? v.plate : v.name;
    try {
      await appState.assignOwner(v, picked.key);
      if (context.mounted) {
        showSnack(context, tr('role.ownerAssigned', {'name': picked.value, 'vehicle': name}));
      }
    } catch (e) {
      if (context.mounted) showSnack(context, '$e');
    }
  }

  void _openMaintenance(BuildContext context, Vehicle v, MaintenanceRecord? m) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MaintenanceEditScreen(vehicleId: v.id, record: m),
    ));
  }

  static String _maintSummary(MaintenanceRecord m) {
    final parts = <String>[
      ...maintenanceItems.where(m.items.contains).map(maintenanceItemLabel),
    ];
    final txt = parts.join(', ');
    if (m.notes.isEmpty) return txt.isEmpty ? '—' : txt;
    return txt.isEmpty ? m.notes : '$txt\n${m.notes}';
  }

  static String _size(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
      case DeadlineKind.tax:
        icon = Icons.receipt_long_outlined;
        break;
      case DeadlineKind.custom:
        icon = Icons.event_note_outlined;
        break;
    }
    String subtitle;
    if (d.kind == DeadlineKind.service) {
      subtitle = tr('service.last', {'date': fmtDate(d.date)});
      if (d.dueDate != null) {
        subtitle += '\n${tr('service.next', {'date': fmtDate(d.dueDate), 'n': d.intervalMonths})}';
      }
    } else {
      subtitle = d.date == null ? tr('deadline.noDate') : tr('deadline.expiresOn', {'date': fmtDate(d.date)});
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.displayLabel, style: const TextStyle(fontFamily: handFont, fontSize: 21, height: 1.1)),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            if (d.dueDate != null) ...[
              const SizedBox(height: 4),
              StatusChip(due: d.dueDate!),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _ImageViewer extends StatelessWidget {
  final String title;
  final File file;
  const _ImageViewer({required this.title, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: InteractiveViewer(
        maxScale: 6,
        child: Center(child: Image.file(file)),
      ),
    );
  }
}
