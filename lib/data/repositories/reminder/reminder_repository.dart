/// Phone notifications that remind the user to record spending and warn
/// before regular payments are due. Which ones are on lives in
/// SettingsRepository; this keeps the scheduled notifications in line
/// with those settings and the transactions.
abstract class ReminderRepository {
  /// Whether the phone lets the app show notifications.
  Future<bool> notificationsAllowed();

  /// Asks the phone for permission to show notifications; true when
  /// allowed.
  Future<bool> requestPermission();

  /// Route paths to open, one for each reminder the user taps while the
  /// app runs.
  Stream<String> get openRequests;

  /// The route of the reminder that opened the app, if one did.
  Future<String?> launchRoute();

  /// Schedules the reminders and keeps them up to date.
  Future<void> start();

  void dispose();
}
