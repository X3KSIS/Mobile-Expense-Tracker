import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_expensetracker/data/repositories/detected_payment/detected_payment_repository_notifications.dart';
import 'package:flutter_expensetracker/data/services/database/app_database.dart';
import 'package:flutter_expensetracker/data/services/notification_listener_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for Android's notification listener.
class _FakeClient extends NotificationListenerClient {
  _FakeClient({this.granted = true, this.tray = const []});

  bool granted;
  List<PostedNotification> tray;
  final StreamController<PostedNotification> live =
      StreamController.broadcast();

  @override
  bool get isSupported => true;

  @override
  Future<bool> isPermissionGranted() async => granted;

  @override
  Future<bool> requestPermission() async => granted = true;

  @override
  Stream<PostedNotification> get notifications => live.stream;

  @override
  Future<List<PostedNotification>> active() async => tray;
}

PostedNotification _sms(
  String content, {
  String title = 'MoMo',
  String package = 'com.google.android.apps.messaging',
  bool removed = false,
}) => (
  packageName: package,
  title: title,
  content: content,
  postedAt: DateTime(2026, 11, 26, 9),
  removed: removed,
);

void main() {
  AppDatabase db() {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    return database;
  }

  const payment =
      'You have paid ZMW 150.00 to SHOPRITE MANDA HILL. Txn ID: 987654.';

  test('does nothing until notification access is allowed', () async {
    final client = _FakeClient(granted: false, tray: [_sms(payment)]);
    final repo = DetectedPaymentRepositoryNotifications(db(), client: client);
    addTearDown(repo.dispose);

    await repo.refresh();
    expect(repo.isEnabled, isFalse);
    expect(repo.pending, isEmpty);

    final result = await repo.enable();
    expect(result, isA<Object>());
    expect(repo.isEnabled, isTrue);
    expect(repo.pending.single.message.amount, 150);
  });

  test('keeps payment messages only, from the tray and live', () async {
    final client = _FakeClient(
      tray: [
        _sms(payment),
        _sms('Hey, I sent you K200 for lunch', title: 'Mum'),
        _sms('Your OTP is 4455', title: 'Zanaco'),
      ],
    );
    final repo = DetectedPaymentRepositoryNotifications(db(), client: client);
    addTearDown(repo.dispose);
    await repo.refresh();
    expect(repo.pending, hasLength(1));

    client.live.add(
      _sms(
        'Money received. Amt: K500.00 From: 0971234567 MARY PHIRI. '
        'TID: MP1.A2',
        title: 'AirtelMoney',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(repo.pending, hasLength(2));
  });

  test('offers each payment once, and not again after dismissing', () async {
    final client = _FakeClient(tray: [_sms(payment), _sms(payment)]);
    final repo = DetectedPaymentRepositoryNotifications(db(), client: client);
    addTearDown(repo.dispose);

    await repo.refresh();
    expect(repo.pending, hasLength(1));

    await repo.dismiss(repo.pending.single.id);
    await repo.refresh();
    expect(repo.pending, isEmpty);
  });

  test('ignores removals and its own notifications', () async {
    final client = _FakeClient(
      tray: [
        _sms(payment, removed: true),
        _sms(payment, package: 'com.example.flutter_expensetracker'),
      ],
    );
    final repo = DetectedPaymentRepositoryNotifications(db(), client: client);
    addTearDown(repo.dispose);

    await repo.refresh();
    expect(repo.pending, isEmpty);
  });

  test('pending and handled payments survive a restart', () async {
    final database = db();
    final client = _FakeClient(
      tray: [
        _sms(payment),
        _sms(
          'Money received. Amt: K500.00 From: 0971234567 MARY PHIRI. '
          'TID: MP1.A2',
          title: 'AirtelMoney',
        ),
      ],
    );
    final first = DetectedPaymentRepositoryNotifications(
      database,
      client: client,
    );
    await first.refresh();
    expect(first.pending, hasLength(2));
    await first.dismiss('987654');
    first.dispose();

    final second = DetectedPaymentRepositoryNotifications(
      database,
      client: client,
    );
    addTearDown(second.dispose);
    await second.refresh();
    expect(second.pending.single.message.amount, 500);
  });
}
