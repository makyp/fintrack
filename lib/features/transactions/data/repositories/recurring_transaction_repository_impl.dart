import 'package:injectable/injectable.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/recurring_transaction.dart';
import '../../domain/repositories/recurring_transaction_repository.dart';
import '../datasources/recurring_transaction_datasource.dart';

@LazySingleton(as: RecurringTransactionRepository)
class RecurringTransactionRepositoryImpl
    implements RecurringTransactionRepository {
  final RecurringTransactionDataSource _ds;
  RecurringTransactionRepositoryImpl(this._ds);

  @override
  Stream<List<RecurringTransaction>> watchAll(String userId) =>
      _ds.watchAll(userId);

  @override
  Future<Either<Failure, RecurringTransaction>> add(
      RecurringTransaction rt) async {
    try {
      final result = await _ds.add(rt);
      return Either.right(result);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, RecurringTransaction>> update(
      RecurringTransaction rt) async {
    try {
      final result = await _ds.update(rt);
      return Either.right(result);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deactivate(String userId, String id) async {
    try {
      await _ds.deactivate(userId, id);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    }
  }
}
