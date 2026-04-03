import 'package:injectable/injectable.dart';
import '../entities/account.dart';
import '../repositories/account_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';

@lazySingleton
class GetAccounts {
  final AccountRepository _repository;
  const GetAccounts(this._repository);

  Stream<List<Account>> watch(String userId) => _repository.watchAccounts(userId);

  Future<Either<Failure, List<Account>>> call(String userId) =>
      _repository.getAccounts(userId);
}
