import 'package:drift/native.dart';
import 'package:flutter_expensetracker/data/repositories/settings/settings_repository_drift.dart';
import 'package:flutter_expensetracker/data/services/database/app_database.dart';
import 'package:flutter_expensetracker/data/services/privacy_screen_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what the app asked Android to do.
class _RecordingPrivacy extends PrivacyScreenService {
  final List<bool> calls = [];

  @override
  Future<void> setEnabled(bool enabled) async => calls.add(enabled);
}

void main() {
  test('the privacy screen is applied when changed and on start', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.openAccount(
      userId: 'u',
      email: 'e@example.com',
      name: 'N',
      createdAt: DateTime(2026),
    );

    final privacy = _RecordingPrivacy();
    final settings = SettingsRepositoryDrift(db, privacy: privacy);
    addTearDown(settings.dispose);
    await settings.setPrivacyScreen(true);
    expect(privacy.calls, [true]);
    expect((await db.select(db.profiles).getSingle()).privacyScreen, isTrue);

    final nextLaunch = _RecordingPrivacy();
    final restarted = SettingsRepositoryDrift(db, privacy: nextLaunch);
    addTearDown(restarted.dispose);
    await restarted.load();
    expect(restarted.privacyScreen, isTrue);
    expect(nextLaunch.calls, [true]);
  });
}
