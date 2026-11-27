import 'package:drift/drift.dart';

/// Converts database values to and from the server's JSON: dates as UTC
/// ISO 8601 strings, numbers whatever JSON number they arrive as.
class SyncSerializer extends ValueSerializer {
  const SyncSerializer();

  @override
  T fromJson<T>(dynamic json) {
    if (json == null) return null as T;
    final probe = <T>[];
    if (probe is List<DateTime?>) {
      return DateTime.parse(json as String).toLocal() as T;
    }
    if (probe is List<double?>) return _number(json).toDouble() as T;
    if (probe is List<int?>) return _number(json).toInt() as T;
    if (probe is List<bool?>) return (json == true || json == 1) as T;
    return json as T;
  }

  @override
  dynamic toJson<T>(T value) {
    if (value is DateTime) return value.toUtc().toIso8601String();
    return value;
  }

  static num _number(dynamic json) =>
      json is num ? json : num.parse(json.toString());
}

/// `openingBalance` → `opening_balance`.
String snakeCase(String camel) =>
    camel.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

/// `opening_balance` → `openingBalance`.
String camelCase(String snake) =>
    snake.replaceAllMapped(RegExp('_([a-z])'), (m) => m[1]!.toUpperCase());
