import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/recurring_transaction.dart';
import '../repositories/recurring_transaction_repository.dart';

class UpdateRecurringTransaction {
  final RecurringTransactionRepository _repo;
  UpdateRecurringTransaction(this._repo);

  Future<Either<Failure, RecurringTransaction>> call(RecurringTransaction rt) =>
      _repo.update(rt);

  Future<Either<Failure, void>> deactivate(String userId, String id) =>
      _repo.deactivate(userId, id);
}
