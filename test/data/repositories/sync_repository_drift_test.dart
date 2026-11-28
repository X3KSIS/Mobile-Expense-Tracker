import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_expensetracker/data/repositories/budget/budget_repository_drift.dart';
import 'package:flutter_expensetracker/data/repositories/category/default_categories.dart';
import 'package:flutter_expensetracker/data/repositories/detected_payment/detected_payment_repository_notifications.dart';
import 'package:flutter_expensetracker/data/repositories/settings/settings_repository_drift.dart';
import 'package:flutter_expensetracker/data/repositories/sync/sync_repository.dart';
import 'package:flutter_expensetracker/data/repositories/sync/sync_repository_drift.dart';
import 'package:flutter_expensetracker/data/repositories/transaction/transaction_repository_drift.dart';
import 'package:flutter_expensetracker/data/services/database/app_database.dart';
import 'package:flutter_expensetracker/data/services/notification_listener_client.dart';
import 'package:flutter_expensetracker/data/services/privacy_screen_service.dart';
import 'package:flutter_expensetracker/domain/models/budget.dart';
import 'package:flutter_expensetracker/domain/models/money_message.dart';
import 'package:flutter_expensetracker/domain/models/transaction.dart';
import 'package:flutter_expensetracker/domain/models/transaction_draft.dart';
import 'package:flutter_expensetracker/domain/models/wallet.dart';
import 'package:flutter_expensetracker/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/fakes/fake_remote_store.dart';

/// One phone: its own database, repositories and sync, sharing a server.
class _Device {
  _Device(FakeRemoteStore remote, {required this.clock})
    : db = AppDatabase(NativeDatabase.memory()) {
    transactions = TransactionRepositoryDrift(db, clock: () => clock.now);
    budgets = BudgetRepositoryDrift(db, clock: () => clock.now);
    settings = SettingsRepositoryDrift(
      db,
      privacy: const _NoPrivacy(),
      clock: () => clock.now,
    );
    sync = SyncRepositoryDrift(db, remote);
  }

  final AppDatabase db;
  final _Clock clock;
  late final TransactionRepositoryDrift transactions;
  late final BudgetRepositoryDrift budgets;
  late final SettingsRepositoryDrift settings;
  late final SyncRepositoryDrift sync;

  Future<void> signIn(String userId) => db
      .into(db.profiles)
      .insert(
        ProfilesCompanion.insert(
          userId: userId,
          createdAt: clock.now,
          modifiedAt: DateTime.utc(2000),
        ),
      );

  Future<List<Transaction>> all() async =>
      (await transactions.getTransactions() as Ok<List<Transaction>>).value;

  Future<void> close() async {
    transactions.dispose();
    budgets.dispose();
    settings.dispose();
    sync.dispose();
    await db.close();
  }
}

/// Android's secure flag, left alone in tests.
class _NoPrivacy extends PrivacyScreenService {
  const _NoPrivacy();

  @override
  Future<void> setEnabled(bool enabled) async {}
}

/// Notification access turned off.
class _NoAccessClient extends NotificationListenerClient {
  const _NoAccessClient();

  @override
  Future<bool> isPermissionGranted() async => false;
}

class _Clock {
  DateTime now = DateTime(2026, 11, 27, 9);

  void tick() => now = now.add(const Duration(minutes: 1));
}

TransactionDraft _draft(double amount, {String title = 'Shoprite'}) =>
    TransactionDraft(
      title: title,
      amount: amount,
      category: DefaultCategories.groceries,
      date: DateTime(2026, 11, 26, 18),
    );

void main() {
  late FakeRemoteStore remote;
  late _Clock clock;
  late _Device phone;
  late _Device tablet;

  setUp(() async {
    remote = FakeRemoteStore();
    remote.profile = {
      'user_id': 'user-1',
      'name': 'Paul',
      'payday': 1,
      'theme': 'system',
      'modified_at': '2000-01-01T00:00:00.000Z',
      'updated_at': '2000-01-01T00:00:00.000Z',
    };
    clock = _Clock();
    phone = _Device(remote, clock: clock);
    tablet = _Device(remote, clock: clock);
    await phone.signIn('user-1');
    await tablet.signIn('user-1');
  });

  tearDown(() async {
    await phone.close();
    await tablet.close();
  });

  test('a new transaction reaches the server and another device', () async {
    await phone.transactions.addTransaction(_draft(640));
    expect(await phone.sync.sync(), isA<Ok<void>>());

    final stored = remote.tables['transactions']!.values.single;
    expect(stored['user_id'], 'user-1');
    expect(stored['amount'], 640);
    expect(stored['category_name'], 'Groceries');
    expect(stored.containsKey('dirty'), isFalse);

    await tablet.sync.sync();
    final onTablet = (await tablet.all()).single;
    expect(onTablet.title, 'Shoprite');
    expect(onTablet.date, DateTime(2026, 11, 26, 18));
    expect(phone.sync.status, SyncStatus.idle);
  });

  test('nothing is sent twice', () async {
    await phone.transactions.addTransaction(_draft(640));
    await phone.sync.sync();
    final pushes = remote.pushes;

    await phone.sync.sync();
    expect(remote.pushes, pushes);
  });

  test('edits and deletions reach other devices', () async {
    final added = (await phone.transactions.addTransaction(
      _draft(640),
    ) as Ok<Transaction>).value;
    await phone.sync.sync();
    await tablet.sync.sync();

    clock.tick();
    await tablet.transactions.updateTransaction(added.id, _draft(655));
    await tablet.sync.sync();
    await phone.sync.sync();
    expect((await phone.all()).single.amount, 655);

    clock.tick();
    await phone.transactions.deleteTransaction(added.id);
    await phone.sync.sync();
    await tablet.sync.sync();
    expect(await tablet.all(), isEmpty);
    expect(remote.tables['transactions']![added.id]!['deleted'], isTrue);
  });

  test('the later edit wins when two devices change the same one', () async {
    final added = (await phone.transactions.addTransaction(
      _draft(640),
    ) as Ok<Transaction>).value;
    await phone.sync.sync();
    await tablet.sync.sync();

    clock.tick();
    await phone.transactions.updateTransaction(added.id, _draft(700));
    clock.tick();
    await tablet.transactions.updateTransaction(added.id, _draft(800));

    // The older edit arrives first, then the newer one.
    await phone.sync.sync();
    await tablet.sync.sync();
    await phone.sync.sync();
    expect((await phone.all()).single.amount, 800);
    expect((await tablet.all()).single.amount, 800);

    // Sent in the other order, the server still keeps the newer edit.
    clock.tick();
    await tablet.transactions.updateTransaction(added.id, _draft(900));
    clock.tick();
    await phone.transactions.updateTransaction(added.id, _draft(950));
    await phone.sync.sync();
    await tablet.sync.sync();
    await phone.sync.sync();
    expect((await tablet.all()).single.amount, 950);
    expect((await phone.all()).single.amount, 950);
  });

  test('works offline and catches up when back online', () async {
    remote.offline = true;
    await phone.transactions.addTransaction(_draft(50, title: 'Bus fare'));

    expect(await phone.sync.sync(), isA<Error<void>>());
    expect(phone.sync.status, SyncStatus.failed);
    expect((await phone.all()).single.title, 'Bus fare');

    remote.offline = false;
    expect(await phone.sync.sync(), isA<Ok<void>>());
    await tablet.sync.sync();
    expect((await tablet.all()).single.title, 'Bus fare');
  });

  test('budget order and settings follow the account', () async {
    for (final name in ['Groceries', 'Transport']) {
      await phone.budgets.saveBudget(
        Budget(
          id: '',
          categoryName: name,
          categoryIcon: 'other',
          categoryColor: 0,
          limit: 500,
        ),
      );
    }
    final ids = [
      for (final b
          in (await phone.budgets.getBudgets() as Ok<List<Budget>>).value)
        b.id,
    ];
    clock.tick();
    await phone.budgets.reorderBudgets(ids.reversed.toList());
    clock.tick();
    await phone.settings.setPayday(25);
    await phone.settings.setBudgetAlertPercent(90);
    await phone.settings.setDefaultWalletId('w-cash');
    await phone.settings.setShowHabitsOnHome(false);
    await phone.settings.setHideAmountsOnHome(true);
    await phone.settings.setPrivacyScreen(true);
    await phone.settings.setAppLock(true);
    await phone.sync.sync();

    await tablet.sync.sync();
    final onTablet =
        (await tablet.budgets.getBudgets() as Ok<List<Budget>>).value;
    expect(
      [for (final b in onTablet) b.categoryName],
      ['Transport', 'Groceries'],
    );
    expect(remote.profile!['payday'], 25);
    await tablet.settings.load();
    expect(tablet.settings.payday, 25);
    expect(remote.profile!['budget_alert_percent'], 90);
    expect(tablet.settings.budgetAlertPercent, 90);
    expect(tablet.settings.defaultWalletId, 'w-cash');
    expect(tablet.settings.showHabitsOnHome, isFalse);
    expect(tablet.settings.hideAmountsOnHome, isTrue);
    expect(remote.profile!['privacy_screen'], isTrue);
    expect(tablet.settings.privacyScreen, isTrue);
    expect(remote.profile!['app_lock'], isTrue);
    expect(tablet.settings.appLock, isTrue);
  });

  test('detected payments keep their message details', () async {
    remote.seed('detected_payments', {
      'id': 'TX9',
      'message': const MoneyMessage(
        kind: MoneyMessageKind.spent,
        amount: 120,
        provider: 'MTN MoMo',
        providerKind: WalletKind.mobileMoney,
        counterparty: 'Shoprite',
        reference: 'TX9',
      ).toJson(),
      'received_at': '2026-11-27T07:00:00.000Z',
      'sender': 'MoMo',
      'status': 'pending',
      'modified_at': '2026-11-27T07:00:00.000Z',
      'deleted': false,
    });
    await phone.sync.sync();

    final repo = DetectedPaymentRepositoryNotifications(
      phone.db,
      client: const _NoAccessClient(),
    );
    addTearDown(repo.dispose);
    await repo.refresh();
    final payment = repo.pending.single;
    expect(payment.message.counterparty, 'Shoprite');
    expect(payment.message.providerKind, WalletKind.mobileMoney);

    await repo.dismiss('TX9');
    await phone.sync.sync();
    expect(remote.tables['detected_payments']!['TX9']!['status'], 'dismissed');
    expect(remote.tables['detected_payments']!['TX9']!['message'], isA<Map>());
  });

  test('a sync with nothing new changes nothing on the device', () async {
    await phone.transactions.addTransaction(_draft(640));
    await phone.sync.sync();
    await phone.sync.sync();

    var writes = 0;
    final watch = phone.db.tableUpdates().listen((_) => writes++);
    addTearDown(watch.cancel);
    await phone.sync.sync();
    await pumpEventQueue();
    expect(writes, 0);
  });

  test(
    'a profile photo goes up, reaches other devices and can be removed',
    () async {
      final photo = Uint8List.fromList(List.generate(64, (i) => i));
      await phone.db
          .update(phone.db.profiles)
          .write(
            ProfilesCompanion(
              avatarBytes: Value(photo),
              avatarDirty: const Value(true),
              dirty: const Value(true),
              modifiedAt: Value(clock.now),
            ),
          );
      await phone.sync.sync();

      final path = remote.profile!['avatar_path'] as String;
      expect(path, startsWith('user-1/avatar-'));
      expect(remote.photos[path], photo);

      await tablet.sync.sync();
      final onTablet = await tablet.db.select(tablet.db.profiles).getSingle();
      expect(onTablet.avatarBytes, photo);
      expect(onTablet.avatarPath, path);

      clock.tick();
      await phone.db
          .update(phone.db.profiles)
          .write(
            ProfilesCompanion(
              avatarBytes: const Value(null),
              avatarDirty: const Value(true),
              dirty: const Value(true),
              modifiedAt: Value(clock.now),
            ),
          );
      await phone.sync.sync();
      expect(remote.profile!['avatar_path'], isNull);
      expect(remote.photos, isEmpty);

      await tablet.sync.sync();
      final cleared = await tablet.db.select(tablet.db.profiles).getSingle();
      expect(cleared.avatarBytes, isNull);
    },
  );

  test('does nothing while signed out', () async {
    remote.userId = null;
    await phone.transactions.addTransaction(_draft(640));

    expect(await phone.sync.sync(), isA<Ok<void>>());
    expect(phone.sync.status, SyncStatus.off);
    expect(remote.tables, isEmpty);
  });
}
