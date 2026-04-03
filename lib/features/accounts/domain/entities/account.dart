import 'package:equatable/equatable.dart';

enum AccountType {
  cash,
  checking,
  savings,
  credit,
  investment;

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
  });

  /// For net worth: credit balance is subtracted (it's debt)
  double get netBalance => type.isLiability ? -balance : balance;

  Account copyWith({
    String? name,
    AccountType? type,
    double? balance,
    String? currency,
    int? colorValue,
    String? icon,
    bool? isArchived,
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
    );
  }

  @override
  List<Object?> get props => [id, userId, name, type, balance, currency, colorValue, icon, isArchived];
}
