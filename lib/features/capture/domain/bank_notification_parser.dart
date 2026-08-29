import '../../transactions/domain/category_matcher.dart';
import '../../transactions/domain/entities/transaction_type.dart';
import '../../transactions/domain/statement_parser.dart';
import 'entities/transaction_draft.dart';

/// A notification the listener kept, as it arrived from Android.
class BankNotification {
  /// App that posted it (`com.bancolombia.app`, …).
  final String packageName;
  final String title;
  final String text;
  final DateTime postedAt;

  const BankNotification({
    required this.packageName,
    required this.title,
    required this.text,
    required this.postedAt,
  });

  String get fullText => '$title. $text'.trim();

  factory BankNotification.fromJson(Map<String, dynamic> json) {
    final millis = (json['postedAt'] as num?)?.toInt();
    return BankNotification(
      packageName: json['package'] as String? ?? '',
      title: json['title'] as String? ?? '',
      text: json['text'] as String? ?? '',
      postedAt: millis != null
          ? DateTime.fromMillisecondsSinceEpoch(millis)
          : DateTime.now(),
    );
  }

  /// Same purchase notified twice (the bank often posts an update) is one
  /// movement as far as the user is concerned.
  String get fingerprint => '$packageName|${fullText.toLowerCase()}';
}

/// Reads a bank's push notification and works out what movement it describes.
///
/// This is the closest thing to automatic capture that costs nothing: the bank
/// already tells the phone about every purchase, so the amount and the shop
/// are right there. Nothing here is ever saved on its own — a match becomes a
/// [TransactionDraft] the user confirms in the normal form.
class BankNotificationParser {
  const BankNotificationParser._();

  /// Wording that means money left the account.
  static const _expenseHints = [
    'compra', 'pago', 'pagaste', 'retiro', 'retiraste', 'enviaste',
    'transferencia a', 'transferiste', 'debito', 'cargo', 'consumo',
    'avance', 'suscripcion',
  ];

  /// Wording that means money came in.
  static const _incomeHints = [
    'recibiste', 'te enviaron', 'consignacion', 'consignaron', 'abono',
    'deposito', 'depositaron', 'devolucion', 'reembolso', 'nomina',
    'transferencia de', 'te llego',
  ];

  /// Notifications that carry an amount but are not a movement: they would
  /// otherwise show up as a purchase for the balance itself.
  static const _ignoreHints = [
    'saldo', 'cupo disponible', 'codigo', 'clave', 'otp', 'token',
    'promocion', 'aprovecha', 'felicidades', 'gana', 'sorteo', 'cuota de manejo',
    'proximo pago', 'vence', 'recuerda pagar', 'extracto', 'intento de',
    'rechazada', 'declinada', 'no autorizada',
  ];

  /// Amount preceded by a currency mark or by "por", which is how every bank
  /// in the region writes it.
  static final _amountPattern = RegExp(
    r'(?:\$|us\$|cop|usd|eur|mxn|pen|clp|ars|brl|s/|€|por)\s*'
    r'([\d][\d.,]*\d|\d)',
    caseSensitive: false,
  );

  /// The shop or person: what follows "en", "a" or "de" up to the end of the
  /// sentence or the next bit of banking boilerplate.
  static final _merchantPattern = RegExp(
    r'\b(?:en|a|de)\s+([A-Za-zÁÉÍÓÚÑáéíóúñ0-9][^.,;]{2,40})',
    caseSensitive: false,
  );

  static final _cardNoise = RegExp(
    r'\b(?:con\s+)?(?:tu\s+|su\s+)?(?:tarjeta|cuenta|producto|debito|credito)\b.*',
    caseSensitive: false,
  );

  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ñ', 'n');

  /// True when the text looks like a movement at all — the cheap check the
  /// native listener uses before keeping a notification around.
  static bool looksLikeMovement(String text) {
    final normalized = _normalize(text);
    if (_ignoreHints.any(normalized.contains)) return false;
    if (!_amountPattern.hasMatch(text)) return false;
    return _expenseHints.any(normalized.contains) ||
        _incomeHints.any(normalized.contains);
  }

  /// Turns a notification into a draft, or null when it is not a movement.
  static TransactionDraft? parse(BankNotification notification) {
    final text = notification.fullText;
    if (!looksLikeMovement(text)) return null;

    final amount = _amount(text);
    if (amount == null || amount <= 0) return null;

    final normalized = _normalize(text);
    // An outgoing transfer and an incoming one differ by a single word, so
    // whichever hint appears first in the sentence wins.
    final type = _resolveType(normalized);
    final merchant = _merchant(text);
    final description = merchant ?? notification.title.trim();

    return TransactionDraft(
      amount: amount,
      type: type,
      category: CategoryMatcher.suggest(description, type: type),
      description: description.isEmpty ? null : description,
      date: notification.postedAt,
      source: CaptureSource.notification,
      merchant: merchant,
      rawText: text,
    );
  }

  static TransactionType _resolveType(String normalized) {
    var expenseAt = -1;
    for (final hint in _expenseHints) {
      final index = normalized.indexOf(hint);
      if (index >= 0 && (expenseAt < 0 || index < expenseAt)) expenseAt = index;
    }
    var incomeAt = -1;
    for (final hint in _incomeHints) {
      final index = normalized.indexOf(hint);
      if (index >= 0 && (incomeAt < 0 || index < incomeAt)) incomeAt = index;
    }
    if (incomeAt < 0) return TransactionType.expense;
    if (expenseAt < 0) return TransactionType.income;
    return incomeAt < expenseAt
        ? TransactionType.income
        : TransactionType.expense;
  }

  static double? _amount(String text) {
    // The biggest match wins: a notification that mentions both the purchase
    // and the four digits of the card should not book $1.234.
    double? best;
    for (final match in _amountPattern.allMatches(text)) {
      final value = StatementParser.parseAmount(match.group(1)!);
      if (value == null) continue;
      if (best == null || value.abs() > best.abs()) best = value.abs();
    }
    return best;
  }

  static String? _merchant(String text) {
    // Cut the card boilerplate first, or "en EXITO con tu tarjeta *1234"
    // comes back with the card attached.
    final cleaned = text.replaceAll(_cardNoise, ' ').trim();
    for (final match in _merchantPattern.allMatches(cleaned)) {
      final candidate = match.group(1)!.trim();
      // "por 45.000 en" leaves numbers behind; a shop name has letters.
      if (!RegExp(r'[A-Za-zÁÉÍÓÚÑáéíóúñ]{3}').hasMatch(candidate)) continue;
      final normalized = _normalize(candidate);
      if (_expenseHints.any(normalized.startsWith) ||
          _incomeHints.any(normalized.startsWith)) {
        continue;
      }
      return _tidy(candidate);
    }
    return null;
  }

  /// "RAPPI COLOMBIA SAS " → "Rappi Colombia Sas": banks shout, the app
  /// doesn't have to.
  static String _tidy(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed != trimmed.toUpperCase()) return trimmed;
    return trimmed
        .split(' ')
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}
