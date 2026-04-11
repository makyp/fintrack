import 'package:equatable/equatable.dart';

enum TransactionType { expense, income, transfer }

enum TransactionCategory {
  // Expenses
  food,
  transport,
  entertainment,
  health,
  education,
  home,
  clothing,
  shopping,
  technology,
  services,
  cleaning,
  other,
  // Income
  salary,
  freelance,
  investment,
  sale,
  gift,
  bonus,
  // Transfer
  transfer;

  String get label {
    switch (this) {
      case TransactionCategory.food: return 'Alimentación';
      case TransactionCategory.transport: return 'Transporte';
      case TransactionCategory.entertainment: return 'Entretenimiento';
      case TransactionCategory.health: return 'Salud';
      case TransactionCategory.education: return 'Educación';
      case TransactionCategory.home: return 'Hogar';
      case TransactionCategory.clothing: return 'Ropa';
      case TransactionCategory.shopping: return 'Compras online';
      case TransactionCategory.technology: return 'Tecnología';
      case TransactionCategory.services: return 'Servicios';
      case TransactionCategory.cleaning: return 'Aseo';
      case TransactionCategory.salary: return 'Salario';
      case TransactionCategory.freelance: return 'Freelance';
      case TransactionCategory.investment: return 'Inversiones';
      case TransactionCategory.sale: return 'Venta';
      case TransactionCategory.gift: return 'Regalo';
      case TransactionCategory.bonus: return 'Bono';
      case TransactionCategory.transfer: return 'Transferencia';
      case TransactionCategory.other: return 'Otro';
    }
  }

  String get icon {
    switch (this) {
      case TransactionCategory.food: return '🍔';
      case TransactionCategory.transport: return '🚗';
      case TransactionCategory.entertainment: return '🎬';
      case TransactionCategory.health: return '💊';
      case TransactionCategory.education: return '📚';
      case TransactionCategory.home: return '🏠';
      case TransactionCategory.clothing: return '👕';
      case TransactionCategory.shopping: return '🛒';
      case TransactionCategory.technology: return '💻';
      case TransactionCategory.services: return '⚡';
      case TransactionCategory.cleaning: return '🧹';
      case TransactionCategory.salary: return '💼';
      case TransactionCategory.freelance: return '🧑‍💻';
      case TransactionCategory.investment: return '📈';
      case TransactionCategory.sale: return '🛍️';
      case TransactionCategory.gift: return '🎁';
      case TransactionCategory.bonus: return '⭐';
      case TransactionCategory.transfer: return '↔️';
      case TransactionCategory.other: return '📌';
    }
  }

  static List<TransactionCategory> forType(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return [food, transport, entertainment, health, education, home, clothing, shopping, technology, services, cleaning, other];
      case TransactionType.income:
        return [salary, freelance, investment, sale, gift, bonus, other];
      case TransactionType.transfer:
        return [transfer];
    }
  }
}

class Transaction extends Equatable {
  final String id;
  final String userId;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final String accountId;
  final String? toAccountId; // for transfers
  final String description;
  final DateTime date;
  final bool isRecurring;
  final String? householdId;
  final String? receiptUrl;
  final List<String> tags;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.category,
    required this.accountId,
    this.toAccountId,
    required this.description,
    required this.date,
    this.isRecurring = false,
    this.householdId,
    this.receiptUrl,
    this.tags = const [],
    required this.createdAt,
  });

  Transaction copyWith({
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    String? accountId,
    String? toAccountId,
    String? description,
    DateTime? date,
    bool? isRecurring,
    String? receiptUrl,
    List<String>? tags,
  }) {
    return Transaction(
      id: id,
      userId: userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      description: description ?? this.description,
      date: date ?? this.date,
      isRecurring: isRecurring ?? this.isRecurring,
      householdId: householdId,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      tags: tags ?? this.tags,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, amount, type, category, accountId, description, date];
}
