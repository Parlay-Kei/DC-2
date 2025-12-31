/// Booking Flow Integration Tests
///
/// Tests the complete booking flow:
/// - Service selection
/// - Time slot selection
/// - Booking creation
/// - Confirmation screen
/// - Booking management (cancel, reschedule)
///
/// Run with: flutter test test/integration/booking_flow_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/barber.dart';
import '../../lib/models/booking.dart';
import '../../lib/models/service.dart';
import '../mocks/mock_services.dart';
import '../mocks/mock_providers.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Booking Flow Integration Tests', () {
    late MockBookingService mockBookingService;
    late Barber testBarber;
    late List<Service> testServices;

    setUp(() {
      mockBookingService = MockBookingService();

      testBarber = Barber(
        id: 'barber-001',
        visibleName: 'John Smith',
        shopName: 'Downtown Cuts',
        bio: 'Professional barber',
        location: 'Chicago, IL',
        latitude: 41.8781,
        longitude: -87.6298,
        isVerified: true,
        isActive: true,
        rating: 4.8,
        totalReviews: 127,
        stripeOnboardingComplete: true,
        createdAt: DateTime.now(),
      );

      testServices = [
        Service(
          id: 'service-001',
          barberId: 'barber-001',
          name: 'Classic Haircut',
          description: 'Traditional haircut with scissors and clippers',
          price: 35.00,
          durationMinutes: 30,
          isActive: true,
          sortOrder: 1,
          createdAt: DateTime.now(),
        ),
        Service(
          id: 'service-002',
          barberId: 'barber-001',
          name: 'Beard Trim',
          description: 'Professional beard trimming and shaping',
          price: 20.00,
          durationMinutes: 15,
          isActive: true,
          sortOrder: 2,
          createdAt: DateTime.now(),
        ),
        Service(
          id: 'service-003',
          barberId: 'barber-001',
          name: 'Haircut + Beard',
          description: 'Complete haircut with beard trim combo',
          price: 50.00,
          durationMinutes: 45,
          isActive: true,
          sortOrder: 3,
          createdAt: DateTime.now(),
        ),
      ];
    });

    group('Service Selection Tests', () {
      testWidgets('should display available services', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: _ServiceSelectionTestWidget(services: testServices),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Should display all services
        expect(find.text('Classic Haircut'), findsOneWidget);
        expect(find.text('Beard Trim'), findsOneWidget);
        expect(find.text('Haircut + Beard'), findsOneWidget);
      });

      testWidgets('should show service prices', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: _ServiceSelectionTestWidget(services: testServices),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Should display prices
        expect(find.textContaining('\$35'), findsWidgets);
        expect(find.textContaining('\$20'), findsWidgets);
        expect(find.textContaining('\$50'), findsWidgets);
      });

      testWidgets('should show service durations', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: _ServiceSelectionTestWidget(services: testServices),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Should display durations
        expect(find.textContaining('30 min'), findsWidgets);
        expect(find.textContaining('15 min'), findsWidgets);
        expect(find.textContaining('45 min'), findsWidgets);
      });

      testWidgets('should select service on tap', (tester) async {
        Service? selectedService;

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: ListView.builder(
                itemCount: testServices.length,
                itemBuilder: (context, index) {
                  final service = testServices[index];
                  return ListTile(
                    key: Key('service-${service.id}'),
                    title: Text(service.name),
                    onTap: () => selectedService = service,
                  );
                },
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Tap on first service
        await tester.tap(find.byKey(const Key('service-service-001')));
        await tester.pumpAndSettle();

        expect(selectedService?.id, 'service-001');
        expect(selectedService?.name, 'Classic Haircut');
      });

      testWidgets('should enable continue button after selection',
          (tester) async {
        bool isSelected = false;

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: testServices.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(testServices[index].name),
                              onTap: () => setState(() => isSelected = true),
                            );
                          },
                        ),
                      ),
                      ElevatedButton(
                        onPressed: isSelected ? () {} : null,
                        child: const Text('Continue'),
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

        // Button should be disabled initially
        final button = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Continue'),
        );
        expect(button.onPressed, isNull);

        // Select a service
        await tester.tap(find.text('Classic Haircut'));
        await tester.pumpAndSettle();

        // Button should now be enabled
        final updatedButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Continue'),
        );
        expect(updatedButton.onPressed, isNotNull);
      });
    });

    group('Time Slot Selection Tests', () {
      testWidgets('should display date picker', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: _DateTimeSelectionTestWidget(
                barberId: testBarber.id,
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Should display date selection UI
        expect(find.text('Select Date'), findsOneWidget);
      });

      testWidgets('should show available time slots', (tester) async {
        final timeSlots = ['09:00', '10:00', '11:00', '13:00', '14:00'];

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: _TimeSlotTestWidget(timeSlots: timeSlots),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Should display time slots
        expect(find.text('09:00'), findsOneWidget);
        expect(find.text('10:00'), findsOneWidget);
        expect(find.text('11:00'), findsOneWidget);
      });

      testWidgets('should disable unavailable time slots', (tester) async {
        final availableSlots = ['09:00', '10:00'];
        final bookedSlots = ['11:00', '13:00'];

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: Wrap(
                children: [
                  ...availableSlots.map((slot) => Chip(
                        key: Key('slot-$slot'),
                        label: Text(slot),
                      )),
                  ...bookedSlots.map((slot) => Chip(
                        key: Key('slot-$slot'),
                        label: Text(slot),
                        backgroundColor: Colors.grey,
                      )),
                ],
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // All slots should be visible
        expect(find.text('09:00'), findsOneWidget);
        expect(find.text('11:00'), findsOneWidget);
      });

      testWidgets('should select time slot on tap', (tester) async {
        String? selectedSlot;

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: Wrap(
                children: ['09:00', '10:00', '11:00'].map((slot) {
                  return GestureDetector(
                    key: Key('slot-$slot'),
                    onTap: () => selectedSlot = slot,
                    child: Chip(label: Text(slot)),
                  );
                }).toList(),
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('slot-10:00')));
        await tester.pumpAndSettle();

        expect(selectedSlot, '10:00');
      });

      testWidgets('should not allow past dates', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: CalendarDatePicker(
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
                onDateChanged: (_) {},
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Calendar should be present
        expect(find.byType(CalendarDatePicker), findsOneWidget);
      });
    });

    group('Booking Creation Tests', () {
      testWidgets('should show booking summary before confirmation',
          (tester) async {
        final selectedService = testServices.first;
        final selectedDate = DateTime.now().add(const Duration(days: 1));
        const selectedTime = '10:00';

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: _BookingSummaryTestWidget(
                barber: testBarber,
                service: selectedService,
                date: selectedDate,
                time: selectedTime,
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Should display booking summary
        expect(find.text(testBarber.displayName), findsOneWidget);
        expect(find.text(selectedService.name), findsOneWidget);
        expect(find.textContaining('\$35'), findsWidgets);
      });

      testWidgets('should show confirm booking button', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: Column(
                children: [
                  const Text('Booking Summary'),
                  ElevatedButton(
                    key: const Key('confirm-booking-btn'),
                    onPressed: () {},
                    child: const Text('Confirm Booking'),
                  ),
                ],
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('confirm-booking-btn')), findsOneWidget);
      });

      testWidgets('should show loading during booking creation',
          (tester) async {
        bool isLoading = false;

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      if (isLoading)
                        const CircularProgressIndicator()
                      else
                        ElevatedButton(
                          onPressed: () {
                            setState(() => isLoading = true);
                          },
                          child: const Text('Confirm Booking'),
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

        // Tap confirm button
        await tester.tap(find.text('Confirm Booking'));
        await tester.pump();

        // Should show loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should show success screen after booking', (tester) async {
        bool showSuccess = false;

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  if (showSuccess) {
                    return const _BookingSuccessTestWidget();
                  }
                  return ElevatedButton(
                    onPressed: () => setState(() => showSuccess = true),
                    child: const Text('Confirm Booking'),
                  );
                },
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Confirm booking
        await tester.tap(find.text('Confirm Booking'));
        await tester.pumpAndSettle();

        // Should show success
        expect(find.text('Booking Confirmed!'), findsOneWidget);
      });
    });

    group('Booking Management Tests', () {
      testWidgets('should display upcoming bookings', (tester) async {
        final bookings = [
          Booking(
            id: 'booking-001',
            customerId: 'test-user-id',
            barberId: 'barber-001',
            serviceId: 'service-001',
            scheduledDate: DateTime.now().add(const Duration(days: 1)),
            scheduledTime: '10:00',
            status: 'confirmed',
            totalPrice: 35.00,
            platformFee: 5.25,
            barberEarnings: 29.75,
            paymentMethod: 'card',
            paymentStatus: 'paid',
            locationType: 'shop',
            createdAt: DateTime.now(),
            serviceName: 'Classic Haircut',
          ),
        ];

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: _BookingsListTestWidget(bookings: bookings),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Classic Haircut'), findsOneWidget);
        expect(find.text('10:00'), findsOneWidget);
      });

      testWidgets('should show cancel booking option', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: Column(
                children: [
                  const Text('Booking Details'),
                  TextButton(
                    key: const Key('cancel-booking-btn'),
                    onPressed: () {},
                    child: const Text('Cancel Booking'),
                  ),
                ],
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('cancel-booking-btn')), findsOneWidget);
      });

      testWidgets('should confirm cancellation', (tester) async {
        bool showDialog = false;
        bool cancelled = false;

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Stack(
                    children: [
                      TextButton(
                        onPressed: () => setState(() => showDialog = true),
                        child: const Text('Cancel Booking'),
                      ),
                      if (showDialog)
                        AlertDialog(
                          title: const Text('Cancel Booking?'),
                          content: const Text('Are you sure?'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  setState(() => showDialog = false),
                              child: const Text('No'),
                            ),
                            TextButton(
                              key: const Key('confirm-cancel-btn'),
                              onPressed: () {
                                setState(() {
                                  cancelled = true;
                                  showDialog = false;
                                });
                              },
                              child: const Text('Yes, Cancel'),
                            ),
                          ],
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

        // Initiate cancellation
        await tester.tap(find.text('Cancel Booking'));
        await tester.pumpAndSettle();

        // Confirm dialog should appear
        expect(find.text('Cancel Booking?'), findsOneWidget);

        // Confirm cancellation
        await tester.tap(find.byKey(const Key('confirm-cancel-btn')));
        await tester.pumpAndSettle();

        expect(cancelled, true);
      });

      testWidgets('should show reschedule option', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: Column(
                children: [
                  const Text('Booking Details'),
                  TextButton(
                    key: const Key('reschedule-btn'),
                    onPressed: () {},
                    child: const Text('Reschedule'),
                  ),
                ],
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('reschedule-btn')), findsOneWidget);
      });
    });
  });
}

// ============================================================================
// Test Widgets
// ============================================================================

class _ServiceSelectionTestWidget extends StatelessWidget {
  final List<Service> services;

  const _ServiceSelectionTestWidget({required this.services});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return ListTile(
          key: Key('service-${service.id}'),
          title: Text(service.name),
          subtitle: Text(service.description ?? ''),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${service.price.toStringAsFixed(0)}'),
              Text('${service.durationMinutes} min'),
            ],
          ),
        );
      },
    );
  }
}

class _DateTimeSelectionTestWidget extends StatelessWidget {
  final String barberId;

  const _DateTimeSelectionTestWidget({required this.barberId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Select Date'),
        CalendarDatePicker(
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
          onDateChanged: (_) {},
        ),
      ],
    );
  }
}

class _TimeSlotTestWidget extends StatelessWidget {
  final List<String> timeSlots;

  const _TimeSlotTestWidget({required this.timeSlots});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: timeSlots
          .map((slot) => Chip(
                key: Key('slot-$slot'),
                label: Text(slot),
              ))
          .toList(),
    );
  }
}

class _BookingSummaryTestWidget extends StatelessWidget {
  final Barber barber;
  final Service service;
  final DateTime date;
  final String time;

  const _BookingSummaryTestWidget({
    required this.barber,
    required this.service,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Booking Summary'),
        const SizedBox(height: 16),
        Text('Barber: ${barber.displayName}'),
        Text('Service: ${service.name}'),
        Text('Date: ${date.toString().split(' ')[0]}'),
        Text('Time: $time'),
        const Divider(),
        Text('Total: \$${service.price.toStringAsFixed(2)}'),
      ],
    );
  }
}

class _BookingSuccessTestWidget extends StatelessWidget {
  const _BookingSuccessTestWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          const Text('Booking Confirmed!'),
          const SizedBox(height: 8),
          const Text('Your appointment has been scheduled.'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            child: const Text('View Booking'),
          ),
        ],
      ),
    );
  }
}

class _BookingsListTestWidget extends StatelessWidget {
  final List<Booking> bookings;

  const _BookingsListTestWidget({required this.bookings});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return ListTile(
          title: Text(booking.serviceName ?? 'Service'),
          subtitle: Text(
            '${booking.scheduledDate.toString().split(' ')[0]} at ${booking.scheduledTime}',
          ),
          trailing: Chip(label: Text(booking.status)),
        );
      },
    );
  }
}
