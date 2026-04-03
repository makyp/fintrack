import '../entities/account.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';

abstract class AccountRepository {
  Stream<List<Account>> watchAccounts(String userId);
  Future<Either<Failure, List<Account>>> getAccounts(String userId);
  Future<Either<Failure, Account>> addAccount(Account account);
  Future<Either<Failure, Account>> updateAccount(Account account);
  Future<Either<Failure, void>> archiveAccount(String userId, String accountId);
  Future<Either<Failure, void>> updateBalance(String userId, String accountId, double newBalance);
}
