import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Scheda "Famiglia": veicoli dei nuclei familiari condivisi.
class FamilyTab extends StatelessWidget {
  final void Function(Vehicle v) onOpen;
  final void Function(String groupId) onAdd;
  const FamilyTab({super.key, required this.onOpen, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!appState.isCloud) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(10, 24, 12, 24),
        children: [
          Icon(Icons.family_restroom, size: 72, color: scheme.primary),
          const SizedBox(height: 12),
          Text('Parco auto di famiglia',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(
            appState.auth.cloudAvailable
                ? 'Per vedere e condividere i veicoli con la famiglia serve un account online.\n\n'
                    'Vai in Impostazioni → Esci, poi accedi con "Account online" '
                    '(email oppure Google).'
                : 'La condivisione online non è ancora attiva in questa versione dell\'app.\n\n'
                    'Quando sarà attivata potrai creare un nucleo familiare, invitare i '
                    'familiari con un codice e vedere qui i loro veicoli.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    final groups = appState.data.groups;
    return RefreshIndicator(
      onRefresh: appState.retrySync,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 32),
        children: [
          if (groups.isEmpty) ...[
            const SizedBox(height: 24),
            Icon(Icons.family_restroom, size: 72, color: scheme.primary),
            const SizedBox(height: 12),
            Text('Nessun nucleo familiare',
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'Crea un nucleo e dai il codice invito ai familiari, oppure entra '
              'nel nucleo di un familiare con il suo codice.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
          ...groups.map((g) => _groupSection(context, g)),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => createGroupDialog(context),
                icon: const Icon(Icons.group_add),
                label: const Text('Crea nucleo familiare'),
              ),
              OutlinedButton.icon(
                onPressed: () => joinGroupDialog(context),
                icon: const Icon(Icons.key),
                label: const Text('Entra con un codice'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _groupSection(BuildContext context, FleetGroup g) {
    final list = appState.groupVehicles(g.id);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => GroupScreen(groupId: g.id))),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Icon(Icons.home_outlined, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(g.name,
                      style: TextStyle(
                          fontFamily: handFont, fontSize: 26, color: scheme.primary, height: 1.1)),
                  Text('${g.members.length} ${g.members.length == 1 ? 'membro' : 'membri'} · '
                      '${list.length} ${list.length == 1 ? 'veicolo' : 'veicoli'}',
                      style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
              const Icon(Icons.settings_outlined, size: 20),
            ]),
          ),
        ),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text('Ancora nessun veicolo in questo nucleo.',
                style: TextStyle(color: scheme.onSurfaceVariant)),
          ),
        ...list.map((v) => VehicleCard(vehicle: v, onTap: () => onOpen(v))),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => onAdd(g.id),
            icon: const Icon(Icons.add),
            label: Text('Aggiungi veicolo a "${g.name}"'),
          ),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------- Dialoghi

Future<void> createGroupDialog(BuildContext context) async {
  final c = TextEditingController(text: 'Famiglia');
  final name = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Nuovo nucleo familiare'),
      content: TextField(
        controller: c,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
            labelText: 'Nome (es. Famiglia Rossi)', border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Crea')),
      ],
    ),
  );
  if (name == null || name.isEmpty || !context.mounted) return;
  try {
    final g = await appState.createGroup(name);
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GroupScreen(groupId: g.id)));
  } catch (_) {
    if (context.mounted) showSnack(context, 'Serve una connessione internet per creare il nucleo.');
  }
}

Future<void> joinGroupDialog(BuildContext context) async {
  final c = TextEditingController();
  final code = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Codice invito'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Inserisci il codice che ti ha dato un familiare.'),
        const SizedBox(height: 12),
        TextField(
          controller: c,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration:
              const InputDecoration(hintText: 'Es. AB12CD34EF', border: OutlineInputBorder()),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Entra')),
      ],
    ),
  );
  if (code == null || code.isEmpty || !context.mounted) return;
  try {
    final g = await appState.joinGroup(code);
    if (context.mounted) showSnack(context, 'Sei entrato in "${g.name}"!');
  } catch (_) {
    if (context.mounted) {
      showSnack(context, 'Impossibile entrare: controlla il codice e la connessione.');
    }
  }
}

// ---------------------------------------------------------------- Gestione nucleo

class GroupScreen extends StatelessWidget {
  final String groupId;
  const GroupScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final g = appState.data.groupById(groupId);
        if (g == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const NotebookPage(child: Center(child: Text('Nucleo non disponibile.'))),
          );
        }
        final me = appState.session?.key;
        final isOwner = g.ownerUid == me;
        final scheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(title: Text(g.name)),
          body: NotebookPage(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 12, 10, 32),
              children: [
                Text('Codice invito', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Expanded(
                        child: SelectableText(g.id,
                            style: const TextStyle(
                                fontSize: 24, letterSpacing: 3, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        tooltip: 'Copia',
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: g.id));
                          showSnack(context, 'Codice copiato: incollalo su WhatsApp o SMS');
                        },
                      ),
                    ]),
                  ),
                ),
                Text(
                  'Il familiare installa l\'app, accede con un account online, apre la scheda '
                  'Famiglia → "Entra con un codice" e inserisce questo codice.',
                  style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                Text('Membri (${g.members.length})',
                    style: Theme.of(context).textTheme.titleLarge),
                ...g.members.entries.map((m) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(m.key == g.ownerUid ? Icons.star : Icons.person_outline,
                          color: m.key == g.ownerUid ? Colors.amber.shade700 : null),
                      title: Text(m.value + (m.key == me ? ' (tu)' : '')),
                      subtitle: m.key == g.ownerUid ? const Text('Creatore') : null,
                      trailing: isOwner && m.key != me
                          ? IconButton(
                              tooltip: 'Rimuovi',
                              icon: const Icon(Icons.person_remove_outlined),
                              onPressed: () => _removeMember(context, g, m.key, m.value),
                            )
                          : null,
                    )),
                const SizedBox(height: 20),
                if (isOwner)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Rinomina nucleo'),
                    onTap: () => _rename(context, g),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(isOwner ? Icons.delete_forever_outlined : Icons.exit_to_app,
                      color: Colors.red.shade700),
                  title: Text(isOwner ? 'Elimina nucleo' : 'Lascia il nucleo'),
                  subtitle: Text(isOwner
                      ? 'Tutti i membri perderanno l\'accesso ai veicoli del nucleo'
                      : 'Non vedrai più i veicoli di questo nucleo'),
                  onTap: () => _leave(context, g, isOwner),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _rename(BuildContext context, FleetGroup g) async {
    final c = TextEditingController(text: g.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nome del nucleo'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Salva')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await appState.renameGroup(g.id, name);
    } catch (_) {
      if (context.mounted) showSnack(context, 'Serve una connessione internet.');
    }
  }

  Future<void> _removeMember(BuildContext context, FleetGroup g, String uid, String email) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rimuovere il membro?'),
        content: Text('$email non vedrà più i veicoli di "${g.name}".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Rimuovi')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await appState.removeMember(g.id, uid);
    } catch (_) {
      if (context.mounted) showSnack(context, 'Serve una connessione internet.');
    }
  }

  Future<void> _leave(BuildContext context, FleetGroup g, bool isOwner) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isOwner ? 'Eliminare il nucleo?' : 'Lasciare il nucleo?'),
        content: Text(isOwner
            ? '"${g.name}" verrà eliminato per tutti i membri, insieme ai suoi veicoli.'
            : 'I veicoli di "${g.name}" spariranno da questo telefono.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isOwner ? 'Elimina' : 'Lascia'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      if (isOwner) {
        await appState.deleteGroup(g.id);
      } else {
        await appState.leaveGroup(g.id);
      }
      if (context.mounted) Navigator.of(context).pop();
    } catch (_) {
      if (context.mounted) showSnack(context, 'Serve una connessione internet.');
    }
  }
}
