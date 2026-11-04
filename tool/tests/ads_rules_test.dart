import 'package:flutter_test/flutter_test.dart';
import 'package:myfleetmanager/services/ads_service.dart';

void main() {
  test('annunci solo per chi non è Pro, almeno 2 ore tra due, al massimo 5 al giorno', () {
    final now = DateTime(2026, 11, 2, 12);
    int ago(Duration d) => now.subtract(d).millisecondsSinceEpoch;
    bool ok({bool session = true, bool pro = false, bool locked = false, Duration? last, int today = 0}) =>
        AdsRules.allowed(
          hasSession: session,
          pro: pro,
          locked: locked,
          firstSeen: ago(const Duration(minutes: 1)),
          lastShown: last == null ? 0 : ago(last),
          now: now,
          shownToday: today,
        );
    expect(AdsRules.gap, const Duration(hours: 2));
    expect(ok(), isTrue);
    expect(ok(pro: true), isFalse);
    expect(ok(session: false), isFalse);
    expect(ok(locked: true), isFalse);
    expect(ok(last: const Duration(minutes: 119)), isFalse);
    expect(ok(last: const Duration(hours: 2)), isTrue);
    expect(ok(last: const Duration(hours: 3), today: 4), isTrue);
    expect(ok(last: const Duration(hours: 3), today: 5), isFalse);
    expect(AdsRules.dayKey(DateTime(2026, 11, 2, 23, 59)), 20261102);
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

  test('4° e 5° veicolo scelti dall\'utente, i primi 3 restano fissi', () {
    final ids = ['a', 'b', 'c', 'd', 'e', 'f', 'g'];
    var p = AdsRules.plan(ids, excluded: {'b'}, base: 3, extra: 0, chosen: const []);
    expect(p.base, ['a', 'c', 'd']);
    expect(p.limited, {'b', 'e', 'f', 'g'});
    p = AdsRules.plan(ids, excluded: {'b'}, base: 3, extra: 2, chosen: const []);
    expect(p.slots, ['e', 'f']);
    p = AdsRules.plan(ids, excluded: {'b'}, base: 3, extra: 2, chosen: const ['g', '']);
    expect(p.slots, ['g', 'e']);
    expect(p.limited, {'b', 'f'});
    p = AdsRules.plan(ids, excluded: {'b'}, base: 3, extra: 1, chosen: const ['a', 'b', 'f']);
    expect(p.slots, ['e']);
    p = AdsRules.plan(['a', 'b'], excluded: const {}, base: 3, extra: 2, chosen: const ['x']);
    expect(p.slots, isEmpty);
    expect(p.limited, isEmpty);
  });

  test('4° e 5° veicolo si scelgono una volta sola', () {
    expect(AdsRules.slotLocked(const [], const ['e', 'f'], 0), isFalse);
    var chosen = AdsRules.choose(const [], const ['e', 'f'], 2, 0, 'g')!;
    expect(chosen, ['g', '']);
    expect(AdsRules.slotLocked(chosen, const ['g', 'e'], 0), isTrue);
    expect(AdsRules.slotLocked(chosen, const ['g', 'e'], 1), isFalse);
    expect(AdsRules.choose(chosen, const ['g', 'e'], 2, 0, 'f'), isNull);
    expect(AdsRules.choose(chosen, const ['g', 'e'], 2, 1, 'g'), isNull);
    chosen = AdsRules.choose(chosen, const ['g', 'e'], 2, 1, 'f')!;
    expect(chosen, ['g', 'f']);
    expect(AdsRules.slotLocked(['x', 'f'], const ['e', 'f'], 0), isFalse);
    expect(AdsRules.choose(const ['', 'e'], const ['f', 'e'], 2, 0, 'e'), isNull);
    expect(AdsRules.choose(const [], const ['e', 'f'], 2, 1, 'e'), ['', 'e']);
    expect(AdsRules.mergeChosen(const ['', 'f'], const ['g', 'h']), ['g', 'f']);
    expect(AdsRules.mergeChosen(const [], const ['g']), ['g']);
  });
}
