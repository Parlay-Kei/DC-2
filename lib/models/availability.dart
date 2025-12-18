class Availability {
  final String id;
  final String barberId;
  final int dayOfWeek; // 0 = Sunday, 6 = Saturday
  final String startTime; // HH:mm format
  final String endTime;
  final bool isActive;

  Availability({
    required this.id,
    required this.barberId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
  });

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      id: json['id'] as String,
      barberId: json['barber_id'] as String,
      dayOfWeek: json['day_of_week'] as int,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barber_id': barberId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'is_active': isActive,
    };
  }

  String get dayName {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    return days[dayOfWeek];
  }

  String get shortDayName {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[dayOfWeek];
  }

  String get formattedHours => '$startTime - $endTime';

  Availability copyWith({
    String? id,
    String? barberId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    bool? isActive,
  }) {
    return Availability(
      id: id ?? this.id,
      barberId: barberId ?? this.barberId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
    );
  }
}

class TimeSlot {
  final String time; // HH:mm format
  final bool isAvailable;
  final String? bookingId; // If already booked

  TimeSlot({
    required this.time,
    required this.isAvailable,
    this.bookingId,
  });

  String get formattedTime {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

class DaySchedule {
  final DateTime date;
  final List<TimeSlot> slots;
  final bool isWorkingDay;

  DaySchedule({
    required this.date,
    required this.slots,
    required this.isWorkingDay,
  });

  List<TimeSlot> get availableSlots =>
      slots.where((s) => s.isAvailable).toList();

  bool get hasAvailability => availableSlots.isNotEmpty;
}
