import '../entities/transaction.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';

abstract class TransactionRepository {
  Stream<List<Transaction>> watchTransactions(String userId, {int limit = 50});
  Future<Either<Failure, List<Transaction>>> getTransactions(
    String userId, {
    DateTime? from,
    DateTime? to,
    TransactionType? type,
    TransactionCategory? category,
    String? accountId,
    String? searchQuery,
    int limit = 50,
    String? lastDocId,
  });
  Future<Either<Failure, Transaction>> addTransaction(Transaction transaction);
  Future<Either<Failure, Transaction>> updateTransaction(Transaction transaction);
  Future<Either<Failure, void>> deleteTransaction(String userId, String transactionId, {required String accountId, required double amount, required TransactionType type});
}
