/// Result of an operation that can fail, returned by repositories instead of
/// throwing.
///
/// ```dart
/// switch (result) {
///   case Ok(:final value): ...
///   case Error(:final error): ...
/// }
/// ```
sealed class Result<T> {
  const Result();

  /// Creates a successful [Result] holding [value].
  const factory Result.ok(T value) = Ok._;

  /// Creates a failed [Result] holding [error].
  const factory Result.error(Exception error) = Error._;
}

/// A successful [Result].
final class Ok<T> extends Result<T> {
  const Ok._(this.value);

  final T value;

  @override
  String toString() => 'Result<$T>.ok($value)';
}

/// A failed [Result].
final class Error<T> extends Result<T> {
  const Error._(this.error);

  final Exception error;

  @override
  String toString() => 'Result<$T>.error($error)';
}
