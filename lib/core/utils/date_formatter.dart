import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime date, {String locale = 'es'}) {
    return DateFormat('d MMM yyyy', locale).format(date);
  }

  static String formatShortDate(DateTime date, {String locale = 'es'}) {
    return DateFormat('d MMM', locale).format(date);
  }

  static String formatMonthYear(DateTime date, {String locale = 'es'}) {
    return DateFormat('MMMM yyyy', locale).format(date);
  }

  static String formatMonth(DateTime date, {String locale = 'es'}) {
    return DateFormat('MMMM', locale).format(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final diff = today.difference(dateOnly).inDays;

    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    if (diff < 7) return 'Hace $diff días';
    return DateFormatter.formatDate(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String monthKey(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }
}
