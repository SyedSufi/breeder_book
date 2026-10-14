import 'package:breeder_book/core/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ageText formats days, months and years', () {
    expect(ageText('2026-03-01', now: DateTime(2026, 3, 21)), '20d');
    expect(ageText('2026-01-10', now: DateTime(2026, 6, 15)), '5m');
    expect(ageText('2024-01-01', now: DateTime(2026, 3, 15)), '2y 2m');
    expect(ageText(null), '');
  });

  test('showDate formats ISO dates', () {
    expect(showDate('2024-03-05'), '5 Mar 2024');
    expect(showDate(null), '-');
  });
}
