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
      // Debug: Log the response data type and content for troubleshooting
      _debugLogResponseData(e.response!.data, operation);
      return _handleHttpError(
          e.response!.statusCode!, e.response!.data, operation);
    } else {
      return _handleNetworkError(e, operation);
    }
  }

  // Debug method to log response data for troubleshooting
  static void _debugLogResponseData(dynamic data, String operation) {
    print('🔍 Debug - Error response for $operation:');
    print('   Type: ${data.runtimeType}');
    print('   Content: $data');
    if (data is Map) {
      print('   Keys: ${data.keys.toList()}');
    }
  }

  // Helper method to safely extract error message from response data
  static String? _extractErrorMessage(dynamic errorData) {
    if (errorData == null) return null;

    if (errorData is Map<String, dynamic>) {
      // Try different common error message keys
      return errorData['error']?.toString() ??
          errorData['message']?.toString() ??
          errorData['detail']?.toString() ??
          errorData['details']?.toString() ??
          errorData['msg']?.toString();
    } else if (errorData is String) {
      return errorData;
    } else if (errorData is List && errorData.isNotEmpty) {
      // Handle array of errors
      final firstError = errorData.first;
      if (firstError is Map<String, dynamic>) {
        return _extractErrorMessage(firstError);
      } else {
        return firstError.toString();
      }
    } else {
      return errorData.toString();
    }
  }

  static Exception _handleHttpError(
      int statusCode, dynamic errorData, String operation) {
    final errorMessage = _extractErrorMessage(errorData);

    switch (statusCode) {
      case 400:
        return DbInvalidInputException(
          message: 'Bad request: Invalid data provided',
          details: errorMessage ?? 'Invalid request data for $operation',
        );
      case 401:
        return DbAuthenticationException(
          message: 'User not authenticated',
          details: errorMessage ?? 'Authentication required for $operation',
        );
      case 403:
        return DbAuthorizationException(
          message: 'Access denied',
          details: errorMessage ?? 'User not authorized for $operation',
        );
      case 404:
        return DbNotFoundException(
          message: 'Resource not found',
          details: errorMessage ??
              'The requested resource for $operation does not exist',
        );
      case 409:
        return DbConflictException(
          message: 'Resource conflict',
          details: errorMessage ?? 'Resource conflict during $operation',
        );
      case 422:
        return DbInvalidInputException(
          message: 'Validation failed',
          details: errorMessage ?? 'Input validation failed for $operation',
        );
      case 429:
        return DbRateLimitExceededException(
          message: 'Too many requests',
          details: errorMessage ?? 'Rate limit exceeded for $operation',
        );
      case 500:
        return DbServiceUnavailableException(
          message: 'Server error occurred',
          details: errorMessage ?? 'Internal server error during $operation',
        );
      case 502:
        return DbServiceUnavailableException(
          message: 'Bad gateway',
          details: errorMessage ?? 'Bad gateway error during $operation',
        );
      case 503:
        return DbServiceUnavailableException(
          message: 'Service temporarily unavailable',
          details: errorMessage ?? 'Service is temporarily down for $operation',
        );
      case 504:
        return DbTimeoutException(
          message: 'Gateway timeout',
          details: errorMessage ?? 'Gateway timeout during $operation',
        );
      default:
        return DbUnknownException(
          message: 'Request failed with status $statusCode',
          details: errorMessage ?? 'Unknown error occurred during $operation',
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
