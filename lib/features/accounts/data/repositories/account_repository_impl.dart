import 'package:injectable/injectable.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_remote_datasource.dart';
import '../models/account_model.dart';

@LazySingleton(as: AccountRepository)
class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource _dataSource;
  const AccountRepositoryImpl(this._dataSource);

  @override
  Stream<List<Account>> watchAccounts(String userId) =>
      _dataSource.watchAccounts(userId);

  @override
  Future<Either<Failure, List<Account>>> getAccounts(String userId) async {
    try {
      final accounts = await _dataSource.getAccounts(userId);
      return Either.right(accounts);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Account>> addAccount(Account account) async {
    try {
      final model = AccountModel.fromEntity(account);
      final result = await _dataSource.addAccount(model);
      return Either.right(result);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Account>> updateAccount(Account account) async {
    try {
      final model = AccountModel.fromEntity(account);
      final result = await _dataSource.updateAccount(model);
      return Either.right(result);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> archiveAccount(String userId, String accountId) async {
    try {
      await _dataSource.archiveAccount(userId, accountId);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateBalance(
      String userId, String accountId, double newBalance) async {
    try {
      await _dataSource.updateBalance(userId, accountId, newBalance);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    }
  }
}
