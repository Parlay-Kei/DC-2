import '../config/supabase_config.dart';
import '../models/booking.dart';
import '../models/service.dart';

class BookingService {
  final _client = SupabaseConfig.client;

  /// Create a new booking
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
    final customerId = SupabaseConfig.currentUserId;
    if (customerId == null) return null;

    try {
      // Get service details for pricing
      final serviceResponse = await _client
          .from('barber_services')
          .select()
          .eq('id', serviceId)
          .single();

      final service = Service.fromJson(serviceResponse);

      // Calculate fees (15% platform fee)
      final totalPrice = service.price;
      final platformFee = totalPrice * 0.15;
      final barberEarnings = totalPrice - platformFee;

      final bookingData = {
        'customer_id': customerId,
        'barber_id': barberId,
        'service_id': serviceId,
        'scheduled_date': date.toIso8601String().split('T')[0],
        'scheduled_time': time,
        'status': 'pending',
        'total_price': totalPrice,
        'platform_fee': platformFee,
        'barber_earnings': barberEarnings,
        'payment_method': paymentMethod,
        'payment_status': paymentMethod == 'cash' ? 'pending' : 'pending',
        'location_type': locationType,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes,
      };

      final response = await _client
          .from('appointments')
          .insert(bookingData)
          .select()
          .single();

      return Booking.fromJson(response);
    } catch (e) {
      return null;
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
        final today = DateTime.now().toIso8601String().split('T')[0];
        query = query
            .gte('scheduled_date', today)
            .inFilter('status', ['pending', 'confirmed']);
      }

      final response = await query.order('scheduled_date', ascending: true);

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
        final targetDate =
            (date ?? DateTime.now()).toIso8601String().split('T')[0];
        query = query.eq('scheduled_date', targetDate);
      }

      final response = await query.order('scheduled_time', ascending: true);

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
      await _client.from('appointments').update({
        'scheduled_date': newDate.toIso8601String().split('T')[0],
        'scheduled_time': newTime,
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
          .order('scheduled_date', ascending: false)
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
      final dateStr = date.toIso8601String().split('T')[0];

      final response = await _client
          .from('appointments')
          .select('id')
          .eq('barber_id', barberId)
          .eq('scheduled_date', dateStr)
          .eq('scheduled_time', time)
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
