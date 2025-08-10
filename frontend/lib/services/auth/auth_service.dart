import 'package:flutter/foundation.dart';
import 'package:sportsin/services/auth/auth_provider.dart';
import 'package:sportsin/services/auth/auth_user.dart';
import 'package:sportsin/services/auth/custom_auth_provider.dart';
import 'package:sportsin/services/notification/fcm_service.dart';

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

    // Send FCM token after successful login
    try {
      await FcmService.instance.onUserLogin();
      debugPrint("✅ FCM token registered after login.");
    } catch (e) {
      debugPrint("⚠️ Failed to register FCM token after login: $e");
      // Don't throw error to avoid blocking login flow
    }

    return user;
  }

  @override
  Future<void> signOut() async {
    // Clean up FCM token before logout
    try {
      await FcmService.instance.onUserLogout();
      debugPrint("✅ FCM token removed from server before logout.");
    } catch (e) {
      debugPrint("⚠️ Failed to remove FCM token before logout: $e");
      // Don't throw error to avoid blocking logout flow
    }

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

    // Send FCM token after successful Google sign-in
    try {
      await FcmService.instance.onUserLogin();
      debugPrint("✅ FCM token registered after Google sign-in.");
    } catch (e) {
      debugPrint("⚠️ Failed to register FCM token after Google sign-in: $e");
      // Don't throw error to avoid blocking login flow
    }

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

      // Send FCM token if user is authenticated after refresh
      try {
        await FcmService.instance.onUserLogin();
        debugPrint("✅ FCM token registered after auth state refresh.");
      } catch (e) {
        debugPrint("⚠️ Failed to register FCM token after auth refresh: $e");
        // Don't throw error to avoid blocking refresh flow
      }
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

    // Send FCM token after successful email verification (login)
    try {
      await FcmService.instance.onUserLogin();
      debugPrint("✅ FCM token registered after email verification.");
    } catch (e) {
      debugPrint(
          "⚠️ Failed to register FCM token after email verification: $e");
      // Don't throw error to avoid blocking verification flow
    }

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
