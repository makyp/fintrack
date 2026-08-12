import '../../../../core/utils/text_normalizer.dart';
import '../../../transactions/domain/category_matcher.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../entities/transaction_draft.dart';
import 'spanish_amount_parser.dart';
import 'spanish_date_parser.dart';

/// Turns a dictated sentence into a [TransactionDraft].
///
/// Works entirely on-device over the transcript the speech recognizer
/// produced. Nothing is saved here — the draft only prefills the form.
///
/// Handles phrasings like:
///   "gasté 25 mil en almuerzo"
///   "pagué el internet 80.000 ayer"
///   "me pagaron el salario dos millones"
///   "transferí 100 mil a ahorros el 5 de marzo"
class VoiceTransactionParser {
  const VoiceTransactionParser._();

  /// Verbs and nouns that reveal the transaction type. Accent-stripped,
  /// because that is how tokens reach the parser.
  static const _expenseVerbs = {
    'gaste', 'gastamos', 'gasto', 'pague', 'pagamos', 'compre', 'compramos',
    'costo', 'costaron', 'salio', 'invertir', 'consigne',
  };

  static const _incomeVerbs = {
    'recibi', 'recibimos', 'cobre', 'cobramos', 'gane', 'ganamos',
    'pagaron', 'ingreso', 'ingresaron', 'entro', 'entraron', 'llego',
    'llegaron', 'depositaron', 'vendi', 'vendimos', 'regalaron',
  };

  static const _transferVerbs = {
    'transferi', 'transfiero', 'transferimos', 'mover', 'movi', 'pase',
    'traslade',
  };

  /// Nouns strong enough to imply income when no verb was said
  /// ("salario dos millones").
  static const _incomeNouns = {
    'salario', 'sueldo', 'nomina', 'quincena', 'bono', 'prima', 'dividendo',
    'comision', 'honorarios',
  };

  /// Dropped from the front and back of the description.
  static const _connectors = {
    'en', 'de', 'del', 'por', 'para', 'a', 'al', 'el', 'la', 'los', 'las',
    'un', 'una', 'unos', 'unas', 'mi', 'mis', 'me', 'se', 'lo', 'y', 'que',
    'con', 'fue', 'era', 'hoy',
  };

  /// Parses [transcript] into a draft. Always returns a draft — an empty one
  /// when nothing could be extracted.
  static TransactionDraft parse(String transcript, {DateTime? reference}) {
    final rawTokens = transcript
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    if (rawTokens.isEmpty) {
      return TransactionDraft(source: CaptureSource.voice, rawText: transcript);
    }

    final normalized =
        rawTokens.map((t) => TextNormalizer.normalize(t)).toList();
    final consumed = <int>{};

    // 1. Date first, so its digits can't be mistaken for the amount.
    final dateMatch = SpanishDateParser.find(normalized, reference: reference);
    if (dateMatch != null) consumed.addAll(dateMatch.tokens);

    // 2. Amount, skipping whatever the date already claimed.
    final amountMatch =
        SpanishAmountParser.findBest(normalized, skip: consumed);
    if (amountMatch != null) {
      for (var i = amountMatch.start; i < amountMatch.end; i++) {
        consumed.add(i);
      }
    }

    // 3. Type, from the verb that was said.
    final type = _detectType(normalized, consumed);

    // 4. Whatever is left becomes the description.
    final description = _buildDescription(rawTokens, normalized, consumed);

    // 5. Category from the description, falling back to the whole sentence.
    final categorySource = description.isNotEmpty ? description : transcript;
    final category = CategoryMatcher.suggest(
      categorySource,
      type: type ?? TransactionType.expense,
    );

    return TransactionDraft(
      amount: amountMatch?.value,
      type: type,
      category: category,
      description: description.isEmpty ? null : description,
      date: dateMatch?.date,
      source: CaptureSource.voice,
      rawText: transcript.trim(),
    );
  }

  /// Marks the type verb as consumed so it never reaches the description.
  static TransactionType? _detectType(List<String> tokens, Set<int> consumed) {
    for (var i = 0; i < tokens.length; i++) {
      if (consumed.contains(i)) continue;
      final token = _strip(tokens[i]);

      if (_expenseVerbs.contains(token)) {
        consumed.add(i);
        return TransactionType.expense;
      }
      if (_incomeVerbs.contains(token)) {
        consumed.add(i);
        return TransactionType.income;
      }
      if (_transferVerbs.contains(token)) {
        consumed.add(i);
        return TransactionType.transfer;
      }
    }

    // No verb: a strong income noun still tells us the direction. The noun is
    // kept in the description — it is the best label the user gave us.
    for (var i = 0; i < tokens.length; i++) {
      if (consumed.contains(i)) continue;
      if (_incomeNouns.contains(_strip(tokens[i]))) return TransactionType.income;
    }
    return null;
  }

  static String _buildDescription(
    List<String> rawTokens,
    List<String> normalized,
    Set<int> consumed,
  ) {
    final kept = <String>[];
    for (var i = 0; i < rawTokens.length; i++) {
      if (consumed.contains(i)) continue;
      final token = _strip(normalized[i]);
      if (token.isEmpty) continue;
      // Leftover money words carry no meaning for the label.
      if (SpanishAmountParser.currencyWords.contains(token)) continue;
      kept.add(rawTokens[i]);
    }

    // Trim connectors from both ends ("en almuerzo" -> "almuerzo").
    var start = 0;
    var end = kept.length;
    while (start < end && _connectors.contains(_strip(TextNormalizer.normalize(kept[start])))) {
      start++;
    }
    while (end > start && _connectors.contains(_strip(TextNormalizer.normalize(kept[end - 1])))) {
      end--;
    }
    if (start >= end) return '';

    final text = kept.sublist(start, end).join(' ').trim();
    // Drop trailing punctuation left over from the transcript.
    final cleaned = text.replaceAll(RegExp(r'[.,;:!?]+$'), '').trim();
    return TextNormalizer.capitalize(cleaned);
  }

  static String _strip(String token) =>
      token.replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '');
}
