import 'package:injectable/injectable.dart';
import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';

@lazySingleton
class UpdateTransaction {
  final TransactionRepository _repository;
  const UpdateTransaction(this._repository);

  Future<Either<Failure, Transaction>> call(Transaction transaction) =>
      _repository.updateTransaction(transaction);

  Future<Either<Failure, void>> delete(
    String userId,
    String transactionId, {
    required String accountId,
    required double amount,
    required TransactionType type,
  }) =>
      _repository.deleteTransaction(
        userId,
        transactionId,
        accountId: accountId,
        amount: amount,
        type: type,
      );
}
