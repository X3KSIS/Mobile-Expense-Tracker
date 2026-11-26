import 'package:flutter_expensetracker/utils/dates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ordinal uses st, nd, rd and th, with 11th to 13th', () {
    expect([1, 2, 3, 4, 11, 12, 13, 21, 22, 23, 28].map(ordinal), [
      '1st',
      '2nd',
      '3rd',
      '4th',
      '11th',
      '12th',
      '13th',
      '21st',
      '22nd',
      '23rd',
      '28th',
    ]);
  });

  test('formatDayMonth shows the day and short month', () {
    expect(formatDayMonth(DateTime(2026, 12, 25)), '25 Dec');
  });
}
