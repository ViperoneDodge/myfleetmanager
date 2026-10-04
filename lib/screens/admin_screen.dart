import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../services/sync_service.dart' show cloudErrorMessage;
import '../theme.dart';
import '../widgets/common.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  static final _fmt = DateFormat('dd/MM/yyyy HH:mm');

  static String _date(dynamic ms) =>
      ms is num ? _fmt.format(DateTime.fromMillisecondsSinceEpoch(ms.toInt())) : '—';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Amministrazione Pro'),
          bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.w600),
              tabs: [
            Tab(icon: Icon(Icons.shopping_bag_outlined), text: 'Acquistata'),
            Tab(icon: Icon(Icons.key_outlined), text: 'Codice sviluppatore'),
          ]),
        ),
        body: NotebookPage(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: appState.sync.watchAllPro(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Accesso negato o errore del server.\n\n${cloudErrorMessage(snap.error!)}',
                        textAlign: TextAlign.center),
                  ),
                );
              }
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final all = snap.data!
                ..sort((a, b) => ((b['updatedAt'] as num?) ?? 0).compareTo((a['updatedAt'] as num?) ?? 0));
              final bought = all.where((e) => e['method'] == 'purchase').toList();
              final dev = all.where((e) => e['method'] != 'purchase').toList();
              return TabBarView(children: [
                _list(context, bought, dev: false),
                _list(context, dev, dev: true),
              ]);
            },
          ),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, List<Map<String, dynamic>> items, {required bool dev}) {
    final scheme = Theme.of(context).colorScheme;
    final active = items.where((e) => e['active'] == true && e['revoked'] != true).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 12, 10, 24),
      children: [
        Text(
          dev
              ? 'Attivi: $active · Totale voci: ${items.length}'
              : 'Utenti con acquisto: ${items.length}',
          style: TextStyle(fontFamily: handFont, fontSize: 22, color: scheme.primary),
        ),
        if (dev)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              'La Pro con codice si azzera a ogni aggiornamento dell\'app. Una revoca impedisce '
              'all\'utente di riusare il codice finché non la annulli.',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: Text('Nessuno in elenco.')),
          ),
        ...items.map((e) => _tile(context, e, dev: dev)),
      ],
    );
  }

  Widget _tile(BuildContext context, Map<String, dynamic> e, {required bool dev}) {
    final scheme = Theme.of(context).colorScheme;
    final revoked = e['revoked'] == true;
    final activeNow = e['active'] == true && !revoked;
    final String status;
    final Color color;
    if (revoked) {
      status = 'Revocata il ${_date(e['revokedAt'])}';
      color = scheme.error;
    } else if (activeNow) {
      status = 'Attiva dal ${_date(e['since'])} · versione ${e['appVersion'] ?? '?'}';
      color = Colors.green.shade700;
    } else {
      final why = e['endedReason'] == 'update'
          ? 'scaduta per aggiornamento'
          : (e['endedReason'] == 'user' ? 'disattivata dall\'utente' : 'non attiva');
      status = '${why[0].toUpperCase()}${why.substring(1)} · ${_date(e['updatedAt'])}';
      color = scheme.outline;
    }
    final name = (e['name'] as String?)?.trim();
    final email = (e['email'] as String?) ?? '';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          dev ? Icons.key : Icons.verified,
          color: activeNow ? scheme.primary : scheme.outline,
        ),
        title: Text(name == null || name.isEmpty ? email : name),
        subtitle: Text('${email.isEmpty ? e['uid'] : email}\n$status',
            style: TextStyle(color: color, fontSize: 12)),
        isThreeLine: true,
        trailing: !dev
            ? null
            : revoked
                ? TextButton(
                    onPressed: () => _act(context, e, revoke: false),
                    child: const Text('Annulla revoca'),
                  )
                : TextButton(
                    style: TextButton.styleFrom(foregroundColor: scheme.error),
                    onPressed: () => _act(context, e, revoke: true),
                    child: const Text('Revoca'),
                  ),
      ),
    );
  }

  Future<void> _act(BuildContext context, Map<String, dynamic> e, {required bool revoke}) async {
    final who = (e['email'] as String?)?.isNotEmpty == true ? e['email'] : e['uid'];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(revoke ? 'Revocare la Pro di sviluppo?' : 'Annullare la revoca?'),
        content: Text(revoke
            ? '$who perderà subito la versione Pro sbloccata con il codice e non potrà riusarlo.'
            : '$who potrà di nuovo usare il codice sviluppatore.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Conferma')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final uid = e['uid'] as String;
      if (revoke) {
        await appState.sync.revokeDevPro(uid);
      } else {
        await appState.sync.restoreDevPro(uid);
      }
      if (context.mounted) showSnack(context, revoke ? 'Pro di sviluppo revocata' : 'Revoca annullata');
    } catch (err) {
      if (context.mounted) showSnack(context, cloudErrorMessage(err));
    }
  }
}
