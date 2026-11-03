import 'package:flutter_test/flutter_test.dart';
import 'package:myfleetmanager/widgets/common.dart';

void main() {
  test('anni interi tra due date, in entrambe le direzioni', () {
    expect(fullYearsBetween(DateTime(2026, 11, 3), DateTime(2028, 11, 4)), 2);
    expect(fullYearsBetween(DateTime(2026, 11, 3), DateTime(2029, 11, 2)), 2);
    expect(fullYearsBetween(DateTime(2026, 11, 3), DateTime(2029, 11, 3)), 3);
    expect(fullYearsBetween(DateTime(2031, 5, 1), DateTime(2026, 11, 3)), 4);
    expect(yearsAfterDays, 730);
  });
}
