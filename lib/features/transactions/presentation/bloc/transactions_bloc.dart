import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../budgets/data/budget_alert_service.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/usecases/get_transactions.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/update_transaction.dart';
import 'transactions_event.dart';
import 'transactions_state.dart';

@injectable
class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final GetTransactions _getTransactions;
  final AddTransaction _addTransaction;
  final UpdateTransaction _updateTransaction;
  final BudgetAlertService _budgetAlerts;
  StreamSubscription<List<Transaction>>? _subscription;

  String _userId = '';

  TransactionsBloc(this._getTransactions, this._addTransaction,
      this._updateTransaction, this._budgetAlerts)
      : super(const TransactionsState.initial()) {
    on<TransactionsWatchStarted>(_onWatchStarted);
    on<TransactionsLoadMore>(_onLoadMore);
    on<TransactionsUpdated>(_onUpdated);
    on<TransactionAdded>(_onAdded);
    on<TransactionEdited>(_onEdited);
    on<TransactionDeleted>(_onDeleted);
    on<TransactionsFiltered>(_onFiltered);
  }

  void _onWatchStarted(TransactionsWatchStarted event, Emitter<TransactionsState> emit) {
    _userId = event.userId;
    emit(const TransactionsState.loading());
    _watch(kTransactionsPageSize);
  }

  void _onLoadMore(TransactionsLoadMore event, Emitter<TransactionsState> emit) {
    // Pagination only applies to the unfiltered view; filtered views already
    // show the complete matching set.
    if (state.isFiltered || !state.hasMore || state.loadingMore) return;
    emit(state.copyWith(loadingMore: true));
    _watch(state.limit + kTransactionsPageSize);
  }

  /// (Re)subscribes the realtime stream using the given page [limit].
  void _watch(int limit) {
    _subscription?.cancel();
    _pendingLimit = limit; // remembered for the next TransactionsUpdated
    _subscription = _getTransactions.watch(_userId, limit: limit).listen(
      (txs) => add(TransactionsUpdated(txs)),
      onError: (e) => add(const TransactionsUpdated([])),
    );
  }

  int _pendingLimit = kTransactionsPageSize;

  void _onUpdated(TransactionsUpdated event, Emitter<TransactionsState> emit) {
    final txs = event.transactions;
    emit(state.copyWith(
      status: TransactionsStatus.loaded,
      transactions: txs,
      limit: _pendingLimit,
      loadingMore: false,
      isFiltered: false,
      clearFilter: true,
      // If we received a full page, there are probably more to load.
      hasMore: txs.length >= _pendingLimit,
    ));
  }

  Future<void> _onAdded(TransactionAdded event, Emitter<TransactionsState> emit) async {
    final result = await _addTransaction(event.transaction);
    result.fold(
      (f) => emit(TransactionsState.error(f.message)),
      (_) => _checkBudgets(event.transaction),
    );
  }

  Future<void> _onEdited(TransactionEdited event, Emitter<TransactionsState> emit) async {
    final result = await _updateTransaction(event.transaction);
    result.fold(
      (f) => emit(TransactionsState.error(f.message)),
      (_) => _checkBudgets(event.transaction),
    );
  }

  /// A saved expense may have just pushed a category past its cap. Fire and
  /// forget: the alert must never delay or fail the save.
  void _checkBudgets(Transaction tx) {
    if (tx.type != TransactionType.expense) return;
    unawaited(_budgetAlerts.check(tx.userId));
  }

  Future<void> _onDeleted(TransactionDeleted event, Emitter<TransactionsState> emit) async {
    final result = await _updateTransaction.delete(
      event.userId,
      event.transactionId,
      accountId: event.accountId,
      amount: event.amount,
      type: event.transactionType,
    );
    result.fold(
      (f) => emit(TransactionsState.error(f.message)),
      (_) {},
    );
  }

  Future<void> _onFiltered(TransactionsFiltered event, Emitter<TransactionsState> emit) async {
    _userId = event.userId;
    // Stop the realtime stream so it can't overwrite the filtered result.
    await _subscription?.cancel();
    _subscription = null;

    final hasAnyFilter = event.from != null ||
        event.to != null ||
        event.type != null ||
        event.category != null ||
        (event.accountId != null && event.accountId!.isNotEmpty) ||
        (event.searchQuery != null && event.searchQuery!.isNotEmpty);

    // No filter left → fall back to the normal paginated watch.
    if (!hasAnyFilter) {
      add(TransactionsWatchStarted(event.userId));
      return;
    }

    emit(const TransactionsState.loading());
    // limit: 0 → fetch the COMPLETE matching set (no pagination).
    final result = await _getTransactions(
      event.userId,
      from: event.from,
      to: event.to,
      type: event.type,
      category: event.category,
      accountId: event.accountId,
      searchQuery: event.searchQuery,
      limit: 0,
    );
    result.fold(
      (f) => emit(TransactionsState.error(f.message)),
      (txs) => emit(state.copyWith(
        status: TransactionsStatus.loaded,
        transactions: txs,
        isFiltered: true,
        hasMore: false,
        loadingMore: false,
        from: event.from,
        to: event.to,
        type: event.type,
        category: event.category,
        accountId: event.accountId,
        searchQuery: event.searchQuery,
      )),
    );
  }

  /// Fetches the COMPLETE set of transactions matching the active filter
  /// (or the whole history when unfiltered) for export. Independent of the
  /// on-screen pagination limit.
  Future<List<Transaction>> fetchAllForExport() async {
    final result = await _getTransactions(
      _userId,
      from: state.from,
      to: state.to,
      type: state.type,
      category: state.category,
      accountId: state.accountId,
      searchQuery: state.searchQuery,
      limit: 0,
    );
    return result.fold((_) => <Transaction>[], (txs) => txs);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
