import '../../../../core/utils/text_normalizer.dart';
import '../../../transactions/domain/category_matcher.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../entities/transaction_draft.dart';
import 'spanish_amount_parser.dart';

/// Turns the raw text of a receipt photo (from on-device OCR) into a
/// [TransactionDraft].
///
/// A receipt is almost always an expense, so the type is fixed. The work is
/// finding the *total* — never "the biggest number", which on a real receipt
/// is usually a barcode, a NIT or an invoice number — plus the merchant, the
/// line items and the printed date.
class ReceiptParser {
  const ReceiptParser._();

  /// Ordered by trust: the earlier the label matches, the more we believe it.
  /// Only a labelled amount is ever accepted as the total.
  static const _totalLabels = <String>[
    'total a pagar',
    'total pagar',
    'neto a pagar',
    'valor a pagar',
    'total factura',
    'total venta',
    'total compra',
    'valor total',
    'importe total',
    'monto total',
    'gran total',
    'total general',
    'total neto',
    'a pagar',
    'total',
  ];

  /// Lines carrying these never hold the amount we want.
  static const _totalBlocklist = <String>[
    'subtotal', 'sub total', 'total items', 'total articulos', 'total art',
    'total unidades', 'total descuento', 'total ahorro', 'base gravable',
    'iva', 'impuesto', 'impoconsumo', 'cambio', 'efectivo', 'recibido',
    'propina', 'descuento', 'devuelta', 'su ahorro', 'puntos',
  ];

  /// Header noise that is never the merchant name.
  static const _merchantBlocklist = <String>[
    'nit', 'factura', 'ticket', 'recibo', 'caja', 'cajero', 'vendedor',
    'tel', 'telefono', 'direccion', 'calle', 'carrera', 'cra', 'cll',
    'avenida', 'regimen', 'resolucion', 'dian', 'autorizacion', 'sucursal',
    'fecha', 'hora', 'cliente', 'documento', 'pos', 'www', 'gracias',
  ];

  /// Lines that are structure or invoice header fields, not products.
  static const _itemBlocklist = <String>[
    ..._totalBlocklist,
    ..._merchantBlocklist,
    'total', 'a pagar', 'cantidad', 'descripcion', 'valor', 'precio',
    'unitario', 'articulo', 'items', 'forma de pago', 'tarjeta', 'credito',
    'debito', 'aprobacion', 'terminal', 'lote', 'referencia', 'codigo',
    'cufe', 'qr', 'firma',
    // Invoice header fields that carry a number and would otherwise read as
    // a product line ("CONSUMIDOR FINAL  222222222").
    'consumidor final', 'consumidor', 'razon social', 'nombre', 'identificacion',
    'cedula', 'cc', 'ciudad', 'departamento', 'municipio',
    'telefono', 'celular', 'correo', 'email', 'mesa', 'mesero', 'atendido',
    'punto de venta', 'transaccion', 'autorizacion', 'establecimiento',
  ];

  /// A price at the end of the line: either grouped ("4.500", "12.733") or a
  /// plain figure of at most six digits. Longer unseparated runs are document
  /// numbers, not money.
  static final _trailingPrice = RegExp(
    r'(\$?\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{2})?|\$?\d{1,6}(?:[.,]\d{2})?)\s*$',
  );

  /// Colombian receipts usually print the quantity before the product
  /// ("2 AREPA QUESO   6.000"). Matching it lets us both strip it from the
  /// name and recognise that the receipt uses that layout.
  static final _quantityPrefix = RegExp(
    r'^\s*\d{1,3}(?:[.,]\d{1,3})?\s*(?:x|un|und|uds|u|kg|gr|grs|g|lt|lts|ml)?\s+(?=[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ])',
    caseSensitive: false,
  );

  /// Seven or more consecutive digits: barcodes, NITs, document and invoice
  /// numbers. A price always breaks into groups well before that.
  static final _longDigitRun = RegExp(r'\d{7,}');

  static const _months = <String, int>{
    'ene': 1, 'enero': 1, 'feb': 2, 'febrero': 2, 'mar': 3, 'marzo': 3,
    'abr': 4, 'abril': 4, 'may': 5, 'mayo': 5, 'jun': 6, 'junio': 6,
    'jul': 7, 'julio': 7, 'ago': 8, 'agosto': 8, 'sep': 9, 'sept': 9,
    'septiembre': 9, 'setiembre': 9, 'oct': 10, 'octubre': 10, 'nov': 11,
    'noviembre': 11, 'dic': 12, 'diciembre': 12,
  };

  /// Parses OCR [text]. Always returns a draft, possibly with null fields.
  static TransactionDraft parse(String text, {DateTime? reference}) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final amount = _findTotal(lines);
    final merchant = _findMerchant(lines);
    final products = _findProducts(lines);
    final date = _findDate(lines, reference: reference);

    final description = _buildDescription(merchant, products);
    final category = CategoryMatcher.suggest(
      [merchant, ...products].whereType<String>().join(' '),
      type: TransactionType.expense,
    );

    return TransactionDraft(
      amount: amount,
      // A receipt is money going out; the user can still flip it in the form.
      type: TransactionType.expense,
      category: category,
      description: description,
      date: date,
      source: CaptureSource.receipt,
      merchant: merchant,
      products: products,
      rawText: text.trim(),
    );
  }

  // ── Total ────────────────────────────────────────────────────────────────

  /// Returns the amount printed next to a TOTAL-like label, or `null`.
  ///
  /// Deliberately has **no** "largest number" fallback: an unlabelled big
  /// number on a receipt is far more often a barcode or a document number
  /// than the total, and a wrong amount is worse than an empty field.
  static double? _findTotal(List<String> lines) {
    // Two views of each line: labels are matched on the letters-only form,
    // amounts are read from the form that still has its `.` and `,` — losing
    // those would turn "12.733" into a 733.
    final labels = lines.map(TextNormalizer.normalizeWords).toList();
    final values = lines.map(TextNormalizer.normalize).toList();

    for (final label in _totalLabels) {
      for (var i = 0; i < labels.length; i++) {
        if (!_containsPhrase(labels[i], label)) continue;
        if (_totalBlocklist.any((b) => _containsPhrase(labels[i], b))) continue;

        // The value usually sits on the same line; some layouts push it to
        // the next one.
        final sameLine = _largestAmountIn(values[i]);
        if (sameLine != null) return sameLine;
        if (i + 1 < values.length) {
          final nextLine = _largestAmountIn(values[i + 1]);
          if (nextLine != null) return nextLine;
        }
      }
    }
    return null;
  }

  static double? _largestAmountIn(String normalizedLine) {
    final tokens = normalizedLine
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    final matches = SpanishAmountParser.findAll(tokens);
    double? best;
    for (final match in matches) {
      // Line numbers, quantities and item counts are too small to be a total.
      if (match.value < 100) continue;
      if (best == null || match.value > best) best = match.value;
    }
    return best;
  }

  /// Whole-word phrase containment, so "subtotal" does not match "total".
  static bool _containsPhrase(String haystack, String needle) {
    var from = 0;
    while (true) {
      final index = haystack.indexOf(needle, from);
      if (index == -1) return false;
      final before = index == 0 ? ' ' : haystack[index - 1];
      final afterIndex = index + needle.length;
      final after = afterIndex >= haystack.length ? ' ' : haystack[afterIndex];
      final isWord = RegExp(r'[a-z0-9]');
      if (!isWord.hasMatch(before) && !isWord.hasMatch(after)) return true;
      from = index + 1;
    }
  }

  // ── Merchant ─────────────────────────────────────────────────────────────

  /// The merchant is normally the first real line of the header.
  static String? _findMerchant(List<String> lines) {
    final limit = lines.length < 8 ? lines.length : 8;
    for (var i = 0; i < limit; i++) {
      final raw = lines[i];
      final normalized = TextNormalizer.normalizeWords(raw);
      if (normalized.length < 4) continue;
      if (_merchantBlocklist.any((b) => _containsPhrase(normalized, b))) {
        continue;
      }

      final letters = normalized.replaceAll(RegExp(r'[^a-z]'), '');
      // Mostly digits (NITs, phone numbers, codes) is not a name.
      if (letters.length < 4) continue;
      if (letters.length < normalized.replaceAll(' ', '').length / 2) continue;

      return TextNormalizer.capitalize(raw.toLowerCase());
    }
    return null;
  }

  // ── Line items ───────────────────────────────────────────────────────────

  /// Product lines: a name with a price at the end of the line.
  ///
  /// Receipts are noisy — header fields like "CONSUMIDOR FINAL 222222222" look
  /// superficially like an item. Three structural rules keep them out: the
  /// price must sit at the *end* of the line, the line must contain no long
  /// digit run (barcodes, NITs, document numbers), and known header labels are
  /// rejected outright.
  ///
  /// On top of that, when the receipt prints the quantity before the product —
  /// the usual Colombian layout — only quantity-prefixed lines are accepted,
  /// since on such a receipt anything without a quantity is not an item.
  static List<String> _findProducts(List<String> lines) {
    final candidates = <_ItemLine>[];

    for (final raw in lines) {
      final labels = TextNormalizer.normalizeWords(raw);
      if (labels.length < 3) continue;
      if (_itemBlocklist.any((b) => _containsPhrase(labels, b))) continue;

      // Drop barcodes/PLUs/document numbers first. Supermarket receipts often
      // print the code before the product, so removing the run keeps a real
      // item ("7702004003114 ARROZ DIANA 4.500") while a header field left
      // with nothing but its id ("CONSUMIDOR FINAL 222222222") loses the very
      // number that made it look like a priced line.
      final cleaned = raw.replaceAll(_longDigitRun, ' ').trimRight();

      final priceMatch = _trailingPrice.firstMatch(cleaned);
      if (priceMatch == null) continue;

      // The trailing figure has to be money-sized to be a price.
      final price = SpanishAmountParser.parse(priceMatch.group(1)!);
      if (price == null || price < 100) continue;

      final body = cleaned.substring(0, priceMatch.start);
      final hasQuantity = _quantityPrefix.hasMatch(body);

      final name = _extractItemName(body);
      if (name == null) continue;

      candidates.add(_ItemLine(name: name, hasQuantity: hasQuantity));
    }

    // If the receipt uses the quantity-first layout, trust it and drop
    // everything that does not follow it.
    final quantified = candidates.where((c) => c.hasQuantity).toList();
    final selected = quantified.length >= 2 ? quantified : candidates;

    final products = <String>[];
    for (final candidate in selected) {
      if (!products.contains(candidate.name)) products.add(candidate.name);
    }
    return products;
  }

  /// Strips the quantity prefix, leftover numeric columns and unit markers,
  /// leaving the product name.
  static String? _extractItemName(String body) {
    var text = body.replaceFirst(_quantityPrefix, ' ');

    // Any remaining numeric column ("2 x 4.500", unit prices, PLU codes).
    text = text.replaceAll(RegExp(r'\$?\d[\d.,]*'), ' ');
    // Leftover operators and separators from the stripped columns.
    text = text.replaceAll(RegExp(r'[xX*@|:•\-_/]+'), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Unit markers left dangling after the numbers went away.
    text = text
        .replaceAll(
            RegExp(r'\b(kg|gr|grs|g|ml|lt|lts|und|un|uds|c\/u)\b',
                caseSensitive: false),
            '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Needs a real word, not a stray initial left behind by the cleanup.
    final hasWord = RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]{3,}').hasMatch(text);
    if (!hasWord) return null;

    return TextNormalizer.capitalize(text.toLowerCase());
  }

  /// The description the form gets: the store plus what was bought.
  static String? _buildDescription(String? merchant, List<String> products) {
    if (products.isEmpty) return merchant;

    const maxProducts = 5;
    final shown = products.take(maxProducts).join(', ');
    final remaining = products.length - maxProducts;
    final list = remaining > 0 ? '$shown y $remaining más' : shown;

    return merchant == null ? list : '$merchant: $list';
  }

  // ── Date ─────────────────────────────────────────────────────────────────

  /// Finds the receipt date, working out which number is the day and which
  /// is the month instead of assuming a single layout.
  ///
  /// Handles `dd/mm/yyyy`, `mm/dd/yyyy`, ISO `yyyy-mm-dd`, two-digit years and
  /// month names (`10 AGO 2026`, `10 de agosto de 2026`). Lines labelled
  /// "fecha" win over any other date-looking text.
  static DateTime? _findDate(List<String> lines, {DateTime? reference}) {
    final now = reference ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // A line that says "fecha" is the most reliable source.
    for (final pass in [true, false]) {
      for (final raw in lines) {
        final labelled =
            _containsPhrase(TextNormalizer.normalizeWords(raw), 'fecha');
        if (labelled != pass) continue;

        final date = _dateInLine(raw, today);
        if (date != null) return date;
      }
    }
    return null;
  }

  static DateTime? _dateInLine(String raw, DateTime today) {
    final text = TextNormalizer.normalize(raw);

    // 1. Month by name: "10 ago 2026", "10 de agosto de 2026", "ago 10 2026".
    final named = _namedMonthDate(text, today);
    if (named != null) return named;

    // 2. Three numeric groups.
    final pattern = RegExp(r'(\d{1,4})[/\-.](\d{1,2})[/\-.](\d{1,4})');
    for (final match in pattern.allMatches(text)) {
      final a = int.parse(match.group(1)!);
      final b = int.parse(match.group(2)!);
      final c = int.parse(match.group(3)!);

      final resolved = _resolveNumericDate(a, b, c, today);
      if (resolved != null) return resolved;
    }
    return null;
  }

  /// Works out the layout of three numbers, in this order:
  /// a 4-digit group pins the year; a value over 12 pins the day; if both the
  /// first two could be a day, Colombian `dd/mm` wins — unless that lands in
  /// the future and the `mm/dd` reading does not.
  static DateTime? _resolveNumericDate(int a, int b, int c, DateTime today) {
    // ISO: yyyy-mm-dd
    if (a > 31) {
      return _validate(year: a, month: b, day: c, today: today);
    }

    final year = _expandYear(c, today);
    if (year == null) return null;

    // A value over 12 can only be the day.
    if (a > 12 && b <= 12) {
      return _validate(year: year, month: b, day: a, today: today);
    }
    if (b > 12 && a <= 12) {
      return _validate(year: year, month: a, day: b, today: today);
    }
    if (a > 12 && b > 12) return null;

    // Ambiguous: both fit as a day. Colombia prints dd/mm, so try that first,
    // and only swap if it would put the receipt in the future.
    final dayFirst = _validate(year: year, month: b, day: a, today: today);
    if (dayFirst != null) return dayFirst;
    return _validate(year: year, month: a, day: b, today: today);
  }

  static DateTime? _namedMonthDate(String text, DateTime today) {
    // "10 de agosto de 2026" / "10 ago 2026" / "10-ago-26"
    final dayFirst = RegExp(
      r'\b(\d{1,2})\s*(?:de\s+)?[\-/ ]?\s*([a-z]{3,10})\.?\s*(?:de\s+)?[\-/ ]?\s*(\d{2,4})?\b',
    );
    for (final match in dayFirst.allMatches(text)) {
      final month = _months[match.group(2)!];
      if (month == null) continue;
      final day = int.parse(match.group(1)!);
      final rawYear = match.group(3);
      final year = rawYear == null
          ? today.year
          : _expandYear(int.parse(rawYear), today);
      if (year == null) continue;

      final date = _validate(year: year, month: month, day: day, today: today);
      if (date != null) return date;
      // A date ahead of today with no explicit year means last year.
      if (rawYear == null) {
        final previous = _validate(
            year: year - 1, month: month, day: day, today: today);
        if (previous != null) return previous;
      }
    }
    return null;
  }

  /// Turns a 2-digit year into a 4-digit one; rejects implausible years.
  static int? _expandYear(int raw, DateTime today) {
    if (raw >= 100) {
      return (raw >= 2000 && raw <= today.year) ? raw : null;
    }
    final expanded = 2000 + raw;
    return expanded <= today.year ? expanded : null;
  }

  /// Accepts a date only if it is real and not in the future — a receipt
  /// cannot have been printed tomorrow.
  static DateTime? _validate({
    required int year,
    required int month,
    required int day,
    required DateTime today,
  }) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    if (year < 2000 || year > today.year) return null;

    final date = DateTime(year, month, day);
    // DateTime rolls overflow over (Feb 30 -> Mar 2); reject those.
    if (date.month != month || date.day != day) return null;
    if (date.isAfter(today)) return null;
    return date;
  }
}

/// A candidate product line and whether it followed the quantity-first layout.
class _ItemLine {
  final String name;
  final bool hasQuantity;

  const _ItemLine({required this.name, required this.hasQuantity});
}
