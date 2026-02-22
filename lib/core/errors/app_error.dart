class AppError implements Exception {
  final String code;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const AppError({
    required this.code,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() => 'AppError(code: $code, message: $message)';
}

class AuthError extends AppError {
  const AuthError({
    required super.code,
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

class SyncError extends AppError {
  const SyncError({
    required super.code,
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

class StorageError extends AppError {
  const StorageError({
    required super.code,
    required super.message,
    super.cause,
    super.stackTrace,
  });
}
