import 'package:injectable/injectable.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';

@lazySingleton
class SignInWithGoogle {
  final AuthRepository _repository;
  const SignInWithGoogle(this._repository);

  Future<Either<Failure, AppUser>> call() => _repository.signInWithGoogle();
}
