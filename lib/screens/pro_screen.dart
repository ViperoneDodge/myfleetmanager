import 'package:flutter/material.dart';

import '../l10n.dart';
import '../main.dart';
import '../services/app_state.dart';
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
      reason: tr('pro.reasonLimit', {'n': AppState.freeVehicleLimit}));
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
          (Icons.favorite_outline, tr('pro.benefitSupport')),
        ];
        return Scaffold(
          appBar: AppBar(title: const Text('MyFleetManager Pro')),
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
                Text(tr('pro.freeInfo', {'n': AppState.freeVehicleLimit}),
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
