import 'package:flutter/material.dart';

import '../main.dart';
import '../models.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'family_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _offsets = [30, 7, 1, 0];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final s = appState.session;
        final n = appState.data.notify;
        final allOn = _offsets.every(n.offsets.contains);
        final scheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(title: const Text('Impostazioni')),
          body: NotebookPage(
            child: ListView(padding: const EdgeInsets.only(top: 6, right: 4), children: [
            // ---------------- Account ----------------
            _header(context, 'Account'),
            ListTile(
              leading: Icon(appState.isCloud ? Icons.cloud : Icons.phone_android),
              title: Text(s?.displayName ?? ''),
              subtitle: Text(appState.isCloud
                  ? 'Account online · dati salvati sul telefono e condivisi con la famiglia'
                  : 'Account solo su questo telefono'),
            ),

            // ---------------- Aspetto ----------------
            ..._appearance(context),

            // ---------------- Notifiche ----------------
            _header(context, 'Notifiche'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Quando vuoi essere avvisato prima di una scadenza?',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ),
            CheckboxListTile(
              title: const Text('Tutti gli avvisi', style: TextStyle(fontWeight: FontWeight.w600)),
              value: allOn,
              onChanged: (b) {
                final ns = NotifySettings(
                    offsets: b == true ? _offsets.toSet() : <int>{},
                    hour: n.hour,
                    minute: n.minute);
                appState.updateNotify(ns);
              },
            ),
            ..._offsets.map((o) => CheckboxListTile(
                  contentPadding: const EdgeInsets.only(left: 40, right: 16),
                  title: Text(NotificationService.offsetLabel(o)),
                  value: n.offsets.contains(o),
                  onChanged: (b) {
                    final set = Set<int>.from(n.offsets);
                    if (b == true) {
                      set.add(o);
                    } else {
                      set.remove(o);
                    }
                    appState.updateNotify(
                        NotifySettings(offsets: set, hour: n.hour, minute: n.minute));
                  },
                )),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Orario delle notifiche'),
              trailing: Text(
                  '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 16)),
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: n.hour, minute: n.minute),
                );
                if (t != null) {
                  appState.updateNotify(
                      NotifySettings(offsets: n.offsets, hour: t.hour, minute: t.minute));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('Prova notifica'),
              subtitle: const Text('Verifica che le notifiche siano permesse'),
              onTap: () async {
                await appState.notifications.requestPermission();
                await appState.notifications.showTest();
                final count = await appState.notifications
                    .rescheduleAll(appState.data.vehicles, appState.data.notify);
                if (context.mounted) {
                  showSnack(context, 'Notifiche programmate: $count');
                }
              },
            ),

            // ---------------- Famiglia ----------------
            _header(context, 'Nuclei familiari'),
            if (!appState.isCloud)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  appState.auth.cloudAvailable
                      ? 'Per condividere i veicoli con la famiglia esci e accedi con un '
                          'account online (email o Google).'
                      : 'La condivisione con la famiglia non è ancora attiva in questa '
                          'versione dell\'app: arriverà con un prossimo aggiornamento.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              )
            else
              ..._familySection(context),

            // ---------------- Esci ----------------
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Esci'),
              subtitle: const Text('I dati restano salvati sul telefono'),
              onTap: () async {
                Navigator.of(context).popUntil((r) => r.isFirst);
                await appState.logout();
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: Text('MyFleetManager 1.0',
                  style: TextStyle(fontSize: 12, color: scheme.outline)),
            ),
            const SizedBox(height: 24),
          ]),
          ),
        );
      },
    );
  }

  List<Widget> _appearance(BuildContext context) {
    final t = appState.theme;
    void save({ThemeMode? mode, int? palette, PaperStyle? paper}) {
      appState.updateTheme(ThemeSettings(
        mode: mode ?? t.mode,
        palette: palette ?? t.palette,
        paper: paper ?? t.paper,
      ));
    }

    return [
      _header(context, 'Aspetto'),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Chiaro')),
            ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Scuro')),
            ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('Auto')),
          ],
          selected: {t.mode},
          onSelectionChanged: (sel) => save(mode: sel.first),
        ),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 6),
        child: Text('Colore copertina'),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(palettes.length, (i) {
            final p = palettes[i];
            final sel = i == t.palette;
            return Tooltip(
              message: p.name,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => save(palette: i),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: p.seed,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: sel ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: sel ? const Icon(Icons.check, color: Colors.white) : null,
                ),
              ),
            );
          }),
        ),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Text('Sfondo delle pagine'),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Wrap(
          spacing: 8,
          children: PaperStyle.values
              .map((p) => ChoiceChip(
                    label: Text(paperStyleLabel(p)),
                    selected: t.paper == p,
                    onSelected: (_) => save(paper: p),
                  ))
              .toList(),
        ),
      ),
    ];
  }

  List<Widget> _familySection(BuildContext context) {
    final groups = appState.data.groups;
    return [
      ...groups.map((g) => ListTile(
            leading: const Icon(Icons.home_outlined),
            title: Text(g.name),
            subtitle: Text('${g.members.length} membri · codice ${g.id}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => GroupScreen(groupId: g.id))),
          )),
      ListTile(
        leading: const Icon(Icons.group_add),
        title: const Text('Crea nucleo familiare'),
        onTap: () => createGroupDialog(context),
      ),
      ListTile(
        leading: const Icon(Icons.key),
        title: const Text('Entra con un codice invito'),
        onTap: () => joinGroupDialog(context),
      ),
    ];
  }

  Widget _header(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(t,
            style: TextStyle(
                fontFamily: handFont,
                fontSize: 24,
                color: Theme.of(context).colorScheme.primary)),
      );
}
