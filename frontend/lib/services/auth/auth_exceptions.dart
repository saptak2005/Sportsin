import 'package:dio/dio.dart';

abstract class AuthException implements Exception {}

class UserNotFoundAuthException extends AuthException {}

class WrongPasswordAuthException extends AuthException {}

class WeakPasswordAuthException extends AuthException {}

class EmailAlreadyInUseAuthException extends AuthException {}

class InvalidEmailAuthException extends AuthException {}

class NetworkException extends AuthException {}

class ServerException extends AuthException {
  final String message;
  ServerException(this.message);
}

class TokenExpiredException extends AuthException {}

class InvalidCredentialsException extends AuthException {}

class AccountDisabledException extends AuthException {}

class TooManyRequestsException extends AuthException {}

class EmailNotVerifiedException extends AuthException {}

class GenericAuthException extends AuthException {}

class UserNotLoggedInAuthException extends AuthException {}

class UserCancelledAuthException extends AuthException {}

class CouldNotRefreshUser extends AuthException {}

AuthException handleDioError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return NetworkException();
    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode;
      final errorData = error.response?.data;

      switch (statusCode) {
        case 400:
          if (errorData != null && errorData['error'] != null) {
            final errorMessage = errorData['error'].toString().toLowerCase();
            if (errorMessage.contains('email')) {
              if (errorMessage.contains('already') ||
                  errorMessage.contains('exists')) {
                return EmailAlreadyInUseAuthException();
              } else if (errorMessage.contains('invalid')) {
                return InvalidEmailAuthException();
              }
            } else if (errorMessage.contains('password')) {
              return WeakPasswordAuthException();
            }
          }
          return GenericAuthException();
        case 401:
          return InvalidCredentialsException();
        case 403:
          return EmailNotVerifiedException();
        case 404:
          return UserNotFoundAuthException();
        case 429:
          return TooManyRequestsException();
        case 500:
        default:
          return ServerException(
              errorData?['error'] ?? 'Server error occurred');
      }
    case DioExceptionType.cancel:
      return UserCancelledAuthException();
    case DioExceptionType.connectionError:
    case DioExceptionType.unknown:
    default:
      return NetworkException();
  }
}
