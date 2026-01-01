class BlockedTime {
  final String id;
  final String barberId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String? reason;
  final bool isAllDay;
  final DateTime createdAt;

  BlockedTime({
    required this.id,
    required this.barberId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.reason,
    this.isAllDay = false,
    required this.createdAt,
  });

  factory BlockedTime.fromJson(Map<String, dynamic> json) {
    return BlockedTime(
      id: json['id'] as String,
      barberId: json['barber_id'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      reason: json['reason'] as String?,
      isAllDay: json['is_all_day'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barber_id': barberId,
      'date': date.toIso8601String().split('T')[0],
      'start_time': startTime,
      'end_time': endTime,
      'reason': reason,
      'is_all_day': isAllDay,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedTimeRange {
    if (isAllDay) return 'All Day';
    return '$startTime - $endTime';
  }
}
