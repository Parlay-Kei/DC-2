class Review {
  final String id;
  final String bookingId;
  final String customerId;
  final String barberId;
  final int rating;
  final String? comment;
  final String? barberResponse;
  final DateTime createdAt;
  final DateTime? respondedAt;

  // Joined data
  final String? customerName;
  final String? customerAvatar;

  Review({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.barberId,
    required this.rating,
    this.comment,
    this.barberResponse,
    required this.createdAt,
    this.respondedAt,
    this.customerName,
    this.customerAvatar,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    // Handle nested profile data if present
    final profile = json['profiles'] as Map<String, dynamic>?;

    return Review(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      customerId: json['customer_id'] as String,
      barberId: json['barber_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      barberResponse: json['barber_response'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
      customerName: profile?['full_name'] as String?,
      customerAvatar: profile?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'customer_id': customerId,
      'barber_id': barberId,
      'rating': rating,
      'comment': comment,
      'barber_response': barberResponse,
      'created_at': createdAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
    };
  }

  bool get hasComment => comment != null && comment!.isNotEmpty;
  bool get hasResponse => barberResponse != null && barberResponse!.isNotEmpty;

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays > 365) {
      return '${diff.inDays ~/ 365}y ago';
    } else if (diff.inDays > 30) {
      return '${diff.inDays ~/ 30}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Review copyWith({
    String? id,
    String? bookingId,
    String? customerId,
    String? barberId,
    int? rating,
    String? comment,
    String? barberResponse,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? customerName,
    String? customerAvatar,
  }) {
    return Review(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      barberId: barberId ?? this.barberId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      barberResponse: barberResponse ?? this.barberResponse,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      customerName: customerName ?? this.customerName,
      customerAvatar: customerAvatar ?? this.customerAvatar,
    );
  }
}
