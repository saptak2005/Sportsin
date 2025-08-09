import 'package:dio/dio.dart';

class DbExceptions implements Exception {
  final String? message;
  final String? details;

  const DbExceptions({
    this.message,
    this.details,
  });

  // Static utility methods for handling exceptions
  static Exception handleDioException(DioException e, String operation) {
    if (e.response != null) {
      return _handleHttpError(
          e.response!.statusCode!, e.response!.data, operation);
    } else {
      return _handleNetworkError(e, operation);
    }
  }

  static Exception _handleHttpError(
      int statusCode, dynamic errorData, String operation) {
    final errorMessage = errorData?['error']?.toString();

    switch (statusCode) {
      case 400:
        return DbInvalidInputException(
          message: 'Bad request: Invalid data provided',
          details: errorMessage ?? 'Invalid request data',
        );
      case 401:
        return const DbAuthenticationException(
          message: 'User not authenticated',
          details: 'Authentication required',
        );
      case 403:
        return const DbAuthorizationException(
          message: 'Access denied',
          details: 'User not authorized for this operation',
        );
      case 404:
        return const DbNotFoundException(
          message: 'Resource not found',
          details: 'The requested resource does not exist',
        );
      case 429:
        return const DbRateLimitExceededException(
          message: 'Too many requests',
          details: 'Rate limit exceeded',
        );
      case 500:
        return DbServiceUnavailableException(
          message: 'Server error occurred',
          details: errorMessage ?? 'Internal server error',
        );
      case 503:
        return const DbServiceUnavailableException(
          message: 'Service temporarily unavailable',
          details: 'Service is temporarily down',
        );
      default:
        return Exception(
          'Request failed with status $statusCode: ${errorMessage ?? 'Unknown error'}',
        );
    }
  }

  static Exception _handleNetworkError(DioException e, String operation) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return DbTimeoutException(
          message: 'Request timeout',
          details: 'Network timeout while $operation: ${e.message}',
        );
      case DioExceptionType.connectionError:
        return DbConnectionException(
          message: 'Network connection error',
          details: 'Failed to connect to server: ${e.message}',
        );
      case DioExceptionType.cancel:
        return DbUnknownException(
          message: 'Request cancelled',
          details: '$operation request was cancelled',
        );
      default:
        return DbConnectionException(
          message: 'Network error',
          details: 'Network error occurred: ${e.message}',
        );
    }
  }

  // Helper methods for determining when to return null
  static bool shouldReturnNullForUser(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      switch (statusCode) {
        case 401:
        case 403:
        case 404:
          return true;
        default:
          return false;
      }
    } else {
      return true;
    }
  }

  static bool shouldReturnNullForPost(DioException e) {
    if (e.response != null) {
      return e.response!.statusCode == 404;
    }
    return false;
  }
}

class DbConnectionException extends DbExceptions {
  const DbConnectionException({
    super.message,
    super.details,
  });
}

class DbQueryException extends DbExceptions {
  const DbQueryException({
    super.message,
    super.details,
  });
}

class DbInsertException extends DbExceptions {
  const DbInsertException({
    super.message,
    super.details,
  });
}

class DbUpdateException extends DbExceptions {
  const DbUpdateException({
    super.message,
    super.details,
  });
}

class DbDeleteException extends DbExceptions {
  const DbDeleteException({
    super.message,
    super.details,
  });
}

class DbTransactionException extends DbExceptions {
  const DbTransactionException({
    super.message,
    super.details,
  });
}

class DbNotFoundException extends DbExceptions {
  const DbNotFoundException({
    super.message,
    super.details,
  });
}

class DbConflictException extends DbExceptions {
  const DbConflictException({
    super.message,
    super.details,
  });
}

class DbPermissionDeniedException extends DbExceptions {
  const DbPermissionDeniedException({
    super.message,
    super.details,
  });
}

class DbRateLimitExceededException extends DbExceptions {
  const DbRateLimitExceededException({
    super.message,
    super.details,
  });
}

class DbInvalidInputException extends DbExceptions {
  const DbInvalidInputException({
    super.message,
    super.details,
  });
}

class DbUnknownException extends DbExceptions {
  const DbUnknownException({
    super.message,
    super.details,
  });
}

class DbTimeoutException extends DbExceptions {
  const DbTimeoutException({
    super.message,
    super.details,
  });
}

class DbAuthenticationException extends DbExceptions {
  const DbAuthenticationException({
    super.message,
    super.details,
  });
}

class DbAuthorizationException extends DbExceptions {
  const DbAuthorizationException({
    super.message,
    super.details,
  });
}

class DbServiceUnavailableException extends DbExceptions {
  const DbServiceUnavailableException({
    super.message,
    super.details,
  });
}

class DbMaintenanceModeException extends DbExceptions {
  const DbMaintenanceModeException({
    super.message,
    super.details,
  });
}

class DbFeatureNotSupportedException extends DbExceptions {
  const DbFeatureNotSupportedException({
    super.message,
    super.details,
  });
}

class DbPostCreationException extends DbExceptions {
  const DbPostCreationException({
    super.message,
    super.details,
  });
}

class DbPostValidationException extends DbExceptions {
  const DbPostValidationException({
    super.message,
    super.details,
  });
}

class DbImageUploadException extends DbExceptions {
  const DbImageUploadException({
    super.message,
    super.details,
  });
}

class WebSocketConnectionException extends DbExceptions {
  const WebSocketConnectionException({
    super.message,
    super.details,
  });
}
