import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n.dart';
import '../main.dart';
import '../models.dart';
import '../services/app_state.dart' show AppState;
import '../services/notification_service.dart';
import '../services/support_service.dart';
import '../services/sync_service.dart' show cloudErrorMessage;
import '../version.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'admin_screen.dart';
import 'family_screen.dart';
import 'login_screen.dart';
import 'pro_screen.dart';

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
          appBar: AppBar(title: Text(tr('settings.title'))),
          body: NotebookPage(
            child: ListView(padding: const EdgeInsets.only(top: 6, right: 4), children: [
            // ---------------- Account ----------------
            _header(context, tr('settings.account')),
            ListTile(
              leading: Icon(appState.isCloud ? Icons.cloud : Icons.phone_android),
              title: Text(s?.displayName ?? ''),
              subtitle: Text(appState.isCloud
                  ? tr('settings.accountCloud')
                  : tr('settings.accountLocal')),
            ),
            if (!appState.isCloud && appState.auth.cloudAvailable)
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined),
                title: Text(tr('upgrade.button')),
                subtitle: Text(tr('upgrade.settingsInfo')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const LoginScreen(upgrade: true))),
              ),

            // ---------------- Versione Pro ----------------
            _header(context, tr('pro.section')),
            ListTile(
              leading: Icon(Icons.workspace_premium,
                  color: appState.isPro ? Colors.amber.shade700 : scheme.primary),
              title: Text(appState.isPro ? tr('pro.active') : tr('pro.title')),
              subtitle: Text(appState.isPro
                  ? (appState.devPro && !appState.purchasedPro
                      ? tr('pro.activeDev')
                      : tr('pro.activeThanks'))
                  : tr('pro.freeInfo', {'n': 3})),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const ProScreen())),
            ),

            // ---------------- Lingua ----------------
            _header(context, tr('settings.language')),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(appState.langPref == null
                  ? '${tr('settings.langAuto')} (${L10n.names[L10n.code]})'
                  : (L10n.names[appState.langPref] ?? appState.langPref!)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _chooseLanguage(context),
            ),

            // ---------------- Aspetto ----------------
            ..._appearance(context),

            // ---------------- Notifiche ----------------
            _header(context, tr('settings.notifications')),
            const _NotifyStatus(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(tr('settings.whenNotify'),
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ),
            CheckboxListTile(
              title: Text(tr('settings.allAlerts'), style: const TextStyle(fontWeight: FontWeight.w600)),
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
              title: Text(tr('settings.notifyTime')),
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
              title: Text(tr('settings.testNow')),
              subtitle: Text(tr('settings.testNowInfo')),
              onTap: () async {
                await appState.notifications.requestPermission();
                await appState.notifications.showTest();
                final count = await appState.notifications
                    .rescheduleAll(appState.activeVehicles, appState.data.notify);
                if (context.mounted) {
                  showSnack(context, tr('settings.scheduledCount', {'n': count}));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(tr('settings.test1min')),
              subtitle: Text(tr('settings.test1minInfo')),
              onTap: () async {
                await appState.notifications.requestPermission();
                try {
                  await appState.notifications.scheduleTest(const Duration(minutes: 1));
                  if (context.mounted) {
                    showSnack(context, tr('settings.test1minDone'));
                  }
                } catch (e) {
                  if (context.mounted) showSnack(context, tr('settings.testFailed', {'error': e}));
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                tr('settings.batteryHint'),
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ),
            if (appState.isCloud) ...[
              _header(context, tr('settings.push')),
              ListTile(
                leading: Icon(
                  appState.push.registered ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                  color: appState.push.registered ? Colors.green.shade700 : Colors.orange.shade800,
                ),
                title: Text(appState.push.registered
                    ? tr('settings.pushOk')
                    : tr('settings.pushNo')),
                subtitle: Text(appState.push.registered
                    ? tr('settings.pushOkInfo')
                    : tr('settings.pushNoInfo')),
                onTap: () async {
                  if (!appState.push.registered) {
                    await appState.startPush();
                    if (context.mounted && !appState.push.registered) {
                      showSnack(context, tr('settings.pushFailed'));
                    }
                    return;
                  }
                  Clipboard.setData(ClipboardData(text: appState.push.token!));
                  showSnack(context, tr('settings.pushCopied'));
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active_outlined),
                title: Text(tr('settings.groupAlerts')),
                subtitle: Text(tr('settings.groupAlertsInfo')),
                value: appState.groupAlerts,
                onChanged: (on) => appState.setGroupAlerts(on),
              ),
            ],

            // ---------------- Famiglia ----------------
            _header(context, tr('settings.groups')),
            if (!appState.isCloud)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  appState.auth.cloudAvailable
                      ? tr('settings.groupsNeedCloud')
                      : tr('family.cloudOff'),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              )
            else
              ..._familySection(context),

            // ---------------- Assistenza e privacy ----------------
            _header(context, tr('support.title')),
            // Solo per l'account amministratore (appmyfleetmanager@gmail.com).
            if (appState.isAdmin)
              ListTile(
                leading: Icon(Icons.admin_panel_settings_outlined, color: scheme.primary),
                title: const Text('Amministrazione Pro'),
                subtitle: const Text('Chi ha la Pro: acquisti e codici sviluppatore'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const AdminScreen())),
              ),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: Text(tr('bug.title')),
              subtitle: Text(tr('bug.subtitle')),
              onTap: () => _bugReport(context),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(tr('privacy.title')),
              subtitle: Text(tr('privacy.subtitle')),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () async {
                final ok = await SupportService.openPrivacy();
                if (!ok && context.mounted) showSnack(context, SupportService.privacyUrl);
              },
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: Text(tr('privacy.deleteRequest')),
              subtitle: Text(SupportService.email),
              onTap: () async {
                final ok = await SupportService.openEmail(
                  subject: 'MyFleetManager - ${tr('privacy.deleteRequest')}',
                  body: '${tr('login.email')}: ${appState.session?.email ?? appState.session?.displayName ?? ''}\n\n',
                );
                if (!ok && context.mounted) {
                  showSnack(context, tr('bug.noMail', {'email': SupportService.email}));
                }
              },
            ),
            if (appState.isCloud)
              ListTile(
                leading: Icon(Icons.delete_forever_outlined, color: scheme.error),
                title: Text(tr('account.delete'), style: TextStyle(color: scheme.error)),
                subtitle: Text(tr('account.deleteInfo')),
                onTap: () => _deleteAccount(context),
              ),

            // ---------------- Esci ----------------
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(tr('settings.logout')),
              subtitle: Text(tr('settings.logoutInfo')),
              onTap: () async {
                Navigator.of(context).popUntil((r) => r.isFirst);
                await appState.logout();
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: Text('MyFleetManager $appVersion',
                  style: TextStyle(fontSize: 12, color: scheme.outline)),
            ),
            const SizedBox(height: 24),
          ]),
          ),
        );
      },
    );
  }

  Future<void> _bugReport(BuildContext context) async {
    final name = TextEditingController(
        text: appState.session?.displayName ?? '');
    final msg = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('bug.title')),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                  labelText: tr('bug.name'), border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: msg,
              maxLines: 6,
              minLines: 4,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                  labelText: tr('bug.message'),
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            Text(tr('bug.info'), style: Theme.of(ctx).textTheme.bodySmall),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('common.cancel'))),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send),
            label: Text(tr('bug.send')),
          ),
        ],
      ),
    );
    if (send != true || msg.text.trim().isEmpty) return;
    final device = await SupportService.deviceDescription();
    final body = '${msg.text.trim()}\n\n'
        '-----\n'
        '${tr('bug.name')}: ${name.text.trim()}\n'
        'App: MyFleetManager $appVersion${appState.isPro ? ' (Pro)' : ''}\n'
        '${appState.isCloud ? 'Account online' : 'Account locale'} · ${L10n.code}\n'
        '$device\n';
    final ok = await SupportService.openEmail(
      subject: 'MyFleetManager $appVersion - ${tr('bug.title')}',
      body: body,
    );
    if (!ok && context.mounted) {
      showSnack(context, tr('bug.noMail', {'email': SupportService.email}));
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('account.deleteTitle')),
        content: Text(tr('account.deleteBody')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('common.cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('common.delete')),
          ),
        ],
      ),
    );
    if (yes != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      final complete = await appState.deleteCloudAccount();
      nav.popUntil((r) => r.isFirst);
      messenger.showSnackBar(SnackBar(
          content: Text(complete ? tr('account.deleted') : tr('account.relogin'))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(cloudErrorMessage(e))));
    }
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
      _header(context, tr('settings.appearance')),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
                value: ThemeMode.light, icon: const Icon(Icons.light_mode), label: Text(tr('theme.light'))),
            ButtonSegment(
                value: ThemeMode.dark, icon: const Icon(Icons.dark_mode), label: Text(tr('theme.dark'))),
            ButtonSegment(
                value: ThemeMode.system,
                icon: const Icon(Icons.brightness_auto),
                label: Text(tr('theme.auto'))),
          ],
          selected: {t.mode},
          onSelectionChanged: (sel) => save(mode: sel.first),
        ),
      ),
      // Tenendo premuta per 5 secondi questa etichetta compare il campo
      // per il codice sviluppatore (sblocco Pro per le prove).
      _SecretLabel(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Text(tr('theme.cover')),
        ),
      ),
      const _DevCodeField(),
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
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Text(tr('theme.paper')),
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
            leading: const Icon(Icons.groups_outlined),
            title: Text(g.name),
            subtitle: Text('${trn('family.members', g.members.length)} · ${tr('settings.code', {'code': g.id})}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => GroupScreen(groupId: g.id))),
          )),
      ListTile(
        leading: const Icon(Icons.group_add),
        title: Text(tr('family.create')),
        onTap: () => createGroupDialog(context),
      ),
      ListTile(
        leading: const Icon(Icons.key),
        title: Text(tr('settings.joinInvite')),
        onTap: () => joinGroupDialog(context),
      ),
    ];
  }

  Future<void> _chooseLanguage(BuildContext context) async {
    const auto = '__auto__';
    final codes = [...L10n.available]..sort((a, b) => L10n.names[a]!.compareTo(L10n.names[b]!));
    final sel = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
          child: ListView(shrinkWrap: true, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(tr('settings.language'),
                  style: const TextStyle(fontFamily: handFont, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.phone_android),
              title: Text(tr('settings.langAuto')),
              trailing: appState.langPref == null ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, auto),
            ),
            const Divider(height: 1),
            ...codes.map((c) => ListTile(
                  title: Text(L10n.names[c]!),
                  trailing: appState.langPref == c ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.pop(ctx, c),
                )),
          ]),
        ),
      ),
    );
    if (sel == null) return;
    await appState.setLanguage(sel == auto ? null : sel);
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

/// Stato dei permessi notifiche, aggiornato quando si torna nell'app
/// (ad esempio dopo averli abilitati nelle impostazioni di Android).
class _NotifyStatus extends StatefulWidget {
  const _NotifyStatus();

  @override
  State<_NotifyStatus> createState() => _NotifyStatusState();
}

class _NotifyStatusState extends State<_NotifyStatus> with WidgetsBindingObserver {
  ({bool enabled, bool exact})? _st;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      final s = await appState.notifications.status();
      if (mounted) setState(() => _st = s);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final st = _st;
    if (st == null) return const SizedBox.shrink();
    if (!st.enabled) {
      return ListTile(
        leading: Icon(Icons.notifications_off, color: Colors.red.shade700),
        title: Text(tr('settings.blocked'), style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(tr('settings.blockedInfo')),
        onTap: () async {
          await appState.notifications.requestPermission();
          await _load();
        },
      );
    }
    // Niente sveglie esatte (regole Play Store): i promemoria giornalieri possono
    // arrivare con qualche minuto di tolleranza, quindi nessun avviso da mostrare.
    return ListTile(
      leading: Icon(Icons.notifications_active, color: Colors.green.shade700),
      title: Text(tr('settings.allowed')),
    );
  }
}


/// Rende visibile il campo del codice sviluppatore.
final ValueNotifier<bool> _devFieldVisible = ValueNotifier(false);

/// Etichetta che, tenuta premuta per 5 secondi, mostra il campo del codice.
class _SecretLabel extends StatefulWidget {
  final Widget child;
  const _SecretLabel({required this.child});

  @override
  State<_SecretLabel> createState() => _SecretLabelState();
}

class _SecretLabelState extends State<_SecretLabel> {
  Timer? _t;

  void _start() {
    _t?.cancel();
    _t = Timer(const Duration(seconds: 5), () {
      HapticFeedback.heavyImpact();
      _devFieldVisible.value = true;
    });
  }

  void _stop() {
    _t?.cancel();
    _t = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _start(),
        onPointerUp: (_) => _stop(),
        onPointerCancel: (_) => _stop(),
        child: widget.child,
      );
}

class _DevCodeField extends StatefulWidget {
  const _DevCodeField();

  @override
  State<_DevCodeField> createState() => _DevCodeFieldState();
}

class _DevCodeFieldState extends State<_DevCodeField> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final r = await appState.unlockDev(_c.text);
    if (!mounted) return;
    switch (r) {
      case AppState.devOk:
        _c.clear();
        FocusScope.of(context).unfocus();
        showSnack(context, tr('pro.devUnlocked'));
        break;
      case AppState.devNeedCloud:
        showSnack(context, tr('pro.devNeedCloud'));
        break;
      case AppState.devRevoked:
        showSnack(context, tr('pro.devRevoked'));
        break;
      default:
        showSnack(context, tr('pro.devWrong'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _devFieldVisible,
      builder: (context, visible, _) {
        if (!visible) return const SizedBox.shrink();
        return Card(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                const Icon(Icons.developer_mode, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(tr('pro.devTitle'),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => _devFieldVisible.value = false,
                ),
              ]),
              if (appState.devPro) ...[
                Text(tr('pro.activeDev')),
                const SizedBox(height: 6),
                OutlinedButton(
                  onPressed: () {
                    appState.disableDev();
                    showSnack(context, tr('pro.devDisabled'));
                  },
                  child: Text(tr('pro.devDisable')),
                ),
              ] else
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _c,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      obscureText: true,
                      decoration: InputDecoration(
                        isDense: true,
                        border: const OutlineInputBorder(),
                        hintText: tr('pro.devHint'),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _submit, child: Text(tr('common.ok'))),
                ]),
            ]),
          ),
        );
      },
    );
  }
}
