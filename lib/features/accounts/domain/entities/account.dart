import 'package:equatable/equatable.dart';

import '../../../../core/domain/currency_registry.dart';

enum AccountType {
  cash,
  checking,
  savings,
  credit,
  investment,
  highYield;

  String get label {
    switch (this) {
      case AccountType.cash:
        return 'Efectivo';
      case AccountType.checking:
        return 'Cuenta corriente';
      case AccountType.savings:
        return 'Cuenta de ahorros';
      case AccountType.credit:
        return 'Tarjeta de crédito';
      case AccountType.investment:
        return 'Inversiones';
      case AccountType.highYield:
        return 'Alto rendimiento';
    }
  }

  String get icon {
    switch (this) {
      case AccountType.cash:
        return '💵';
      case AccountType.checking:
        return '🏦';
      case AccountType.savings:
        return '💰';
      case AccountType.credit:
        return '💳';
      case AccountType.investment:
        return '📈';
      case AccountType.highYield:
        return '🏆';
    }
  }

  /// Credit cards have negative balance (debt), assets are positive
  bool get isLiability => this == AccountType.credit;
}

class Account extends Equatable {
  final String id;
  final String userId;
  final String name;
  final AccountType type;
  final double balance;
  final String currency;
  final int colorValue;
  final String icon;
  final bool isArchived;
  final DateTime createdAt;
  /// Annual effective interest rate (e.g. 0.12 = 12% EA).
  /// Only meaningful for [AccountType.highYield].
  final double? interestRate;

  /// Day of the month the statement closes ("fecha de corte", 1–31).
  /// Only meaningful for [AccountType.credit].
  final int? statementDay;

  /// Day of the month the payment is due ("fecha límite de pago", 1–31).
  /// Only meaningful for [AccountType.credit].
  final int? paymentDay;

  const Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.balance,
    this.currency = 'COP',
    required this.colorValue,
    required this.icon,
    this.isArchived = false,
    required this.createdAt,
    this.interestRate,
    this.statementDay,
    this.paymentDay,
  });

  /// For net worth: credit balance is subtracted (it's debt)
  double get netBalance => type.isLiability ? -balance : balance;

  /// A credit card that knows when it closes and when it must be paid, so we
  /// can remind the user.
  bool get hasBillingCycle =>
      type == AccountType.credit && statementDay != null && paymentDay != null;

  /// Next time the statement closes, counting from [from] (today by default).
  /// Includes today when today *is* the closing day.
  DateTime? nextStatementDate({DateTime? from}) =>
      _nextOccurrence(statementDay, from ?? DateTime.now());

  /// Next payment due date, counting from [from] (today by default).
  DateTime? nextPaymentDate({DateTime? from}) =>
      _nextOccurrence(paymentDay, from ?? DateTime.now());

  /// The next calendar date landing on [day]. Months shorter than [day] fall
  /// back to their last day, so a card that closes on the 31st still closes in
  /// February (on the 28th/29th).
  static DateTime? _nextOccurrence(int? day, DateTime from) {
    if (day == null || day < 1 || day > 31) return null;
    final today = DateTime(from.year, from.month, from.day);
    final thisMonth = _clampToMonth(today.year, today.month, day);
    if (!thisMonth.isBefore(today)) return thisMonth;
    return _clampToMonth(today.year, today.month + 1, day);
  }

  /// [month] may overflow past 12 — DateTime rolls it into the next year.
  static DateTime _clampToMonth(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day > lastDay ? lastDay : day);
  }

  Account copyWith({
    String? name,
    AccountType? type,
    double? balance,
    String? currency,
    int? colorValue,
    String? icon,
    bool? isArchived,
    double? interestRate,
    bool clearInterestRate = false,
    int? statementDay,
    int? paymentDay,
    bool clearBillingCycle = false,
  }) {
    return Account(
      id: id,
      userId: userId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      colorValue: colorValue ?? this.colorValue,
      icon: icon ?? this.icon,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      interestRate: clearInterestRate ? null : (interestRate ?? this.interestRate),
      statementDay:
          clearBillingCycle ? null : (statementDay ?? this.statementDay),
      paymentDay: clearBillingCycle ? null : (paymentDay ?? this.paymentDay),
    );
  }

  @override
  List<Object?> get props => [id, userId, name, type, balance, currency, colorValue, icon, isArchived, interestRate, statementDay, paymentDay];
}

/// Totals across accounts that may be held in different currencies.
///
/// Every sum goes through [CurrencyRegistry], so an account in USD is counted
/// at the rate the user typed — and, when there is no rate yet, is left out and
/// reported in [ConsolidatedAmount.missingRates] instead of being added at 1:1.
extension AccountTotals on Iterable<Account> {
  ConsolidatedAmount get consolidatedNet => CurrencyRegistry.consolidate(
      map((a) => MapEntry(a.netBalance, a.currency)));

  ConsolidatedAmount get consolidatedAssets => CurrencyRegistry.consolidate(
      where((a) => !a.type.isLiability).map((a) => MapEntry(a.balance, a.currency)));

  ConsolidatedAmount get consolidatedLiabilities => CurrencyRegistry.consolidate(
      where((a) => a.type.isLiability).map((a) => MapEntry(a.balance, a.currency)));

  /// Every currency these accounts are held in, base included, sorted.
  List<String> get currenciesInUse {
    final codes = map((a) => a.currency.toUpperCase()).toSet().toList()..sort();
    return codes;
  }

  /// True once money is held in more than one currency — the trigger for
  /// showing conversion hints and the rates editor.
  bool get isMultiCurrency => currenciesInUse.length > 1;
}
