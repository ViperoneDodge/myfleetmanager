import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n.dart';
import '../services/registration_reader.dart';
import '../services/tyres.dart';
import 'common.dart';

Map<String, String> ocrFields() => {
      'plate': tr('edit.plate'),
      'reg': tr('vehicle.regDate'),
      'vin': tr('tech.vin'),
      'power': tr('tech.power'),
      'cc': tr('tech.engine'),
      'tyres': tr('tech.tyres'),
    };

String ocrTyreText(RegistrationData data) =>
    TyreSet.format(TyreSet.byRim(data.tyres, (r) => tr('tyre.rim', {'n': r})));

List<({String key, String value})> _rows(RegistrationData data) => [
      if (data.plate != null) (key: 'plate', value: data.plate!),
      if (data.registrationDate != null) (key: 'reg', value: fmtDate(data.registrationDate)),
      if (data.vin != null) (key: 'vin', value: data.vin!),
      if (data.powerKw != null) (key: 'power', value: data.powerKw!),
      if (data.engineCc != null) (key: 'cc', value: data.engineCc!),
      if (data.tyres.isNotEmpty) (key: 'tyres', value: ocrTyreText(data)),
    ];

Future<Set<String>?> showOcrReview(BuildContext context, RegistrationData data, String raw) async {
  final fields = ocrFields();
  final chosen = _rows(data).map((r) => r.key).toSet();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        title: Text(tr('ocr.found')),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                border: Border.all(color: const Color(0xFFB07A00)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFB07A00)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(tr('ocr.disclaimer'),
                      style: const TextStyle(fontSize: 13, color: Color(0xFF5A3E00), fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            Text(data.isEmpty ? tr('ocr.none') : tr('ocr.foundHint'), style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            Text(tr('ocr.assignHint', {'button': tr('ocr.rawText')}),
                style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            ..._rows(data).map((r) => CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: chosen.contains(r.key),
                  onChanged: (b) => setSt(() => b == true ? chosen.add(r.key) : chosen.remove(r.key)),
                  title: Text(r.value),
                  subtitle: Text(fields[r.key]!),
                )),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => showOcrRawText(ctx, raw, onAssign: (field, value) {
              if (!RegistrationReader.apply(data, field, value)) return false;
              setSt(() => chosen.add(field));
              return true;
            }),
            child: Text(tr('ocr.rawText')),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('common.cancel'))),
          FilledButton(
            onPressed: chosen.isEmpty ? null : () => Navigator.pop(ctx, true),
            child: Text(tr('ocr.apply')),
          ),
        ],
      ),
    ),
  );
  return ok == true && chosen.isNotEmpty ? chosen : null;
}

Future<bool> ocrAssign(BuildContext context, String selected, bool Function(String field, String value) onAssign) async {
  final fields = ocrFields();
  final field = await showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(tr('ocr.assignTitle')),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(selected,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
        ),
        for (final e in fields.entries)
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, e.key), child: Text(e.value)),
      ],
    ),
  );
  if (field == null || !context.mounted) return false;
  final controller = TextEditingController(text: RegistrationReader.propose(field, selected));
  String? error;
  final done = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) {
        void confirm() {
          if (onAssign(field, controller.text)) {
            Navigator.pop(ctx, true);
          } else {
            setSt(() => error = tr('ocr.assignBad', {'field': fields[field]!}));
          }
        }

        return AlertDialog(
          title: Text(fields[field]!),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => confirm(),
            decoration: InputDecoration(
              helperText: tr('ocr.checkValue'),
              errorText: error,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('common.cancel'))),
            FilledButton(onPressed: confirm, child: Text(tr('common.ok'))),
          ],
        );
      },
    ),
  );
  return done == true;
}

Future<void> showOcrRawText(BuildContext context, String raw,
        {bool Function(String field, String value)? onAssign}) =>
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('ocr.rawText')),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              raw.trim().isEmpty ? '—' : raw.trim(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              contextMenuBuilder: (menuCtx, state) {
                final value = state.textEditingValue;
                final selected = value.selection.isValid && !value.selection.isCollapsed
                    ? value.selection.textInside(value.text).trim()
                    : '';
                return AdaptiveTextSelectionToolbar.buttonItems(
                  anchors: state.contextMenuAnchors,
                  buttonItems: [
                    if (onAssign != null && selected.isNotEmpty)
                      ContextMenuButtonItem(
                        label: tr('ocr.assign'),
                        onPressed: () async {
                          ContextMenuController.removeAny();
                          if (await ocrAssign(ctx, selected, onAssign) && ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                        },
                      ),
                    ...state.contextMenuButtonItems,
                  ],
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: raw));
              showSnack(ctx, tr('ocr.rawCopied'));
            },
            child: Text(tr('common.copy')),
          ),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.ok'))),
        ],
      ),
    );
