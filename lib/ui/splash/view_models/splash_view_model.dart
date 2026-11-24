import 'package:flutter/foundation.dart';

import '../../../routing/routes.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// Holds the splash screen briefly, then decides where the app starts.
class SplashViewModel extends ChangeNotifier {
  SplashViewModel({this.holdDuration = const Duration(milliseconds: 1500)}) {
    start = Command0<String>(_start);
  }

  /// How long the splash stays on screen.
  final Duration holdDuration;

  /// Completes with the route path to navigate to.
  late final Command0<String> start;

  Future<Result<String>> _start() async {
    await Future<void>.delayed(holdDuration);
    // TODO(auth): check the Firebase Auth state through an AuthRepository
    // and return a sign-in route when the user is signed out. For now the
    // user is assumed to be signed in.
    return const Result.ok(Routes.home);
  }

  @override
  void dispose() {
    start.dispose();
    super.dispose();
  }
}
