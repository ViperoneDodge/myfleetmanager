import 'package:flutter/material.dart';

import '../l10n.dart';
import '../main.dart';
import '../services/ads_service.dart';
import '../services/app_state.dart' show AppState;
import '../theme.dart';
import '../widgets/common.dart';

Future<bool> requirePro(BuildContext context, {String? reason}) async {
  if (appState.isPro) return true;
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProScreen(reason: reason)));
  return appState.isPro;
}

Future<bool> ensureCanAddVehicle(BuildContext context) async {
  if (appState.canAddVehicle) return true;
  return requirePro(context,
      reason: tr('pro.reasonLimit', {'n': appState.freeVehicleLimit}));
}

class ProScreen extends StatelessWidget {
  final String? reason;
  const ProScreen({super.key, this.reason});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final pro = appState.pro;
        final product = pro.product;
        final benefits = <(IconData, String)>[
          (Icons.all_inclusive, tr('pro.benefitVehicles')),
          (Icons.local_shipping_outlined, tr('pro.benefitTypes')),
          (Icons.description_outlined, tr('pro.benefitDocs')),
          (Icons.build_circle_outlined, tr('pro.benefitMaint')),
          (Icons.tune, tr('pro.benefitTech')),
          (Icons.block, tr('pro.benefitNoAds')),
          (Icons.favorite_outline, tr('pro.benefitSupport')),
        ];
        return Scaffold(
          appBar: AppBar(
            title: const Text('MyFleetManager Pro'),
            actions: [
              if (appState.rewardsAvailable && appState.rewardSlots < AdsRules.maxSlots)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                      child: Text('${appState.rewardProgress}/${AdsRules.adsPerSlot}',
                          style: const TextStyle(color: Color(0xFF0257C3), fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
            ],
          ),
          body: NotebookPage(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 16, 12, 32),
              children: [
                Icon(Icons.workspace_premium, size: 72, color: Colors.amber.shade700),
                const SizedBox(height: 8),
                Text(
                  appState.isPro ? tr('pro.active') : tr('pro.title'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (reason != null && !appState.isPro) ...[
                  const SizedBox(height: 10),
                  Card(
                    color: scheme.tertiaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(reason!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.onTertiaryContainer)),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(tr('pro.subtitle'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                ...benefits.map((b) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(b.$1, color: scheme.primary),
                      title: Text(b.$2),
                      trailing: Icon(Icons.check_circle, color: Colors.green.shade600),
                    )),
                const SizedBox(height: 8),
                Text(tr('pro.freeInfo', {'n': appState.freeVehicleLimit}),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: scheme.outline)),
                const SizedBox(height: 20),
                if (appState.isPro)
                  Center(
                    child: Chip(
                      avatar: const Icon(Icons.verified, color: Colors.green),
                      label: Text(appState.devPro && !appState.purchasedPro
                          ? tr('pro.activeDev')
                          : tr('pro.activeThanks')),
                    ),
                  )
                else ...[
                  FilledButton.icon(
                    onPressed: (product == null || pro.busy)
                        ? null
                        : () async {
                            final ok = await pro.buy();
                            if (!ok && context.mounted) {
                              showSnack(context, pro.lastError ?? tr('pro.unavailable'));
                            }
                          },
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: pro.busy
                        ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.shopping_cart_outlined),
                    label: Text(product == null
                        ? tr('pro.buy')
                        : tr('pro.buyPrice', {'price': product.price})),
                  ),
                  if (product == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(tr('pro.unavailable'),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: scheme.outline)),
                    ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: pro.storeAvailable
                        ? () async {
                            await pro.restore();
                            if (context.mounted) showSnack(context, tr('pro.restoring'));
                          }
                        : null,
                    child: Text(tr('pro.restore')),
                  ),
                  if (appState.rewardsAvailable) const RewardSlots(),
                ],
                const SizedBox(height: 8),
                Text(tr('pro.oneTime'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: handFont, fontSize: 18)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class RewardSlots extends StatefulWidget {
  const RewardSlots({super.key});

  @override
  State<RewardSlots> createState() => _RewardSlotsState();
}

class _RewardSlotsState extends State<RewardSlots> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (appState.rewardSlots < AdsRules.maxSlots) AdsService.instance.preloadRewarded();
  }

  Future<void> _watch() async {
    setState(() => _busy = true);
    final r = await appState.watchRewardAd();
    if (!mounted) return;
    setState(() => _busy = false);
    switch (r) {
      case 'unlocked':
        showSnack(context, tr('reward.done', {'n': appState.freeVehicleLimit}));
        break;
      case 'noReward':
        showSnack(context, tr('reward.noReward'));
        break;
      case 'notReady':
        showSnack(context, tr('reward.notReady'));
        break;
    }
  }

  Widget _slot(BuildContext context, int index) {
    final scheme = Theme.of(context).colorScheme;
    final n = AppState.baseVehicleLimit + index + 1;
    final done = appState.rewardSlots > index;
    final current = appState.rewardSlots == index;
    final ads = AdsService.instance;
    final loading = _busy || (current && !ads.rewardedReady && ads.rewardedLoading);
    Widget trailing;
    if (done) {
      trailing = Chip(
        avatar: const Icon(Icons.check_circle, color: Colors.green, size: 18),
        label: Text(tr('reward.unlocked')),
      );
    } else if (current) {
      trailing = FilledButton.tonalIcon(
        onPressed: loading ? null : _watch,
        icon: loading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.play_circle_outline),
        label: Text(tr('reward.watch', {'done': appState.rewardProgress, 'total': AdsRules.adsPerSlot})),
      );
    } else {
      trailing = const FilledButton.tonal(onPressed: null, child: Icon(Icons.lock_outline, size: 18));
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Row(children: [
          Icon(Icons.directions_car_outlined, color: done || current ? scheme.primary : scheme.outline),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('reward.slot', {'n': n}), style: const TextStyle(fontWeight: FontWeight.w600)),
              if (current)
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 8),
                  child: LinearProgressIndicator(
                    value: appState.rewardProgress / AdsRules.adsPerSlot,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                )
              else if (!done)
                Text(tr('reward.locked', {'n': n - 1}), style: TextStyle(fontSize: 12, color: scheme.outline)),
            ]),
          ),
          trailing,
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(tr('reward.title'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(tr('reward.info', {'n': AdsRules.adsPerSlot}),
            textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        for (var i = 0; i < AdsRules.maxSlots; i++) _slot(context, i),
      ]),
    );
  }
}
