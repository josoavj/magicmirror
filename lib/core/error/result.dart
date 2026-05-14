import 'app_exception.dart';

/// A Result type that represents either a success (with value of type T) or a failure (with AppException)
/// Inspired by Rust's Result and Kotlin's Result types
abstract class Result<T> {
  const Result();

  /// Returns true if this is a success result
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a failure result
  bool get isFailure => this is Failure<T>;

  /// Get the value if success, throws if failure
  T getOrThrow() {
    final self = this;
    if (self is Success<T>) {
      return self.value;
    } else if (self is Failure<T>) {
      throw self.exception;
    }
    throw UnimplementedError('Unknown Result type');
  }

  /// Get the value if success, returns null if failure
  T? getOrNull() {
    final self = this;
    if (self is Success<T>) {
      return self.value;
    }
    return null;
  }

  /// Get the exception if failure, returns null if success
  AppException? exceptionOrNull() {
    final self = this;
    if (self is Failure<T>) {
      return self.exception;
    }
    return null;
  }

  /// Map the success value to another type
  Result<R> map<R>(R Function(T) transform) {
    final self = this;
    if (self is Success<T>) {
      try {
        return Success(transform(self.value));
      } catch (e, st) {
        return Failure(
          UnknownException(
            message: 'Error during map transformation',
            originalError: e,
            stackTrace: st,
          ),
        );
      }
    } else if (self is Failure<T>) {
      return Failure(self.exception);
    }
    return Failure(
      UnknownException(message: 'Unknown Result type', originalError: null),
    );
  }

  /// Map the success value to another Result type (flatMap/bind)
  Future<Result<R>> flatMapAsync<R>(
    Future<Result<R>> Function(T) transform,
  ) async {
    final self = this;
    if (self is Success<T>) {
      try {
        return await transform(self.value);
      } catch (e, st) {
        return Failure(
          UnknownException(
            message: 'Error during async transformation',
            originalError: e,
            stackTrace: st,
          ),
        );
      }
    } else if (self is Failure<T>) {
      return Failure(self.exception);
    }
    return Failure(
      UnknownException(message: 'Unknown Result type', originalError: null),
    );
  }

  /// Execute a callback on success (side effect)
  Result<T> onSuccess(void Function(T) callback) {
    final self = this;
    if (self is Success<T>) {
      try {
        callback(self.value);
      } catch (e, st) {
        // Log but don't rethrow - this is a side effect
        print('Error in onSuccess callback: $e\n$st');
      }
    }
    return this;
  }

  /// Execute a callback on failure (side effect)
  Result<T> onFailure(void Function(AppException) callback) {
    final self = this;
    if (self is Failure<T>) {
      try {
        callback(self.exception);
      } catch (e, st) {
        // Log but don't rethrow
        print('Error in onFailure callback: $e\n$st');
      }
    }
    return this;
  }

  /// Fold result into a single value
  R fold<R>(R Function(AppException) onFailure, R Function(T) onSuccess) {
    final self = this;
    if (self is Success<T>) {
      return onSuccess(self.value);
    } else if (self is Failure<T>) {
      return onFailure(self.exception);
    }
    throw UnimplementedError('Unknown Result type');
  }
}

/// Success result containing a value
class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  String toString() => 'Success($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Failure result containing an exception
class Failure<T> extends Result<T> {
  final AppException exception;

  const Failure(this.exception);

  @override
  String toString() => 'Failure(${exception.message})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          exception == other.exception;

  @override
  int get hashCode => exception.hashCode;
}

/// Extension to wrap Future<T> into Future<Result<T>>
extension FutureResultExt<T> on Future<T> {
  /// Wraps a Future into Result, catching any exceptions
  Future<Result<T>> toResult() async {
    try {
      final value = await this;
      return Success(value);
    } catch (e, st) {
      if (e is AppException) {
        return Failure(e);
      }
      return Failure(
        UnknownException(
          message: 'Unexpected error: ${e.toString()}',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }
}
