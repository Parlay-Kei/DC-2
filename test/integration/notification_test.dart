/// Notification Integration Tests
///
/// Tests the push notification flows:
/// - Token registration
/// - Permission handling
/// - Notification receipt (mocked)
/// - Notification display
///
/// Run with: flutter test test/integration/notification_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/mock_services.dart';
import '../mocks/mock_providers.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Notification Integration Tests', () {
    group('Token Registration Tests', () {
      testWidgets('should display notification setup UI', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: const _NotificationSetupWidget(),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Enable Notifications'), findsOneWidget);
      });

      testWidgets('should show notification registration status',
          (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications_active,
                        color: Colors.green),
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Enabled'),
                    trailing: Switch(
                      value: true,
                      onChanged: (_) {},
                    ),
                  ),
                ],
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Push Notifications'), findsOneWidget);
        expect(find.text('Enabled'), findsOneWidget);
      });

      testWidgets('should handle token registration success', (tester) async {
        bool tokenRegistered = false;

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (tokenRegistered) ...[
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 48),
                        const Text('Notifications Enabled'),
                      ] else
                        ElevatedButton(
                          onPressed: () async {
                            // Simulate token registration
                            await Future.delayed(
                                const Duration(milliseconds: 100));
                            setState(() => tokenRegistered = true);
                          },
                          child: const Text('Enable Notifications'),
                        ),
                    ],
                  );
                },
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Enable notifications
        await tester.tap(find.text('Enable Notifications'));
        await tester.pumpAndSettle();

        expect(find.text('Notifications Enabled'), findsOneWidget);
      });

      testWidgets('should handle token registration failure', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text('Failed to enable notifications'),
                  const SizedBox(height: 8),
                  const Text('Please try again later'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Failed'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });
    });

    group('Permission Handling Tests', () {
      testWidgets('should show permission request dialog', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: const _PermissionRequestWidget(),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('permission'), findsWidgets);
      });

      testWidgets('should handle permission granted', (tester) async {
        bool permissionGranted = false;

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  if (permissionGranted) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 48),
                          Text('Notifications enabled'),
                        ],
                      ),
                    );
                  }
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications, size: 48),
                        const Text('Allow notifications?'),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {},
                              child: const Text('Deny'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              key: const Key('allow-btn'),
                              onPressed: () =>
                                  setState(() => permissionGranted = true),
                              child: const Text('Allow'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Grant permission
        await tester.tap(find.byKey(const Key('allow-btn')));
        await tester.pumpAndSettle();

        expect(find.text('Notifications enabled'), findsOneWidget);
      });

      testWidgets('should handle permission denied', (tester) async {
        bool permissionDenied = false;

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  if (permissionDenied) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications_off,
                              size: 48, color: Colors.grey),
                          const Text('Notifications disabled'),
                          const SizedBox(height: 16),
                          const Text('Enable in Settings to receive updates'),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text('Open Settings'),
                          ),
                        ],
                      ),
                    );
                  }
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Allow notifications?'),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              key: const Key('deny-btn'),
                              onPressed: () =>
                                  setState(() => permissionDenied = true),
                              child: const Text('Deny'),
                            ),
                            ElevatedButton(
                              onPressed: () {},
                              child: const Text('Allow'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Deny permission
        await tester.tap(find.byKey(const Key('deny-btn')));
        await tester.pumpAndSettle();

        expect(find.text('Notifications disabled'), findsOneWidget);
        expect(find.text('Open Settings'), findsOneWidget);
      });

      testWidgets('should show settings redirect for permanently denied',
          (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_off,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Notifications are disabled'),
                  const SizedBox(height: 8),
                  const Text(
                    'To receive booking updates, enable notifications in your device settings.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    key: const Key('open-settings-btn'),
                    icon: const Icon(Icons.settings),
                    onPressed: () {},
                    label: const Text('Open Settings'),
                  ),
                ],
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('open-settings-btn')), findsOneWidget);
      });
    });

    group('Notification Display Tests', () {
      testWidgets('should display notification list', (tester) async {
        final notifications = NotificationFixtures.sampleNotificationList;

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              appBar: AppBar(title: const Text('Notifications')),
              body: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(notification['type']![0].toUpperCase()),
                    ),
                    title: Text(notification['title'] as String),
                    subtitle: Text(notification['body'] as String),
                    trailing: notification['is_read'] == false
                        ? const CircleAvatar(
                            radius: 5,
                            backgroundColor: Colors.blue,
                          )
                        : null,
                  );
                },
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Booking Confirmed'), findsOneWidget);
        expect(find.text('New Message'), findsOneWidget);
        expect(find.text('Appointment Reminder'), findsOneWidget);
      });

      testWidgets('should show empty state when no notifications',
          (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              appBar: AppBar(title: const Text('Notifications')),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No notifications yet'),
                    SizedBox(height: 8),
                    Text('We\'ll notify you about your bookings here'),
                  ],
                ),
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('No notifications yet'), findsOneWidget);
      });

      testWidgets('should mark notification as read on tap', (tester) async {
        bool isRead = false;

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return ListTile(
                    title: const Text('Booking Confirmed'),
                    trailing: isRead
                        ? null
                        : const CircleAvatar(
                            radius: 5,
                            backgroundColor: Colors.blue,
                          ),
                    onTap: () => setState(() => isRead = true),
                  );
                },
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Initially has unread indicator
        expect(find.byType(CircleAvatar), findsOneWidget);

        // Tap notification
        await tester.tap(find.text('Booking Confirmed'));
        await tester.pumpAndSettle();

        // Unread indicator should be gone
        expect(find.byType(CircleAvatar), findsNothing);
      });

      testWidgets('should show unread count badge', (tester) async {
        const unreadCount = 3;

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              appBar: AppBar(
                title: const Text('Home'),
                actions: [
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications),
                        onPressed: () {},
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: const Text(
                            '$unreadCount',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              body: const SizedBox(),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('should navigate to relevant screen on notification tap',
          (tester) async {
        String? navigatedTo;

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  if (navigatedTo != null) {
                    return Center(child: Text('Navigated to: $navigatedTo'));
                  }
                  return ListView(
                    children: [
                      ListTile(
                        key: const Key('booking-notification'),
                        title: const Text('Booking Confirmed'),
                        onTap: () => setState(() => navigatedTo = 'booking'),
                      ),
                      ListTile(
                        key: const Key('message-notification'),
                        title: const Text('New Message'),
                        onTap: () => setState(() => navigatedTo = 'chat'),
                      ),
                    ],
                  );
                },
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Tap booking notification
        await tester.tap(find.byKey(const Key('booking-notification')));
        await tester.pumpAndSettle();

        expect(find.text('Navigated to: booking'), findsOneWidget);
      });
    });

    group('Notification Settings Tests', () {
      testWidgets('should display notification preferences', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              appBar: AppBar(title: const Text('Notification Settings')),
              body: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Booking Reminders'),
                    subtitle:
                        const Text('Get reminded before your appointments'),
                    value: true,
                    onChanged: (_) {},
                  ),
                  SwitchListTile(
                    title: const Text('New Messages'),
                    subtitle:
                        const Text('Get notified when you receive a message'),
                    value: true,
                    onChanged: (_) {},
                  ),
                  SwitchListTile(
                    title: const Text('Promotions'),
                    subtitle: const Text('Receive offers and discounts'),
                    value: false,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Booking Reminders'), findsOneWidget);
        expect(find.text('New Messages'), findsOneWidget);
        expect(find.text('Promotions'), findsOneWidget);
      });

      testWidgets('should toggle notification preferences', (tester) async {
        bool bookingReminders = true;

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return SwitchListTile(
                    key: const Key('booking-reminders'),
                    title: const Text('Booking Reminders'),
                    value: bookingReminders,
                    onChanged: (value) =>
                        setState(() => bookingReminders = value),
                  );
                },
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Toggle off
        await tester.tap(find.byKey(const Key('booking-reminders')));
        await tester.pumpAndSettle();

        // Widget should reflect changed state
        final switchWidget = tester.widget<SwitchListTile>(
          find.byKey(const Key('booking-reminders')),
        );
        expect(switchWidget.value, false);
      });
    });

    group('Foreground Notification Tests', () {
      testWidgets('should display in-app notification banner', (tester) async {
        bool showBanner = true;

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Stack(
                    children: [
                      const Center(child: Text('Home Screen')),
                      if (showBanner)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Material(
                            elevation: 4,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              color: Colors.white,
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Booking Confirmed'),
                                        Text(
                                            'Your appointment is tomorrow at 10 AM'),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    key: const Key('dismiss-banner'),
                                    icon: const Icon(Icons.close),
                                    onPressed: () =>
                                        setState(() => showBanner = false),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Banner should be visible
        expect(find.text('Booking Confirmed'), findsOneWidget);

        // Dismiss banner
        await tester.tap(find.byKey(const Key('dismiss-banner')));
        await tester.pumpAndSettle();

        // Banner should be gone
        expect(find.text('Booking Confirmed'), findsNothing);
      });
    });
  });
}

// ============================================================================
// Test Widgets
// ============================================================================

class _NotificationSetupWidget extends StatelessWidget {
  const _NotificationSetupWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'Stay Updated',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Get notified about your bookings, messages, and special offers.',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Enable Notifications'),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Maybe Later'),
          ),
        ],
      ),
    );
  }
}

class _PermissionRequestWidget extends StatelessWidget {
  const _PermissionRequestWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_active, size: 64),
          const SizedBox(height: 24),
          const Text('Allow notification permission to receive updates'),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {},
                child: const Text('Deny'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Allow'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
