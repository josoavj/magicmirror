import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'app_exception.dart';
import 'result.dart';

/// Configuration for retry behavior
class RetryConfig {
  /// Maximum number of retry attempts (not including the initial attempt)
  final int maxAttempts;

  /// Initial delay before first retry
  final Duration initialDelay;

  /// Maximum delay between retries (caps exponential backoff)
  final Duration maxDelay;

  /// Multiplier for exponential backoff (e.g., 2.0 means delay doubles each time)
  final double backoffMultiplier;

  /// Whether to add random jitter to delays (prevents thundering herd)
  final bool useJitter;

  /// Function to determine if an exception is retryable
  final bool Function(AppException) isRetryable;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 100),
    this.maxDelay = const Duration(seconds: 10),
    this.backoffMultiplier = 2.0,
    this.useJitter = true,
    this.isRetryable = _defaultIsRetryable,
  });

  /// Calculate delay for a given attempt number (0-based)
  Duration calculateDelay(int attemptNumber) {
    var delay =
        initialDelay.inMilliseconds *
        pow(backoffMultiplier, attemptNumber).toDouble();
    delay = min(delay, maxDelay.inMilliseconds.toDouble());

    if (useJitter) {
      final jitter = Random().nextDouble() * delay * 0.1; // ±10% jitter
      delay += jitter;
    }

    return Duration(milliseconds: delay.toInt());
  }

  static bool _defaultIsRetryable(AppException exception) {
    return exception is NetworkException ||
        (exception is DatabaseException &&
            exception.code != '42703' && // Column not found - don't retry
            exception.code != '23505'); // Unique constraint - don't retry
  }
}

/// Retry helper for managing retry logic with exponential backoff
class Retry {
  static const RetryConfig _defaultConfig = RetryConfig();

  /// Retry a function up to maxAttempts times with exponential backoff
  static Future<T> execute<T>(
    Future<T> Function() fn, {
    RetryConfig config = _defaultConfig,
    VoidCallback? onRetry,
  }) async {
    int attemptNumber = 0;

    while (true) {
      try {
        return await fn();
      } catch (e) {
        final isLastAttempt = attemptNumber >= config.maxAttempts;

        if (isLastAttempt) {
          rethrow;
        }

        final exception = _toAppException(e);

        if (!config.isRetryable(exception)) {
          rethrow;
        }

        final delay = config.calculateDelay(attemptNumber);
        if (kDebugMode) {
          print(
            '[Retry] Attempt ${attemptNumber + 1}/${config.maxAttempts + 1} failed: $exception. '
            'Retrying in ${delay.inMilliseconds}ms...',
          );
        }

        onRetry?.call();
        await Future.delayed(delay);
        attemptNumber++;
      }
    }
  }

  /// Retry a function that returns Result<T>
  static Future<Result<T>> executeResult<T>(
    Future<Result<T>> Function() fn, {
    RetryConfig config = _defaultConfig,
    VoidCallback? onRetry,
  }) async {
    int attemptNumber = 0;

    while (true) {
      final result = await fn();

      if (result.isSuccess) {
        return result;
      }

      final exception = result.exceptionOrNull()!;
      final isLastAttempt = attemptNumber >= config.maxAttempts;

      if (isLastAttempt || !config.isRetryable(exception)) {
        return result;
      }

      final delay = config.calculateDelay(attemptNumber);
      if (kDebugMode) {
        print(
          '[Retry] Attempt ${attemptNumber + 1}/${config.maxAttempts + 1} failed: $exception. '
          'Retrying in ${delay.inMilliseconds}ms...',
        );
      }

      onRetry?.call();
      await Future.delayed(delay);
      attemptNumber++;
    }
  }

  static AppException _toAppException(dynamic e) {
    if (e is AppException) {
      return e;
    }
    return UnknownException(message: e.toString(), originalError: e);
  }
}

/// Mixin for adding retry capability to services
mixin RetryableMixin {
  RetryConfig get retryConfig => const RetryConfig();

  Future<T> withRetry<T>(Future<T> Function() fn, {VoidCallback? onRetry}) =>
      Retry.execute(fn, config: retryConfig, onRetry: onRetry);

  Future<Result<T>> withRetryResult<T>(
    Future<Result<T>> Function() fn, {
    VoidCallback? onRetry,
  }) => Retry.executeResult(fn, config: retryConfig, onRetry: onRetry);
}
