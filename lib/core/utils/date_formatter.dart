import 'package:intl/intl.dart';

class DateFormatter {
  static const _locale = 'es';

  /// Creates a DateFormat with the Spanish locale, falling back to no-locale
  /// if locale data has not been initialized (e.g. when the app is launched via
  /// a notification before main() finishes setting up the locale).
  static DateFormat _fmt(String pattern) {
    try {
      return DateFormat(pattern, _locale);
    } catch (_) {
      return DateFormat(pattern);
    }
  }

  static String formatDate(DateTime date) {
    return _fmt('d MMM yyyy').format(date);
  }

  static String formatShortDate(DateTime date) {
    return _fmt('d MMM').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return _fmt('MMMM yyyy').format(date);
  }

  static String formatMonth(DateTime date) {
    return _fmt('MMMM').format(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final diff = today.difference(dateOnly).inDays;

    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    if (diff < 4) return 'Hace $diff días';
    return DateFormatter.formatDate(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String monthKey(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }
}
