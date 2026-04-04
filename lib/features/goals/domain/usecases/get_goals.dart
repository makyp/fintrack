import '../entities/savings_goal.dart';
import '../repositories/goal_repository.dart';

class GetGoals {
  final GoalRepository _repo;
  GetGoals(this._repo);

  Stream<List<SavingsGoal>> watch(String userId) => _repo.watchGoals(userId);
}
