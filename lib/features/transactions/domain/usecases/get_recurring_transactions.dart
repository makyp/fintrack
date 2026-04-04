import '../entities/recurring_transaction.dart';
import '../repositories/recurring_transaction_repository.dart';

class GetRecurringTransactions {
  final RecurringTransactionRepository _repo;
  GetRecurringTransactions(this._repo);

  Stream<List<RecurringTransaction>> watch(String userId) =>
      _repo.watchAll(userId);
}
