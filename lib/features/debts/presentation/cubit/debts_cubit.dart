import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/datasources/debt_datasource.dart';
import '../../domain/entities/debt.dart';

part 'debts_state.dart';

class DebtsCubit extends Cubit<DebtsState> {
  final DebtDataSource _ds;
  StreamSubscription<List<Debt>>? _sub;

  DebtsCubit(this._ds) : super(const DebtsState.initial());

  void watch(String userId) {
    emit(const DebtsState.loading());
    _sub?.cancel();
    _sub = _ds.watchDebts(userId).listen(
      (list) => emit(DebtsState.loaded(list)),
      onError: (e) => emit(DebtsState.error(e.toString())),
    );
  }

  Future<bool> add(Debt debt) async {
    try {
      await _ds.add(debt);
      return true;
    } catch (e) {
      emit(DebtsState.error(e.toString()));
      return false;
    }
  }

  Future<bool> update(Debt debt) async {
    try {
      await _ds.update(debt);
      return true;
    } catch (e) {
      emit(DebtsState.error(e.toString()));
      return false;
    }
  }

  Future<bool> delete(String userId, String debtId) async {
    try {
      await _ds.delete(userId, debtId);
      return true;
    } catch (e) {
      emit(DebtsState.error(e.toString()));
      return false;
    }
  }

  Future<bool> addPayment(String userId, String debtId, double amount,
      {String? note}) async {
    try {
      await _ds.addPayment(userId, debtId, amount, note: note);
      return true;
    } catch (e) {
      emit(DebtsState.error(e.toString()));
      return false;
    }
  }

  Future<bool> markClosed(String userId, String debtId) async {
    try {
      await _ds.close(userId, debtId);
      return true;
    } catch (e) {
      emit(DebtsState.error(e.toString()));
      return false;
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
