import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/household.dart';
import '../../domain/repositories/household_repository.dart';

part 'household_state.dart';

class HouseholdCubit extends Cubit<HouseholdState> {
  final HouseholdRepository _repo;
  StreamSubscription<Household?>? _sub;

  HouseholdCubit(this._repo) : super(const HouseholdState.initial());

  /// Start watching if the user already belongs to a household.
  void watch(String? householdId) {
    _sub?.cancel();
    if (householdId == null || householdId.isEmpty) {
      emit(const HouseholdState.noHousehold());
      return;
    }
    emit(const HouseholdState.loading());
    _sub = _repo.watchHousehold(householdId).listen(
      (h) => emit(h != null
          ? HouseholdState.loaded(h)
          : const HouseholdState.noHousehold()),
      onError: (e) => emit(HouseholdState.error(e.toString())),
    );
  }

  Future<void> create(
      String userId, String displayName, String email, String name) async {
    emit(const HouseholdState.loading());
    try {
      final h = await _repo.createHousehold(userId, displayName, email, name);
      _sub?.cancel();
      _sub = _repo.watchHousehold(h.id).listen(
        (updated) => emit(updated != null
            ? HouseholdState.loaded(updated)
            : const HouseholdState.noHousehold()),
        onError: (e) => emit(HouseholdState.error(e.toString())),
      );
      emit(HouseholdState.loaded(h));
    } catch (e) {
      emit(HouseholdState.error(e.toString()));
    }
  }

  Future<void> join(
      String userId, String displayName, String email, String code) async {
    emit(const HouseholdState.loading());
    try {
      final h = await _repo.joinHousehold(userId, displayName, email, code);
      _sub?.cancel();
      _sub = _repo.watchHousehold(h.id).listen(
        (updated) => emit(updated != null
            ? HouseholdState.loaded(updated)
            : const HouseholdState.noHousehold()),
        onError: (e) => emit(HouseholdState.error(e.toString())),
      );
      emit(HouseholdState.loaded(h));
    } catch (e) {
      emit(HouseholdState.error(e.toString()));
    }
  }

  Future<void> leave(String userId, String householdId) async {
    emit(const HouseholdState.loading());
    try {
      await _repo.leaveHousehold(userId, householdId);
      _sub?.cancel();
      emit(const HouseholdState.noHousehold());
    } catch (e) {
      emit(HouseholdState.error(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
