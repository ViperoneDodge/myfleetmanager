import 'package:flutter/material.dart';

import '../l10n.dart';
import '../main.dart';

class WebProGate extends StatelessWidget {
  const WebProGate({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final who = appState.session?.email ?? appState.session?.displayName ?? '';
    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset('assets/icon.png', width: 76, height: 76),
                  ),
                  const SizedBox(height: 16),
                  Text(tr('web.proOnlyTitle'),
                      textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Text(tr('web.proOnly'), textAlign: TextAlign.center),
                  if (who.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(who,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  ],
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () => appState.logout(),
                    icon: const Icon(Icons.logout),
                    label: Text(tr('settings.logout')),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
