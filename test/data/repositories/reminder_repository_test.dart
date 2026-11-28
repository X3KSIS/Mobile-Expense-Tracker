import 'package:flutter_expensetracker/data/repositories/reminder/reminder_repository_local.dart';
import 'package:flutter_expensetracker/data/repositories/settings/settings_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/repositories/transaction/transaction_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/services/local_notification_service.dart';
import 'package:flutter_expensetracker/domain/models/transaction.dart';
import 'package:flutter_expensetracker/routing/routes.dart';
import 'package:flutter_expensetracker/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Scheduled = ({int id, DateTime at, String title, String? payload});

/// Records what would be scheduled on the phone.
class _FakeNotifications implements LocalNotificationService {
  final List<_Scheduled> scheduled = [];
  int cancels = 0;

  @override
  Stream<String> get taps => const Stream.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> launchPayload() async => null;

  @override
  Future<bool> areEnabled() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required ReminderChannel channel,
    required String title,
    required String body,
    String? payload,
  }) async => scheduled.add((id: id, at: at, title: title, payload: payload));

  @override
  Future<void> cancelPending() async {
    cancels++;
    scheduled.clear();
  }
}

/// Returns exactly [list].
class _Transactions extends TransactionRepositoryLocalFake {
  _Transactions(this.list) : super(delay: Duration.zero);

  final List<Transaction> list;

  @override
  Future<Result<List<Transaction>>> getTransactions() async => Result.ok(list);
}

Transaction _expense(String id, String title, DateTime date) => Transaction(
  id: id,
  title: title,
  categoryName: 'Subscriptions',
  categoryIcon: 'other',
  categoryColor: 0,
  amount: 640,
  type: TransactionType.expense,
  date: date,
);

void main() {
  late SettingsRepositoryLocalFake settings;
  late _FakeNotifications phone;

  ReminderRepositoryLocal build(List<Transaction> transactions, DateTime now) {
    final repo = ReminderRepositoryLocal(
      settings: settings,
      transactions: _Transactions(transactions),
      service: phone,
      clock: () => now,
      debounce: Duration.zero,
    );
    addTearDown(repo.dispose);
    return repo;
  }

  setUp(() {
    settings = SettingsRepositoryLocalFake();
    phone = _FakeNotifications();
  });

  test('nothing is scheduled while reminders are off', () async {
    await build(const [], DateTime(2026, 11, 28, 9)).reschedule();
    expect(phone.scheduled, isEmpty);
    expect(phone.cancels, 1);
  });

  test('the daily reminder covers a week at the chosen time', () async {
    await settings.setDailyReminder(true);
    await settings.setReminderMinutes(20 * 60 + 30);
    await build(const [], DateTime(2026, 11, 28, 9)).reschedule();

    expect(phone.scheduled, hasLength(ReminderRepositoryLocal.dailyDays));
    expect(phone.scheduled.first.at, DateTime(2026, 11, 28, 20, 30));
    expect(phone.scheduled.last.at, DateTime(2026, 12, 4, 20, 30));
    expect(phone.scheduled.first.payload, Routes.add);
  });

  test(
    'today is skipped once something was recorded, or the time passed',
    () async {
      await settings.setDailyReminder(true);
      await build([
        _expense('t', 'Lunch', DateTime(2026, 11, 28, 13)),
      ], DateTime(2026, 11, 28, 14)).reschedule();
      expect(phone.scheduled.first.at, DateTime(2026, 11, 29, 20));

      await build(const [], DateTime(2026, 11, 28, 21)).reschedule();
      expect(phone.scheduled.first.at, DateTime(2026, 11, 29, 20));
    },
  );

  test('a bill reminder comes the evening before it is due', () async {
    await settings.setBillReminders(true);
    await build([
      for (final month in [8, 9, 10, 11])
        _expense('d$month', 'DStv Compact', DateTime(2026, month, 3)),
    ], DateTime(2026, 11, 28, 9)).reschedule();

    final bill = phone.scheduled.single;
    expect(bill.at, DateTime(2026, 12, 2, ReminderRepositoryLocal.billHour));
    expect(bill.title, 'DStv Compact is due tomorrow');
    expect(bill.payload, Routes.recurring);
  });

  test('changing a setting reschedules', () async {
    final repo = build(const [], DateTime(2026, 11, 28, 9));
    await repo.start();
    expect(phone.scheduled, isEmpty);

    await settings.setDailyReminder(true);
    await pumpEventQueue();
    expect(phone.scheduled, isNotEmpty);

    await settings.setDailyReminder(false);
    await pumpEventQueue();
    expect(phone.scheduled, isEmpty);
  });
}
