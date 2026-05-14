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
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
         message: message,
         code: code,
         originalError: originalError,
         stackTrace: stackTrace,
       );
}

/// Authentication errors (invalid token, expired session, unauthorized)
class AuthException extends AppException {
  AuthException({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
         message: message,
         code: code,
         originalError: originalError,
         stackTrace: stackTrace,
       );
}

/// Database/Storage errors (query failed, permission denied, constraint violation)
class DatabaseException extends AppException {
  final String? constraint;

  DatabaseException({
    required String message,
    String? code,
    this.constraint,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
         message: message,
         code: code,
         originalError: originalError,
         stackTrace: stackTrace,
       );
}

/// Validation errors (invalid input, required field missing)
class ValidationException extends AppException {
  final Map<String, String> fieldErrors;

  ValidationException({
    required String message,
    this.fieldErrors = const {},
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
         message: message,
         code: 'VALIDATION_ERROR',
         originalError: originalError,
         stackTrace: stackTrace,
       );
}

/// Parse/Serialization errors (malformed JSON, invalid model)
class ParseException extends AppException {
  ParseException({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
         message: message,
         code: code,
         originalError: originalError,
         stackTrace: stackTrace,
       );
}

/// Generic business logic errors
class BusinessException extends AppException {
  BusinessException({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
         message: message,
         code: code,
         originalError: originalError,
         stackTrace: stackTrace,
       );
}

/// Unknown/unexpected errors
class UnknownException extends AppException {
  UnknownException({
    required String message,
    String? code,
    required dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
         message: message,
         code: code ?? 'UNKNOWN_ERROR',
         originalError: originalError,
         stackTrace: stackTrace,
       );
}
