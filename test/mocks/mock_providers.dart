/// Mock providers for testing Direct Cuts application
///
/// This file provides mock Riverpod providers that can be used
/// to override real providers during testing.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../lib/models/barber.dart';
import '../../lib/models/booking.dart';
import '../../lib/models/profile.dart';
import '../../lib/models/service.dart';
import '../../lib/providers/auth_provider.dart';
import 'mock_services.dart';

// ============================================================================
// Mock Auth Providers
// ============================================================================

/// Creates a mock auth state provider for testing
StreamProvider<User?> createMockAuthStateProvider({
  bool isAuthenticated = true,
  User? user,
}) {
  return StreamProvider<User?>((ref) {
    if (isAuthenticated) {
      return Stream.value(user ?? createMockUser());
    }
    return Stream.value(null);
  });
}

/// Creates a mock current user provider for testing
Provider<User?> createMockCurrentUserProvider({
  bool isAuthenticated = true,
  User? user,
}) {
  return Provider<User?>((ref) {
    if (isAuthenticated) {
      return user ?? createMockUser();
    }
    return null;
  });
}

/// Creates a mock profile provider for testing
FutureProvider<Profile?> createMockCurrentProfileProvider({
  Profile? profile,
}) {
  return FutureProvider<Profile?>((ref) async {
    return profile ??
        Profile(
          id: 'test-user-id',
          fullName: 'Test User',
          email: 'test@example.com',
          role: 'customer',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
  });
}

// ============================================================================
// Mock Data Providers
// ============================================================================

/// Creates provider overrides for a fully mocked test environment
List<Override> createTestOverrides({
  bool isAuthenticated = true,
  User? user,
  Profile? profile,
}) {
  return [
    // Override auth state
    authStateProvider.overrideWith((ref) {
      if (isAuthenticated) {
        return Stream.value(user ?? createMockUser());
      }
      return Stream.value(null);
    }),

    // Override current user
    currentUserProvider.overrideWith((ref) {
      if (isAuthenticated) {
        return user ?? createMockUser();
      }
      return null;
    }),

    // Override current profile
    currentProfileProvider.overrideWith((ref) async {
      return profile ??
          Profile(
            id: 'test-user-id',
            fullName: 'Test User',
            email: 'test@example.com',
            role: 'customer',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
    }),
  ];
}

// ============================================================================
// Test Provider Container Factory
// ============================================================================

/// Creates a ProviderContainer configured for testing
ProviderContainer createTestContainer({
  List<Override> overrides = const [],
  bool isAuthenticated = true,
  User? user,
  Profile? profile,
}) {
  return ProviderContainer(
    overrides: [
      ...createTestOverrides(
        isAuthenticated: isAuthenticated,
        user: user,
        profile: profile,
      ),
      ...overrides,
    ],
  );
}

// ============================================================================
// Mock Service Classes for Provider Testing
// ============================================================================

/// Mock implementation of AuthService for testing
class MockAuthService {
  bool shouldSucceed = true;
  String errorMessage = 'Authentication failed';

  Future<MockAuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (shouldSucceed) {
      return MockAuthResult(
        success: true,
        user: createMockUser(email: email),
      );
    }
    throw Exception(errorMessage);
  }

  Future<MockAuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (shouldSucceed) {
      return MockAuthResult(
        success: true,
        user: createMockUser(email: email, fullName: fullName, role: role),
      );
    }
    throw Exception(errorMessage);
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 50));
  }

  Future<void> resetPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!shouldSucceed) {
      throw Exception(errorMessage);
    }
  }
}

class MockAuthResult {
  final bool success;
  final User? user;
  final String? errorMessage;

  MockAuthResult({
    required this.success,
    this.user,
    this.errorMessage,
  });
}

/// Mock implementation of BarberService for testing
class MockBarberService {
  List<Barber> mockBarbers = [];
  List<Service> mockServices = [];
  bool shouldFail = false;
  String errorMessage = 'Failed to fetch data';

  Future<List<Barber>> getActiveBarbers({int limit = 50}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (shouldFail) throw Exception(errorMessage);
    return mockBarbers;
  }

  Future<Barber?> getBarber(String barberId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (shouldFail) throw Exception(errorMessage);
    try {
      return mockBarbers.firstWhere((b) => b.id == barberId);
    } catch (_) {
      return null;
    }
  }

  Future<List<Barber>> searchBarbers(String query) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (shouldFail) throw Exception(errorMessage);
    return mockBarbers
        .where((b) =>
            b.displayName.toLowerCase().contains(query.toLowerCase()) ||
            (b.shopName?.toLowerCase().contains(query.toLowerCase()) ?? false))
        .toList();
  }

  Future<List<Service>> getBarberServices(String barberId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (shouldFail) throw Exception(errorMessage);
    return mockServices.where((s) => s.barberId == barberId).toList();
  }
}

/// Mock implementation of BookingService for testing
class MockBookingService {
  List<Booking> mockBookings = [];
  bool shouldFail = false;
  String errorMessage = 'Booking operation failed';

  Future<Booking?> createBooking({
    required String barberId,
    required String serviceId,
    required DateTime date,
    required String time,
    required String paymentMethod,
    required String locationType,
    String? address,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (shouldFail) throw Exception(errorMessage);

    final booking = Booking(
      id: 'booking-${DateTime.now().millisecondsSinceEpoch}',
      customerId: 'test-user-id',
      barberId: barberId,
      serviceId: serviceId,
      scheduledDate: date,
      scheduledTime: time,
      status: 'pending',
      totalPrice: 35.00,
      platformFee: 5.25,
      barberEarnings: 29.75,
      paymentMethod: paymentMethod,
      paymentStatus: 'pending',
      locationType: locationType,
      address: address,
      latitude: latitude,
      longitude: longitude,
      notes: notes,
      createdAt: DateTime.now(),
    );

    mockBookings.add(booking);
    return booking;
  }

  Future<List<Booking>> getCustomerBookings({
    String? status,
    bool upcoming = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (shouldFail) throw Exception(errorMessage);

    var result = mockBookings;
    if (status != null) {
      result = result.where((b) => b.status == status).toList();
    }
    if (upcoming) {
      final today = DateTime.now();
      result = result
          .where((b) =>
              b.scheduledDate.isAfter(today) &&
              (b.status == 'pending' || b.status == 'confirmed'))
          .toList();
    }
    return result;
  }

  Future<bool> cancelBooking(String bookingId, {String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (shouldFail) return false;

    final index = mockBookings.indexWhere((b) => b.id == bookingId);
    if (index >= 0) {
      mockBookings[index] = mockBookings[index].copyWith(status: 'cancelled');
      return true;
    }
    return false;
  }

  Future<bool> isTimeSlotAvailable(
    String barberId,
    DateTime date,
    String time,
  ) async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (shouldFail) return false;

    return !mockBookings.any((b) =>
        b.barberId == barberId &&
        b.scheduledDate.year == date.year &&
        b.scheduledDate.month == date.month &&
        b.scheduledDate.day == date.day &&
        b.scheduledTime == time &&
        (b.status == 'pending' || b.status == 'confirmed'));
  }
}

/// Mock implementation of PaymentService for testing
class MockPaymentService {
  bool shouldSucceed = true;
  String errorMessage = 'Payment failed';

  Future<MockPaymentIntentResult?> createPaymentIntent({
    required double amount,
    required String barberId,
    required String bookingId,
    String currency = 'usd',
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!shouldSucceed) return null;

    return MockPaymentIntentResult(
      clientSecret: 'pi_test_secret_${DateTime.now().millisecondsSinceEpoch}',
      paymentIntentId: 'pi_test_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<MockPaymentResult> presentPaymentSheet({
    required String clientSecret,
    String? merchantDisplayName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (shouldSucceed) {
      return MockPaymentResult.success();
    }
    return MockPaymentResult.failed(errorMessage);
  }

  Future<bool> confirmPayment({
    required String bookingId,
    required String paymentIntentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return shouldSucceed;
  }
}

class MockPaymentIntentResult {
  final String clientSecret;
  final String paymentIntentId;
  final String? ephemeralKey;
  final String? customerId;

  MockPaymentIntentResult({
    required this.clientSecret,
    required this.paymentIntentId,
    this.ephemeralKey,
    this.customerId,
  });
}

class MockPaymentResult {
  final bool isSuccess;
  final bool isCancelled;
  final String? errorMessage;

  MockPaymentResult._({
    required this.isSuccess,
    this.isCancelled = false,
    this.errorMessage,
  });

  factory MockPaymentResult.success() => MockPaymentResult._(isSuccess: true);
  factory MockPaymentResult.cancelled() =>
      MockPaymentResult._(isSuccess: false, isCancelled: true);
  factory MockPaymentResult.failed(String message) =>
      MockPaymentResult._(isSuccess: false, errorMessage: message);
}
