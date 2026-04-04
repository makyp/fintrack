import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/recurring_transaction.dart';
import '../repositories/recurring_transaction_repository.dart';

class AddRecurringTransaction {
  final RecurringTransactionRepository _repo;
  AddRecurringTransaction(this._repo);

  Future<Either<Failure, RecurringTransaction>> call(RecurringTransaction rt) =>
      _repo.add(rt);
}
