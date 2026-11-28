import 'package:intl/intl.dart';

/// Short label for when a transaction happened, relative to [now]:
/// `14:05` today, `Yesterday`, otherwise `18 Nov`.
String formatActivityTime(DateTime date, {DateTime? now}) {
  final today = dateOnly(now ?? DateTime.now());
  final day = dateOnly(date);
  final difference = today.difference(day).inDays;
  if (difference == 0) return DateFormat.Hm().format(date);
  if (difference == 1) return 'Yesterday';
  return DateFormat('d MMM').format(date);
}

/// The time of day, e.g. `14:05`.
String formatTimeOfDay(DateTime date) => DateFormat.Hm().format(date);

/// Heading for a day of transactions: `Today`, `Yesterday`, otherwise
/// `Tuesday, 18 Nov` (with the year when it is not [now]'s year).
String formatDayHeading(DateTime date, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final difference = dateOnly(reference).difference(dateOnly(date)).inDays;
  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  final pattern = date.year == reference.year ? 'EEEE, d MMM' : 'EEEE, d MMM y';
  return DateFormat(pattern).format(date);
}

/// Date for form fields: `Today`, `Yesterday`, otherwise `Tue, 18 Nov 2026`.
String formatPickerDate(DateTime date, {DateTime? now}) {
  final difference = dateOnly(now ?? DateTime.now())
      .difference(dateOnly(date))
      .inDays;
  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  return DateFormat('EEE, d MMM y').format(date);
}

/// Full date and time, e.g. `Tuesday, 25 Nov 2026 · 14:05`.
String formatFullDateTime(DateTime date) =>
    '${DateFormat('EEEE, d MMM y').format(date)} · '
    '${DateFormat.Hm().format(date)}';

/// Full month name, e.g. `November`.
String formatMonth(DateTime date) => DateFormat.MMMM().format(date);

/// Short month name, e.g. `Nov`.
String formatMonthShort(DateTime date) => DateFormat.MMM().format(date);

/// Month and year, e.g. `November 2026`.
String formatMonthYear(DateTime date) => DateFormat('MMMM y').format(date);

/// [d] with the time of day removed.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// The first day of [d]'s month.
DateTime monthOf(DateTime d) => DateTime(d.year, d.month);

/// 1st, 2nd, 3rd, 4th … 11th, 12th, 13th … 21st, 22nd, 23rd.
String ordinal(int n) {
  if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
  return switch (n % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th',
  };
}

/// e.g. "25 Dec".
String formatDayMonth(DateTime date) => DateFormat('d MMM').format(date);

/// How long ago [date] was, relative to [now]: `just now`, `5 min ago`,
/// `at 14:05` (today), otherwise `on 25 Nov`.
String formatAgo(DateTime date, DateTime now) {
  final minutes = now.difference(date).inMinutes;
  if (minutes < 1) return 'just now';
  if (minutes < 60) return '$minutes min ago';
  if (dateOnly(date) == dateOnly(now)) {
    return 'at ${DateFormat.Hm().format(date)}';
  }
  return 'on ${formatDayMonth(date)}';
}
