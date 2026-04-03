import 'package:injectable/injectable.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';

@lazySingleton
class SendPasswordReset {
  final AuthRepository _repository;
  const SendPasswordReset(this._repository);

  Future<Either<Failure, void>> call(String email) =>
      _repository.sendPasswordResetEmail(email);
}
