import 'package:flutter_expensetracker/domain/models/recurring_payment.dart';
import 'package:flutter_expensetracker/ui/recurring/view_models/recurring_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/fakes/fake_repositories.dart';

void main() {
  final now = DateTime(2026, 11, 25, 15);

  RecurringViewModel build() {
    final vm = RecurringViewModel(
      transactionRepository: instantTransactionRepository(now: now),
      clock: () => now,
    );
    addTearDown(vm.dispose);
    return vm;
  }

  test('splits repeat payments by kind and adds up the month', () async {
    final vm = build();
    await vm.load.execute();

    expect(vm.payments, isNotEmpty);
    expect(
      vm.ofKind(RecurringKind.subscription).map((p) => p.title),
      containsAll(['DStv Compact', 'MTN airtime']),
    );
    expect(
      vm.monthlyTotal,
      closeTo(
        RecurringKind.values.fold<double>(
          0,
          (sum, k) => sum + vm.monthlyTotalOf(k),
        ),
        0.001,
      ),
    );
  });

  test('lists what is due soon or late, soonest first', () async {
    final vm = build();
    await vm.load.execute();

    final due = vm.dueSoon;
    expect(due.map((p) => p.title), contains('DStv Compact'));
    for (var i = 1; i < due.length; i++) {
      expect(due[i - 1].nextDue.isAfter(due[i].nextDue), isFalse);
    }
  });
}
