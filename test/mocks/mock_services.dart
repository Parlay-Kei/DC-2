/// Mock services for testing Direct Cuts application
///
/// This file provides mock implementations of all external services
/// used throughout the app for isolated, reliable testing.

import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================================
// Supabase Mocks
// ============================================================================

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder {}

class MockPostgrestResponse extends Mock implements PostgrestResponse {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockSession extends Mock implements Session {}

class MockUser extends Mock implements User {}

// ============================================================================
// Auth Mock Helpers
// ============================================================================

/// Creates a mock user for testing
User createMockUser({
  String id = 'test-user-id',
  String email = 'test@example.com',
  String? fullName = 'Test User',
  String role = 'customer',
}) {
  final user = MockUser();
  when(() => user.id).thenReturn(id);
  when(() => user.email).thenReturn(email);
  when(() => user.createdAt).thenReturn(DateTime.now().toIso8601String());
  when(() => user.userMetadata).thenReturn({
    'full_name': fullName,
    'role': role,
  });
  return user;
}

/// Creates a mock session for testing
Session createMockSession({
  String accessToken = 'mock-access-token',
  String refreshToken = 'mock-refresh-token',
  User? user,
}) {
  final session = MockSession();
  when(() => session.accessToken).thenReturn(accessToken);
  when(() => session.refreshToken).thenReturn(refreshToken);
  when(() => session.user).thenReturn(user ?? createMockUser());
  return session;
}

/// Creates a mock auth response for testing
AuthResponse createMockAuthResponse({
  Session? session,
  User? user,
}) {
  final response = MockAuthResponse();
  when(() => response.session).thenReturn(session ?? createMockSession());
  when(() => response.user).thenReturn(user ?? createMockUser());
  return response;
}

// ============================================================================
// Fake Classes for Fallback Registration
// ============================================================================

class FakeUri extends Fake implements Uri {}

class FakeStackTrace extends Fake implements StackTrace {}

// ============================================================================
// Test Fixtures
// ============================================================================

/// Standard test data for barbers
class BarberFixtures {
  static Map<String, dynamic> get sampleBarber => {
        'id': 'barber-001',
        'shop_name': 'Downtown Cuts',
        'bio': 'Professional barber with 10 years experience',
        'location': 'Chicago, IL',
        'latitude': 41.8781,
        'longitude': -87.6298,
        'service_radius_miles': 15,
        'is_mobile': true,
        'offers_home_service': true,
        'travel_fee_per_mile': 2.0,
        'is_verified': true,
        'is_active': true,
        'rating': 4.8,
        'total_reviews': 127,
        'stripe_account_id': 'acct_test123',
        'stripe_onboarding_complete': true,
        'onboarding_complete': true,
        'subscription_tier': 'pro',
        'created_at': DateTime.now().toIso8601String(),
      };

  static List<Map<String, dynamic>> get sampleBarberList => [
        sampleBarber,
        {
          ...sampleBarber,
          'id': 'barber-002',
          'shop_name': 'Urban Style Barbers',
          'latitude': 41.8819,
          'longitude': -87.6278,
          'rating': 4.5,
          'total_reviews': 89,
        },
        {
          ...sampleBarber,
          'id': 'barber-003',
          'shop_name': 'Classic Cuts',
          'latitude': 41.8765,
          'longitude': -87.6320,
          'rating': 4.9,
          'total_reviews': 203,
        },
      ];
}

/// Standard test data for services
class ServiceFixtures {
  static Map<String, dynamic> get sampleService => {
        'id': 'service-001',
        'barber_id': 'barber-001',
        'name': 'Classic Haircut',
        'description': 'Traditional haircut with scissors and clippers',
        'price': 35.00,
        'duration_minutes': 30,
        'is_active': true,
        'sort_order': 1,
        'created_at': DateTime.now().toIso8601String(),
      };

  static List<Map<String, dynamic>> get sampleServiceList => [
        sampleService,
        {
          ...sampleService,
          'id': 'service-002',
          'name': 'Beard Trim',
          'price': 20.00,
          'duration_minutes': 15,
          'sort_order': 2,
        },
        {
          ...sampleService,
          'id': 'service-003',
          'name': 'Haircut + Beard',
          'price': 50.00,
          'duration_minutes': 45,
          'sort_order': 3,
        },
      ];
}

/// Standard test data for bookings
class BookingFixtures {
  static Map<String, dynamic> get sampleBooking => {
        'id': 'booking-001',
        'customer_id': 'test-user-id',
        'barber_id': 'barber-001',
        'service_id': 'service-001',
        'scheduled_date': DateTime.now()
            .add(const Duration(days: 1))
            .toIso8601String()
            .split('T')[0],
        'scheduled_time': '10:00',
        'status': 'pending',
        'total_price': 35.00,
        'platform_fee': 5.25,
        'barber_earnings': 29.75,
        'payment_method': 'card',
        'payment_status': 'pending',
        'location_type': 'shop',
        'address': null,
        'latitude': null,
        'longitude': null,
        'notes': null,
        'created_at': DateTime.now().toIso8601String(),
      };

  static Map<String, dynamic> get confirmedBooking => {
        ...sampleBooking,
        'id': 'booking-002',
        'status': 'confirmed',
        'payment_status': 'paid',
      };

  static Map<String, dynamic> get completedBooking => {
        ...sampleBooking,
        'id': 'booking-003',
        'status': 'completed',
        'payment_status': 'paid',
        'scheduled_date': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String()
            .split('T')[0],
      };
}

/// Standard test data for notifications
class NotificationFixtures {
  static Map<String, dynamic> get sampleNotification => {
        'id': 'notification-001',
        'user_id': 'test-user-id',
        'type': 'booking_confirmed',
        'title': 'Booking Confirmed',
        'body': 'Your appointment with Downtown Cuts has been confirmed.',
        'data': {'booking_id': 'booking-001'},
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'read_at': null,
      };

  static List<Map<String, dynamic>> get sampleNotificationList => [
        sampleNotification,
        {
          ...sampleNotification,
          'id': 'notification-002',
          'type': 'new_message',
          'title': 'New Message',
          'body': 'You have a new message from your barber.',
          'data': {'conversation_id': 'conv-001'},
        },
        {
          ...sampleNotification,
          'id': 'notification-003',
          'type': 'booking_reminder',
          'title': 'Appointment Reminder',
          'body': 'Your appointment is tomorrow at 10:00 AM.',
          'is_read': true,
        },
      ];
}

/// Standard test data for payment
class PaymentFixtures {
  static Map<String, dynamic> get paymentIntentResponse => {
        'clientSecret': 'pi_test_secret_123',
        'paymentIntentId': 'pi_test_123',
        'ephemeralKey': 'ek_test_123',
        'customerId': 'cus_test_123',
      };

  static Map<String, dynamic> get savedPaymentMethod => {
        'id': 'pm-001',
        'stripe_payment_method_id': 'pm_test_123',
        'brand': 'visa',
        'last4': '4242',
        'exp_month': 12,
        'exp_year': 2025,
        'is_default': true,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };
}
