import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sportsin/models/enums.dart';
import 'package:sportsin/services/auth/auth_provider.dart';
import 'package:sportsin/services/auth/auth_user.dart';
import 'package:sportsin/services/auth/auth_exceptions.dart';
import 'package:sportsin/services/core/dio_client.dart';
import 'package:sportsin/services/core/secure_storage.dart';
import 'package:sportsin/services/core/jwt_service.dart';
import 'package:sportsin/services/db/db_provider.dart';

class CustomAuthProvider extends ChangeNotifier implements AuthProvider {
  late final DioClient _dioClient;
  late final SecureStorageService _storageService;
  late final JwtService _jwtService;
  AuthUser? _currentUser;

  CustomAuthProvider() {
    _dioClient = DioClient.instance;
    _storageService = SecureStorageService.instance;
    _jwtService = JwtService.instance;
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    try {
      final token = await _storageService.getToken();
      if (token != null && !_jwtService.isTokenExpired(token)) {
        _currentUser = await _storageService.getUser();

        if (_currentUser == null) {
          final userInfo = _jwtService.getUserInfo(token);
          if (userInfo != null) {
            final roleString = userInfo['custom:role']?.toString();
            debugPrint(
                'Auth: Loading user from JWT - Role from token: $roleString');

            if (roleString == null || roleString.isEmpty) {
              debugPrint(
                  'Auth: No role found in JWT token, cannot create user');
              await _storageService.clearAuthData();
              _currentUser = null;
              return;
            }

            _currentUser = AuthUser(
                id: userInfo['id']?.toString() ?? '',
                email: userInfo['email']?.toString() ?? '',
                isEmailVerified: true,
                role: Role.fromJson(roleString));
            await _storageService.saveUser(_currentUser!);
            debugPrint(
                'Auth: User created from JWT with role: ${_currentUser!.role.value}');
          }
        } else {
          debugPrint(
              'Auth: User loaded from storage with role: ${_currentUser!.role.value}');
        }
      } else if (token != null) {
        await _storageService.clearAuthData();
        _currentUser = null;
      }
    } catch (e) {
      debugPrint('Auth: Error loading user from storage: $e');
      await _storageService.clearAuthData();
      _currentUser = null;
    }
  }

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final requestData = {
        'email': email,
        'password': password,
        'role': role,
      };

      final response = await _dioClient.post(
        '/signup',
        data: requestData,
      );

      if (response.statusCode == 200) {
        final tempUser = AuthUser(
          email: email,
          isEmailVerified: false,
          role: Role.fromJson(role),
          id: '',
        );

        _currentUser = tempUser;
        notifyListeners();

        return _currentUser!;
      } else {
        throw ServerException('Unexpected response: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      throw GenericAuthException();
    }
  }

  @override
  AuthUser? get getCurrentUser => _currentUser;

  @override
  AuthUser? get user => _currentUser;

  @override
  Future<void> sendPasswordResetEmail({required String toEmail}) async {
    try {
      final response = await _dioClient.post(
        '/forgot-password',
        data: {'email': toEmail},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (kDebugMode) {
          print(
              'Password reset email sent: ${responseData['message'] ?? 'Password reset link sent to your email.'}');
        }
      } else {
        throw ServerException('Failed to send password reset email');
      }
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      throw GenericAuthException();
    }
  }

  @override
  Future<AuthUser> signIn(
      {required String email, required String password}) async {
    try {
      final response = await _dioClient.post(
        '/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        final idToken = responseData['id_token'];

        if (idToken == null) {
          throw ServerException('No id_token received from server');
        }

        final userInfo = _jwtService.getUserInfo(idToken);

        if (userInfo == null) {
          throw ServerException('Invalid JWT token received');
        }

        if (_jwtService.isTokenExpired(idToken)) {
          throw ServerException('Received expired token');
        }

        await _storageService.saveToken(idToken);

        final roleString = userInfo['custom:role']?.toString();
        debugPrint('Auth: Sign in - Role from JWT token: $roleString');

        if (roleString == null || roleString.isEmpty) {
          throw ServerException('No role found in JWT token');
        }

        _currentUser = AuthUser(
          id: userInfo['id']?.toString() ?? '',
          email: userInfo['email']?.toString() ?? email,
          role: Role.fromJson(roleString),
          isEmailVerified: true,
        );

        await _storageService.saveUser(_currentUser!);
        debugPrint(
            'Auth: User signed in with role: ${_currentUser!.role.value}');

        return _currentUser!;
      } else {
        throw ServerException(
            'Sign in failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw GenericAuthException();
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      final response = await _dioClient.post(
        '/auth/google',
        data: {
          'googleToken':
              'google_id_token_here', // Replace with actual Google token
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        final idToken = responseData['id_token'];

        if (idToken == null) {
          throw ServerException('No id_token received from server');
        }

        final userInfo = _jwtService.getUserInfo(idToken);

        if (userInfo == null) {
          throw ServerException('Invalid JWT token received');
        }

        if (_jwtService.isTokenExpired(idToken)) {
          throw ServerException('Received expired token');
        }

        await _storageService.saveToken(idToken);

        final roleString = userInfo['custom:role']?.toString();
        debugPrint('Auth: Google sign in - Role from JWT token: $roleString');

        if (roleString == null || roleString.isEmpty) {
          throw ServerException('No role found in JWT token');
        }

        _currentUser = AuthUser(
          id: userInfo['id']?.toString() ?? '',
          email: userInfo['email']?.toString() ?? '',
          role: Role.fromJson(roleString),
          isEmailVerified: true,
        );

        notifyListeners();

        await _storageService.saveUser(_currentUser!);
        debugPrint(
            'Auth: User signed in with Google with role: ${_currentUser!.role.value}');

        return _currentUser!;
      } else {
        throw ServerException('Google sign in failed');
      }
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw GenericAuthException();
    }
  }

  @override
  Future<void> signOut() async {
    await _storageService.clearAuthData();
    _currentUser = null;
    DbProvider.instance.clearCache();
    DbProvider.reset();
    notifyListeners();
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    try {
      final response = await _dioClient.put(
        '/user/password',
        data: {'password': newPassword},
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed to update password');
      }
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      throw GenericAuthException();
    }
  }

  @override
  Future<AuthUser> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dioClient.post(
        '/verify',
        data: {
          'email': email,
          'code': code,
        },
      );

      if (response.statusCode == 200) {
        if (_currentUser != null) {
          _currentUser = AuthUser(
            id: _currentUser!.id,
            email: _currentUser!.email,
            role: _currentUser!.role,
            isEmailVerified: true,
          );
          await _storageService.saveUser(_currentUser!);
        }
        return _currentUser!;
      } else {
        throw ServerException('Email verification failed');
      }
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      throw GenericAuthException();
    }
  }

  @override
  Future<void> resendVerificationCode({required String email}) async {
    try {
      final response = await _dioClient.post(
        '/resend-code',
        data: {'email': email},
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed to resend verification code');
      }
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      throw GenericAuthException();
    }
  }

  @override
  Future<AuthUser?> refreshUser() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) return null;

      if (_jwtService.isTokenExpired(token)) {
        await _storageService.clearAuthData();
        _currentUser = null;
        return null;
      }

      final response = await _dioClient.get('/profile/me');

      if (response.statusCode == 200) {
        final profileData = response.data['profile'];
        if (profileData != null) {
          final roleString = profileData['role']?.toString();
          debugPrint('Auth: Refresh user - Role from profile: $roleString');

          if (roleString == null || roleString.isEmpty) {
            debugPrint('Auth: No role found in profile, falling back to JWT');
            // Fall back to JWT token
            final userInfo = _jwtService.getUserInfo(token);
            if (userInfo != null) {
              final jwtRoleString = userInfo['custom:role']?.toString();
              if (jwtRoleString != null && jwtRoleString.isNotEmpty) {
                _currentUser = AuthUser(
                  id: userInfo['id']?.toString() ?? '',
                  email: userInfo['email']?.toString() ?? '',
                  role: Role.fromJson(jwtRoleString),
                  isEmailVerified: true,
                );
                await _storageService.saveUser(_currentUser!);
                return _currentUser;
              }
            }
            return null;
          }

          _currentUser = AuthUser(
            id: profileData['id']?.toString() ?? _currentUser?.id ?? '',
            email:
                profileData['email']?.toString() ?? _currentUser?.email ?? '',
            role: Role.fromJson(roleString),
            isEmailVerified: true,
          );
          await _storageService.saveUser(_currentUser!);
          debugPrint(
              'Auth: User refreshed from profile with role: ${_currentUser!.role.value}');
          return _currentUser;
        }
      }

      final userInfo = _jwtService.getUserInfo(token);
      if (userInfo != null) {
        final roleString = userInfo['custom:role']?.toString();
        debugPrint(
            'Auth: Refresh user JWT fallback - Role from JWT: $roleString');

        if (roleString == null || roleString.isEmpty) {
          debugPrint('Auth: No role found in JWT token during refresh');
          return null;
        }

        _currentUser = AuthUser(
          id: userInfo['id']?.toString() ?? '',
          email: userInfo['email']?.toString() ?? '',
          role: Role.fromJson(roleString),
          isEmailVerified: true,
        );
        debugPrint(
            'Auth: User refreshed from JWT with role: ${_currentUser!.role.value}');
        return _currentUser;
      }

      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _storageService.clearAuthData();
        _currentUser = null;
        return null;
      }

      if (e.response?.statusCode == 404) {
        final token = await _storageService.getToken();
        if (token != null && !_jwtService.isTokenExpired(token)) {
          final userInfo = _jwtService.getUserInfo(token);
          if (userInfo != null) {
            final roleString = userInfo['custom:role']?.toString();
            debugPrint('Auth: Refresh user 404 - Role from JWT: $roleString');

            if (roleString == null || roleString.isEmpty) {
              debugPrint('Auth: No role found in JWT token for 404 case');
              return null;
            }

            _currentUser = AuthUser(
              id: userInfo['id']?.toString() ?? '',
              email: userInfo['email']?.toString() ?? '',
              role: Role.fromJson(roleString),
              isEmailVerified: true,
            );
            debugPrint(
                'Auth: User refreshed from JWT (404 case) with role: ${_currentUser!.role.value}');
            return _currentUser;
          }
        }
        return null;
      }

      final token = await _storageService.getToken();
      if (token != null && !_jwtService.isTokenExpired(token)) {
        final userInfo = _jwtService.getUserInfo(token);
        if (userInfo != null) {
          final roleString = userInfo['custom:role']?.toString();
          debugPrint(
              'Auth: Refresh user error fallback - Role from JWT: $roleString');

          if (roleString == null || roleString.isEmpty) {
            debugPrint('Auth: No role found in JWT token for error fallback');
            return null;
          }

          _currentUser = AuthUser(
            id: userInfo['id']?.toString() ?? '',
            email: userInfo['email']?.toString() ?? '',
            role: Role.fromJson(roleString),
            isEmailVerified: true,
          );
          debugPrint(
              'Auth: User refreshed from JWT (error fallback) with role: ${_currentUser!.role.value}');
          return _currentUser;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _dioClient.post(
        '/reset-password',
        data: {
          'email': email,
          'code': code,
          'new_password': newPassword,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        debugPrint(
            'Password reset successful: ${responseData['message'] ?? 'Password has been reset successfully.'}');
      } else {
        throw ServerException('Failed to reset password');
      }
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      throw GenericAuthException();
    }
  }
}
