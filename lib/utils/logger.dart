import 'package:flutter/foundation.dart';

/// Production-safe logging utility
///
/// This logger ensures that sensitive information is never logged in release builds.
/// All debug messages are automatically stripped when kReleaseMode is true.
///
/// Usage:
/// ```dart
/// Logger.debug('User profile loaded');  // Safe - no PII
/// Logger.info('Payment processed');     // Safe - generic message
/// Logger.error('API call failed', error, stackTrace);
/// ```
///
/// NEVER log:
/// - User IDs, emails, phone numbers
/// - Authentication tokens or API keys
/// - Payment card information
/// - Device identifiers
/// - User metadata or profile data
class Logger {
  /// Log debug messages (stripped in release builds)
  ///
  /// Use for detailed debugging information that should not appear in production.
  /// These messages are completely removed when kDebugMode is false.
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }

  /// Log informational messages (stripped in release builds)
  ///
  /// Use for general application flow information.
  /// These messages are removed when kDebugMode is false.
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  /// Log error messages
  ///
  /// Errors are always logged, but detailed error objects and stack traces
  /// are only logged in debug mode. Ensure error messages do not contain PII.
  static void error(
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    // Always log the sanitized error message
    debugPrint('[ERROR] $message');

    // Only log detailed error information in debug mode
    if (kDebugMode) {
      if (error != null) {
        debugPrint('Error details: $error');
      }
      if (stackTrace != null) {
        debugPrint('Stack trace:\n$stackTrace');
      }
    }
  }

  /// Log warning messages (stripped in release builds)
  ///
  /// Use for potentially problematic situations that are not errors.
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('[WARNING] $message');
    }
  }

  /// Check if debug logging is enabled
  static bool get isDebugMode => kDebugMode;
}
