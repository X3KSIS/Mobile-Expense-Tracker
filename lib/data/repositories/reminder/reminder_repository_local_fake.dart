import 'dart:async';

import 'reminder_repository.dart';

/// [ReminderRepository] for tests: permission is [allowed] after asking
/// when [grant] is true.
class ReminderRepositoryLocalFake implements ReminderRepository {
  ReminderRepositoryLocalFake({this.allowed = false, this.grant = true});

  bool allowed;
  bool grant;

  /// How many times permission was asked for.
  int requests = 0;

  final StreamController<String> _opens = StreamController.broadcast();

  /// Pretends the user tapped a reminder opening [route].
  void tap(String route) => _opens.add(route);

  @override
  Future<bool> notificationsAllowed() async => allowed;

  @override
  Future<bool> requestPermission() async {
    requests++;
    if (grant) allowed = true;
    return allowed;
  }

  @override
  Stream<String> get openRequests => _opens.stream;

  @override
  Future<String?> launchRoute() async => null;

  @override
  Future<void> start() async {}

  @override
  void dispose() => _opens.close();
}
