import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/savings_goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../datasources/goal_remote_datasource.dart';

class GoalRepositoryImpl implements GoalRepository {
  final GoalRemoteDataSource _ds;
  GoalRepositoryImpl(this._ds);

  @override
  Stream<List<SavingsGoal>> watchGoals(String userId) =>
      _ds.watchGoals(userId);

  @override
  Future<Either<Failure, SavingsGoal>> add(SavingsGoal goal) async {
    try {
      final result = await _ds.add(goal);
      return Either.right(result);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SavingsGoal>> update(SavingsGoal goal) async {
    try {
      final result = await _ds.update(goal);
      return Either.right(result);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String userId, String goalId) async {
    try {
      await _ds.delete(userId, goalId);
      return Either.right(null);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SavingsGoal>> addContribution(
      String userId, String goalId, double amount) async {
    try {
      final result = await _ds.addContribution(userId, goalId, amount);
      return Either.right(result);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }
}
