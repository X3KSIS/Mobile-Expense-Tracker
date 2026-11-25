import 'package:flutter/foundation.dart';

import 'result.dart';

typedef CommandAction0<T> = Future<Result<T>> Function();
typedef CommandAction1<T, A> = Future<Result<T>> Function(A argument);

/// Wraps an async action and exposes its running, error and completed state
/// so views can react to it.
///
/// Calling `execute` while the action is already running returns the
/// in-flight future instead of starting a second run.
abstract class Command<T> extends ChangeNotifier {
  bool _running = false;
  Result<T>? _result;
  Future<void>? _inFlight;
  bool _disposed = false;

  /// Whether the action is currently running.
  bool get running => _running;

  /// Whether the last run finished with an [Error].
  bool get error => _result is Error<T>;

  /// Whether the last run finished with an [Ok].
  bool get completed => _result is Ok<T>;

  /// The result of the last run, or null if it has not finished yet.
  Result<T>? get result => _result;

  /// Clears the last result, e.g. after an error has been shown.
  void clearResult() {
    if (_result == null) return;
    _result = null;
    _notify();
  }

  Future<void> _execute(CommandAction0<T> action) {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    return _inFlight = _run(action);
  }

  Future<void> _run(CommandAction0<T> action) async {
    _running = true;
    _result = null;
    _notify();
    try {
      _result = await action();
    } on Exception catch (e) {
      _result = Result.error(e);
    } finally {
      _running = false;
      _inFlight = null;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// A [Command] whose action takes no arguments.
class Command0<T> extends Command<T> {
  Command0(this._action);

  final CommandAction0<T> _action;

  /// Runs the action. Completes when the run finishes.
  Future<void> execute() => _execute(_action);
}

/// A [Command] whose action takes one argument of type [A].
class Command1<T, A> extends Command<T> {
  Command1(this._action);

  final CommandAction1<T, A> _action;

  /// Runs the action with [argument]. Completes when the run finishes.
  Future<void> execute(A argument) => _execute(() => _action(argument));
}
