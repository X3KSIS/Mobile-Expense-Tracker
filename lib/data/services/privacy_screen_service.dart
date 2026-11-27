import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Turns Android's secure-window flag on or off: while on, recent apps
/// shows a blank card and screenshots and screen recording are blocked.
/// Does nothing on other platforms.
class PrivacyScreenService {
  const PrivacyScreenService();

  static const MethodChannel _channel = MethodChannel(
    'expense_tracker/privacy',
  );

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> setEnabled(bool enabled) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('setSecure', enabled);
    } on PlatformException {
      // An older build without the channel: nothing to hide.
    } on MissingPluginException {
      // Same, e.g. in tests.
    }
  }
}
