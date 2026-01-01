import '../config/supabase_config.dart';
import '../models/availability.dart';

class AvailabilityService {
  final _client = SupabaseConfig.client;

  /// Get barber's weekly availability
  Future<List<Availability>> getBarberAvailability(String barberId) async {
    try {
      final response = await _client
          .from('barber_availability')
          .select()
          .eq('barber_id', barberId)
          .eq('is_active', true)
          .order('day_of_week', ascending: true);

      return (response as List).map((a) => Availability.fromJson(a)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get available time slots for a specific date
  Future<DaySchedule> getAvailableSlots(
    String barberId,
    DateTime date, {
    int slotDurationMinutes = 30,
  }) async {
    try {
      final dayOfWeek = date.weekday % 7; // Convert to 0-6 (Sunday = 0)

      // Get availability for this day
      final availabilityResponse = await _client
          .from('barber_availability')
          .select()
          .eq('barber_id', barberId)
          .eq('day_of_week', dayOfWeek)
          .eq('is_active', true)
          .maybeSingle();

      if (availabilityResponse == null) {
        return DaySchedule(date: date, slots: [], isWorkingDay: false);
      }

      final availability = Availability.fromJson(availabilityResponse);

      // Get existing bookings for this date using start_time/end_time (actual DB schema)
      // Query for appointments that overlap with this day
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final bookingsResponse = await _client
          .from('appointments')
          .select('start_time, end_time, id')
          .eq('barber_id', barberId)
          .gte('start_time', startOfDay.toUtc().toIso8601String())
          .lt('start_time', endOfDay.toUtc().toIso8601String())
          .inFilter('status', ['pending', 'confirmed']);

      // Build list of booked time ranges for overlap checking
      final bookedRanges = <_BookedRange>[];
      for (final booking in bookingsResponse as List) {
        final startTime = DateTime.parse(booking['start_time'] as String).toLocal();
        final endTime = DateTime.parse(booking['end_time'] as String).toLocal();
        bookedRanges.add(
          _BookedRange(
            id: booking['id'] as String,
            start: startTime,
            end: endTime,
          ),
        );
      }

      // Generate time slots with overlap checking
      final slots = _generateTimeSlotsWithOverlapCheck(
        availability.startTime,
        availability.endTime,
        slotDurationMinutes,
        bookedRanges,
        date,
      );

      return DaySchedule(date: date, slots: slots, isWorkingDay: true);
    } catch (e) {
      return DaySchedule(date: date, slots: [], isWorkingDay: false);
    }
  }

  /// Get schedule for multiple days
  Future<List<DaySchedule>> getWeekSchedule(
    String barberId,
    DateTime startDate, {
    int days = 7,
  }) async {
    final schedules = <DaySchedule>[];

    for (var i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final schedule = await getAvailableSlots(barberId, date);
      schedules.add(schedule);
    }

    return schedules;
  }

  /// Set barber availability (barber action)
  Future<bool> setAvailability({
    required String barberId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    bool isClosed = false,
  }) async {
    try {
      // Upsert availability
      await _client.from('barber_availability').upsert(
        {
          'barber_id': barberId,
          'day_of_week': dayOfWeek,
          'start_time': startTime,
          'end_time': endTime,
          'is_active': !isClosed,
        },
        onConflict: 'barber_id,day_of_week',
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Toggle day availability
  Future<bool> toggleDayAvailability(int dayOfWeek, bool isActive) async {
    final barberId = SupabaseConfig.currentUserId;
    if (barberId == null) return false;

    try {
      await _client
          .from('barber_availability')
          .update({'is_active': isActive})
          .eq('barber_id', barberId)
          .eq('day_of_week', dayOfWeek);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Set default availability (9 AM - 5 PM, Mon-Fri)
  Future<bool> setDefaultAvailability() async {
    final barberId = SupabaseConfig.currentUserId;
    if (barberId == null) return false;

    try {
      final defaults = <Map<String, dynamic>>[];

      // Monday (1) to Friday (5)
      for (var day = 1; day <= 5; day++) {
        defaults.add({
          'barber_id': barberId,
          'day_of_week': day,
          'start_time': '09:00',
          'end_time': '17:00',
          'is_active': true,
        });
      }

      // Saturday (6) - shorter hours
      defaults.add({
        'barber_id': barberId,
        'day_of_week': 6,
        'start_time': '10:00',
        'end_time': '14:00',
        'is_active': true,
      });

      // Sunday (0) - off
      defaults.add({
        'barber_id': barberId,
        'day_of_week': 0,
        'start_time': '00:00',
        'end_time': '00:00',
        'is_active': false,
      });

      await _client
          .from('barber_availability')
          .upsert(defaults, onConflict: 'barber_id,day_of_week');

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generate time slots with overlap checking against existing bookings
  /// This ensures UI never shows slots that would conflict with DB constraint
  List<TimeSlot> _generateTimeSlotsWithOverlapCheck(
    String startTime,
    String endTime,
    int slotDuration,
    List<_BookedRange> bookedRanges,
    DateTime date,
  ) {
    final slots = <TimeSlot>[];

    final startParts = startTime.split(':');
    final endParts = endTime.split(':');

    var currentMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

    while (currentMinutes + slotDuration <= endMinutes) {
      final hour = currentMinutes ~/ 60;
      final minute = currentMinutes % 60;
      final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

      // Build proposed slot range
      final slotStart = DateTime(date.year, date.month, date.day, hour, minute);
      final slotEnd = slotStart.add(Duration(minutes: slotDuration));

      // Check if slot is in the past (for today)
      bool isPast = false;
      if (isToday) {
        isPast = slotStart.isBefore(now);
      }

      // Check for overlap with any existing booking using half-open interval [start, end)
      // Same logic as DB constraint: tstzrange(start_time, end_time, '[)') && tstzrange(slot_start, slot_end, '[)')
      String? conflictingBookingId;
      for (final booked in bookedRanges) {
        // Two half-open intervals [a, b) and [c, d) overlap if a < d AND c < b
        if (slotStart.isBefore(booked.end) && booked.start.isBefore(slotEnd)) {
          conflictingBookingId = booked.id;
          break;
        }
      }

      final isBooked = conflictingBookingId != null;

      slots.add(
        TimeSlot(
          time: timeStr,
          isAvailable: !isBooked && !isPast,
          bookingId: conflictingBookingId,
        ),
      );

      currentMinutes += slotDuration;
    }

    return slots;
  }
}

/// Helper class for tracking booked time ranges
class _BookedRange {
  final String id;
  final DateTime start;
  final DateTime end;

  _BookedRange({
    required this.id,
    required this.start,
    required this.end,
  });
}
