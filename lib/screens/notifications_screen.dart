import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n.dart';
import '../main.dart';
import '../services/notification_log.dart';
import '../theme.dart';
import 'vehicle_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Set<String> _selected = {};
  bool _selecting = false;

  void _toggle(String id) => setState(() {
        if (!_selected.remove(id)) _selected.add(id);
        if (_selected.isEmpty) _selecting = false;
      });

  void _stopSelecting() => setState(() {
        _selecting = false;
        _selected.clear();
      });

  void _open(LogEntry e) {
    final v = e.vehicleId.isEmpty ? null : appState.vehicleById(e.vehicleId);
    final ch = v == null || v.deleted || e.read || !e.isChange ? null : appState.log.changesFor(v.id);
    if (ch == null && !e.read) appState.markNotificationsRead({e.id});
    if (v == null || v.deleted) return;
    final tabs = ch?.tabs ?? const <int>{};
    final pro = appState.isPro;
    final allowed = tabs.where((t) => t == 0 || pro).toList()..sort();
    detailTab.value = allowed.isEmpty ? 0 : allowed.first;
    focusChange.value = ch == null ? null : v.id;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicleId: v.id)));
  }

  Future<void> _deleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(tr('notif.deleteAllConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('common.cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('common.delete'))),
        ],
      ),
    );
    if (ok == true) await appState.clearNotifications();
  }

  static String dayLabel(DateTime d, DateTime now) {
    final day = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return tr('notif.today');
    if (diff == 1) return tr('notif.yesterday');
    return DateFormat('dd/MM/yyyy').format(d);
  }

  static IconData _icon(LogKind k) {
    switch (k) {
      case LogKind.added:
        return Icons.add_circle_outline;
      case LogKind.edited:
        return Icons.edit_outlined;
      case LogKind.deleted:
        return Icons.delete_outline;
      case LogKind.reminder:
        return Icons.event_outlined;
      case LogKind.message:
        return Icons.campaign_outlined;
    }
  }

  Widget _tile(LogEntry e) {
    final scheme = Theme.of(context).colorScheme;
    final sel = _selected.contains(e.id);
    final time = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(e.ts));
    final detail = e.detail;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: sel ? scheme.primaryContainer : scheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sel ? scheme.primary : scheme.outlineVariant),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: CircleAvatar(
          backgroundColor: sel ? scheme.primary : scheme.secondaryContainer,
          foregroundColor: sel ? scheme.onPrimary : scheme.onSecondaryContainer,
          child: Icon(sel ? Icons.check : _icon(e.kind)),
        ),
        title: Text(e.headline, style: TextStyle(fontWeight: e.read ? FontWeight.w400 : FontWeight.w700)),
        subtitle: Text(detail.isEmpty ? time : '$detail · $time'),
        trailing: !e.read && !_selecting
            ? Container(width: 10, height: 10, decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle))
            : null,
        onTap: () => _selecting ? _toggle(e.id) : _open(e),
        onLongPress: () => setState(() {
          _selecting = true;
          _selected.add(e.id);
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final list = appState.log.sorted;
        _selected.removeWhere((id) => !list.any((e) => e.id == id));
        if (_selected.isEmpty) _selecting = false;
        final now = DateTime.now();
        final children = <Widget>[];
        String? last;
        for (final e in list) {
          final label = dayLabel(DateTime.fromMillisecondsSinceEpoch(e.ts), now);
          if (label != last) {
            children.add(Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 4, 4),
              child: Text(label, style: Theme.of(context).textTheme.titleMedium),
            ));
            last = label;
          }
          children.add(_tile(e));
        }
        return PopScope(
          canPop: !_selecting,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _stopSelecting();
          },
          child: Scaffold(
            appBar: _selecting
                ? AppBar(
                    leading: IconButton(
                      tooltip: tr('common.close'),
                      icon: const Icon(Icons.close),
                      onPressed: _stopSelecting,
                    ),
                    title: Text(tr('notif.selected', {'n': _selected.length})),
                    actions: [
                      IconButton(
                        tooltip: tr('notif.selectAll'),
                        icon: const Icon(Icons.select_all),
                        onPressed: () => setState(() => _selected.addAll(list.map((e) => e.id))),
                      ),
                      IconButton(
                        tooltip: tr('notif.markRead'),
                        icon: const Icon(Icons.mark_email_read_outlined),
                        onPressed: () {
                          appState.markNotificationsRead(Set.of(_selected));
                          _stopSelecting();
                        },
                      ),
                      IconButton(
                        tooltip: tr('common.delete'),
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          appState.deleteNotifications(Set.of(_selected));
                          _stopSelecting();
                        },
                      ),
                    ],
                  )
                : AppBar(
                    title: Text(tr('notif.title')),
                    actions: [
                      if (appState.unreadNotifications > 0)
                        IconButton(
                          tooltip: tr('notif.markAllRead'),
                          icon: const Icon(Icons.done_all),
                          onPressed: appState.markAllNotificationsRead,
                        ),
                      if (list.isNotEmpty)
                        PopupMenuButton<int>(
                          onSelected: (_) => _deleteAll(),
                          itemBuilder: (_) => [
                            PopupMenuItem(value: 0, child: Text(tr('notif.deleteAll'))),
                          ],
                        ),
                    ],
                  ),
            body: NotebookPage(
              child: list.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.notifications_none, size: 64, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 12),
                        Text(tr('notif.empty')),
                      ]),
                    )
                  : ListView(padding: const EdgeInsets.fromLTRB(10, 0, 10, 24), children: children),
            ),
          ),
        );
      },
    );
  }
}

class NotificationBell extends StatelessWidget {
  final VoidCallback onPressed;
  const NotificationBell({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final n = appState.unreadNotifications;
    return IconButton(
      tooltip: tr('notif.title'),
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: n > 0,
        label: Text(n > 99 ? '99+' : '$n'),
        child: Icon(n > 0 ? Icons.notifications : Icons.notifications_outlined),
      ),
    );
  }
}
