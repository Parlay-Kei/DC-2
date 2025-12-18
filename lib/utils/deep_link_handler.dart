import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'constants.dart';

/// Deep link handler for the app
class DeepLinkHandler {
  DeepLinkHandler._();

  /// Parse a deep link URI and return the corresponding route
  static String? parseDeepLink(Uri uri) {
    // Handle custom scheme: directcuts://
    if (uri.scheme == AppConstants.deepLinkScheme) {
      return _parsePathAndParams(uri);
    }

    // Handle universal links: https://directcuts.com/
    if (uri.host == AppConstants.universalLinkDomain) {
      return _parsePathAndParams(uri);
    }

    return null;
  }

  static String? _parsePathAndParams(Uri uri) {
    final path = uri.path;
    final params = uri.queryParameters;

    // Barber profile: /barber/{id}
    if (path.startsWith('/barber/')) {
      final barberId = path.replaceFirst('/barber/', '');
      if (barberId.isNotEmpty) {
        return '/barber/$barberId';
      }
    }

    // Booking: /book/{barberId}
    if (path.startsWith('/book/')) {
      final barberId = path.replaceFirst('/book/', '');
      if (barberId.isNotEmpty) {
        return '/book/$barberId';
      }
    }

    // Chat: /chat/{conversationId}
    if (path.startsWith('/chat/')) {
      final conversationId = path.replaceFirst('/chat/', '');
      if (conversationId.isNotEmpty) {
        return '/chat/$conversationId';
      }
    }

    // Booking details: /booking/{id}
    if (path.startsWith('/booking/')) {
      final bookingId = path.replaceFirst('/booking/', '');
      if (bookingId.isNotEmpty) {
        // TODO: Add booking detail route when implemented
        return '/customer'; // Fallback to home for now
      }
    }

    // Review: /review?bookingId=X&barberId=Y
    if (path == '/review') {
      final bookingId = params['bookingId'];
      final barberId = params['barberId'];
      if (bookingId != null && barberId != null) {
        return '/review/$bookingId/$barberId';
      }
    }

    // Settings paths
    if (path.startsWith('/settings')) {
      return path; // Direct passthrough for settings routes
    }

    // Notifications
    if (path == '/notifications') {
      return '/notifications';
    }

    // Conversations
    if (path == '/conversations' || path == '/messages') {
      return '/conversations';
    }

    // Barber dashboard
    if (path == '/dashboard' || path == '/barber-dashboard') {
      return '/barber-dashboard';
    }

    // Default fallback
    return null;
  }

  /// Navigate to a deep link route
  static void handleDeepLink(BuildContext context, Uri uri) {
    final route = parseDeepLink(uri);
    if (route != null) {
      context.go(route);
    }
  }

  /// Create a shareable link for a barber profile
  static String createBarberLink(String barberId) {
    return 'https://${AppConstants.universalLinkDomain}/barber/$barberId';
  }

  /// Create a shareable booking link
  static String createBookingLink(String barberId) {
    return 'https://${AppConstants.universalLinkDomain}/book/$barberId';
  }

  /// Create a deep link URI
  static Uri createDeepLinkUri(String path, [Map<String, String>? params]) {
    return Uri(
      scheme: AppConstants.deepLinkScheme,
      path: path,
      queryParameters: params,
    );
  }
}

/// Mixin for handling deep links in widgets
mixin DeepLinkMixin<T extends StatefulWidget> on State<T> {
  /// Override to handle incoming deep links
  void onDeepLink(Uri uri) {
    DeepLinkHandler.handleDeepLink(context, uri);
  }
}
