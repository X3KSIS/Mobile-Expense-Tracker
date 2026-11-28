import 'package:flutter/material.dart';
import 'package:flutter_expensetracker/data/repositories/app_lock/app_lock_repository.dart';
import 'package:flutter_expensetracker/data/repositories/app_lock/app_lock_repository_local_fake.dart';
import 'package:flutter_expensetracker/ui/app_lock/view_models/app_lock_view_model.dart';
import 'package:flutter_expensetracker/ui/app_lock/widgets/app_lock_gate.dart';
import 'package:flutter_expensetracker/ui/core/themes/theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<AppLockViewModel> pumpGate(
    WidgetTester tester,
    AppLockRepositoryLocalFake repo,
  ) async {
    final vm = AppLockViewModel(appLockRepository: repo);
    addTearDown(vm.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => AppLockGate(viewModel: vm, child: child!),
        home: const Scaffold(body: Text('Balance ZMW 2,500.00')),
      ),
    );
    return vm;
  }

  testWidgets('a locked app prompts at once and opens on success', (
    tester,
  ) async {
    final repo = AppLockRepositoryLocalFake(locked: true);
    await pumpGate(tester, repo);

    expect(find.text('Expense Tracker is locked'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(repo.prompts, 1);
    expect(repo.isLocked, isFalse);
    expect(find.text('Expense Tracker is locked').hitTestable(), findsNothing);
    expect(find.text('Balance ZMW 2,500.00').hitTestable(), findsOneWidget);
  });

  testWidgets('closing the prompt keeps the lock; Unlock asks again', (
    tester,
  ) async {
    final repo = AppLockRepositoryLocalFake(
      locked: true,
      problem: AppLockProblem.cancelled,
    );
    await pumpGate(tester, repo);
    await tester.pumpAndSettle();
    expect(repo.prompts, 1);
    expect(repo.isLocked, isTrue);
    expect(find.text('Balance ZMW 2,500.00').hitTestable(), findsNothing);

    repo.problem = null;
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(repo.prompts, 2);
    expect(repo.isLocked, isFalse);
  });

  testWidgets('too many tries says so', (tester) async {
    final repo = AppLockRepositoryLocalFake(
      locked: true,
      problem: AppLockProblem.lockedOut,
    );
    await pumpGate(tester, repo);
    await tester.pumpAndSettle();
    expect(
      find.text('Too many tries. Wait a moment, then try again.'),
      findsOneWidget,
    );
  });

  testWidgets('locking later covers the app and prompts once', (tester) async {
    final repo = AppLockRepositoryLocalFake(problem: AppLockProblem.cancelled);
    await pumpGate(tester, repo);
    await tester.pumpAndSettle();
    expect(repo.prompts, 0);
    expect(find.text('Balance ZMW 2,500.00').hitTestable(), findsOneWidget);

    repo.lock();
    await tester.pump();
    expect(
      find.text('Expense Tracker is locked').hitTestable(),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    expect(repo.prompts, 1);
  });
}
