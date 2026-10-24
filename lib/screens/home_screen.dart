import 'dart:async';
import 'dart:ui' show DisplayFeatureType;

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../main.dart';
import '../models.dart';
import '../services/app_state.dart';
import '../services/sync_service.dart' show cloudErrorMessage;
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/docs_consent.dart';
import '../services/notification_service.dart';
import 'family_screen.dart';
import 'notifications_screen.dart';
import 'pro_screen.dart';
import 'vehicle_book.dart';
import 'settings_screen.dart';
import 'vehicle_detail_screen.dart';
import 'vehicle_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  late final AppLifecycleListener _life;
  Timer? _exactTimer;

  @override
  void initState() {
    super.initState();
    _life = AppLifecycleListener(onResume: () => appState.refreshExact());
    _exactTimer = Timer(const Duration(seconds: 5), _askExact);
    NotificationService.openLog.addListener(_onOpenLog);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onOpenLog());
  }

  void _onOpenLog() {
    if (!NotificationService.openLog.value || !mounted) return;
    NotificationService.openLog.value = false;
    _openLog();
  }

  void _openLog() {
    appState.reloadLog();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
  }

  @override
  void dispose() {
    NotificationService.openLog.removeListener(_onOpenLog);
    _life.dispose();
    _exactTimer?.cancel();
    super.dispose();
  }

  Future<void> _askExact() async {
    if (!mounted) return;
    if (!await appState.shouldAskExact() || !mounted) {
      await _askDocs();
      return;
    }
    await appState.markExactAsked();
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.alarm, color: Colors.orange.shade800),
        title: Text(tr('settings.exactOff')),
        content: Text(tr('exact.dialogBody')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('exact.later'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('exact.allow'))),
        ],
      ),
    );
    if (ok == true) await appState.notifications.requestExactAlarms();
    await _askDocs();
  }

  Future<void> _askDocs() async {
    if (!mounted || !appState.shouldAskDocsConsent()) return;
    await askDocsConsent(context);
  }
  VehicleType? _filter;

  String? _selectedId;
  bool _twoPane = false;

  Future<void> _openAdd({String? fleetId}) async {
    if (!await ensureCanAddVehicle(context)) return;
    if (!mounted) return;
    var type = _filter ?? VehicleType.auto;
    if (AppState.isProType(type) && !appState.isPro) type = VehicleType.auto;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => VehicleEditScreen(vehicle: Vehicle(type: type, fleetId: fleetId)),
    ));
  }

  void _openDetail(Vehicle v, [List<Vehicle>? siblings]) {
    if (_twoPane) {
      setState(() => _selectedId = v.id);
      return;
    }
    final ids = [for (final s in siblings ?? const <Vehicle>[]) s.id];
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ids.length > 1 && ids.contains(v.id)
          ? VehicleBook(ids: ids, initialId: v.id)
          : VehicleDetailScreen(vehicleId: v.id),
    ));
  }

  static Rect? _verticalHinge(MediaQueryData mq) {
    for (final f in mq.displayFeatures) {
      if (f.type == DisplayFeatureType.cutout) continue;
      final b = f.bounds;
      if (b.height >= b.width && b.left > 120 && b.right < mq.size.width - 120) return b;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final hinge = _verticalHinge(mq);
    final width = mq.size.width;
    _twoPane = hinge != null || width >= 840;
    if (!_twoPane) return _mainScaffold(context);

    final leftWidth = hinge != null ? hinge.left : (width * 0.42).clamp(340.0, 480.0).toDouble();
    final gap = hinge != null ? hinge.width : 0.0;
    final selected = _selectedId == null ? null : appState.vehicleById(_selectedId!);
    return Row(children: [
      SizedBox(width: leftWidth, child: _mainScaffold(context)),
      if (gap > 0) SizedBox(width: gap, child: ColoredBox(color: NotebookColors.of(context).cover)),
      Expanded(
        child: selected == null
            ? _emptyDetail(context)
            : VehicleDetailScreen(
                key: ValueKey(selected.id),
                vehicleId: selected.id,
                embedded: true,
                onClosed: () => setState(() => _selectedId = null),
              ),
      ),
    ]);
  }

  Widget _emptyDetail(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: NotebookPage(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.touch_app_outlined, size: 64, color: scheme.outline),
            const SizedBox(height: 12),
            Text(tr('home.selectVehicle'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: handFont, fontSize: 24)),
          ]),
        ),
      ),
    );
  }

  List<FleetGroup> _groupsWithVehicles() =>
      appState.data.groups.where((g) => appState.groupVehicles(g.id).isNotEmpty).toList();

  Future<void> _exportGroups() async {
    if (!await requirePro(context, reason: tr('pro.reasonPdf')) || !mounted) return;
    final groups = _groupsWithVehicles();
    final all = [for (final g in groups) ...appState.groupVehicles(g.id)];
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(tr('pdf.chooseGroups'), style: const TextStyle(fontFamily: handFont, fontSize: 24)),
            ),
            if (groups.length > 1)
              ListTile(
                leading: const Icon(Icons.select_all),
                title: Text(tr('pdf.allGroups')),
                subtitle: Text(trn('family.vehicles', all.length)),
                onTap: () => Navigator.pop(ctx, ''),
              ),
            for (final g in groups)
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: Text(g.name),
                subtitle: Text(trn('family.vehicles', appState.groupVehicles(g.id).length)),
                onTap: () => Navigator.pop(ctx, g.id),
              ),
          ]),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice.isEmpty) {
      await exportPdf(context, tr('pdf.allGroups'), all);
    } else {
      final g = appState.data.groupById(choice);
      if (g != null) await exportPdf(context, g.name, appState.groupVehicles(g.id));
    }
  }

  Widget _syncAlert(Map<String, Object> problems) => IconButton(
        tooltip: tr('sync.problemTitle'),
        onPressed: () => _showSyncProblems(problems),
        icon: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.red.shade700,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Text('!!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, height: 1)),
        ),
      );

  Future<void> _showSyncProblems(Map<String, Object> problems) async {
    final retry = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.sync_problem, color: Colors.red.shade700, size: 36),
        title: Text(tr('sync.problemTitle')),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('sync.problemInfo')),
            const SizedBox(height: 12),
            for (final e in problems.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(appState.syncProblemLabel(e.key), style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(cloudErrorMessage(e.value),
                          style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
                    ]),
                  ),
                ]),
              ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('common.close'))),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.refresh),
            label: Text(tr('sync.retry')),
          ),
        ],
      ),
    );
    if (retry == true) await appState.retrySync();
  }

  Widget _syncIcon() {
    if (!appState.isCloud) return const SizedBox.shrink();
    switch (appState.syncStatus) {
      case SyncStatus.online:
        return Tooltip(message: tr('sync.done'), child: const Icon(Icons.cloud_done));
      case SyncStatus.connecting:
        return Tooltip(message: tr('sync.connecting'), child: const Icon(Icons.cloud_sync));
      case SyncStatus.offline:
        return IconButton(
          tooltip: tr('sync.offline'),
          icon: const Icon(Icons.cloud_off),
          onPressed: appState.retrySync,
        );
      case SyncStatus.off:
        return const SizedBox.shrink();
    }
  }

  Widget _mainScaffold(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final titles = [_homeTitle(), tr('tab.family'), tr('tab.deadlines')];
        Widget body;
        switch (_tab) {
          case 1:
            body = FamilyTab(onOpen: _openDetail, onAdd: (g) => _openAdd(fleetId: g));
            break;
          case 2:
            body = _deadlinesTab();
            break;
          default:
            body = _vehiclesTab();
        }
        final problems = appState.isCloud ? appState.syncProblems : const <String, Object>{};
        return Scaffold(
          appBar: AppBar(
            leading: problems.isEmpty ? null : _syncAlert(problems),
            title: Text(titles[_tab]),
            actions: [
              if (_tab == 0 && appState.homeVehicles.isNotEmpty)
                IconButton(
                  tooltip: tr('pdf.export'),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: () => exportPdf(context, _homeTitle(), appState.homeVehicles),
                ),
              if (_tab == 1 && _groupsWithVehicles().isNotEmpty)
                IconButton(
                  tooltip: tr('pdf.export'),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: _exportGroups,
                ),
              _syncIcon(),
              NotificationBell(onPressed: _openLog),
              IconButton(
                tooltip: tr('settings.title'),
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
            ],
          ),
          body: NotebookPage(child: body),
          floatingActionButton: _tab == 0
              ? FloatingActionButton.extended(
                  onPressed: () => _openAdd(),
                  icon: const Icon(Icons.add),
                  label: Text(tr('common.add')),
                )
              : null,
          bottomNavigationBar: _bottomBar(context),
        );
      },
    );
  }

  Widget _bottomBar(BuildContext context) {
    final theme = Theme.of(context);
    final nav = theme.navigationBarTheme;
    final nb = NotebookColors.of(context);
    Widget item(int i, IconData icon, IconData selectedIcon, Widget Function(Color) label, String semantics) {
      final sel = _tab == i;
      final color = sel ? Colors.white : Colors.white70;
      return Expanded(
        child: Semantics(
          selected: sel,
          button: true,
          label: semantics,
          excludeSemantics: true,
          child: InkWell(
            onTap: () => setState(() => _tab = i),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 64,
                  height: 32,
                  decoration: BoxDecoration(
                    color: sel ? (nav.indicatorColor ?? nb.paper) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(sel ? selectedIcon : icon,
                      color: sel ? theme.colorScheme.primary : Colors.white70),
                ),
                const SizedBox(height: 2),
                SizedBox(height: 34, child: Center(child: label(color))),
              ]),
            ),
          ),
        ),
      );
    }

    Widget oneLine(String text, Color color) => FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(text,
              maxLines: 1, style: TextStyle(fontFamily: handFont, fontSize: 16, color: color)),
        );

    return Material(
      color: nav.backgroundColor ?? nb.cover,
      child: SafeArea(
        top: false,
        child: Row(children: [
          item(
            0,
            Icons.garage_outlined,
            Icons.garage,
            (c) => FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(tr('tab.myTop'),
                    maxLines: 1,
                    style: TextStyle(fontFamily: handFont, fontSize: 12, height: 1, color: c)),
                Text(tr('tab.myBottom'),
                    maxLines: 1,
                    style: TextStyle(fontFamily: handFont, fontSize: 18, height: 1.05, color: c)),
              ]),
            ),
            tr('fleet.mine'),
          ),
          item(1, Icons.groups_outlined, Icons.groups, (c) => oneLine(tr('tab.family'), c),
              tr('tab.family')),
          item(2, Icons.event_outlined, Icons.event, (c) => oneLine(tr('tab.deadlines'), c),
              tr('tab.deadlines')),
        ]),
      ),
    );
  }

  String _homeTitle() {
    switch (appState.homeView) {
      case HomeView.mine:
        return tr('fleet.mine');
      case HomeView.favorites:
        return tr('fav.title');
      case HomeView.all:
        return tr('fav.allTitle');
    }
  }

  Widget _viewSelector() => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SegmentedButton<HomeView>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
                value: HomeView.all, icon: const Icon(Icons.garage_outlined), label: Text(tr('fav.viewAll'))),
            ButtonSegment(
                value: HomeView.favorites, icon: const Icon(Icons.star_outline), label: Text(tr('fav.viewFav'))),
          ],
          selected: {appState.homeView},
          onSelectionChanged: (s) => appState.setHomeView(s.first),
        ),
      );

  Widget _vehiclesTab() {
    final all = appState.homeVehicles;
    final favView = appState.homeView == HomeView.favorites;
    final list = _filter == null ? all : all.where((v) => v.type == _filter).toList();
    final hasGroupVehicles = appState.vehicles.any((v) => !appState.isMine(v));
    final limited = appState.limitedIds;
    return RefreshIndicator(
      onRefresh: appState.retrySync,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 96),
        children: [
          if (appState.favoritesOn) _viewSelector(),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(tr('filter.all', {'n': all.length})),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
              ),
              ...VehicleType.values.map((t) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      avatar: Icon(vehicleIcon(t), size: 18),
                      label: Text(
                          '${vehicleTypePlural(t)} (${all.where((v) => v.type == t).length})'),
                      selected: _filter == t,
                      onSelected: (_) => setState(() => _filter = t),
                    ),
                  )),
            ]),
          ),
          if (list.length > 1) sortOrderButton(context) else const SizedBox(height: 8),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Column(children: [
                Icon(favView ? Icons.star_outline : Icons.garage_outlined,
                    size: 80, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 12),
                Text(favView ? tr('fav.empty') : tr('home.empty'),
                    style: const TextStyle(fontSize: 26, fontFamily: handFont)),
                const SizedBox(height: 4),
                Text(favView ? tr('fav.emptyHint') : tr('home.emptyHint'), textAlign: TextAlign.center),
                if (all.isEmpty && hasGroupVehicles && !favView) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.groups_outlined),
                    label: Text(tr('home.groupsHint')),
                    onPressed: () => setState(() => _tab = 1),
                  ),
                ],
              ]),
            ),
          ...list.map((v) => VehicleCard(
                vehicle: v,
                changed: appState.hasUnreadChange(v.id),
                selected: _twoPane && v.id == _selectedId,
                limited: limited.contains(v.id),
                onTap: () => limited.contains(v.id)
                    ? requirePro(context,
                        reason: tr('pro.reasonLimited', {'n': AppState.freeVehicleLimit}))
                    : _openDetail(v, list.where((x) => !limited.contains(x.id)).toList()),
                onLongPress: () => moveVehicleSheet(context, v),
                badge: appState.homeView != HomeView.mine && !appState.isPersonal(v)
                    ? appState.fleetLabel(v)
                    : null,
                favorite: appState.isFavorite(v),
                onFavorite: appState.favoritesOn ? () => appState.toggleFavorite(v) : null,
              )),
          if (list.isNotEmpty && appState.isCloud && appState.data.groups.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                tr('home.longPressHint'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
              ),
            ),
        ],
      ),
    );
  }

  Widget _deadlinesTab() {
    final soonOnly = appState.deadlinesSoonOnly;
    final groups = <({Vehicle v, List<Deadline> ds})>[];
    var any = false;
    for (final v in appState.activeVehicles) {
      final all = v.activeDeadlines;
      if (all.isNotEmpty) any = true;
      final ds = (soonOnly ? all.where((d) => daysUntil(d.dueDate!) < dueWarnDays) : all).toList()
        ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
      if (ds.isNotEmpty) groups.add((v: v, ds: ds));
    }
    groups.sort((a, b) => a.ds.first.dueDate!.compareTo(b.ds.first.dueDate!));
    if (!any) {
      return Center(child: Text(tr('deadlines.empty')));
    }
    final showFleet = appState.isCloud && appState.data.groups.isNotEmpty;
    final scheme = Theme.of(context).colorScheme;
    final filter = Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Center(
        child: SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: false, label: Text(tr('deadlines.all'))),
            ButtonSegment(
                value: true,
                icon: const Icon(Icons.warning_amber, size: 18),
                label: Text(tr('deadlines.soon'))),
          ],
          selected: {soonOnly},
          onSelectionChanged: (sel) => appState.setDeadlinesSoonOnly(sel.first),
        ),
      ),
    );
    if (groups.isEmpty) {
      return ListView(padding: const EdgeInsets.fromLTRB(6, 8, 10, 24), children: [
        filter,
        Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(children: [
            Icon(Icons.check_circle_outline, size: 64, color: scheme.outline),
            const SizedBox(height: 10),
            Text(tr('deadlines.noneSoon'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: handFont, fontSize: 24)),
          ]),
        ),
      ]);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(6, 8, 10, 24),
      itemCount: groups.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return filter;
        final g = groups[index - 1];
        final name = g.v.name.isEmpty ? g.v.plate : g.v.name;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            InkWell(
              onTap: () => _openDetail(g.v),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Row(children: [
                  VehicleAvatar(vehicle: g.v, size: 44),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: handFont, fontSize: 22)),
                      if (showFleet)
                        Text(appState.fleetLabel(g.v),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    ]),
                  ),
                ]),
              ),
            ),
            const Divider(height: 1),
            for (var k = 0; k < g.ds.length; k++) ...[
              if (k > 0) Divider(height: 1, indent: 12, endIndent: 12, color: scheme.outlineVariant),
              InkWell(
                onTap: () => _openDetail(g.v),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(g.ds[k].dueLabel,
                              maxLines: 1,
                              softWrap: false,
                              style: const TextStyle(fontFamily: handFont, fontSize: 19)),
                        ),
                        Text(fmtDate(g.ds[k].dueDate),
                            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(due: g.ds[k].dueDate!, compact: true, twoLines: true),
                  ]),
                ),
              ),
            ],
          ]),
        );
      },
    );
  }
}
