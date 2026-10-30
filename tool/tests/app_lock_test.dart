import 'package:flutter_test/flutter_test.dart';
import 'package:myfleetmanager/services/app_lock.dart';

void main() {
  test('blocco solo se attivo e dopo almeno un minuto fuori dall\'app', () {
    final t = DateTime(2026, 10, 31, 9, 0, 0);
    expect(AppLock.shouldLock(enabled: true, awaySince: t, now: t.add(const Duration(seconds: 59))), isFalse);
    expect(AppLock.shouldLock(enabled: true, awaySince: t, now: t.add(const Duration(minutes: 1))), isTrue);
    expect(AppLock.shouldLock(enabled: false, awaySince: t, now: t.add(const Duration(hours: 1))), isFalse);
    expect(AppLock.shouldLock(enabled: true, awaySince: null, now: t), isFalse);
  });
}
