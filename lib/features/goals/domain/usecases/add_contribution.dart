import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/savings_goal.dart';
import '../repositories/goal_repository.dart';

class AddContribution {
  final GoalRepository _repo;
  AddContribution(this._repo);

  Future<Either<Failure, SavingsGoal>> call(
          String userId, String goalId, double amount) =>
      _repo.addContribution(userId, goalId, amount);
}
