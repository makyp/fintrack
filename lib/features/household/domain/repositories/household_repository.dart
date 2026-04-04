import '../entities/household.dart';

abstract class HouseholdRepository {
  Future<Household> createHousehold(String userId, String userDisplayName, String userEmail, String householdName);
  Future<Household> joinHousehold(String userId, String userDisplayName, String userEmail, String inviteCode);
  Future<void> leaveHousehold(String userId, String householdId);
  Stream<Household?> watchHousehold(String householdId);
}
