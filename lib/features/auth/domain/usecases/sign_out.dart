import 'package:injectable/injectable.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';

@lazySingleton
class SignOut {
  final AuthRepository _repository;
  const SignOut(this._repository);

  Future<Either<Failure, void>> call() => _repository.signOut();
}
