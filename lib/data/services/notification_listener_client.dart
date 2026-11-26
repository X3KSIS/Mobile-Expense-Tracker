import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

/// A notification shown on the phone, reduced to what the app reads.
typedef PostedNotification = ({
  String packageName,
  String title,
  String content,
  DateTime postedAt,
  bool removed,
});

/// Wraps Android's notification listener (the
/// `notification_listener_service` plugin). Stateless; only repositories
/// use it.
///
/// Notifications arrive only while the app is running. [active] lists the
/// ones still in the tray, to catch up on what arrived while it was
/// closed.
class NotificationListenerClient {
  const NotificationListenerClient();

  /// Notification access exists on Android only.
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> isPermissionGranted() async =>
      isSupported && await NotificationListenerService.isPermissionGranted();

  /// Opens the system "Notification access" settings page. Resolves to
  /// whether access is granted when the user comes back.
  Future<bool> requestPermission() async =>
      isSupported && await NotificationListenerService.requestPermission();

  /// Notifications as they are posted (and removed).
  Stream<PostedNotification> get notifications => isSupported
      ? NotificationListenerService.notificationsStream.map(_toPosted)
      : const Stream.empty();

  /// Notifications currently in the tray.
  Future<List<PostedNotification>> active() async {
    if (!isSupported) return const [];
    final events = await NotificationListenerService.getActiveNotifications();
    return [for (final e in events) _toPosted(e)];
  }

  static PostedNotification _toPosted(ServiceNotificationEvent e) => (
    packageName: e.packageName,
    title: e.title,
    content: e.content,
    postedAt: e.timestamp > 0 ? e.humanTime : DateTime.now(),
    removed: e.hasRemoved,
  );
}
