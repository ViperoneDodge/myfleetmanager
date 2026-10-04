import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n.dart';
import '../models.dart';

final DateFormat dateFmt = DateFormat('dd/MM/yyyy');

String fmtDate(DateTime? d) => d == null ? '—' : dateFmt.format(d);

String fmtKm(int km) {
  final s = km.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '$b km';
}

int daysUntil(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  return day.difference(today).inDays;
}

class DueStatus {
  final Color color;
  final String text;
  final IconData icon;
  final String line1;
  final String line2;
  DueStatus(this.color, this.text, this.icon, {String? line1, this.line2 = ''})
      : line1 = line1 ?? text;
}

const int dueWarnDays = 15;
const Color dueRed = Color(0xFFC62828);
const Color dueYellow = Color(0xFFB07A00);
const Color dueGreen = Color(0xFF2E7D32);

(String, String) _splitAround(String key, int n) {
  const mark = '\u0001';
  final t = tr(key, {'n': mark});
  final i = t.indexOf(mark);
  if (i < 0) return (tr(key, {'n': n}), '');
  final before = t.substring(0, i).trim();
  final after = t.substring(i + mark.length);
  if (before.isNotEmpty) return (before, '$n$after'.trim());
  final rest = after.trim();
  final sp = rest.indexOf(' ');
  if (sp < 0) return ('$n$after'.trim(), '');
  return ('$n ${rest.substring(0, sp)}', rest.substring(sp + 1).trim());
}

(String, String) _splitWords(String t) {
  final sp = t.indexOf(' ');
  if (sp < 0) return (t, '');
  return (t.substring(0, sp), t.substring(sp + 1));
}

DueStatus dueStatus(DateTime due) {
  final n = daysUntil(due);
  final Color color;
  final IconData icon;
  final String text;
  final (String, String) lines;
  if (n < 0) {
    color = dueRed;
    icon = Icons.error;
    if (n == -1) {
      text = tr('due.yesterday');
      lines = _splitWords(text);
    } else {
      text = tr('due.expiredDays', {'n': -n});
      lines = _splitAround('due.expiredDays', -n);
    }
  } else {
    color = n < dueWarnDays ? dueYellow : dueGreen;
    icon = n < dueWarnDays ? Icons.warning_amber : Icons.check_circle;
    if (n == 0) {
      text = tr('due.today');
      lines = _splitWords(text);
    } else if (n == 1) {
      text = tr('due.tomorrow');
      lines = _splitWords(text);
    } else {
      text = tr('due.inDays', {'n': n});
      lines = _splitAround('due.inDays', n);
    }
  }
  return DueStatus(color, text, icon, line1: lines.$1, line2: lines.$2);
}

IconData vehicleIcon(VehicleType t) {
  switch (t) {
    case VehicleType.auto:
      return Icons.directions_car;
    case VehicleType.moto:
      return Icons.two_wheeler;
    case VehicleType.furgone:
      return Icons.airport_shuttle;
    case VehicleType.camion:
      return Icons.local_shipping;
    case VehicleType.rimorchio:
      return Icons.rv_hookup;
    case VehicleType.agricolo:
      return Icons.agriculture;
  }
}

class VehicleAvatar extends StatelessWidget {
  final Vehicle vehicle;
  final double size;
  const VehicleAvatar({super.key, required this.vehicle, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final bytes = vehicle.photoBytes;
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Container(
        width: size,
        height: size,
        color: scheme.primaryContainer,
        child: bytes != null
            ? Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true)
            : Padding(
                padding: EdgeInsets.all(size * 0.1),
                child: VehicleSilhouette(type: vehicle.type, color: scheme.onPrimaryContainer),
              ),
      ),
    );
  }
}

class VehicleSilhouette extends StatelessWidget {
  final VehicleType type;
  final Color color;
  const VehicleSilhouette({super.key, required this.type, required this.color});

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/vehicles/${type.name}.png',
        color: color,
        colorBlendMode: BlendMode.srcIn,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => FittedBox(child: Icon(vehicleIcon(type), color: color)),
      );
}

class StatusChip extends StatelessWidget {
  final DateTime due;
  final bool compact;
  final bool twoLines;
  const StatusChip({super.key, required this.due, this.compact = false, this.twoLines = false});

  @override
  Widget build(BuildContext context) {
    final s = dueStatus(due);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = dark ? Color.lerp(s.color, Colors.white, 0.4)! : s.color;
    final style = TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600, height: 1.25);
    final split = twoLines && s.line2.isNotEmpty;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: split ? 4 : 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(split ? 12 : 20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(s.icon, size: 14, color: color),
        const SizedBox(width: 4),
        split
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(s.line1, style: style), Text(s.line2, style: style)],
              )
            : Text(s.text, style: style),
      ]),
    );
  }
}

void showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;

  final VoidCallback? onLongPress;

  final String? badge;

  final bool selected;

  final bool limited;
  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.onTap,
    this.onLongPress,
    this.badge,
    this.selected = false,
    this.limited = false,
  });

  static const ColorFilter _greyFilter = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 0.55, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final v = vehicle;
    final next = limited ? null : v.nextDeadline;
    final scheme = Theme.of(context).colorScheme;
    final card = Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      clipBehavior: Clip.antiAlias,
      color: selected ? scheme.secondaryContainer : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            VehicleAvatar(vehicle: v, size: 64),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(v.name.isEmpty ? tr('vehicle.noName') : v.name,
                    style: const TextStyle(fontSize: 22, fontFamily: 'PatrickHand', height: 1.1),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(vehicleIcon(v.type), size: 16),
                  const SizedBox(width: 4),
                  Text(v.plate.isEmpty ? '—' : v.plate,
                      style: const TextStyle(letterSpacing: 1.2)),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: scheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.groups, size: 13, color: scheme.onTertiaryContainer),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(badge!,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11, color: scheme.onTertiaryContainer)),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 6),
                if (limited)
                  Row(children: [
                    Icon(Icons.lock_outline, size: 14, color: scheme.outline),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(tr('pro.limitedCard'),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: scheme.outline)),
                    ),
                  ])
                else if (next != null)
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text('${next.dueLabel}:', style: const TextStyle(fontSize: 12)),
                      StatusChip(due: next.dueDate!, compact: true),
                    ],
                  )
                else
                  Text(tr('vehicle.noDeadlines'),
                      style: TextStyle(
                          fontSize: 12, color: Theme.of(context).colorScheme.outline)),
              ]),
            ),
            Icon(limited ? Icons.lock_outline : Icons.chevron_right),
          ]),
        ),
      ),
    );
    return limited ? ColorFiltered(colorFilter: _greyFilter, child: card) : card;
  }
}
