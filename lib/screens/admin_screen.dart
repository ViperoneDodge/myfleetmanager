import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../models.dart';
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
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Amministrazione Pro'),
          bottom: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.w600),
              tabs: [
            Tab(icon: Icon(Icons.shopping_bag_outlined), text: 'Acquistata'),
            Tab(icon: Icon(Icons.key_outlined), text: 'Codice sviluppatore'),
            Tab(icon: Icon(Icons.directions_car_outlined), text: 'Veicoli'),
            Tab(icon: Icon(Icons.groups_outlined), text: 'Gruppi'),
          ]),
        ),
        body: NotebookPage(
          child: TabBarView(children: [
            _proTab(dev: false),
            _proTab(dev: true),
            const AdminVehiclesTab(),
            const AdminGroupsTab(),
          ]),
        ),
      ),
    );
  }

  static Widget _error(Object e) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Accesso negato o errore del server.\n\n${cloudErrorMessage(e)}',
              textAlign: TextAlign.center),
        ),
      );

  Widget _proTab({required bool dev}) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: appState.sync.watchAllPro(),
        builder: (context, snap) {
          if (snap.hasError) return _error(snap.error!);
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final all = snap.data!
            ..sort((a, b) => ((b['updatedAt'] as num?) ?? 0).compareTo((a['updatedAt'] as num?) ?? 0));
          final items = all.where((e) => (e['method'] == 'purchase') != dev).toList();
          return _list(context, items, dev: dev);
        },
      );

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

class AdminVehiclesTab extends StatefulWidget {
  const AdminVehiclesTab({super.key});

  @override
  State<AdminVehiclesTab> createState() => _AdminVehiclesTabState();
}

class _AdminUser {
  final String uid;
  String name = '';
  String email = '';
  _AdminUser(this.uid);

  String get label => name.isNotEmpty ? name : (email.isNotEmpty ? email : uid);
  String get detail => email.isNotEmpty && email != label ? email : uid;
}

class _AdminVehiclesTabState extends State<AdminVehiclesTab> {
  final _search = TextEditingController();
  late final Stream<List<Vehicle>> _vehicles = appState.sync.watchAllVehicles();
  late final Stream<List<Map<String, dynamic>>> _fleets = appState.sync.watchAllFleets();
  late final Stream<List<Map<String, dynamic>>> _users = appState.sync.watchAllUsers();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Map<String, _AdminUser> _people(List<Map<String, dynamic>> users, List<Map<String, dynamic>> fleets) {
    final out = <String, _AdminUser>{};
    for (final f in fleets) {
      final emails = Map<String, dynamic>.from((f['memberEmails'] as Map?) ?? {});
      emails.forEach((uid, e) => out.putIfAbsent(uid, () => _AdminUser(uid)).email = e.toString());
    }
    for (final u in users) {
      final uid = u['uid'] as String;
      final p = out.putIfAbsent(uid, () => _AdminUser(uid));
      final name = (u['name'] as String?)?.trim() ?? '';
      final email = (u['email'] as String?)?.trim() ?? '';
      if (name.isNotEmpty) p.name = name;
      if (email.isNotEmpty) p.email = email;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _fleets,
      builder: (context, fs) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: _users,
        builder: (context, us) => StreamBuilder<List<Vehicle>>(
          stream: _vehicles,
          builder: (context, vs) {
            final err = fs.error ?? us.error ?? vs.error;
            if (err != null) return AdminScreen._error(err);
            if (!fs.hasData || !us.hasData || !vs.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final fleets = {for (final f in fs.data!) f['id'] as String: f};
            return _content(context, vs.data!, fleets, _people(us.data!, fs.data!));
          },
        ),
      ),
    );
  }

  bool _personalFleet(Map<String, dynamic>? f) => f?['personal'] == true;

  String _owner(Vehicle v, Map<String, Map<String, dynamic>> fleets) {
    if (v.createdBy.isNotEmpty) return v.createdBy;
    final f = fleets[v.fleetId];
    return _personalFleet(f) ? (f?['ownerUid'] as String? ?? v.fleetId!) : '';
  }

  Widget _content(BuildContext context, List<Vehicle> all, Map<String, Map<String, dynamic>> fleets,
      Map<String, _AdminUser> people) {
    final scheme = Theme.of(context).colorScheme;
    String who(String uid) => uid.isEmpty ? 'non indicato' : (people[uid]?.label ?? uid);
    String where(Vehicle v) {
      final f = fleets[v.fleetId];
      if (_personalFleet(f)) return 'Personale di ${who(f?['ownerUid'] as String? ?? v.fleetId!)}';
      return 'Gruppo: ${(f?['name'] as String?) ?? v.fleetId}';
    }

    final q = _search.text.trim().toLowerCase();
    final list = all.where((v) {
      if (q.isEmpty) return true;
      final o = _owner(v, fleets);
      return '${v.name} ${v.plate} ${who(o)} ${people[o]?.email ?? ''} ${where(v)}'.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) {
        final c = who(_owner(a, fleets)).toLowerCase().compareTo(who(_owner(b, fleets)).toLowerCase());
        return c != 0 ? c : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 12, 10, 24),
      children: [
        Text('Veicoli di tutti gli utenti: ${all.length}',
            style: TextStyle(fontFamily: handFont, fontSize: 22, color: scheme.primary)),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text(
            'Proprietario = utente che ha aggiunto il veicolo. Un veicolo di un gruppo resta nel gruppo; '
            'un veicolo personale passa nella flotta personale del nuovo proprietario.',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Cerca per nome, targa, utente o gruppo',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: Text('Nessun veicolo.')),
          ),
        ...list.map((v) {
          final owner = _owner(v, fleets);
          final title = v.name.isEmpty ? (v.plate.isEmpty ? 'Veicolo' : v.plate) : v.name;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: Icon(vehicleIcon(v.type), color: scheme.primary),
              title: Text(title),
              subtitle: Text(
                'Proprietario: ${who(owner)}\n${where(v)}\n${vehicleTypeLabel(v.type)} · ${v.plate.isEmpty ? '—' : v.plate}',
                style: const TextStyle(fontSize: 12),
              ),
              isThreeLine: true,
              trailing: TextButton(
                onPressed: () => _assign(context, v, owner, fleets, people),
                child: const Text('Assegna'),
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _assign(BuildContext context, Vehicle v, String owner,
      Map<String, Map<String, dynamic>> fleets, Map<String, _AdminUser> people) async {
    final f = fleets[v.fleetId];
    final personal = _personalFleet(f);
    final groupMembers = ((f?['members'] as List?) ?? const []).map((e) => e.toString()).toSet();
    final candidates = people.values
        .where((p) => p.uid != owner && (personal || groupMembers.contains(p.uid)))
        .toList()
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    final picked = await showDialog<_AdminUser>(
      context: context,
      builder: (ctx) => _UserPicker(
        users: candidates,
        hint: personal ? null : 'Solo i membri del gruppo "${f?['name'] ?? v.fleetId}".',
      ),
    );
    if (picked == null || !context.mounted) return;
    final title = v.name.isEmpty ? v.plate : v.name;
    final oldName = owner.isEmpty ? 'nessuno' : (people[owner]?.label ?? owner);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Assegnare $title a ${picked.label}?'),
        content: Text(personal
            ? '$title passerà tra i veicoli personali di ${picked.label}. $oldName non lo vedrà più. '
                'I documenti salvati sul telefono non vengono trasferiti.'
            : '${picked.label} diventerà il proprietario di $title, che resta nel gruppo '
                '"${f?['name'] ?? v.fleetId}". $oldName non lo vedrà più tra "I miei veicoli".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Assegna')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await appState.sync.reassignVehicle(v, picked.uid, personal: personal, admin: appState.session!);
      if (context.mounted) showSnack(context, '$title assegnato a ${picked.label}');
    } catch (err) {
      if (context.mounted) showSnack(context, cloudErrorMessage(err));
    }
  }
}

class _UserPicker extends StatefulWidget {
  final List<_AdminUser> users;
  final String? hint;
  const _UserPicker({required this.users, this.hint});

  @override
  State<_UserPicker> createState() => _UserPickerState();
}

class _UserPickerState extends State<_UserPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase();
    final list = widget.users
        .where((u) => q.isEmpty || '${u.name} ${u.email} ${u.uid}'.toLowerCase().contains(q))
        .toList();
    return AlertDialog(
      title: const Text('Nuovo proprietario'),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: 380,
        child: Column(children: [
          if (widget.hint != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(widget.hint!, style: const TextStyle(fontSize: 12)),
            ),
          TextField(
            autofocus: true,
            onChanged: (t) => setState(() => _q = t.trim()),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Nome o email',
              isDense: true,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('Nessun utente.'))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (ctx, i) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.person_outline),
                      title: Text(list[i].label),
                      subtitle: Text(list[i].detail),
                      onTap: () => Navigator.pop(ctx, list[i]),
                    ),
                  ),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
      ],
    );
  }
}

class AdminGroupsTab extends StatelessWidget {
  const AdminGroupsTab({super.key});

  static String _role(GroupRole r) =>
      r == GroupRole.admin ? 'Amministratore' : (r == GroupRole.editor ? 'Può modificare' : 'Solo visualizzazione');

  FleetGroup _group(Map<String, dynamic> f) {
    final emails = Map<String, dynamic>.from((f['memberEmails'] as Map?) ?? {});
    return FleetGroup(
      id: f['id'] as String,
      name: (f['name'] as String?) ?? (f['id'] as String),
      ownerUid: (f['ownerUid'] as String?) ?? '',
      members: {
        for (final uid in ((f['members'] as List?) ?? const [])) uid.toString(): (emails[uid] ?? uid).toString()
      },
      admins: ((f['admins'] as List?) ?? const []).map((e) => e.toString()).toSet(),
      viewers: ((f['viewers'] as List?) ?? const []).map((e) => e.toString()).toSet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: appState.sync.watchAllFleets(),
      builder: (context, snap) {
        if (snap.hasError) return AdminScreen._error(snap.error!);
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final groups = snap.data!.where((f) => f['personal'] != true).map(_group).toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return ListView(
          padding: const EdgeInsets.fromLTRB(8, 12, 10, 24),
          children: [
            Text('Gruppi: ${groups.length}',
                style: TextStyle(fontFamily: handFont, fontSize: 22, color: scheme.primary)),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                'Tocca un membro per cambiarne il ruolo. Solo da qui si può togliere il ruolo di amministratore. '
                'Il creatore del gruppo resta sempre amministratore.',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ),
            ...groups.map((g) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ExpansionTile(
                    leading: Icon(Icons.groups_outlined, color: scheme.primary),
                    title: Text(g.name),
                    subtitle: Text('${g.members.length} membri · codice ${g.id}', style: const TextStyle(fontSize: 12)),
                    children: g.members.entries.map((m) {
                      final role = g.roleOf(m.key);
                      final owner = m.key == g.ownerUid;
                      return ListTile(
                        dense: true,
                        leading: Icon(owner ? Icons.star : Icons.person_outline,
                            color: owner ? Colors.amber.shade700 : null),
                        title: Text(m.value),
                        subtitle: Text(owner ? 'Creatore · ${_role(role)}' : _role(role)),
                        onTap: owner ? null : () => _change(context, g, m.key, m.value, role),
                      );
                    }).toList(),
                  ),
                )),
          ],
        );
      },
    );
  }

  Future<void> _change(BuildContext context, FleetGroup g, String uid, String name, GroupRole current) async {
    final picked = await showDialog<GroupRole>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Ruolo di $name in "${g.name}"'),
        children: GroupRole.values
            .map((r) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, r),
                  child: Row(children: [
                    Icon(r == current ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 20),
                    const SizedBox(width: 10),
                    Text(_role(r)),
                  ]),
                ))
            .toList(),
      ),
    );
    if (picked == null || picked == current) return;
    try {
      await appState.sync.setRole(g.id, uid, picked);
      if (context.mounted) showSnack(context, '$name: ${_role(picked)}');
    } catch (err) {
      if (context.mounted) showSnack(context, cloudErrorMessage(err));
    }
  }
}
