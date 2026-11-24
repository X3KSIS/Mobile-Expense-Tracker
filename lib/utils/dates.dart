import 'package:intl/intl.dart';

/// Short label for when a transaction happened, relative to [now]:
/// `14:05` today, `Yesterday`, otherwise `18 Nov`.
String formatActivityTime(DateTime date, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final day = _dateOnly(date);
  final difference = today.difference(day).inDays;
  if (difference == 0) return DateFormat.Hm().format(date);
  if (difference == 1) return 'Yesterday';
  return DateFormat('d MMM').format(date);
}

/// Full month name, e.g. `November`.
String formatMonth(DateTime date) => DateFormat.MMMM().format(date);

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
