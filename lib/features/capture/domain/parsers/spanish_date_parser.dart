/// A date found inside a token list, plus the token indexes it consumed.
class DateMatch {
  final DateTime date;
  final Set<int> tokens;

  const DateMatch({required this.date, required this.tokens});
}

/// Reads relative and explicit dates out of dictated Spanish: "hoy", "ayer",
/// "antier", "hace 3 días", "el lunes", "el 5 de marzo", "5/3/2026".
///
/// The result is never in the future — the transaction form only accepts dates
/// up to today, so anything ahead of [reference] is pulled back a year (for
/// explicit dates) or clamped.
class SpanishDateParser {
  const SpanishDateParser._();

  static const _months = <String, int>{
    'enero': 1, 'febrero': 2, 'marzo': 3, 'abril': 4, 'mayo': 5, 'junio': 6,
    'julio': 7, 'agosto': 8, 'septiembre': 9, 'setiembre': 9, 'octubre': 10,
    'noviembre': 11, 'diciembre': 12,
  };

  static const _weekdays = <String, int>{
    'lunes': DateTime.monday,
    'martes': DateTime.tuesday,
    'miercoles': DateTime.wednesday,
    'jueves': DateTime.thursday,
    'viernes': DateTime.friday,
    'sabado': DateTime.saturday,
    'domingo': DateTime.sunday,
  };

  static const _smallNumbers = <String, int>{
    'un': 1, 'una': 1, 'uno': 1, 'dos': 2, 'tres': 3, 'cuatro': 4, 'cinco': 5,
    'seis': 6, 'siete': 7, 'ocho': 8, 'nueve': 9, 'diez': 10, 'once': 11,
    'doce': 12, 'trece': 13, 'catorce': 14, 'quince': 15,
  };

  /// Finds the first date expression in [tokens] (already lowercased and
  /// accent-stripped), or `null` when the text has none.
  static DateMatch? find(List<String> tokens, {DateTime? reference}) {
    final now = reference ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var i = 0; i < tokens.length; i++) {
      final token = _clean(tokens[i]);
      if (token.isEmpty) continue;

      if (token == 'hoy') {
        return DateMatch(date: today, tokens: {i});
      }
      if (token == 'ayer') {
        return DateMatch(date: today.subtract(const Duration(days: 1)), tokens: {i});
      }
      if (token == 'antier' || token == 'anteayer') {
        return DateMatch(date: today.subtract(const Duration(days: 2)), tokens: {i});
      }

      // "hace 3 días" / "hace tres dias"
      if (token == 'hace' && i + 2 < tokens.length) {
        final match = _relativeAgo(tokens, i, today);
        if (match != null) return match;
      }

      // "la semana pasada" / "el mes pasado"
      if (token == 'semana' && _isPast(tokens, i + 1)) {
        return DateMatch(
          date: today.subtract(const Duration(days: 7)),
          tokens: _range(i - 1, i + 1, tokens.length),
        );
      }
      if (token == 'mes' && _isPast(tokens, i + 1)) {
        final target = DateTime(today.year, today.month - 1, today.day);
        return DateMatch(date: target, tokens: _range(i - 1, i + 1, tokens.length));
      }

      // "5 de marzo" / "5 de marzo de 2025"
      final day = int.tryParse(token);
      if (day != null && day >= 1 && day <= 31 && i + 2 < tokens.length) {
        final match = _dayOfMonth(tokens, i, day, today);
        if (match != null) return match;
      }

      // "5/3/2026", "05-03-25"
      final numeric = _numericDate(token, today);
      if (numeric != null) return DateMatch(date: numeric, tokens: {i});

      // "el lunes" — the most recent one already past.
      final weekday = _weekdays[token];
      if (weekday != null) {
        var delta = today.weekday - weekday;
        if (delta <= 0) delta += 7;
        return DateMatch(
          date: today.subtract(Duration(days: delta)),
          tokens: _range(i - 1, i, tokens.length, onlyIfArticle: tokens),
        );
      }
    }
    return null;
  }

  static DateMatch? _relativeAgo(List<String> tokens, int index, DateTime today) {
    final countToken = _clean(tokens[index + 1]);
    final count = int.tryParse(countToken) ?? _smallNumbers[countToken];
    if (count == null) return null;

    final unit = _clean(tokens[index + 2]);
    Duration? span;
    if (unit == 'dia' || unit == 'dias') {
      span = Duration(days: count);
    } else if (unit == 'semana' || unit == 'semanas') {
      span = Duration(days: count * 7);
    }
    if (span == null) return null;

    return DateMatch(
      date: today.subtract(span),
      tokens: {index, index + 1, index + 2},
    );
  }

  static DateMatch? _dayOfMonth(
    List<String> tokens,
    int index,
    int day,
    DateTime today,
  ) {
    if (_clean(tokens[index + 1]) != 'de') return null;
    final month = _months[_clean(tokens[index + 2])];
    if (month == null) return null;

    final consumed = {index, index + 1, index + 2};
    var year = today.year;

    // "5 de marzo de 2025"
    if (index + 4 < tokens.length && _clean(tokens[index + 3]) == 'de') {
      final explicit = int.tryParse(_clean(tokens[index + 4]));
      if (explicit != null && explicit > 1900 && explicit <= today.year) {
        year = explicit;
        consumed.addAll({index + 3, index + 4});
      }
    }

    var date = DateTime(year, month, day);
    // A date still ahead of today means the user meant last year.
    if (date.isAfter(today)) date = DateTime(year - 1, month, day);
    return DateMatch(date: date, tokens: consumed);
  }

  static DateTime? _numericDate(String token, DateTime today) {
    final match =
        RegExp(r'^(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?$').firstMatch(token);
    if (match == null) return null;

    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    if (day < 1 || day > 31 || month < 1 || month > 12) return null;

    var year = today.year;
    final rawYear = match.group(3);
    if (rawYear != null) {
      final parsed = int.parse(rawYear);
      year = parsed < 100 ? 2000 + parsed : parsed;
    }

    var date = DateTime(year, month, day);
    if (date.isAfter(today)) {
      if (rawYear != null) return null; // an explicit future date is a misread
      date = DateTime(year - 1, month, day);
    }
    return date;
  }

  static bool _isPast(List<String> tokens, int index) {
    if (index >= tokens.length) return false;
    final token = _clean(tokens[index]);
    return token == 'pasada' || token == 'pasado';
  }

  static Set<int> _range(
    int from,
    int to,
    int length, {
    List<String>? onlyIfArticle,
  }) {
    final start = from < 0 ? 0 : from;
    final result = <int>{};
    for (var i = start; i <= to && i < length; i++) {
      // Only swallow the leading word when it really is an article.
      if (i == from && onlyIfArticle != null) {
        final token = _clean(onlyIfArticle[i]);
        if (token != 'el' && token != 'la') continue;
      }
      result.add(i);
    }
    return result;
  }

  static String _clean(String token) =>
      token.replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '');
}
