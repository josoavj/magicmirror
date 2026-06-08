/// Base exception for all application errors
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => message;
}

/// Network-related errors (no internet, timeout, host unreachable)
class NetworkException extends AppException {
  NetworkException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Authentication errors (invalid token, expired session, unauthorized)
class AuthException extends AppException {
  AuthException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Database/Storage errors (query failed, permission denied, constraint violation)
class DatabaseException extends AppException {
  final String? constraint;

  DatabaseException({
    required super.message,
    super.code,
    this.constraint,
    super.originalError,
    super.stackTrace,
  });
}

/// Validation errors (invalid input, required field missing)
class ValidationException extends AppException {
  final Map<String, String> fieldErrors;

  ValidationException({
    required super.message,
    this.fieldErrors = const {},
    super.originalError,
    super.stackTrace,
  }) : super(
         code: 'VALIDATION_ERROR',
       );
}

/// Parse/Serialization errors (malformed JSON, invalid model)
class ParseException extends AppException {
  ParseException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Generic business logic errors
class BusinessException extends AppException {
  BusinessException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Unknown/unexpected errors
class UnknownException extends AppException {
  UnknownException({
    required super.message,
    String? code,
    required super.originalError,
    super.stackTrace,
  }) : super(
         code: code ?? 'UNKNOWN_ERROR',
       );
}
