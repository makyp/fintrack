import 'package:injectable/injectable.dart';
import '../entities/account.dart';
import '../repositories/account_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';

@lazySingleton
class UpdateAccount {
  final AccountRepository _repository;
  const UpdateAccount(this._repository);

  Future<Either<Failure, Account>> call(Account account) =>
      _repository.updateAccount(account);

  Future<Either<Failure, void>> archive(String userId, String accountId) =>
      _repository.archiveAccount(userId, accountId);

  Future<Either<Failure, void>> delete(String userId, String accountId) =>
      _repository.deleteAccount(userId, accountId);
}
