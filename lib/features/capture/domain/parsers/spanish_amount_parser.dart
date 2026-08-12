/// One amount found inside a token list, with the tokens it consumed so the
/// caller can strip them from the description.
class AmountMatch {
  final double value;
  final int start;

  /// Exclusive.
  final int end;

  /// True when the amount came with an explicit money signal — a `$`, a
  /// multiplier ("mil", "millones", "k") or a currency word ("pesos").
  /// Bare small numbers without one of these are usually not amounts.
  final bool hasCurrencySignal;

  const AmountMatch({
    required this.value,
    required this.start,
    required this.end,
    required this.hasCurrencySignal,
  });
}

/// Parses money amounts out of Spanish text, written either as digits
/// ("25.000", "$25000", "25k") or as words ("veinticinco mil", "dos millones",
/// "treinta y cinco mil quinientos"), including Colombian slang ("lucas",
/// "palos", "barras").
///
/// Pure Dart, no network — it runs on the device over whatever the speech
/// recognizer transcribed.
class SpanishAmountParser {
  const SpanishAmountParser._();

  static const _units = <String, int>{
    'cero': 0, 'un': 1, 'uno': 1, 'una': 1, 'dos': 2, 'tres': 3, 'cuatro': 4,
    'cinco': 5, 'seis': 6, 'siete': 7, 'ocho': 8, 'nueve': 9, 'diez': 10,
    'once': 11, 'doce': 12, 'trece': 13, 'catorce': 14, 'quince': 15,
    'dieciseis': 16, 'diecisiete': 17, 'dieciocho': 18, 'diecinueve': 19,
    'veinte': 20, 'veintiun': 21, 'veintiuno': 21, 'veintiuna': 21,
    'veintidos': 22, 'veintitres': 23, 'veinticuatro': 24, 'veinticinco': 25,
    'veintiseis': 26, 'veintisiete': 27, 'veintiocho': 28, 'veintinueve': 29,
    'treinta': 30, 'cuarenta': 40, 'cincuenta': 50, 'sesenta': 60,
    'setenta': 70, 'ochenta': 80, 'noventa': 90,
    'cien': 100, 'ciento': 100,
    'doscientos': 200, 'doscientas': 200, 'trescientos': 300,
    'trescientas': 300, 'cuatrocientos': 400, 'cuatrocientas': 400,
    'quinientos': 500, 'quinientas': 500, 'seiscientos': 600,
    'seiscientas': 600, 'setecientos': 700, 'setecientas': 700,
    'ochocientos': 800, 'ochocientas': 800, 'novecientos': 900,
    'novecientas': 900,
  };

  /// Multipliers, including Colombian slang: una "luca"/"barra" = 1.000,
  /// un "palo" = 1.000.000.
  static const _multipliers = <String, int>{
    'mil': 1000, 'miles': 1000, 'k': 1000,
    'luca': 1000, 'lucas': 1000, 'barra': 1000, 'barras': 1000,
    'millon': 1000000, 'millones': 1000000,
    'palo': 1000000, 'palos': 1000000, 'melon': 1000000, 'melones': 1000000,
  };

  /// Multipliers that make sense on their own ("mil pesos" = 1.000).
  static const _standaloneMultipliers = {'mil', 'millon', 'millones'};

  static const currencyWords = {
    'peso', 'pesos', 'cop', 'plata', 'dinero', 'dolares', 'dolar', 'usd',
  };

  /// Below this, a bare number without any money signal is treated as a
  /// quantity ("2 almuerzos"), not as an amount in COP.
  static const _bareMinimum = 100;

  /// Convenience wrapper for callers that only have a plain string.
  static double? parse(String text) {
    final tokens = text
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    return findBest(tokens)?.value;
  }

  /// Returns the most plausible amount in [tokens], or `null`.
  ///
  /// [skip] lets the caller exclude token indexes already claimed by another
  /// parser (typically the date), so "el 5 de marzo gasté 20 mil" does not
  /// read the day as the amount.
  static AmountMatch? findBest(List<String> tokens, {Set<int> skip = const {}}) {
    final matches = findAll(tokens, skip: skip);
    if (matches.isEmpty) return null;

    // An explicit money signal always wins over a bare number.
    for (final match in matches) {
      if (match.hasCurrencySignal) return match;
    }
    final plausible =
        matches.where((m) => m.value >= _bareMinimum).toList();
    return plausible.isEmpty ? null : plausible.first;
  }

  /// Every amount-looking run in [tokens], in reading order.
  static List<AmountMatch> findAll(
    List<String> tokens, {
    Set<int> skip = const {},
  }) {
    final matches = <AmountMatch>[];
    var index = 0;
    while (index < tokens.length) {
      if (skip.contains(index)) {
        index++;
        continue;
      }
      final match = _matchAt(tokens, index, skip);
      if (match != null && match.end > match.start) {
        matches.add(match);
        index = match.end;
      } else {
        index++;
      }
    }
    return matches;
  }

  /// Tries to read one amount starting exactly at [start].
  static AmountMatch? _matchAt(List<String> tokens, int start, Set<int> skip) {
    var total = 0.0;
    var current = 0.0;
    var sawNumber = false;
    var hasSignal = false;
    var lastUsed = -1;
    var index = start;

    while (index < tokens.length && !skip.contains(index)) {
      final token = _clean(tokens[index]);
      if (token.isEmpty) break;

      // "treinta y cinco" — the connector only continues an ongoing number.
      if (token == 'y' && sawNumber) {
        index++;
        continue;
      }

      final unit = _units[token];
      if (unit != null) {
        // "cien mil quinientos": hundreds and tens add up, they don't chain.
        current += unit;
        sawNumber = true;
        lastUsed = index;
        index++;
        continue;
      }

      final digits = _parseDigits(token);
      if (digits != null) {
        if (sawNumber && current > 0 && digits.value >= current) break;
        current += digits.value;
        sawNumber = true;
        hasSignal = hasSignal || digits.hasSignal;
        lastUsed = index;
        index++;
        continue;
      }

      final multiplier = _multipliers[token];
      if (multiplier != null) {
        if (!sawNumber && !_standaloneMultipliers.contains(token)) break;
        total += (current == 0 ? 1 : current) * multiplier;
        current = 0;
        sawNumber = true;
        hasSignal = true;
        lastUsed = index;
        index++;
        continue;
      }

      if (currencyWords.contains(token) && sawNumber) {
        hasSignal = true;
        lastUsed = index;
        index++;
        continue;
      }

      break;
    }

    if (!sawNumber || lastUsed < 0) return null;
    final value = total + current;
    if (value <= 0) return null;

    return AmountMatch(
      value: value,
      start: start,
      end: lastUsed + 1,
      hasCurrencySignal: hasSignal,
    );
  }

  /// Strips surrounding punctuation but keeps the inner separators of
  /// "25.000" / "25,50".
  static String _clean(String token) =>
      token.replaceAll(RegExp(r'''^[^\w$]+|[^\w%]+$'''), '');

  static _DigitValue? _parseDigits(String raw) {
    var token = raw;
    var hasSignal = false;

    if (token.startsWith(r'$')) {
      token = token.substring(1);
      hasSignal = true;
    }
    if (token.isEmpty) return null;

    // "25k" / "25mil" / "1.5m" written without a space.
    for (final suffix in const ['mil', 'k', 'm']) {
      if (token.length > suffix.length && token.endsWith(suffix)) {
        final head = token.substring(0, token.length - suffix.length);
        final base = _parseNumeric(head);
        if (base != null) {
          final factor = suffix == 'm' ? 1000000 : 1000;
          return _DigitValue(base * factor, true);
        }
      }
    }

    final value = _parseNumeric(token);
    if (value == null) return null;
    return _DigitValue(value, hasSignal);
  }

  /// Reads a number written with Colombian conventions: `.` groups thousands
  /// and `,` marks decimals, but a lone separator followed by exactly three
  /// digits is treated as a thousands group either way ("25,000" = 25.000).
  static double? _parseNumeric(String token) {
    if (!RegExp(r'^\d').hasMatch(token)) return null;

    // 1.234.567,89
    if (RegExp(r'^\d{1,3}(\.\d{3})+,\d{1,2}$').hasMatch(token)) {
      return double.tryParse(token.replaceAll('.', '').replaceAll(',', '.'));
    }
    // 1,234,567.89
    if (RegExp(r'^\d{1,3}(,\d{3})+\.\d{1,2}$').hasMatch(token)) {
      return double.tryParse(token.replaceAll(',', ''));
    }
    // Pure thousands groups, either separator.
    if (RegExp(r'^\d{1,3}([.,]\d{3})+$').hasMatch(token)) {
      return double.tryParse(token.replaceAll(RegExp(r'[.,]'), ''));
    }
    // A single separator with 1-2 decimals is a decimal value ("1,5 millones").
    if (RegExp(r'^\d+[.,]\d{1,2}$').hasMatch(token)) {
      return double.tryParse(token.replaceAll(',', '.'));
    }
    if (RegExp(r'^\d+$').hasMatch(token)) {
      return double.tryParse(token);
    }
    return null;
  }

  /// True when the token is part of the vocabulary the parser consumes, so
  /// the description builder can drop leftovers like "pesos".
  static bool isNumberWord(String token) {
    final clean = _clean(token);
    return _units.containsKey(clean) ||
        _multipliers.containsKey(clean) ||
        currencyWords.contains(clean);
  }
}

class _DigitValue {
  final double value;
  final bool hasSignal;

  const _DigitValue(this.value, this.hasSignal);
}
