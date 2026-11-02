import 'package:flutter_test/flutter_test.dart';
import 'package:myfleetmanager/services/ads_service.dart';

void main() {
  test('annunci solo per chi non è Pro, mai subito, non troppo spesso', () {
    final now = DateTime(2026, 11, 2, 12);
    int ago(Duration d) => now.subtract(d).millisecondsSinceEpoch;
    final old = AdsRules.newUser * 3;
    bool ok({bool session = true, bool pro = false, bool locked = false, Duration? first, Duration? last}) =>
        AdsRules.allowed(
          hasSession: session,
          pro: pro,
          locked: locked,
          firstSeen: ago(first ?? old),
          lastShown: last == null ? 0 : ago(last),
          now: now,
        );
    expect(ok(), isTrue);
    expect(ok(pro: true), isFalse);
    expect(ok(session: false), isFalse);
    expect(ok(locked: true), isFalse);
    expect(ok(first: AdsRules.newUser ~/ 2), isFalse);
    expect(ok(last: AdsRules.gap ~/ 2), isFalse);
    expect(ok(last: AdsRules.gap), isTrue);
    expect(AdsRules.allowed(hasSession: true, pro: false, locked: false, firstSeen: 0, lastShown: 0, now: now), isFalse);
  });

  test('10 annunci con premio sbloccano un veicolo, al massimo due', () {
    var s = (slots: 0, progress: 0);
    for (var i = 0; i < AdsRules.adsPerSlot - 1; i++) {
      s = AdsRules.afterReward(s.slots, s.progress);
    }
    expect(s, (slots: 0, progress: AdsRules.adsPerSlot - 1));
    s = AdsRules.afterReward(s.slots, s.progress);
    expect(s, (slots: 1, progress: 0));
    for (var i = 0; i < AdsRules.adsPerSlot; i++) {
      s = AdsRules.afterReward(s.slots, s.progress);
    }
    expect(s, (slots: 2, progress: 0));
    expect(AdsRules.afterReward(2, 0), (slots: 2, progress: 0));
  });
}
