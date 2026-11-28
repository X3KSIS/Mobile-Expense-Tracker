import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// A kind of phone notification, shown under its own channel so the user
/// can silence one kind in the phone's settings.
enum ReminderChannel {
  daily('daily_reminder', 'Daily reminder', 'A nudge to record what you spent'),
  bills(
    'bill_reminders',
    'Bill reminders',
    'The evening before a regular payment is due',
  );

  const ReminderChannel(this.id, this.title, this.description);

  final String id;
  final String title;
  final String description;
}

/// Wraps `flutter_local_notifications`: shows scheduled notifications in
/// the phone's notification tray and reports which one was tapped. Does
/// nothing where the plugin isn't available (tests, unsupported
/// platforms).
class LocalNotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<String> _taps = StreamController.broadcast();
  bool _ready = false;

  /// The coral of the app's primary buttons, tinting the small icon.
  static const Color _accent = Color(0xFFD2401F);

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// The payload of each notification the user taps while the app runs.
  Stream<String> get taps => _taps.stream;

  Future<void> initialize() async {
    if (!_supported || _ready) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_wallet'),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) _taps.add(payload);
        },
      );
      _ready = true;
    } on PlatformException {
      // Leave notifications off; the app works without them.
    } on MissingPluginException {
      // Same.
    }
  }

  /// The payload of the notification that opened the app, if one did.
  Future<String?> launchPayload() async {
    if (!_ready) return null;
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details == null || !details.didNotificationLaunchApp) return null;
      return details.notificationResponse?.payload;
    } on PlatformException {
      return null;
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Whether the phone lets the app show notifications.
  Future<bool> areEnabled() async {
    if (!_ready) return false;
    try {
      return await _android?.areNotificationsEnabled() ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Asks the phone for permission to show notifications (Android 13+);
  /// true when allowed.
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      return await _android?.requestNotificationsPermission() ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Shows a notification at [at] (give or take a few minutes, so the
  /// phone can save battery). Opening it reports [payload] on [taps].
  Future<void> schedule({
    required int id,
    required DateTime at,
    required ReminderChannel channel,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.zonedSchedule(
        id: id,
        // An exact moment, so the phone's own time zone applies.
        scheduledDate: tz.TZDateTime.from(at, tz.UTC),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.title,
            channelDescription: channel.description,
            color: _accent,
            styleInformation: BigTextStyleInformation(body),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
        payload: payload,
      );
    } on PlatformException {
      // A reminder that can't be scheduled is skipped.
    }
  }

  /// Removes every notification waiting to be shown (not ones already in
  /// the tray).
  Future<void> cancelPending() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAllPendingNotifications();
    } on PlatformException {
      // Nothing scheduled to remove.
    }
  }
}
