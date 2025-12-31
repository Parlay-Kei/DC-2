/// Test helper utilities for Direct Cuts application
///
/// This file provides common test utilities, widget wrappers,
/// and helper functions used across all test files.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../lib/config/theme.dart';

// ============================================================================
// Widget Test Wrappers
// ============================================================================

/// Wraps a widget with MaterialApp for testing
Widget createTestableWidget(
  Widget child, {
  List<Override> overrides = const [],
  List<NavigatorObserver> observers = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: DCTheme.darkTheme,
      home: child,
      navigatorObservers: observers,
    ),
  );
}

/// Wraps a widget with MaterialApp and GoRouter for navigation testing
Widget createNavigableWidget(
  Widget child, {
  List<Override> overrides = const [],
  String initialLocation = '/',
  List<RouteBase> routes = const [],
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => child,
      ),
      ...routes,
    ],
  );

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      theme: DCTheme.darkTheme,
      routerConfig: router,
    ),
  );
}

/// Creates a scaffold wrapper for widgets that require it
Widget wrapWithScaffold(Widget child) {
  return Scaffold(body: child);
}

// ============================================================================
// Finder Extensions
// ============================================================================

/// Extension methods for common widget finding patterns
extension FinderExtensions on CommonFinders {
  /// Finds a widget by its semantic label
  Finder bySemanticsLabel(String label) {
    return find.bySemanticsLabel(label);
  }

  /// Finds an ElevatedButton with specific text
  Finder elevatedButtonWithText(String text) {
    return find.widgetWithText(ElevatedButton, text);
  }

  /// Finds a TextButton with specific text
  Finder textButtonWithText(String text) {
    return find.widgetWithText(TextButton, text);
  }

  /// Finds a TextField with specific hint text
  Finder textFieldWithHint(String hint) {
    return find.widgetWithText(TextField, hint);
  }

  /// Finds a widget by Key string
  Finder byKeyString(String key) {
    return find.byKey(Key(key));
  }
}

// ============================================================================
// Gesture Helpers
// ============================================================================

/// Simulates a pull-to-refresh gesture
Future<void> pullToRefresh(WidgetTester tester, Finder scrollable) async {
  await tester.drag(scrollable, const Offset(0, 300));
  await tester.pumpAndSettle();
}

/// Simulates a swipe left gesture
Future<void> swipeLeft(WidgetTester tester, Finder target) async {
  await tester.drag(target, const Offset(-300, 0));
  await tester.pumpAndSettle();
}

/// Simulates a swipe right gesture
Future<void> swipeRight(WidgetTester tester, Finder target) async {
  await tester.drag(target, const Offset(300, 0));
  await tester.pumpAndSettle();
}

// ============================================================================
// Form Helpers
// ============================================================================

/// Fills a text field identified by key
Future<void> fillTextField(
  WidgetTester tester,
  String key,
  String text,
) async {
  final field = find.byKey(Key(key));
  await tester.tap(field);
  await tester.enterText(field, text);
  await tester.pump();
}

/// Fills a text field identified by label
Future<void> fillTextFieldByLabel(
  WidgetTester tester,
  String label,
  String text,
) async {
  final field = find.widgetWithText(TextField, label);
  await tester.tap(field);
  await tester.enterText(field, text);
  await tester.pump();
}

/// Submits a form by pressing the done/submit button
Future<void> submitForm(WidgetTester tester, Finder button) async {
  await tester.tap(button);
  await tester.pumpAndSettle();
}

// ============================================================================
// Wait Helpers
// ============================================================================

/// Waits for a specific widget to appear
Future<void> waitForWidget(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final endTime = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(endTime)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (tester.any(finder)) {
      return;
    }
  }
  throw TimeoutException('Widget not found within timeout: $finder');
}

/// Waits for a widget to disappear
Future<void> waitForWidgetToDisappear(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final endTime = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(endTime)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (!tester.any(finder)) {
      return;
    }
  }
  throw TimeoutException('Widget did not disappear within timeout: $finder');
}

/// Waits for async operations with pump cycles
Future<void> waitForAsyncOperations(
  WidgetTester tester, {
  int cycles = 10,
  Duration interval = const Duration(milliseconds: 100),
}) async {
  for (var i = 0; i < cycles; i++) {
    await tester.pump(interval);
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}

// ============================================================================
// Assertion Helpers
// ============================================================================

/// Verifies that a snackbar with specific text is shown
void expectSnackbar(String text) {
  expect(find.text(text), findsOneWidget);
}

/// Verifies that a loading indicator is shown
void expectLoading() {
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
}

/// Verifies that no loading indicator is shown
void expectNoLoading() {
  expect(find.byType(CircularProgressIndicator), findsNothing);
}

/// Verifies that an error message is displayed
void expectErrorMessage(String message) {
  expect(find.text(message), findsOneWidget);
}

// ============================================================================
// Screen Size Helpers
// ============================================================================

/// Sets the screen size for testing different device sizes
Future<void> setScreenSize(
  WidgetTester tester,
  Size size,
) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
}

/// Common device sizes for testing
class DeviceSizes {
  static const iPhoneSE = Size(375, 667);
  static const iPhone14 = Size(390, 844);
  static const iPhone14ProMax = Size(430, 932);
  static const iPadMini = Size(744, 1133);
  static const iPadPro = Size(1024, 1366);
  static const androidSmall = Size(360, 640);
  static const androidMedium = Size(412, 915);
  static const androidLarge = Size(412, 915);
  static const pixel7 = Size(412, 915);
  static const samsungS23 = Size(360, 780);
}

// ============================================================================
// Golden Test Helpers
// ============================================================================

/// Captures a golden image of a widget
Future<void> captureGolden(
  WidgetTester tester,
  Widget widget,
  String name, {
  Size size = const Size(400, 800),
}) async {
  await setScreenSize(tester, size);
  await tester.pumpWidget(createTestableWidget(widget));
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );
}

// ============================================================================
// Mock Data Generators
// ============================================================================

/// Generates a unique test ID
String generateTestId([String prefix = 'test']) {
  return '$prefix-${DateTime.now().millisecondsSinceEpoch}';
}

/// Generates a test email
String generateTestEmail([String prefix = 'test']) {
  return '$prefix${DateTime.now().millisecondsSinceEpoch}@example.com';
}

/// Generates a test phone number
String generateTestPhone() {
  final random = DateTime.now().millisecondsSinceEpoch % 10000000;
  return '+1555${random.toString().padLeft(7, '0')}';
}
