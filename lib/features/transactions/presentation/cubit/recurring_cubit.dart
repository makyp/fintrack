import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/recurring_transaction.dart';
import '../../domain/usecases/get_recurring_transactions.dart';
import '../../domain/usecases/add_recurring_transaction.dart';
import '../../domain/usecases/update_recurring_transaction.dart';

part 'recurring_state.dart';

@injectable
class RecurringCubit extends Cubit<RecurringState> {
  final GetRecurringTransactions _get;
  final AddRecurringTransaction _add;
  final UpdateRecurringTransaction _update;
  StreamSubscription<List<RecurringTransaction>>? _sub;

  RecurringCubit(this._get, this._add, this._update)
      : super(const RecurringState.initial());

  void watch(String userId) {
    emit(const RecurringState.loading());
    _sub?.cancel();
    _sub = _get.watch(userId).listen(
      (list) => emit(RecurringState.loaded(list)),
      onError: (e) => emit(RecurringState.error(e.toString())),
    );
  }

  Future<bool> add(RecurringTransaction rt) async {
    final result = await _add(rt);
    return result.fold(
      (f) { emit(RecurringState.error(f.message)); return false; },
      (_) => true,
    );
  }

  Future<bool> update(RecurringTransaction rt) async {
    final result = await _update(rt);
    return result.fold(
      (f) { emit(RecurringState.error(f.message)); return false; },
      (_) => true,
    );
  }

  Future<bool> deactivate(String userId, String id) async {
    final result = await _update.deactivate(userId, id);
    return result.fold(
      (f) { emit(RecurringState.error(f.message)); return false; },
      (_) => true,
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
