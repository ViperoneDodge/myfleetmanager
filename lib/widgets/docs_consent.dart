import 'package:flutter/material.dart';

import '../l10n.dart';
import '../main.dart';

Future<void> askDocsConsent(BuildContext context, {bool force = false}) async {
  if (!appState.isCloud || (!force && appState.docsConsent != null)) return;
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.cloud_upload_outlined),
      title: Text(tr('docs.consentTitle')),
      content: SingleChildScrollView(child: Text(tr('docs.consentBody'))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('docs.consentNo'))),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('docs.consentYes'))),
      ],
    ),
  );
  if (ok != null) await appState.setDocsConsent(ok);
}
