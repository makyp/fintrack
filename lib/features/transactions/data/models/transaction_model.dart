import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../../domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required String id,
    required String userId,
    required double amount,
    required TransactionType type,
    required TransactionCategory category,
    required String accountId,
    String? toAccountId,
    required String description,
    required DateTime date,
    bool isRecurring = false,
    String? householdId,
    String? receiptUrl,
    List<String> tags = const [],
    required DateTime createdAt,
  }) : super(
          id: id,
          userId: userId,
          amount: amount,
          type: type,
          category: category,
          accountId: accountId,
          toAccountId: toAccountId,
          description: description,
          date: date,
          isRecurring: isRecurring,
          householdId: householdId,
          receiptUrl: receiptUrl,
          tags: tags,
          createdAt: createdAt,
        );

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
      );
}
