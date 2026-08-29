import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/savings_goal.dart';
import '../repositories/goal_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AddGoal {
  final GoalRepository _repo;
  AddGoal(this._repo);

  Future<Either<Failure, SavingsGoal>> call(SavingsGoal goal) =>
      _repo.add(goal);
}
