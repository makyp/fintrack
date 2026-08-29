import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/domain/currency_registry.dart';
import '../../domain/entities/account.dart';

class AccountModel extends Account {
  const AccountModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.type,
    required super.balance,
    super.currency,
    required super.colorValue,
    required super.icon,
    super.isArchived,
    required super.createdAt,
    super.interestRate,
    super.statementDay,
    super.paymentDay,
  });

  factory AccountModel.fromFirestore(Map<String, dynamic> map, String id) {
    return AccountModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: AccountType.values.firstWhere(
        (e) => e.name == (map['type'] as String? ?? 'checking'),
        orElse: () => AccountType.checking,
      ),
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? CurrencyRegistry.base,
      colorValue: map['colorValue'] as int? ?? 0xFF2563EB,
      icon: map['icon'] as String? ?? '🏦',
      isArchived: map['isArchived'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      interestRate: (map['interestRate'] as num?)?.toDouble(),
      statementDay: (map['statementDay'] as num?)?.toInt(),
      paymentDay: (map['paymentDay'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'type': type.name,
      'balance': balance,
      'currency': currency,
      'colorValue': colorValue,
      'icon': icon,
      'isArchived': isArchived,
      'createdAt': Timestamp.fromDate(createdAt),
      if (interestRate != null) 'interestRate': interestRate,
      if (statementDay != null) 'statementDay': statementDay,
      if (paymentDay != null) 'paymentDay': paymentDay,
    };
  }

  static AccountModel fromEntity(Account account) {
    return AccountModel(
      id: account.id,
      userId: account.userId,
      name: account.name,
      type: account.type,
      balance: account.balance,
      currency: account.currency,
      colorValue: account.colorValue,
      icon: account.icon,
      isArchived: account.isArchived,
      createdAt: account.createdAt,
      interestRate: account.interestRate,
      statementDay: account.statementDay,
      paymentDay: account.paymentDay,
    );
  }
}
