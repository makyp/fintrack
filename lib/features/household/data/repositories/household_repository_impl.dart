import '../../domain/entities/household.dart';
import '../../domain/repositories/household_repository.dart';
import '../datasources/household_datasource.dart';

class HouseholdRepositoryImpl implements HouseholdRepository {
  final HouseholdDataSource _ds;

  HouseholdRepositoryImpl(this._ds);

  @override
  Future<Household> createHousehold(
          String userId, String displayName, String email, String name) =>
      _ds.createHousehold(userId, displayName, email, name);

  @override
  Future<Household> joinHousehold(
          String userId, String displayName, String email, String inviteCode) =>
      _ds.joinHousehold(userId, displayName, email, inviteCode);

  @override
  Future<void> leaveHousehold(String userId, String householdId) =>
      _ds.leaveHousehold(userId, householdId);

  @override
  Stream<Household?> watchHousehold(String householdId) =>
      _ds.watchHousehold(householdId);
}
