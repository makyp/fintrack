import 'package:injectable/injectable.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  const AuthRepositoryImpl(this._dataSource);

  @override
  Stream<AppUser?> get authStateChanges => _dataSource.authStateChanges;

  @override
  AppUser? get currentUser => _dataSource.currentUser;

  @override
  Future<Either<Failure, AppUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dataSource.signInWithEmail(email: email, password: password);
      return Either.right(user);
    } on AuthException catch (e) {
      return Either.left(AuthFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, AppUser>> signInWithGoogle() async {
    try {
      final user = await _dataSource.signInWithGoogle();
      return Either.right(user);
    } on AuthException catch (e) {
      return Either.left(AuthFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, AppUser>> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dataSource.registerWithEmail(
        name: name,
        email: email,
        password: password,
      );
      return Either.right(user);
    } on AuthException catch (e) {
      return Either.left(AuthFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await _dataSource.sendPasswordResetEmail(email);
      return Either.right(null);
    } on AuthException catch (e) {
      return Either.left(AuthFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _dataSource.signOut();
      return Either.right(null);
    } on AuthException catch (e) {
      return Either.left(AuthFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount({required String password}) async {
    try {
      await _dataSource.deleteAccount(password: password);
      return Either.right(null);
    } on AuthException catch (e) {
      return Either.left(AuthFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, AppUser>> getCurrentUserProfile() async {
    try {
      final currentUser = _dataSource.currentUser;
      if (currentUser == null) {
        return Either.left(const AuthFailure('No hay sesión activa'));
      }
      final user = await _dataSource.getUserProfile(currentUser.uid);
      return Either.right(user);
    } on AuthException catch (e) {
      return Either.left(AuthFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, AppUser>> updateProfile({String? displayName, String? currency}) async {
    try {
      final user = await _dataSource.updateProfile(displayName: displayName, currency: currency);
      return Either.right(user);
    } on AuthException catch (e) {
      return Either.left(AuthFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({required String currentPassword, required String newPassword}) async {
    try {
      await _dataSource.changePassword(currentPassword: currentPassword, newPassword: newPassword);
      return Either.right(null);
    } on AuthException catch (e) {
      return Either.left(AuthFailure(e.message));
    }
  }
}
