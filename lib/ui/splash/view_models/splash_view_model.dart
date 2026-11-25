import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../routing/routes.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// Holds the splash screen briefly, then decides where the app starts:
/// Home when signed in, otherwise the sign-in screen.
class SplashViewModel extends ChangeNotifier {
  SplashViewModel({
    required this._authRepository,
    this.holdDuration = const Duration(milliseconds: 1500),
  }) {
    start = Command0<String>(_start);
  }

  final AuthRepository _authRepository;

  /// How long the splash stays on screen.
  final Duration holdDuration;

  /// Completes with the route path to navigate to.
  late final Command0<String> start;

  Future<Result<String>> _start() async {
    await Future<void>.delayed(holdDuration);
    return Result.ok(
      _authRepository.isAuthenticated ? Routes.home : Routes.login,
    );
  }

  @override
  void dispose() {
    start.dispose();
    super.dispose();
  }
}
