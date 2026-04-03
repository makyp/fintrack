import 'package:injectable/injectable.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';

@lazySingleton
class SignInWithEmail {
  final AuthRepository _repository;
  const SignInWithEmail(this._repository);

  Future<Either<Failure, AppUser>> call({
    required String email,
    required String password,
  }) {
    return _repository.signInWithEmail(email: email, password: password);
  }
}
