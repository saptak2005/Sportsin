import 'package:sportsin/services/auth/auth_user.dart';

abstract class AuthProvider {
  AuthUser? get getCurrentUser;

  AuthUser? get user;

  Future<AuthUser> createUser({
    required String email,
    required String role,
    required String password,
  });

  Future<AuthUser> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail({
    required String toEmail,
  });

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  Future<void> updatePassword({
    required String newPassword,
  });

  Future<AuthUser> signInWithGoogle();

  Future<AuthUser> verifyEmail({
    required String email,
    required String code,
  });

  Future<void> resendVerificationCode({
    required String email,
  });

  Future<AuthUser?> refreshUser();
}
