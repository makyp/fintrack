import '../entities/app_user.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;

  Future<Either<Failure, AppUser>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, AppUser>> signInWithGoogle();

  Future<Either<Failure, AppUser>> registerWithEmail({
    required String name,
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, void>> deleteAccount({required String password});

  Future<Either<Failure, AppUser>> getCurrentUserProfile();

  Future<Either<Failure, AppUser>> updateProfile({String? displayName, String? currency});

  Future<Either<Failure, void>> changePassword({required String currentPassword, required String newPassword});
}
