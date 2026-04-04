import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/savings_goal.dart';
import '../repositories/goal_repository.dart';

class UpdateGoal {
  final GoalRepository _repo;
  UpdateGoal(this._repo);

  Future<Either<Failure, SavingsGoal>> call(SavingsGoal goal) =>
      _repo.update(goal);
}
