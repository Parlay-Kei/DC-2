import 'dart:io';
import 'package:flutter/foundation.dart';

// Application configuration
//
// This file contains environment-specific configuration values.
// For production, use --dart-define to override values at build time:
//
// Example:
// flutter run --dart-define=ONESIGNAL_APP_ID=your-app-id
// flutter build apk --dart-define=ONESIGNAL_APP_ID=your-app-id
//
// For development, you can also set environment variables:
// - MAPBOX_ACCESS_TOKEN (system environment variable)
// - ONESIGNAL_APP_ID (system environment variable)

class AppConfig {
  AppConfig._();

  /// OneSignal App ID for push notifications
  ///
  /// Get this from OneSignal Dashboard: Settings > Keys & IDs
  /// Set via --dart-define=ONESIGNAL_APP_ID=your-app-id
  /// Or set ONESIGNAL_APP_ID environment variable
  static String get oneSignalAppId {
    // Try dart-define first (for builds)
    const dartDefine = String.fromEnvironment('ONESIGNAL_APP_ID', defaultValue: '');
    if (dartDefine.isNotEmpty) return dartDefine;
    
    // Fallback to environment variable (for development)
    final envVar = Platform.environment['ONESIGNAL_APP_ID'] ?? '';
    return envVar;
  }

  /// Check if OneSignal is configured
  static bool get isOneSignalConfigured => oneSignalAppId.isNotEmpty;

  /// Mapbox Access Token for maps and geocoding
  ///
  /// Get this from Mapbox Dashboard: Account > Access Tokens
  /// Set via --dart-define=MAPBOX_ACCESS_TOKEN=your-access-token
  /// Or set MAPBOX_ACCESS_TOKEN environment variable
  /// 
  /// NOTE: Mobile apps require a secret token (sk.*) with tiles:read scope.
  /// This is normal - Mapbox makes tokens secret when tiles:read is added.
  /// Secret tokens are safe for mobile apps when embedded in the app binary.
  /// 
  /// For development, a default token is provided in debug mode only.
  static String get mapboxAccessToken {
    // Try dart-define first (for builds)
    const dartDefine = String.fromEnvironment('MAPBOX_ACCESS_TOKEN', defaultValue: '');
    if (dartDefine.isNotEmpty) return dartDefine;
    
    // Fallback to environment variable (for development)
    final envVar = Platform.environment['MAPBOX_ACCESS_TOKEN'] ?? '';
    if (envVar.isNotEmpty) return envVar;
    
    // No fallback token - must be provided via --dart-define or environment
    // For development setup, see docs/security/TOKEN_ROTATION_GUIDE.md
    //
    // SECURITY: Never hardcode tokens in source code.
    // The exposed token sk.eyJ1...NXkifQ has been revoked and must be rotated.
    return '';
  }

  /// Check if Mapbox is configured
  static bool get isMapboxConfigured => mapboxAccessToken.isNotEmpty;

  /// Supabase Functions URL for Edge Functions
  /// Used for geocoding, map data, and other backend services
  static const String supabaseFunctionsUrl =
    'https://dskpfnjbgocieoqyiznf.supabase.co/functions/v1';

  /// Debug mode (enable verbose logging)
  static const bool debugMode = bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: false,
  );

  /// App version
  static const String appVersion = '2.0.0';

  /// App name
  static const String appName = 'Direct Cuts';

  /// Deep link scheme
  static const String deepLinkScheme = 'directcuts';

  /// Support email
  static const String supportEmail = 'support@directcuts.app';
}
