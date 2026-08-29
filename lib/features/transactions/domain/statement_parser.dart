import 'entities/transaction_type.dart';

/// One row of a bank statement, already turned into something we can book.
class StatementEntry {
  final DateTime date;
  final String description;

  /// Always positive: the sign lives in [type].
  final double amount;
  final TransactionType type;

  /// The raw cells this came from, kept for the preview table.
  final List<String> raw;

  const StatementEntry({
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    this.raw = const [],
  });

  /// Two rows for the same day, amount and description are the same movement
  /// as far as anyone can tell — used to skip what is already in the app.
  String get fingerprint =>
      '${date.year}-${date.month}-${date.day}|'
      '${amount.toStringAsFixed(2)}|'
      '${description.toLowerCase().trim()}';
}

/// Which column of the file holds what. -1 means "not present".
class ColumnMapping {
  final int date;
  final int description;

  /// Single signed-amount column, when the bank uses one.
  final int amount;

  /// Separate debit / credit columns, when the bank uses two.
  final int debit;
  final int credit;

  const ColumnMapping({
    this.date = -1,
    this.description = -1,
    this.amount = -1,
    this.debit = -1,
    this.credit = -1,
  });

  bool get hasAmount => amount >= 0 || debit >= 0 || credit >= 0;
  bool get isUsable => date >= 0 && hasAmount;

  ColumnMapping copyWith({
    int? date,
    int? description,
    int? amount,
    int? debit,
    int? credit,
  }) {
    return ColumnMapping(
      date: date ?? this.date,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
    );
  }
}

/// A statement file broken into a header and rows, with a guess at what each
/// column means. Nothing is booked from here — the user confirms first.
class ParsedStatement {
  final List<String> header;
  final List<List<String>> rows;
  final ColumnMapping mapping;

  /// True when the first line looked like column titles rather than data.
  final bool hasHeader;

  const ParsedStatement({
    required this.header,
    required this.rows,
    required this.mapping,
    required this.hasHeader,
  });

  bool get isEmpty => rows.isEmpty;

  static const empty = ParsedStatement(
      header: [], rows: [], mapping: ColumnMapping(), hasHeader: false);
}

/// Turns a bank's CSV export into movements the user can review and import.
///
/// Banks disagree about everything — the separator, the date order, whether a
/// charge is a negative number or a column of its own — so every step guesses
/// from the file itself and the user can correct the guess in the preview.
class StatementParser {
  const StatementParser._();

  static const _maxRows = 2000;

  // ── Splitting ────────────────────────────────────────────────────────────

  /// The separator the file actually uses. Spanish-language exports usually
  /// use ';' because the comma is already the decimal mark.
  static String detectDelimiter(String content) {
    final sample = const LineSplitter().take(content, 10);
    var best = ',';
    var bestScore = -1;
    for (final candidate in [';', ',', '\t', '|']) {
      // A real separator appears the same number of times on every line.
      final counts =
          sample.map((l) => _countOutsideQuotes(l, candidate)).toList();
      if (counts.isEmpty || counts.first == 0) continue;
      final consistent = counts.every((c) => c == counts.first);
      final score = counts.first * (consistent ? 10 : 1);
      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }
    return best;
  }

  static int _countOutsideQuotes(String line, String delimiter) {
    var count = 0;
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (!inQuotes && ch == delimiter) {
        count++;
      }
    }
    return count;
  }

  /// Splits one line, honouring quoted cells and the doubled "" escape.
  static List<String> splitLine(String line, String delimiter) {
    final cells = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == delimiter && !inQuotes) {
        cells.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }
    cells.add(buffer.toString().trim());
    return cells;
  }

  // ── Values ───────────────────────────────────────────────────────────────

  /// Reads a date in any of the orders banks use. Ambiguous days (03/04) are
  /// read as day-first, which is what every bank in the region exports.
  static DateTime? parseDate(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final iso = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})').firstMatch(text);
    if (iso != null) {
      return _build(int.parse(iso.group(1)!), int.parse(iso.group(2)!),
          int.parse(iso.group(3)!));
    }

    final dmy =
        RegExp(r'^(\d{1,2})[-/.](\d{1,2})[-/.](\d{2,4})').firstMatch(text);
    if (dmy != null) {
      var year = int.parse(dmy.group(3)!);
      if (year < 100) year += year >= 70 ? 1900 : 2000;
      return _build(year, int.parse(dmy.group(2)!), int.parse(dmy.group(1)!));
    }

    // "15 ene 2026" / "15-ENE-26"
    final named = RegExp(r'^(\d{1,2})[\s\-/]+([a-zA-ZáéíóúÁÉÍÓÚ]{3,})[\s\-/]+(\d{2,4})')
        .firstMatch(text);
    if (named != null) {
      final month = _monthFromName(named.group(2)!);
      if (month != null) {
        var year = int.parse(named.group(3)!);
        if (year < 100) year += year >= 70 ? 1900 : 2000;
        return _build(year, month, int.parse(named.group(1)!));
      }
    }
    return null;
  }

  static DateTime? _build(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final date = DateTime(year, month, day);
    // DateTime rolls 31/02 into March — that was not a real date.
    if (date.month != month || date.day != day) return null;
    return date;
  }

  static const _months = {
    'ene': 1, 'jan': 1, 'feb': 2, 'mar': 3, 'abr': 4, 'apr': 4, 'may': 5,
    'jun': 6, 'jul': 7, 'ago': 8, 'aug': 8, 'sep': 9, 'set': 9, 'oct': 10,
    'nov': 11, 'dic': 12, 'dec': 12,
  };

  static int? _monthFromName(String name) {
    final key = name
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    if (key.length < 3) return null;
    return _months[key.substring(0, 3)];
  }

  /// Reads an amount written in either convention — "1.234,56" or "1,234.56" —
  /// plus the accounting habits: a leading minus, a trailing one, parentheses
  /// for negatives, and a currency symbol stuck to the number.
  static double? parseAmount(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return null;

    var negative = false;
    if (text.startsWith('(') && text.endsWith(')')) {
      negative = true;
      text = text.substring(1, text.length - 1);
    }
    if (text.endsWith('-')) {
      negative = true;
      text = text.substring(0, text.length - 1);
    }

    // Everything that is not a digit, a separator or a sign is decoration.
    text = text.replaceAll(RegExp(r'[^\d,.\-+]'), '').trim();
    if (text.startsWith('-')) {
      negative = true;
      text = text.substring(1);
    } else if (text.startsWith('+')) {
      text = text.substring(1);
    }
    if (text.isEmpty) return null;

    final lastComma = text.lastIndexOf(',');
    final lastDot = text.lastIndexOf('.');
    String normalized;
    if (lastComma >= 0 && lastDot >= 0) {
      // Whichever comes last is the decimal mark; the other groups thousands.
      normalized = lastComma > lastDot
          ? text.replaceAll('.', '').replaceAll(',', '.')
          : text.replaceAll(',', '');
    } else if (lastComma >= 0) {
      // A lone comma is decimal ("1234,56") unless it groups ("1,234").
      final decimals = text.length - lastComma - 1;
      normalized = decimals == 3 && text.split(',').length == 2 && lastComma > 0
          ? text.replaceAll(',', '')
          : text.replaceAll(',', '.');
    } else if (lastDot >= 0) {
      final decimals = text.length - lastDot - 1;
      // "1.234" is a thousands group in Spanish exports, not 1 unit 234.
      normalized = decimals == 3 ? text.replaceAll('.', '') : text;
    } else {
      normalized = text;
    }

    final value = double.tryParse(normalized);
    if (value == null) return null;
    return negative ? -value : value;
  }

  // ── Structure ────────────────────────────────────────────────────────────

  /// Column titles we recognise, by role. Matched without accents so
  /// "Descripción" and "Descripcion" both land.
  static const _headerHints = {
    'date': ['fecha', 'date', 'f. operacion', 'fecha operacion', 'fecha valor', 'dia'],
    'description': [
      'descripcion', 'concepto', 'detalle', 'referencia', 'description',
      'comercio', 'establecimiento', 'movimiento', 'transaccion', 'memo',
    ],
    'amount': ['monto', 'importe', 'valor', 'amount', 'total'],
    'debit': ['debito', 'cargo', 'gasto', 'salida', 'retiro', 'debit', 'egreso'],
    'credit': ['credito', 'abono', 'ingreso', 'deposito', 'entrada', 'credit'],
  };

  static String _normalize(String s) => s
      .toLowerCase()
      .trim()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ñ', 'n');

  static ColumnMapping _mapFromHeader(List<String> header) {
    var mapping = const ColumnMapping();
    for (var i = 0; i < header.length; i++) {
      final cell = _normalize(header[i]);
      if (cell.isEmpty) continue;
      for (final entry in _headerHints.entries) {
        if (!entry.value.any((hint) => cell.contains(hint))) continue;
        switch (entry.key) {
          case 'date':
            if (mapping.date < 0) mapping = mapping.copyWith(date: i);
          case 'description':
            if (mapping.description < 0) {
              mapping = mapping.copyWith(description: i);
            }
          case 'amount':
            if (mapping.amount < 0) mapping = mapping.copyWith(amount: i);
          case 'debit':
            if (mapping.debit < 0) mapping = mapping.copyWith(debit: i);
          case 'credit':
            if (mapping.credit < 0) mapping = mapping.copyWith(credit: i);
        }
        break;
      }
    }
    // "Saldo" columns often match 'valor' too; a file with debit/credit
    // columns does not need the single-amount one.
    if (mapping.debit >= 0 && mapping.credit >= 0) {
      mapping = mapping.copyWith(amount: -1);
    }
    return mapping;
  }

  /// Falls back to reading the data itself when the header is missing or
  /// unhelpful: the first column that parses as a date, the last one that
  /// parses as a number, and the longest text column for the description.
  static ColumnMapping _mapFromData(
      List<List<String>> rows, ColumnMapping partial) {
    var mapping = partial;
    if (rows.isEmpty) return mapping;
    final width = rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);

    int score(int column, bool Function(String) test) {
      var hits = 0;
      for (final row in rows) {
        if (column < row.length && test(row[column])) hits++;
      }
      return hits;
    }

    if (mapping.date < 0) {
      for (var i = 0; i < width; i++) {
        if (score(i, (c) => parseDate(c) != null) > rows.length / 2) {
          mapping = mapping.copyWith(date: i);
          break;
        }
      }
    }
    if (!mapping.hasAmount) {
      for (var i = width - 1; i >= 0; i--) {
        if (i == mapping.date) continue;
        if (score(i, (c) => c.isNotEmpty && parseAmount(c) != null) >
            rows.length / 2) {
          mapping = mapping.copyWith(amount: i);
          break;
        }
      }
    }
    if (mapping.description < 0) {
      var best = -1;
      var bestLength = 0;
      for (var i = 0; i < width; i++) {
        if (i == mapping.date || i == mapping.amount) continue;
        final length = rows.fold<int>(
            0, (sum, r) => sum + (i < r.length ? r[i].length : 0));
        // A column of numbers is not a description, however long it is.
        if (score(i, (c) => c.isNotEmpty && parseAmount(c) != null) >
            rows.length / 2) {
          continue;
        }
        if (length > bestLength) {
          bestLength = length;
          best = i;
        }
      }
      if (best >= 0) mapping = mapping.copyWith(description: best);
    }
    return mapping;
  }

  /// Reads the file into rows plus a first guess at the column roles.
  static ParsedStatement parse(String content) {
    // Strip the UTF-8 BOM Excel writes, or it becomes part of the first title.
    final text = content.startsWith('﻿') ? content.substring(1) : content;
    final lines = const LineSplitter()
        .split(text)
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return ParsedStatement.empty;

    final delimiter = detectDelimiter(text);
    final all = lines.map((l) => splitLine(l, delimiter)).toList();

    // The first line is a header when none of its cells reads as a date.
    final first = all.first;
    final hasHeader = first.every((c) => parseDate(c) == null) &&
        first.any((c) => c.isNotEmpty);

    final header = hasHeader
        ? first
        : List.generate(first.length, (i) => 'Columna ${i + 1}');
    var rows = hasHeader ? all.skip(1).toList() : all;
    if (rows.length > _maxRows) rows = rows.sublist(0, _maxRows);

    var mapping = hasHeader ? _mapFromHeader(first) : const ColumnMapping();
    mapping = _mapFromData(rows, mapping);

    return ParsedStatement(
        header: header, rows: rows, mapping: mapping, hasHeader: hasHeader);
  }

  /// Turns the rows into movements using [mapping]. Rows without a readable
  /// date or amount are dropped — a statement always carries subtotals and
  /// footers that are not movements.
  static List<StatementEntry> toEntries(
    ParsedStatement statement,
    ColumnMapping mapping,
  ) {
    final entries = <StatementEntry>[];
    for (final row in statement.rows) {
      String cell(int index) =>
          (index >= 0 && index < row.length) ? row[index] : '';

      final date = parseDate(cell(mapping.date));
      if (date == null) continue;

      double? signed;
      if (mapping.amount >= 0) {
        signed = parseAmount(cell(mapping.amount));
      } else {
        final debit = parseAmount(cell(mapping.debit));
        final credit = parseAmount(cell(mapping.credit));
        // A debit column is money leaving, whether or not the bank wrote the
        // minus sign; a credit column is money coming in.
        if (debit != null && debit != 0) {
          signed = -debit.abs();
        } else if (credit != null && credit != 0) {
          signed = credit.abs();
        }
      }
      if (signed == null || signed == 0) continue;

      entries.add(StatementEntry(
        date: date,
        description: cell(mapping.description),
        amount: signed.abs(),
        type: signed < 0 ? TransactionType.expense : TransactionType.income,
        raw: row,
      ));
    }
    return entries;
  }
}

/// Splits text into lines regardless of how the file ends them (\r\n, \n, \r).
class LineSplitter {
  const LineSplitter();

  List<String> split(String text) =>
      text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');

  List<String> take(String text, int count) {
    final lines = split(text).where((l) => l.trim().isNotEmpty).toList();
    return lines.length <= count ? lines : lines.sublist(0, count);
  }
}
