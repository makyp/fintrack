import 'package:equatable/equatable.dart';
import 'transaction.dart';

enum RecurringFrequency {
  daily,
  weekly,
  biweekly,
  monthly,
  yearly;

  String get label {
    switch (this) {
      case RecurringFrequency.daily: return 'Diario';
      case RecurringFrequency.weekly: return 'Semanal';
      case RecurringFrequency.biweekly: return 'Quincenal';
      case RecurringFrequency.monthly: return 'Mensual';
      case RecurringFrequency.yearly: return 'Anual';
    }
  }

  /// Calcula la siguiente fecha a partir de una dada
  DateTime nextFrom(DateTime date) {
    switch (this) {
      case RecurringFrequency.daily:
        return date.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return date.add(const Duration(days: 7));
      case RecurringFrequency.biweekly:
        return date.add(const Duration(days: 14));
      case RecurringFrequency.monthly:
        final m = date.month + 1;
        final y = date.year + (m > 12 ? 1 : 0);
        return DateTime(y, m > 12 ? m - 12 : m, date.day);
      case RecurringFrequency.yearly:
        return DateTime(date.year + 1, date.month, date.day);
    }
  }
}

class RecurringTransaction extends Equatable {
  final String id;
  final String userId;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final String accountId;
  final String? toAccountId;
  final String description;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextDueDate;
  final bool isActive;
  final DateTime createdAt;

  const RecurringTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.category,
    required this.accountId,
    this.toAccountId,
    required this.description,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.nextDueDate,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isDue {
    final today = DateTime.now();
    return isActive &&
        nextDueDate.isBefore(DateTime(today.year, today.month, today.day + 1));
  }

  bool get isDueSoon {
    final in3 = DateTime.now().add(const Duration(days: 3));
    return isActive &&
        nextDueDate.isBefore(DateTime(in3.year, in3.month, in3.day + 1));
  }

  RecurringTransaction copyWith({
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    String? accountId,
    String? toAccountId,
    String? description,
    RecurringFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextDueDate,
    bool? isActive,
  }) {
    return RecurringTransaction(
      id: id,
      userId: userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, userId, amount, type, category, accountId, description, frequency, nextDueDate, isActive];
}
