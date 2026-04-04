import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../../domain/entities/recurring_transaction.dart';
import '../../domain/entities/transaction.dart';

class RecurringTransactionModel extends RecurringTransaction {
  const RecurringTransactionModel({
    required super.id,
    required super.userId,
    required super.amount,
    required super.type,
    required super.category,
    required super.accountId,
    super.toAccountId,
    required super.description,
    required super.frequency,
    required super.startDate,
    super.endDate,
    required super.nextDueDate,
    super.isActive = true,
    required super.createdAt,
  });

  factory RecurringTransactionModel.fromFirestore(
      Map<String, dynamic> data, String id) {
    return RecurringTransactionModel(
      id: id,
      userId: data['userId'] as String,
      amount: (data['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
          (e) => e.name == data['type'],
          orElse: () => TransactionType.expense),
      category: TransactionCategory.values.firstWhere(
          (e) => e.name == data['category'],
          orElse: () => TransactionCategory.other),
      accountId: data['accountId'] as String,
      toAccountId: data['toAccountId'] as String?,
      description: data['description'] as String? ?? '',
      frequency: RecurringFrequency.values.firstWhere(
          (e) => e.name == data['frequency'],
          orElse: () => RecurringFrequency.monthly),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      nextDueDate: (data['nextDueDate'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'amount': amount,
        'type': type.name,
        'category': category.name,
        'accountId': accountId,
        if (toAccountId != null) 'toAccountId': toAccountId,
        'description': description,
        'frequency': frequency.name,
        'startDate': Timestamp.fromDate(startDate),
        if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
        'nextDueDate': Timestamp.fromDate(nextDueDate),
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
