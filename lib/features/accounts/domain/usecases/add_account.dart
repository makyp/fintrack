import 'package:injectable/injectable.dart';
import '../entities/account.dart';
import '../repositories/account_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';

@lazySingleton
class AddAccount {
  final AccountRepository _repository;
  const AddAccount(this._repository);

  Future<Either<Failure, Account>> call(Account account) =>
      _repository.addAccount(account);
}
