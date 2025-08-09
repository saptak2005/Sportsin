import 'package:flutter/foundation.dart';
import 'package:sportsin/services/auth/auth_provider.dart';
import 'package:sportsin/services/auth/auth_user.dart';
import 'package:sportsin/services/auth/custom_auth_provider.dart';

class AuthService implements AuthProvider {
  final AuthProvider provider;

  static AuthService? _instance;

  static final ValueNotifier<AuthUser?> _authStateNotifier =
      ValueNotifier<AuthUser?>(null);
  static ValueListenable<AuthUser?> get authStateNotifier => _authStateNotifier;

  AuthService(this.provider) {
    _authStateNotifier.value = provider.getCurrentUser;
  }

  factory AuthService.customProvider() {
    _instance ??= AuthService(CustomAuthProvider());
    return _instance!;
  }

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
    required String role,
  }) async {
    final user = await provider.createUser(
      email: email,
      password: password,
      role: role,
    );
    _authStateNotifier.value = user;
    return user;
  }

  @override
  AuthUser? get getCurrentUser => provider.getCurrentUser;

  @override
  Future<void> sendPasswordResetEmail({required String toEmail}) =>
      provider.sendPasswordResetEmail(
        toEmail: toEmail,
      );

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) =>
      provider.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );

  @override
  Future<AuthUser> signIn(
      {required String email, required String password}) async {
    final user = await provider.signIn(
      email: email,
      password: password,
    );
    _authStateNotifier.value = user;
    return user;
  }

  @override
  Future<void> signOut() async {
    await provider.signOut();
    _authStateNotifier.value = null;
  }

  @override
  AuthUser? get user => provider.user;

  @override
  Future<void> updatePassword({required String newPassword}) =>
      provider.updatePassword(newPassword: newPassword);

  @override
  Future<AuthUser> signInWithGoogle() async {
    final user = await provider.signInWithGoogle();
    _authStateNotifier.value = user;
    return user;
  }

  static Future<void> refreshAuthState() async {
    debugPrint('🔄 AuthService: Refreshing auth state...');
    final authService = AuthService.customProvider();

    final user = await authService.refreshUser();
    _authStateNotifier.value = user;

    if (user != null) {
      debugPrint(
          '✅ AuthService: Auth state refreshed - User: ${user.email}, Role: ${user.role.value}');
    } else {
      debugPrint('❌ AuthService: No user found during auth state refresh');
    }
  }

  @override
  Future<AuthUser> verifyEmail({
    required String email,
    required String code,
  }) async {
    final user = await provider.verifyEmail(
      email: email,
      code: code,
    );
    _authStateNotifier.value = user;
    return user;
  }

  @override
  Future<void> resendVerificationCode({
    required String email,
  }) =>
      provider.resendVerificationCode(email: email);

  @override
  Future<AuthUser?> refreshUser() async {
    final user = await provider.refreshUser();
    _authStateNotifier.value = user;
    return user;
  }
}
