import 'package:injectable/injectable.dart';
import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';

@lazySingleton
class GetTransactions {
  final TransactionRepository _repository;
  const GetTransactions(this._repository);

  Stream<List<Transaction>> watch(String userId, {int limit = 50}) =>
      _repository.watchTransactions(userId, limit: limit);

  Future<Either<Failure, List<Transaction>>> call(
    String userId, {
    DateTime? from,
    DateTime? to,
    TransactionType? type,
    TransactionCategory? category,
    String? accountId,
    String? searchQuery,
    int limit = 50,
    String? lastDocId,
  }) =>
      _repository.getTransactions(
        userId,
        from: from,
        to: to,
        type: type,
        category: category,
        accountId: accountId,
        searchQuery: searchQuery,
        limit: limit,
        lastDocId: lastDocId,
      );
}
