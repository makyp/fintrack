import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/goal_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class DeleteGoal {
  final GoalRepository _repo;
  DeleteGoal(this._repo);

  Future<Either<Failure, void>> call(String userId, String goalId) =>
      _repo.delete(userId, goalId);
}
