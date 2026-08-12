import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../../domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
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
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == (map['categoryId'] as String? ?? 'other'),
        orElse: () => TransactionCategory.other,
      ),
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
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'amount': amount,
      'type': type.name,
      'categoryId': category.name,
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
      );
}
