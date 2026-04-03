import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction.dart';
import '../../../../core/utils/date_formatter.dart';

enum TransactionsStatus { initial, loading, loaded, error }

class TransactionsState extends Equatable {
  final TransactionsStatus status;
  final List<Transaction> transactions;
  final String? errorMessage;

  const TransactionsState._({
    required this.status,
    this.transactions = const [],
    this.errorMessage,
  });

  const TransactionsState.initial() : this._(status: TransactionsStatus.initial);
  const TransactionsState.loading() : this._(status: TransactionsStatus.loading);
  const TransactionsState.loaded(List<Transaction> txs)
      : this._(status: TransactionsStatus.loaded, transactions: txs);
  const TransactionsState.error(String message)
      : this._(status: TransactionsStatus.error, errorMessage: message);

  bool get isLoading => status == TransactionsStatus.loading;
  bool get isLoaded => status == TransactionsStatus.loaded;

  /// Groups transactions by relative date label (Hoy, Ayer, fecha)
  Map<String, List<Transaction>> get groupedByDate {
    final map = <String, List<Transaction>>{};
    for (final tx in transactions) {
      final key = DateFormatter.formatRelative(tx.date);
      map.putIfAbsent(key, () => []).add(tx);
    }
    return map;
  }

  @override
  List<Object?> get props => [status, transactions, errorMessage];
}
