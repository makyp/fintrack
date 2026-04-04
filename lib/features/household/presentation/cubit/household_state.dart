part of 'household_cubit.dart';

enum HouseholdStatus { initial, loading, loaded, error }

class HouseholdState extends Equatable {
  final HouseholdStatus status;
  final Household? household;
  final String? errorMessage;

  const HouseholdState._({
    required this.status,
    this.household,
    this.errorMessage,
  });

  const HouseholdState.initial() : this._(status: HouseholdStatus.initial);
  const HouseholdState.loading() : this._(status: HouseholdStatus.loading);
  const HouseholdState.loaded(Household h)
      : this._(status: HouseholdStatus.loaded, household: h);
  const HouseholdState.noHousehold()
      : this._(status: HouseholdStatus.loaded, household: null);
  const HouseholdState.error(String msg)
      : this._(status: HouseholdStatus.error, errorMessage: msg);

  bool get isLoading => status == HouseholdStatus.loading;
  bool get hasHousehold => household != null;

  @override
  List<Object?> get props => [status, household, errorMessage];
}
