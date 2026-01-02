import '../config/supabase_config.dart';
import '../models/booking.dart';

/// Custom exception for booking errors with user-friendly messages
class BookingException implements Exception {
  final String code;
  final String message;

  BookingException(this.code, this.message);

  @override
  String toString() => message;

  /// Parse RPC error into BookingException
  static BookingException fromError(dynamic error) {
    final msg = error.toString().toLowerCase();

    // SLOT_TAKEN - most common, check first
    // Catches: unique_violation (exact start_time), exclusion_violation (overlap)
    if (msg.contains('slot_taken') ||
        msg.contains('unique_violation') ||
        msg.contains('exclusion_violation') ||
        msg.contains('ux_appointments_barber_slot') ||
        msg.contains('no_overlapping_appointments')) {
      return BookingException(
          'SLOT_TAKEN', 'This time slot was just booked. Please pick another.');
    }

    // AUTH_REQUIRED
    if (msg.contains('auth_required')) {
      return BookingException(
          'AUTH_REQUIRED', 'Please log in to book an appointment.');
    }

    // INVALID_SERVICE
    if (msg.contains('invalid_service')) {
      return BookingException(
          'INVALID_SERVICE', 'This service is no longer available.');
    }

    // INVALID_PAYMENT
    if (msg.contains('invalid_payment')) {
      return BookingException(
          'INVALID_PAYMENT', 'Please select a valid payment method.');
    }

    // INVALID_LOCATION
    if (msg.contains('invalid_location')) {
      return BookingException(
          'INVALID_LOCATION', 'Please select shop or mobile booking.');
    }

    // Generic fallback
    return BookingException(
        'UNKNOWN', 'Something went wrong. Please try again.');
  }
}

class BookingService {
  final _client = SupabaseConfig.client;

  /// Create a new booking using atomic RPC
  /// Throws BookingException with user-friendly message on failure
  ///
  /// Note: durationMinutes and price are passed for display purposes only.
  /// The database now looks up the actual values from the services table
  /// (source of truth) and ignores client-provided values.
  Future<Booking> createBooking({
    required String barberId,
    required String serviceId,
    required DateTime date,
    required String time,
    required String paymentMethod,
    required String locationType,
    int? durationMinutes, // OPTIONAL: DB looks up from service_id
    double? price, // OPTIONAL: DB looks up from service_id
    String? address,
    String? notes,
  }) async {
    final customerId = SupabaseConfig.currentUserId;
    if (customerId == null) {
      throw BookingException(
          'AUTH_REQUIRED', 'Please log in to book an appointment.');
    }

    try {
      // Build start_time from date + time
      // time is in HH:mm format, date is DateTime
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final startTime = DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      );

      // Call atomic RPC - handles slot locking, overlap prevention,
      // and looks up duration/price from services table (source of truth)
      final response = await _client.rpc(
        'create_booking',
        params: {
          'p_barber_id': barberId,
          'p_service_id': serviceId,
          'p_start_time': startTime.toUtc().toIso8601String(),
          'p_payment_method': paymentMethod,
          'p_location_type': locationType,
          'p_address': address,
          'p_notes': notes,
          // Duration and price are now ignored by RPC (looked up from DB)
          // Kept for backwards compatibility with older deployments
          'p_duration_minutes': durationMinutes,
          'p_price': price,
        },
      );

      // RPC returns the created appointment row
      if (response == null) {
        throw BookingException('UNKNOWN', 'Booking failed. Please try again.');
      }

      return Booking.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      // Re-throw if already a BookingException
      if (e is BookingException) rethrow;

      // Parse RPC errors into user-friendly exceptions
      throw BookingException.fromError(e);
    }
  }

  /// Get customer's bookings
  Future<List<Booking>> getCustomerBookings({
    String? status,
    bool upcoming = false,
  }) async {
    final customerId = SupabaseConfig.currentUserId;
    if (customerId == null) return [];

    try {
      var query =
          _client.from('appointments').select().eq('customer_id', customerId);

      if (status != null) {
        query = query.eq('status', status);
      }

      if (upcoming) {
        // Use start_time (actual DB schema) instead of scheduled_date
        final now = DateTime.now().toUtc().toIso8601String();
        query = query
            .gte('start_time', now)
            .inFilter('status', ['pending', 'confirmed']);
      }

      final response = await query.order('start_time', ascending: true);

      return (response as List).map((b) => Booking.fromJson(b)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get barber's bookings
  Future<List<Booking>> getBarberBookings({
    String? status,
    DateTime? date,
    bool todayOnly = false,
  }) async {
    final barberId = SupabaseConfig.currentUserId;
    if (barberId == null) return [];

    try {
      var query =
          _client.from('appointments').select().eq('barber_id', barberId);

      if (status != null) {
        query = query.eq('status', status);
      }

      if (todayOnly || date != null) {
        // Use start_time range for date filtering
        final targetDate = date ?? DateTime.now();
        final startOfDay =
            DateTime(targetDate.year, targetDate.month, targetDate.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        query = query
            .gte('start_time', startOfDay.toUtc().toIso8601String())
            .lt('start_time', endOfDay.toUtc().toIso8601String());
      }

      final response = await query.order('start_time', ascending: true);

      return (response as List).map((b) => Booking.fromJson(b)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get a single booking with details
  Future<BookingWithDetails?> getBookingDetails(String bookingId) async {
    try {
      final response = await _client.from('appointments').select('''
            *,
            barber:barber_id(id, display_name, phone, profile_image_url),
            customer:customer_id(id, full_name, phone, avatar_url),
            service:service_id(id, name, price, duration_minutes)
          ''').eq('id', bookingId).single();

      return BookingWithDetails.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Update booking status
  Future<bool> updateBookingStatus(String bookingId, String status) async {
    try {
      await _client
          .from('appointments')
          .update({'status': status}).eq('id', bookingId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Confirm booking (barber action)
  Future<bool> confirmBooking(String bookingId) async {
    return updateBookingStatus(bookingId, 'confirmed');
  }

  /// Cancel booking
  Future<bool> cancelBooking(String bookingId, {String? reason}) async {
    try {
      final updates = <String, dynamic>{
        'status': 'cancelled',
      };
      if (reason != null) {
        updates['cancellation_reason'] = reason;
      }

      await _client.from('appointments').update(updates).eq('id', bookingId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Complete booking (barber action)
  Future<bool> completeBooking(String bookingId) async {
    return updateBookingStatus(bookingId, 'completed');
  }

  /// Mark as no-show (barber action)
  Future<bool> markNoShow(String bookingId) async {
    return updateBookingStatus(bookingId, 'no_show');
  }

  /// Reschedule booking
  Future<bool> rescheduleBooking(
    String bookingId, {
    required DateTime newDate,
    required String newTime,
  }) async {
    try {
      // Build new start_time from date + time
      final timeParts = newTime.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final newStartTime = DateTime(
        newDate.year,
        newDate.month,
        newDate.day,
        hour,
        minute,
      );

      // Get current booking to calculate duration
      final current = await _client
          .from('appointments')
          .select('start_time, end_time')
          .eq('id', bookingId)
          .single();

      final oldStart = DateTime.parse(current['start_time'] as String);
      final oldEnd = DateTime.parse(current['end_time'] as String);
      final duration = oldEnd.difference(oldStart);
      final newEndTime = newStartTime.add(duration);

      await _client.from('appointments').update({
        'start_time': newStartTime.toUtc().toIso8601String(),
        'end_time': newEndTime.toUtc().toIso8601String(),
        'status': 'pending', // Reset to pending for re-confirmation
      }).eq('id', bookingId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get booking history (completed bookings)
  Future<List<Booking>> getBookingHistory({int limit = 50}) async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('appointments')
          .select()
          .or('customer_id.eq.$userId,barber_id.eq.$userId')
          .eq('status', 'completed')
          .order('start_time', ascending: false)
          .limit(limit);

      return (response as List).map((b) => Booking.fromJson(b)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if a time slot is available
  Future<bool> isTimeSlotAvailable(
    String barberId,
    DateTime date,
    String time,
  ) async {
    try {
      // Build start_time from date + time
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final startTime = DateTime(date.year, date.month, date.day, hour, minute);

      final response = await _client
          .from('appointments')
          .select('id')
          .eq('barber_id', barberId)
          .eq('start_time', startTime.toUtc().toIso8601String())
          .inFilter('status', ['pending', 'confirmed']);

      return (response as List).isEmpty;
    } catch (e) {
      return false;
    }
  }
}

class BookingWithDetails {
  final Booking booking;
  final Map<String, dynamic>? barber;
  final Map<String, dynamic>? customer;
  final Map<String, dynamic>? service;

  BookingWithDetails({
    required this.booking,
    this.barber,
    this.customer,
    this.service,
  });

  factory BookingWithDetails.fromJson(Map<String, dynamic> json) {
    return BookingWithDetails(
      booking: Booking.fromJson(json),
      barber: json['barber'] as Map<String, dynamic>?,
      customer: json['customer'] as Map<String, dynamic>?,
      service: json['service'] as Map<String, dynamic>?,
    );
  }

  String get barberName =>
      barber?['display_name'] as String? ?? 'Unknown Barber';
  String get customerName =>
      customer?['full_name'] as String? ?? 'Unknown Customer';
  String get serviceName => service?['name'] as String? ?? 'Service';
  int get serviceDuration => service?['duration_minutes'] as int? ?? 30;
}
