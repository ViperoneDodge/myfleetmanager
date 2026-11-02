import 'package:flutter_test/flutter_test.dart';
import 'package:myfleetmanager/services/ads_service.dart';

void main() {
  test('annunci solo per chi non è Pro, mai il primo giorno, al massimo ogni 4 ore', () {
    final now = DateTime(2026, 11, 2, 12);
    int ago(Duration d) => now.subtract(d).millisecondsSinceEpoch;
    bool ok({bool session = true, bool pro = false, bool locked = false, Duration first = const Duration(days: 3), Duration? last}) =>
        AdsRules.allowed(
          hasSession: session,
          pro: pro,
          locked: locked,
          firstSeen: ago(first),
          lastShown: last == null ? 0 : ago(last),
          now: now,
        );
    expect(ok(), isTrue);
    expect(ok(pro: true), isFalse);
    expect(ok(session: false), isFalse);
    expect(ok(locked: true), isFalse);
    expect(ok(first: const Duration(hours: 5)), isFalse);
    expect(ok(last: const Duration(hours: 3)), isFalse);
    expect(ok(last: const Duration(hours: 4)), isTrue);
    expect(AdsRules.allowed(hasSession: true, pro: false, locked: false, firstSeen: 0, lastShown: 0, now: now), isFalse);
  });
}
