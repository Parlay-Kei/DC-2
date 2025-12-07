import 'package:flutter/material.dart';

class DCTheme {
  // Direct Cuts Brand Colors (from DC-1)
  static const Color primary = Color(0xFFE63946); // Brand Red
  static const Color primaryLight = Color(0xFFFF6B6B); // Light red
  static const Color primaryDark = Color(0xFFC62828); // Dark red

  static const Color secondary = Color(0xFFB20000); // Deep red (logo accent)

  // Background hierarchy (from DC-1)
  static const Color background = Color(0xFF121212); // surface-base
  static const Color surface = Color(0xFF1A1A1A); // surface-primary
  static const Color surfaceSecondary = Color(0xFF2D2D2D); // surface-secondary
  static const Color surfaceElevated = Color(0xFF3D3D3D); // surface-elevated
  static const Color surfaceOverlay = Color(0xFF4D4D4D); // surface-overlay

  static const Color text = Color(0xFFFFFFFF); // Primary text
  static const Color textMuted = Color(0xFF9CA3AF); // Secondary text (gray-400)
  static const Color textDark = Color(0xFF6B7280); // Tertiary text (gray-500)

  static const Color success = Color(0xFF22C55E); // Green
  static const Color error = Color(0xFFEF4444); // Red
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color info = Color(0xFF3B82F6); // Blue

  static const Color gold = Color(0xFFFFD700); // Gold accent
  static const Color silver = Color(0xFFC0C0C0); // Silver accent

  static const Color border = Color(0xFF374151); // gray-700
  static const Color divider = Color(0xFF1F2937); // gray-800

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // Border Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 9999.0;

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: primary,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          surface: surface,
          error: error,
          onPrimary: text,
          onSecondary: text,
          onSurface: text,
          onError: text,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: text,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: text,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: text,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            side: const BorderSide(color: primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: error, width: 2),
          ),
          hintStyle: TextStyle(color: textMuted.withOpacity(0.5)),
          labelStyle: const TextStyle(color: textMuted),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: primary,
          unselectedItemColor: textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(
          color: border,
          thickness: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: surface,
          contentTextStyle: const TextStyle(color: text),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: text, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: text, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: text, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(color: text, fontWeight: FontWeight.w600),
          headlineMedium: TextStyle(color: text, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(color: text, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: text, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: text, fontWeight: FontWeight.w500),
          titleSmall: TextStyle(color: text, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: text),
          bodyMedium: TextStyle(color: text),
          bodySmall: TextStyle(color: textMuted),
          labelLarge: TextStyle(color: text, fontWeight: FontWeight.w600),
          labelMedium: TextStyle(color: textMuted),
          labelSmall: TextStyle(color: textMuted),
        ),
      );
}
