import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LogLevel { debug, info, warn, error }

final appLoggerProvider = Provider<AppLogger>((ref) => AppLogger());

class AppLogger {
  static const _redacted = '<redacted>';
  static const _sensitiveKeyParts = [
    'password',
    'token',
    'secret',
    'email',
    'phone',
    'authorization',
    'cookie',
    'key',
  ];

  void debug(String message, {Map<String, Object?> data = const {}}) {
    _log(LogLevel.debug, message, data: data);
  }

  void info(String message, {Map<String, Object?> data = const {}}) {
    _log(LogLevel.info, message, data: data);
  }

  void warn(
    String message, {
    Map<String, Object?> data = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.warn,
      message,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void error(
    String message, {
    Map<String, Object?> data = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.error,
      message,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _log(
    LogLevel level,
    String message, {
    Map<String, Object?> data = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    final event = <String, Object?>{
      'ts': DateTime.now().toIso8601String(),
      'level': level.name,
      'message': message,
      if (data.isNotEmpty) 'data': _redactMap(data),
      if (error != null) 'error': error.toString(),
      if (stackTrace != null && kDebugMode) 'stack': stackTrace.toString(),
    };
    debugPrint(jsonEncode(event));
  }

  Map<String, Object?> _redactMap(Map<String, Object?> input) {
    final output = <String, Object?>{};
    input.forEach((key, value) {
      final lower = key.toLowerCase();
      final shouldRedact = _sensitiveKeyParts.any(lower.contains);
      if (shouldRedact) {
        output[key] = _redacted;
      } else if (value is Map<String, Object?>) {
        output[key] = _redactMap(value);
      } else {
        output[key] = value;
      }
    });
    return output;
  }
}
