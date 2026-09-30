import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';

import '../main.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'maintenance_screen.dart';
import 'vehicle_edit_screen.dart';

class VehicleDetailScreen extends StatelessWidget {
  final String vehicleId;
  const VehicleDetailScreen({super.key, required this.vehicleId});

  Future<void> _delete(BuildContext context, Vehicle v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare il veicolo?'),
        content: Text('"${v.name.isEmpty ? v.plate : v.name}", le sue scadenze e i documenti '
            'verranno eliminati${appState.isCloud ? ' (le scadenze anche per gli altri membri della famiglia)' : ''}.'),
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

  // ------------------------------------------------------------ Documenti

  Future<String?> _askName(BuildContext context, {String initial = ''}) {
    final c = TextEditingController(text: initial);
    const suggestions = ['Libretto', 'Polizza assicurazione', 'Certificato revisione', 'Bollo', 'Fattura tagliando'];
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Nome del documento'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: c,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Es. Libretto'),
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim().isEmpty ? 'Documento' : c.text.trim()),
              child: const Text('Salva'),
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
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Aggiungi documento', style: TextStyle(fontFamily: handFont, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.document_scanner_outlined),
            title: const Text('Fotografa il documento'),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Immagine dalla galleria'),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('File PDF o immagine'),
            subtitle: const Text('Dai file del telefono, Drive, download…'),
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
      if (context.mounted) showSnack(context, 'Impossibile aprire il file: $e');
      return;
    }
    if (path == null || !context.mounted) return;
    final name = await _askName(context, initial: v.documents.isEmpty ? 'Libretto' : '');
    if (name == null) return;
    try {
      await appState.addDocument(v.id, path, name);
      if (context.mounted) showSnack(context, 'Documento salvato');
    } catch (e) {
      if (context.mounted) showSnack(context, 'Errore nel salvataggio: $e');
    }
  }

  Future<void> _openDocument(BuildContext context, VehicleDocument d) async {
    final f = await appState.documentFile(d);
    if (!await f.exists()) {
      if (context.mounted) showSnack(context, 'File non trovato sul telefono.');
      return;
    }
    if (d.isPdf) {
      final r = await OpenFilex.open(f.path, type: 'application/pdf');
      if (r.type != ResultType.done && context.mounted) {
        showSnack(context, 'Nessuna app per aprire i PDF: ${r.message}');
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
            title: const Text('Apri'),
            onTap: () => Navigator.pop(ctx, 'open'),
          ),
          ListTile(
            leading: const Icon(Icons.drive_file_rename_outline),
            title: const Text('Rinomina'),
            onTap: () => Navigator.pop(ctx, 'rename'),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red.shade700),
            title: const Text('Elimina'),
            onTap: () => Navigator.pop(ctx, 'delete'),
          ),
        ]),
      ),
    );
    if (!context.mounted) return;
    if (a == 'open') {
      await _openDocument(context, d);
    } else if (a == 'rename') {
      final n = await _askName(context, initial: d.name);
      if (n != null) await appState.renameDocument(v.id, d.id, n);
    } else if (a == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminare il documento?'),
          content: Text('"${d.name}" verrà cancellato dal telefono.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Elimina')),
          ],
        ),
      );
      if (ok == true) await appState.removeDocument(v.id, d.id);
    }
  }

  // ------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final v = appState.vehicleById(vehicleId);
        if (v == null) {
          return Scaffold(
              appBar: AppBar(),
              body: const NotebookPage(child: Center(child: Text('Veicolo non trovato.'))));
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
          body: NotebookPage(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 14, 10, 96),
              children: [
                // Foto stile "polaroid" fissata con lo scotch
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
                                  child: Icon(vehicleIcon(v.type),
                                      size: 80, color: scheme.onPrimaryContainer),
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
                Text(v.name.isEmpty ? 'Senza nome' : v.name,
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
                    if (appState.isCloud && appState.data.groups.isNotEmpty)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(appState.isPersonal(v) ? Icons.person_outline : Icons.home_outlined,
                            size: 18),
                        const SizedBox(width: 4),
                        Text(appState.fleetLabel(v)),
                      ]),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Scadenze', style: Theme.of(context).textTheme.titleLarge),
                if (tracked.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Nessuna scadenza monitorata.'),
                  ),
                ...tracked.map((d) => _deadlineTile(context, d)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: Text('Manutenzioni', style: Theme.of(context).textTheme.titleLarge)),
                  TextButton.icon(
                    onPressed: () => _openMaintenance(context, v, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Aggiungi'),
                  ),
                ]),
                if (v.maintenance.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Registra qui tagliandi e interventi: data, km e filtri sostituiti.',
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
                        onTap: () => _openMaintenance(context, v, m),
                      ),
                    )),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: Text('Documenti', style: Theme.of(context).textTheme.titleLarge)),
                  TextButton.icon(
                    onPressed: () => _addDocument(context, v),
                    icon: const Icon(Icons.add),
                    label: const Text('Aggiungi'),
                  ),
                ]),
                if (v.documents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Salva qui libretto, polizza e altri documenti (foto o PDF).',
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
                            '${d.isPdf ? 'PDF' : 'Immagine'} · ${_size(d.size)} · ${fmtDate(DateTime.fromMillisecondsSinceEpoch(d.addedAt))}'),
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
                    child: Text('I documenti restano solo su questo telefono.',
                        style: TextStyle(fontSize: 12, color: scheme.outline)),
                  ),
                if (v.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Note', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(v.notes, style: const TextStyle(fontFamily: handFont, fontSize: 20)),
                ],
                if (appState.isCloud && v.updatedBy.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'Ultima modifica: ${v.updatedBy} · '
                      '${fmtDate(DateTime.fromMillisecondsSinceEpoch(v.updatedAt))}',
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
      case DeadlineKind.custom:
        icon = Icons.event_note_outlined;
        break;
    }
    String subtitle;
    if (d.kind == DeadlineKind.service) {
      subtitle = 'Ultimo: ${fmtDate(d.date)}';
      if (d.dueDate != null) {
        subtitle += '\nProssimo: ${fmtDate(d.dueDate)} (ogni ${d.intervalMonths} mesi)';
      }
    } else {
      subtitle = d.date == null ? 'Data non impostata' : 'Scade il ${fmtDate(d.date)}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.label, style: const TextStyle(fontFamily: handFont, fontSize: 21, height: 1.1)),
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
