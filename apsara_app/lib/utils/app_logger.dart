import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(String message) {
    _log('INFO', message, null, null);
  }

  static void warn(String message, [Object? error, StackTrace? stackTrace]) {
    _log('WARN', message, error, stackTrace);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log('ERROR', message, error, stackTrace);
  }

  static void _log(
    String level,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    final buffer = StringBuffer('[Apsara][$level] $message');
    if (error != null) {
      buffer.write(' | $error');
    }
    debugPrint(buffer.toString());
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
