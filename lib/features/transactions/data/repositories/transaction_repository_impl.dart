import 'package:injectable/injectable.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_remote_datasource.dart';
import '../models/transaction_model.dart';

@LazySingleton(as: TransactionRepository)
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource _dataSource;
  const TransactionRepositoryImpl(this._dataSource);

  @override
  Stream<List<Transaction>> watchTransactions(String userId, {int limit = 50}) =>
      _dataSource.watchTransactions(userId, limit: limit);

  @override
  Future<Either<Failure, List<Transaction>>> getTransactions(String userId, {
    DateTime? from, DateTime? to, TransactionType? type, TransactionCategory? category,
    String? accountId, String? searchQuery, int limit = 50, String? lastDocId,
  }) async {
    try {
      final txs = await _dataSource.getTransactions(userId,
          from: from, to: to, type: type, category: category,
          accountId: accountId, searchQuery: searchQuery, limit: limit, lastDocId: lastDocId);
      return Either.right(txs);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Transaction>> addTransaction(Transaction transaction) async {
    try {
      final model = TransactionModel.fromEntity(transaction);
      final result = await _dataSource.addTransaction(model);
      return Either.right(result);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Transaction>> updateTransaction(Transaction transaction) async {
    try {
      final model = TransactionModel.fromEntity(transaction);
      final result = await _dataSource.updateTransaction(model);
      return Either.right(result);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(String userId, String transactionId, {
    required String accountId, required double amount, required TransactionType type,
  }) async {
    try {
      await _dataSource.deleteTransaction(userId, transactionId,
          accountId: accountId, amount: amount, type: type);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    }
  }
}
