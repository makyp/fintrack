import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/recurring_transaction.dart';

abstract class RecurringTransactionRepository {
  Stream<List<RecurringTransaction>> watchAll(String userId);
  Future<Either<Failure, RecurringTransaction>> add(RecurringTransaction rt);
  Future<Either<Failure, RecurringTransaction>> update(RecurringTransaction rt);
  Future<Either<Failure, void>> deactivate(String userId, String id);
}
