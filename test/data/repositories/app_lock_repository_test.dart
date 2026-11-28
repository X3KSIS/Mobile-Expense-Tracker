import 'package:flutter_expensetracker/data/repositories/app_lock/app_lock_repository.dart';
import 'package:flutter_expensetracker/data/repositories/app_lock/app_lock_repository_device.dart';
import 'package:flutter_expensetracker/data/repositories/settings/settings_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/services/device_auth_service.dart';
import 'package:flutter_expensetracker/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every prompt with [outcome] and counts the prompts.
class _FakeDeviceAuth implements DeviceAuthService {
  DeviceAuthOutcome outcome = DeviceAuthOutcome.success;
  int prompts = 0;

  /// Runs while the prompt is open, e.g. the app going to the background.
  void Function()? duringPrompt;

  @override
  Future<bool> isAvailable() async => outcome != DeviceAuthOutcome.noScreenLock;

  @override
  Future<DeviceAuthOutcome> authenticate(String reason) async {
    prompts++;
    duringPrompt?.call();
    return outcome;
  }
}

void main() {
  late SettingsRepositoryLocalFake settings;
  late _FakeDeviceAuth auth;
  late DateTime now;

  AppLockRepositoryDevice build() {
    final repo = AppLockRepositoryDevice(
      settings,
      service: auth,
      clock: () => now,
    );
    addTearDown(repo.dispose);
    return repo;
  }

  setUp(() {
    settings = SettingsRepositoryLocalFake();
    auth = _FakeDeviceAuth();
    now = DateTime(2026, 11, 28, 18);
  });

  test('opens unlocked when the lock is off', () {
    expect(build().isLocked, isFalse);
  });

  test(
    'a cold start with the lock on opens locked; unlocking opens it',
    () async {
      await settings.setAppLock(true);
      final lock = build();
      expect(lock.isLocked, isTrue);

      auth.outcome = DeviceAuthOutcome.cancelled;
      final cancelled = await lock.unlock();
      expect(cancelled, isA<Error<void>>());
      expect(lock.isLocked, isTrue);

      auth.outcome = DeviceAuthOutcome.success;
      expect(await lock.unlock(), isA<Ok<void>>());
      expect(lock.isLocked, isFalse);
    },
  );

  test('locks again only after a minute away', () async {
    await settings.setAppLock(true);
    final lock = build();
    await lock.unlock();

    lock.appHidden();
    now = now.add(const Duration(seconds: 40));
    lock.appResumed();
    expect(lock.isLocked, isFalse, reason: 'a quick trip to the gallery');

    lock.appHidden();
    now = now.add(AppLockRepository.lockAfter);
    lock.appResumed();
    expect(lock.isLocked, isTrue);
  });

  test('the prompt sending the app away does not lock it again', () async {
    await settings.setAppLock(true);
    final lock = build();
    auth.duringPrompt = () {
      lock.appHidden();
      now = now.add(const Duration(minutes: 3));
    };
    await lock.unlock();
    lock.appResumed();
    expect(lock.isLocked, isFalse);
  });

  test('a phone without a screen lock is never shut out', () async {
    await settings.setAppLock(true);
    final lock = build();
    auth.outcome = DeviceAuthOutcome.noScreenLock;
    expect(await lock.unlock(), isA<Ok<void>>());
    expect(lock.isLocked, isFalse);
  });

  test('turning the lock off unlocks', () async {
    await settings.setAppLock(true);
    final lock = build();
    await settings.setAppLock(false);
    expect(lock.isLocked, isFalse);
  });

  test('confirming reports why it failed and leaves the lock alone', () async {
    final lock = build();
    auth.outcome = DeviceAuthOutcome.lockedOut;
    final result = await lock.confirm();
    expect(
      (result as Error<void>).error,
      isA<AppLockException>().having(
        (e) => e.problem,
        'problem',
        AppLockProblem.lockedOut,
      ),
    );
    expect(lock.isLocked, isFalse);
    expect(auth.prompts, 1);
  });
}
