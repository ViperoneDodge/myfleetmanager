import 'package:flutter/material.dart';

import '../l10n.dart';
import '../main.dart';
import '../widgets/common.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    final ok = await appState.unlockApp();
    if (!ok && mounted) setState(() => _failed = true);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: const Color(0xFF0B2A5B),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const AppName(size: 40),
                const SizedBox(height: 36),
                const Icon(Icons.lock_outline, size: 64, color: Colors.white),
                const SizedBox(height: 14),
                Text(tr('lock.title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                if (_failed) ...[
                  const SizedBox(height: 8),
                  Text(tr('lock.retry'),
                      textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                ],
                const SizedBox(height: 28),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0257C3),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  ),
                  onPressed: _unlock,
                  icon: const Icon(Icons.fingerprint),
                  label: Text(tr('lock.unlock')),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
