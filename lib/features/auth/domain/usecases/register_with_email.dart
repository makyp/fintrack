import 'package:injectable/injectable.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';

@lazySingleton
class RegisterWithEmail {
  final AuthRepository _repository;
  const RegisterWithEmail(this._repository);

  Future<Either<Failure, AppUser>> call({
    required String name,
    required String email,
    required String password,
  }) {
    return _repository.registerWithEmail(
      name: name,
      email: email,
      password: password,
    );
  }
}
