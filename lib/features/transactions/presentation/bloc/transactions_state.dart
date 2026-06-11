import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction.dart';
import '../../../../core/utils/date_formatter.dart';

enum TransactionsStatus { initial, loading, loaded, error }

/// Page size for the paginated (unfiltered) list. "Ver más" loads one more page.
const int kTransactionsPageSize = 50;

class TransactionsState extends Equatable {
  final TransactionsStatus status;
  final List<Transaction> transactions;
  final String? errorMessage;

  /// Current page size for the unfiltered watch stream.
  final int limit;

  /// True when there are likely more transactions to load (unfiltered view).
  final bool hasMore;

  /// True while a "Ver más" request is loading the next page.
  final bool loadingMore;

  /// True when an explicit filter is active. Filtered views fetch the COMPLETE
  /// matching set (no pagination), so "ver todo de una tarjeta" shows it all.
  final bool isFiltered;

  // ── Active filter (mirrored here so export can reuse it) ──────────────────
  final DateTime? from;
  final DateTime? to;
  final TransactionType? type;
  final TransactionCategory? category;
  final String? accountId;
  final String? searchQuery;

  const TransactionsState._({
    required this.status,
    this.transactions = const [],
    this.errorMessage,
    this.limit = kTransactionsPageSize,
    this.hasMore = false,
    this.loadingMore = false,
    this.isFiltered = false,
    this.from,
    this.to,
    this.type,
    this.category,
    this.accountId,
    this.searchQuery,
  });

  const TransactionsState.initial() : this._(status: TransactionsStatus.initial);
  const TransactionsState.loading() : this._(status: TransactionsStatus.loading);
  const TransactionsState.loaded(List<Transaction> txs)
      : this._(status: TransactionsStatus.loaded, transactions: txs);
  const TransactionsState.error(String message)
      : this._(status: TransactionsStatus.error, errorMessage: message);

  bool get isLoading => status == TransactionsStatus.loading;
  bool get isLoaded => status == TransactionsStatus.loaded;

  TransactionsState copyWith({
    TransactionsStatus? status,
    List<Transaction>? transactions,
    String? errorMessage,
    int? limit,
    bool? hasMore,
    bool? loadingMore,
    bool? isFiltered,
    DateTime? from,
    DateTime? to,
    TransactionType? type,
    TransactionCategory? category,
    String? accountId,
    String? searchQuery,
    bool clearFilter = false,
  }) {
    return TransactionsState._(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      errorMessage: errorMessage,
      limit: limit ?? this.limit,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      isFiltered: clearFilter ? false : (isFiltered ?? this.isFiltered),
      from: clearFilter ? null : (from ?? this.from),
      to: clearFilter ? null : (to ?? this.to),
      type: clearFilter ? null : (type ?? this.type),
      category: clearFilter ? null : (category ?? this.category),
      accountId: clearFilter ? null : (accountId ?? this.accountId),
      searchQuery: clearFilter ? null : (searchQuery ?? this.searchQuery),
    );
  }

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
  List<Object?> get props => [
        status,
        transactions,
        errorMessage,
        limit,
        hasMore,
        loadingMore,
        isFiltered,
        from,
        to,
        type,
        category,
        accountId,
        searchQuery,
      ];
}
