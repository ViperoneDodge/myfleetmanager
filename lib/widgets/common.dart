import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';

final DateFormat dateFmt = DateFormat('dd/MM/yyyy');

String fmtDate(DateTime? d) => d == null ? '—' : dateFmt.format(d);

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
  DueStatus(this.color, this.text, this.icon);
}

DueStatus dueStatus(DateTime due) {
  final n = daysUntil(due);
  if (n < 0) {
    return DueStatus(Colors.red.shade700,
        n == -1 ? 'Scaduta ieri' : 'Scaduta da ${-n} giorni', Icons.error);
  }
  if (n == 0) return DueStatus(Colors.red.shade700, 'Scade oggi', Icons.error);
  if (n == 1) return DueStatus(Colors.deepOrange, 'Scade domani', Icons.warning_amber);
  if (n <= 7) return DueStatus(Colors.deepOrange, 'Tra $n giorni', Icons.warning_amber);
  if (n <= 30) return DueStatus(Colors.orange.shade800, 'Tra $n giorni', Icons.schedule);
  return DueStatus(Colors.green.shade700, 'Tra $n giorni', Icons.check_circle);
}

IconData vehicleIcon(VehicleType t) =>
    t == VehicleType.moto ? Icons.two_wheeler : Icons.directions_car;

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
            : Icon(vehicleIcon(vehicle.type),
                size: size * 0.55, color: scheme.onPrimaryContainer),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final DateTime due;
  final bool compact;
  const StatusChip({super.key, required this.due, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final s = dueStatus(due);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: 3),
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(s.icon, size: 14, color: s.color),
        const SizedBox(width: 4),
        Text(s.text,
            style: TextStyle(color: s.color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

void showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}
