import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../../../categories/domain/category_registry.dart';
import '../../domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  TransactionModel({
    required super.id,
    required super.userId,
    required super.amount,
    required super.type,
    required super.category,
    required super.accountId,
    super.toAccountId,
    required super.description,
    required super.date,
    super.isRecurring = false,
    super.householdId,
    super.receiptUrl,
    super.tags = const [],
    required super.createdAt,
    super.installments,
    super.currency,
  });

  factory TransactionModel.fromFirestore(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: TransactionType.values.firstWhere(
        (e) => e.name == (map['type'] as String? ?? 'expense'),
        orElse: () => TransactionType.expense,
      ),
      category: CategoryRegistry.byId(map['categoryId'] as String? ?? 'other'),
      accountId: map['accountId'] as String? ?? '',
      toAccountId: map['toAccountId'] as String?,
      description: map['description'] as String? ?? '',
      date: map['date'] != null
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      isRecurring: map['isRecurring'] as bool? ?? false,
      householdId: map['householdId'] as String?,
      receiptUrl: map['receiptUrl'] as String?,
      tags: List<String>.from(map['tags'] as List? ?? []),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      installments: (map['installments'] as num?)?.toInt(),
      // Movements written before multi-currency have no code: they were all
      // in what is now the base currency.
      currency: map['currency'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'amount': amount,
      'type': type.name,
      'categoryId': categoryId,
      'accountId': accountId,
      if (toAccountId != null) 'toAccountId': toAccountId,
      'description': description,
      'date': Timestamp.fromDate(date),
      'isRecurring': isRecurring,
      if (householdId != null) 'householdId': householdId,
      if (receiptUrl != null) 'receiptUrl': receiptUrl,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      if (installments != null && installments! > 1) 'installments': installments,
      'currency': currency,
    };
  }

  static TransactionModel fromEntity(Transaction t) => TransactionModel(
        id: t.id,
        userId: t.userId,
        amount: t.amount,
        type: t.type,
        category: t.category,
        accountId: t.accountId,
        toAccountId: t.toAccountId,
        description: t.description,
        date: t.date,
        isRecurring: t.isRecurring,
        householdId: t.householdId,
        receiptUrl: t.receiptUrl,
        tags: t.tags,
        createdAt: t.createdAt,
        installments: t.installments,
        currency: t.currency,
      );
}
