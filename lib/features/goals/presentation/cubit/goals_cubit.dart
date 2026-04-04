import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/savings_goal.dart';
import '../../domain/usecases/get_goals.dart';
import '../../domain/usecases/add_goal.dart';
import '../../domain/usecases/update_goal.dart';
import '../../domain/usecases/delete_goal.dart';
import '../../domain/usecases/add_contribution.dart';

part 'goals_state.dart';

class GoalsCubit extends Cubit<GoalsState> {
  final GetGoals _get;
  final AddGoal _add;
  final UpdateGoal _update;
  final DeleteGoal _delete;
  final AddContribution _contribute;
  StreamSubscription<List<SavingsGoal>>? _sub;

  GoalsCubit(
    this._get,
    this._add,
    this._update,
    this._delete,
    this._contribute,
  ) : super(const GoalsState.initial());

  void watch(String userId) {
    emit(const GoalsState.loading());
    _sub?.cancel();
    _sub = _get.watch(userId).listen(
      (list) => emit(GoalsState.loaded(list)),
      onError: (e) => emit(GoalsState.error(e.toString())),
    );
  }

  Future<bool> add(SavingsGoal goal) async {
    final result = await _add(goal);
    return result.fold(
      (f) { emit(GoalsState.error(f.message)); return false; },
      (_) => true,
    );
  }

  Future<bool> update(SavingsGoal goal) async {
    final result = await _update(goal);
    return result.fold(
      (f) { emit(GoalsState.error(f.message)); return false; },
      (_) => true,
    );
  }

  Future<bool> delete(String userId, String goalId) async {
    final result = await _delete(userId, goalId);
    return result.fold(
      (f) { emit(GoalsState.error(f.message)); return false; },
      (_) => true,
    );
  }

  /// Returns the updated goal. If null, an error occurred.
  Future<SavingsGoal?> addContribution(
      String userId, String goalId, double amount) async {
    final result = await _contribute(userId, goalId, amount);
    return result.fold(
      (f) { emit(GoalsState.error(f.message)); return null; },
      (goal) => goal,
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
