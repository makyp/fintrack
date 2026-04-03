import 'package:injectable/injectable.dart';
import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';

@lazySingleton
class AddTransaction {
  final TransactionRepository _repository;
  const AddTransaction(this._repository);

  Future<Either<Failure, Transaction>> call(Transaction transaction) =>
      _repository.addTransaction(transaction);
}
