import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/theme.dart';

/// Centralized error handling utility
class ErrorHandler {
  static ErrorHandler? _instance;
  static ErrorHandler get instance => _instance ??= ErrorHandler._();
  
  ErrorHandler._();

  /// Convert any error to user-friendly message
  String getErrorMessage(dynamic error) {
    if (error is AuthException) {
      return _handleAuthError(error);
    }
    
    if (error is PostgrestException) {
      return _handlePostgrestError(error);
    }
    
    if (error is StorageException) {
      return _handleStorageError(error);
    }
    
    if (error is SocketException) {
      return 'No internet connection. Please check your network.';
    }
    
    if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    }
    
    if (error is FormatException) {
      return 'Invalid data format received.';
    }
    
    // Generic error
    final message = error.toString();
    if (message.contains('network') || message.contains('connection')) {
      return 'Network error. Please check your connection.';
    }
    
    return 'Something went wrong. Please try again.';
  }

  String _handleAuthError(AuthException error) {
    final message = error.message.toLowerCase();
    
    if (message.contains('invalid login credentials')) {
      return 'Invalid email or password.';
    }
    if (message.contains('email not confirmed')) {
      return 'Please verify your email address.';
    }
    if (message.contains('user already registered')) {
      return 'An account with this email already exists.';
    }
    if (message.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }
    if (message.contains('weak password')) {
      return 'Password is too weak. Please use a stronger password.';
    }
    if (message.contains('session expired') || message.contains('refresh_token')) {
      return 'Your session has expired. Please sign in again.';
    }
    if (message.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment.';
    }
    
    return error.message;
  }

  String _handlePostgrestError(PostgrestException error) {
    final code = error.code;
    
    switch (code) {
      case '23505': // unique_violation
        return 'This record already exists.';
      case '23503': // foreign_key_violation
        return 'Referenced record not found.';
      case '42501': // insufficient_privilege
        return 'You don\'t have permission for this action.';
      case '42P01': // undefined_table
        return 'Service temporarily unavailable.';
      case 'PGRST301': // Row not found
        return 'Record not found.';
      default:
        if (error.message.contains('Row Level Security')) {
          return 'You don\'t have access to this resource.';
        }
        return 'Database error. Please try again.';
    }
  }

  String _handleStorageError(StorageException error) {
    final message = error.message.toLowerCase();
    
    if (message.contains('not found')) {
      return 'File not found.';
    }
    if (message.contains('access denied') || message.contains('unauthorized')) {
      return 'Access denied to this file.';
    }
    if (message.contains('too large') || message.contains('size')) {
      return 'File is too large. Maximum size is 5MB.';
    }
    if (message.contains('invalid') && message.contains('type')) {
      return 'Invalid file type. Please use JPG, PNG, or GIF.';
    }
    
    return 'File upload failed. Please try again.';
  }

  /// Show error snackbar
  void showError(BuildContext context, dynamic error) {
    final message = getErrorMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: DCTheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show success snackbar
  void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: DCTheme.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show info snackbar
  void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: DCTheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show warning snackbar
  void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_outlined, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: DCTheme.warning,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show error dialog for critical errors
  Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: DCTheme.surface,
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: DCTheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(color: DCTheme.text)),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(color: DCTheme.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: DCTheme.textMuted)),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onAction();
              },
              child: Text(actionLabel, style: const TextStyle(color: DCTheme.primary)),
            ),
        ],
      ),
    );
  }

  /// Wrap async operation with error handling
  Future<T?> tryAsync<T>(
    Future<T> Function() operation, {
    BuildContext? context,
    String? errorMessage,
    bool showError = true,
  }) async {
    try {
      return await operation();
    } catch (e) {
      if (showError && context != null && context.mounted) {
        this.showError(context, errorMessage ?? e);
      }
      return null;
    }
  }
}

/// Extension for easy error handling
extension ErrorHandlerExtension on BuildContext {
  void showError(dynamic error) => ErrorHandler.instance.showError(this, error);
  void showSuccess(String message) => ErrorHandler.instance.showSuccess(this, message);
  void showInfo(String message) => ErrorHandler.instance.showInfo(this, message);
  void showWarning(String message) => ErrorHandler.instance.showWarning(this, message);
}
