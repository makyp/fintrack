import 'package:intl/intl.dart';

import '../domain/currency.dart';
import '../domain/currency_registry.dart';

class CurrencyFormatter {
  /// Formats [amount] in [code], or in the user's base currency when [code]
  /// is omitted — which is what almost every call site wants, since most
  /// people keep everything in one currency.
  static String format(
    double amount, {
    String? code,
    String locale = 'es_CO',
    bool showSign = false,
    bool compact = false,
  }) {
    final currency = Currency.byCode(code ?? CurrencyRegistry.base);
    final symbol = currency.symbol;

    if (compact) {
      if (amount.abs() >= 1000000) {
        return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
      }
      if (amount.abs() >= 1000) {
        return '$symbol${(amount / 1000).toStringAsFixed(0)}K';
      }
    }

    final pattern =
        currency.decimals == 0 ? '#,##0' : '#,##0.${'0' * currency.decimals}';
    final formatted = NumberFormat(pattern, locale).format(amount.abs());
    final sign = showSign ? (amount >= 0 ? '+' : '-') : (amount < 0 ? '-' : '');
    return '$sign$symbol$formatted';
  }

  /// Same as [format] but always signed — for deltas and comparisons.
  static String formatChange(double amount, {String? code}) =>
      format(amount, code: code, showSign: true);

  /// Amount plus its code ("US$1.200 USD"), for the places where two
  /// currencies sit next to each other and the symbol alone is ambiguous.
  static String formatWithCode(double amount, String code,
      {bool compact = false}) {
    final upper = code.trim().toUpperCase();
    return '${format(amount, code: upper, compact: compact)} $upper';
  }

  static String formatPercent(double percent) {
    final sign = percent >= 0 ? '+' : '';
    return '$sign${percent.toStringAsFixed(1)}%';
  }
}
