import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction.dart';

abstract class TransactionsEvent extends Equatable {
  const TransactionsEvent();
  @override
  List<Object?> get props => [];
}

class TransactionsWatchStarted extends TransactionsEvent {
  final String userId;
  const TransactionsWatchStarted(this.userId);
  @override
  List<Object> get props => [userId];
}

class TransactionsUpdated extends TransactionsEvent {
  final List<Transaction> transactions;
  const TransactionsUpdated(this.transactions);
  @override
  List<Object> get props => [transactions];
}

class TransactionAdded extends TransactionsEvent {
  final Transaction transaction;
  const TransactionAdded(this.transaction);
  @override
  List<Object> get props => [transaction];
}

class TransactionEdited extends TransactionsEvent {
  final Transaction transaction;
  const TransactionEdited(this.transaction);
  @override
  List<Object> get props => [transaction];
}

class TransactionDeleted extends TransactionsEvent {
  final String userId;
  final String transactionId;
  final String accountId;
  final double amount;
  final TransactionType transactionType;
  const TransactionDeleted({
    required this.userId,
    required this.transactionId,
    required this.accountId,
    required this.amount,
    required this.transactionType,
  });
  @override
  List<Object> get props => [userId, transactionId, accountId, amount, transactionType];
}

class TransactionsFiltered extends TransactionsEvent {
  final String userId;
  final DateTime? from;
  final DateTime? to;
  final TransactionType? type;
  final TransactionCategory? category;
  final String? accountId;
  final String? searchQuery;
  const TransactionsFiltered({
    required this.userId,
    this.from, this.to, this.type, this.category, this.accountId, this.searchQuery,
  });
  @override
  List<Object?> get props => [userId, from, to, type, category, accountId, searchQuery];
}
