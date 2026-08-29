import 'currency.dart';

/// The result of adding up money that lives in several currencies.
class ConsolidatedAmount {
  /// The total, expressed in the base currency.
  final double amount;

  /// Currencies that were left out because the user has not given them a
  /// rate yet. Never silently converted at 1:1 — a wrong total is worse than
  /// an incomplete one, so the UI warns instead.
  final List<String> missingRates;

  const ConsolidatedAmount(this.amount, this.missingRates);

  bool get isComplete => missingRates.isEmpty;
}

/// In-memory snapshot of the user's base currency and exchange rates.
///
/// Same reasoning as [CategoryRegistry]: formatting an amount or adding up
/// balances happens in places with no BuildContext and no DI (models, the
/// home-screen widget service, the PDF generator), and has to be synchronous.
/// The auth bloc refreshes this whenever the profile changes.
///
/// Rates are stored as "how many units of the base currency one unit of the
/// foreign currency is worth" — the direction people actually quote out loud
/// ("el dólar está a 4.000").
class CurrencyRegistry {
  const CurrencyRegistry._();

  static const _defaultBase = 'COP';

  static String _base = _defaultBase;
  static Map<String, double> _rates = const {};

  /// Replaces base and rates. Called by the auth bloc on every profile load.
  static void snapshot({required String base, Map<String, double>? rates}) {
    _base = base.trim().toUpperCase();
    _rates = {
      for (final e in (rates ?? const <String, double>{}).entries)
        if (e.value > 0) e.key.trim().toUpperCase(): e.value,
    };
  }

  /// Back to the shipped default (sign-out, tests).
  static void reset() {
    _base = _defaultBase;
    _rates = const {};
  }

  static String get base => _base;

  static Currency get baseCurrency => Currency.byCode(_base);

  static Map<String, double> get rates => Map.unmodifiable(_rates);

  /// True once the user keeps money in something other than the base currency.
  static bool get hasRates => _rates.isNotEmpty;

  /// How many units of the base currency one unit of [code] is worth.
  /// The base itself is always 1; anything without a rate is null.
  static double? rateFor(String code) {
    final c = code.trim().toUpperCase();
    if (c == _base) return 1;
    return _rates[c];
  }

  /// [amount] expressed in [code], converted to the base currency.
  /// Null when there is no rate for [code] — the caller decides what to do
  /// rather than getting a number that looks right and isn't.
  static double? toBase(double amount, String code) {
    final rate = rateFor(code);
    return rate == null ? null : amount * rate;
  }

  /// [amount] expressed in the base currency, converted into [code].
  static double? fromBase(double amount, String code) {
    final rate = rateFor(code);
    return (rate == null || rate == 0) ? null : amount / rate;
  }

  /// Adds up amounts that may be in different currencies.
  /// [entries] maps each amount to the code it is expressed in.
  static ConsolidatedAmount consolidate(
      Iterable<MapEntry<double, String>> entries) {
    var total = 0.0;
    final missing = <String>{};
    for (final e in entries) {
      final converted = toBase(e.key, e.value);
      if (converted == null) {
        missing.add(e.value.trim().toUpperCase());
      } else {
        total += converted;
      }
    }
    final sorted = missing.toList()..sort();
    return ConsolidatedAmount(total, sorted);
  }
}
