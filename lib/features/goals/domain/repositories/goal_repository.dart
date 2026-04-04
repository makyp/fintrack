import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/savings_goal.dart';

abstract class GoalRepository {
  Stream<List<SavingsGoal>> watchGoals(String userId);
  Future<Either<Failure, SavingsGoal>> add(SavingsGoal goal);
  Future<Either<Failure, SavingsGoal>> update(SavingsGoal goal);
  Future<Either<Failure, void>> delete(String userId, String goalId);
  Future<Either<Failure, SavingsGoal>> addContribution(
      String userId, String goalId, double amount);
}
