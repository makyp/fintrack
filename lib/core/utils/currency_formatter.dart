import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(
    double amount, {
    String currencySymbol = '\$',
    String locale = 'es_CO',
    bool showSign = false,
    bool compact = false,
  }) {
    if (compact) {
      if (amount.abs() >= 1000000) {
        return '$currencySymbol${(amount / 1000000).toStringAsFixed(1)}M';
      }
      if (amount.abs() >= 1000) {
        return '$currencySymbol${(amount / 1000).toStringAsFixed(0)}K';
      }
    }

    final formatter = NumberFormat('#,##0', locale);
    final formatted = formatter.format(amount.abs());
    final sign = showSign ? (amount >= 0 ? '+' : '-') : (amount < 0 ? '-' : '');
    return '$sign$currencySymbol$formatted';
  }

  static String formatChange(double amount, {String currencySymbol = '\$'}) {
    final sign = amount >= 0 ? '+' : '-';
    final formatter = NumberFormat('#,##0', 'es_CO');
    return '$sign$currencySymbol${formatter.format(amount.abs())}';
  }

  static String formatPercent(double percent) {
    final sign = percent >= 0 ? '+' : '';
    return '$sign${percent.toStringAsFixed(1)}%';
  }
}
