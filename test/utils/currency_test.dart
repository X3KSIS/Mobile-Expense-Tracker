import 'package:flutter_expensetracker/utils/currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('currency', () {
    test('formatZmw uses ZMW prefix, separators and two decimals', () {
      expect(formatZmw(1234), 'ZMW 1,234.00');
      expect(formatZmw(0.5), 'ZMW 0.50');
      expect(formatZmw(-640), '-ZMW 640.00');
    });

    test('formatZmwSigned adds + for income and - for expenses', () {
      expect(formatZmwSigned(12500, isIncome: true), '+ZMW 12,500.00');
      expect(formatZmwSigned(640, isIncome: false), '-ZMW 640.00');
    });

    test('formatWhole drops decimals', () {
      expect(formatWhole(12500), '12,500');
      expect(formatWhole(7680.4), '7,680');
    });

    test('splitMoney separates whole part and decimals', () {
      final parts = splitMoney(4820);
      expect(parts.whole, '4,820');
      expect(parts.decimals, '.00');

      final negative = splitMoney(-1234.5);
      expect(negative.whole, '-1,234');
      expect(negative.decimals, '.50');
    });
  });
}
