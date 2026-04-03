import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
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
  StreamSubscription<List<Transaction>>? _subscription;

  TransactionsBloc(this._getTransactions, this._addTransaction, this._updateTransaction)
      : super(const TransactionsState.initial()) {
    on<TransactionsWatchStarted>(_onWatchStarted);
    on<TransactionsUpdated>(_onUpdated);
    on<TransactionAdded>(_onAdded);
    on<TransactionEdited>(_onEdited);
    on<TransactionDeleted>(_onDeleted);
    on<TransactionsFiltered>(_onFiltered);
  }

  void _onWatchStarted(TransactionsWatchStarted event, Emitter<TransactionsState> emit) {
    emit(const TransactionsState.loading());
    _subscription?.cancel();
    _subscription = _getTransactions.watch(event.userId).listen(
      (txs) => add(TransactionsUpdated(txs)),
      onError: (e) => emit(TransactionsState.error(e.toString())),
    );
  }

  void _onUpdated(TransactionsUpdated event, Emitter<TransactionsState> emit) {
    emit(TransactionsState.loaded(event.transactions));
  }

  Future<void> _onAdded(TransactionAdded event, Emitter<TransactionsState> emit) async {
    final result = await _addTransaction(event.transaction);
    result.fold(
      (f) => emit(TransactionsState.error(f.message)),
      (_) {},
    );
  }

  Future<void> _onEdited(TransactionEdited event, Emitter<TransactionsState> emit) async {
    final result = await _updateTransaction(event.transaction);
    result.fold(
      (f) => emit(TransactionsState.error(f.message)),
      (_) {},
    );
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
    emit(const TransactionsState.loading());
    final result = await _getTransactions(
      event.userId,
      from: event.from,
      to: event.to,
      type: event.type,
      category: event.category,
      accountId: event.accountId,
      searchQuery: event.searchQuery,
    );
    result.fold(
      (f) => emit(TransactionsState.error(f.message)),
      (txs) => emit(TransactionsState.loaded(txs)),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
