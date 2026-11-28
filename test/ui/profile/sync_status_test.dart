import 'package:flutter/material.dart';
import 'package:flutter_expensetracker/data/repositories/settings/settings_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/repositories/sync/sync_repository.dart';
import 'package:flutter_expensetracker/ui/core/themes/theme.dart';
import 'package:flutter_expensetracker/ui/profile/view_models/profile_view_model.dart';
import 'package:flutter_expensetracker/ui/profile/widgets/sync_status_card.dart';
import 'package:flutter_expensetracker/utils/dates.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/fakes/fake_repositories.dart';

void main() {
  final now = DateTime(2026, 11, 28, 10, 30);

  test('formatAgo reads naturally', () {
    expect(formatAgo(now, now), 'just now');
    expect(
      formatAgo(now.subtract(const Duration(minutes: 5)), now),
      '5 min ago',
    );
    expect(formatAgo(DateTime(2026, 11, 28, 7, 5), now), 'at 07:05');
    expect(formatAgo(DateTime(2026, 11, 25, 9), now), 'on 25 Nov');
  });

  test('Profile follows the sync status and can sync now', () async {
    final sync = FakeSyncRepository();
    final vm = ProfileViewModel(
      transactionRepository: instantTransactionRepository(),
      authRepository: instantAuthRepository(signedIn: true),
      settingsRepository: SettingsRepositoryLocalFake(),
      syncRepository: sync,
      clock: () => now,
    );
    addTearDown(vm.dispose);
    var notified = 0;
    vm.addListener(() => notified++);

    sync.status = SyncStatus.failed;
    expect(vm.syncStatus, SyncStatus.failed);
    expect(notified, 1);

    await vm.syncNow.execute();
    expect(sync.syncs, 1);
  });

  Future<void> pumpCard(WidgetTester tester, SyncStatus status) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SyncStatusCard(
              status: status,
              lastSyncedAt: now.subtract(const Duration(minutes: 2)),
              now: now,
              onSyncNow: () {},
            ),
          ),
        ),
      );

  testWidgets('the card explains each state', (tester) async {
    await pumpCard(tester, SyncStatus.idle);
    expect(find.text('Saved online'), findsOneWidget);
    expect(find.text('Last synced 2 min ago'), findsOneWidget);

    await pumpCard(tester, SyncStatus.failed);
    await tester.pumpAndSettle();
    expect(find.text('Waiting for connection'), findsOneWidget);

    await pumpCard(tester, SyncStatus.syncing);
    await tester.pumpAndSettle();
    final button = tester.widget<TextButton>(find.byType(TextButton));
    expect(button.onPressed, isNull);
  });
}
