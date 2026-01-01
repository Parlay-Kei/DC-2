class Booking {
  final String id;
  final String customerId;
  final String barberId;
  final String serviceId;
  final DateTime scheduledDate;
  final String scheduledTime;
  final String status;
  final double totalPrice;
  final double platformFee;
  final double barberEarnings;
  final String paymentMethod;
  final String paymentStatus;
  final String locationType;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final DateTime createdAt;

  // Joined fields from related tables (populated when fetching with joins)
  final String? customerName;
  final String? customerAvatar;
  final String? customerPhone;
  final String? barberName;
  final String? barberAvatar;
  final String? serviceName;
  final int? durationMinutes;
  final bool hasReview;

  Booking({
    required this.id,
    required this.customerId,
    required this.barberId,
    required this.serviceId,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.status,
    required this.totalPrice,
    required this.platformFee,
    required this.barberEarnings,
    required this.paymentMethod,
    this.paymentStatus = 'pending',
    required this.locationType,
    this.address,
    this.latitude,
    this.longitude,
    this.notes,
    required this.createdAt,
    this.customerName,
    this.customerAvatar,
    this.customerPhone,
    this.barberName,
    this.barberAvatar,
    this.serviceName,
    this.durationMinutes,
    this.hasReview = false,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Handle joined customer profile data
    String? customerName;
    String? customerAvatar;
    String? customerPhone;
    if (json['customer'] != null && json['customer'] is Map) {
      customerName = json['customer']['full_name'] as String?;
      customerAvatar = json['customer']['avatar_url'] as String?;
      customerPhone = json['customer']['phone'] as String?;
    }

    // Handle joined barber profile data
    String? barberName;
    String? barberAvatar;
    if (json['barber'] != null && json['barber'] is Map) {
      barberName = json['barber']['shop_name'] ?? json['barber']['full_name'] as String?;
      barberAvatar = json['barber']['avatar_url'] as String?;
    }

    // Handle joined service data
    String? serviceName;
    int? durationMinutes;
    if (json['service'] != null && json['service'] is Map) {
      serviceName = json['service']['name'] as String?;
      durationMinutes = json['service']['duration'] as int?;
    }

    // Handle review existence
    bool hasReview = false;
    if (json['reviews'] != null) {
      if (json['reviews'] is List) {
        hasReview = (json['reviews'] as List).isNotEmpty;
      } else if (json['reviews'] is Map) {
        hasReview = true;
      }
    }

    // Handle both old schema (scheduled_date/time) and new schema (start_time/end_time)
    DateTime scheduledDate;
    String scheduledTime;

    if (json['start_time'] != null) {
      // New schema: start_time is a timestamptz
      final startTime = DateTime.parse(json['start_time'] as String);
      scheduledDate = DateTime(startTime.year, startTime.month, startTime.day);
      scheduledTime =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    } else {
      // Old schema: separate date and time fields
      scheduledDate = DateTime.parse(json['scheduled_date'] as String);
      scheduledTime = json['scheduled_time'] as String;
    }

    // Handle price field naming differences
    final totalPrice = (json['total_price'] ?? json['price'] ?? 0) as num;
    final platformFee = (json['platform_fee'] ?? 0) as num;
    // barber_earnings might not exist in new schema, calculate it
    final barberEarnings =
        (json['barber_earnings'] ?? (totalPrice.toDouble() - platformFee.toDouble())) as num;

    // Handle address field naming
    final address = json['address'] ?? json['service_address'];

    // Handle location type (might be enum in DB)
    final locationType = json['location_type']?.toString() ?? 'shop';

    return Booking(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      barberId: json['barber_id'] as String,
      serviceId: json['service_id'] as String,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      status: json['status'] as String,
      totalPrice: totalPrice.toDouble(),
      platformFee: platformFee.toDouble(),
      barberEarnings: barberEarnings.toDouble(),
      paymentMethod: json['payment_method'] as String,
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      locationType: locationType,
      address: address as String?,
      latitude: (json['latitude'] ?? json['service_lat'] as num?)?.toDouble(),
      longitude: (json['longitude'] ?? json['service_lng'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      customerName: customerName ?? json['customer_name'] as String?,
      customerAvatar: customerAvatar ?? json['customer_avatar'] as String?,
      customerPhone: customerPhone ?? json['customer_phone'] as String?,
      barberName: barberName ?? json['barber_name'] as String?,
      barberAvatar: barberAvatar ?? json['barber_avatar'] as String?,
      serviceName: serviceName ?? json['service_name'] as String?,
      durationMinutes: durationMinutes ?? json['service_duration'] as int?,
      hasReview: hasReview,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'barber_id': barberId,
      'service_id': serviceId,
      'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
      'scheduled_time': scheduledTime,
      'status': status,
      'total_price': totalPrice,
      'platform_fee': platformFee,
      'barber_earnings': barberEarnings,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'location_type': locationType,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isNoShow => status == 'no_show';
  bool get isExpired => status == 'expired';

  /// True if booking is still active (not cancelled, expired, no-show)
  bool get isActive => isPending || isConfirmed;

  /// True if booking was terminated (cancelled, expired, no-show)
  bool get isTerminated => isCancelled || isExpired || isNoShow;

  bool get isMobileBooking => locationType == 'mobile';
  bool get isShopBooking => locationType == 'shop';

  bool get isPaid => paymentStatus == 'paid';
  bool get isCashPayment => paymentMethod == 'cash';
  bool get isCardPayment => paymentMethod == 'card';

  Booking copyWith({
    String? id,
    String? customerId,
    String? barberId,
    String? serviceId,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? status,
    double? totalPrice,
    double? platformFee,
    double? barberEarnings,
    String? paymentMethod,
    String? paymentStatus,
    String? locationType,
    String? address,
    double? latitude,
    double? longitude,
    String? notes,
    DateTime? createdAt,
    String? customerName,
    String? customerAvatar,
    String? customerPhone,
    String? barberName,
    String? barberAvatar,
    String? serviceName,
    int? durationMinutes,
    bool? hasReview,
  }) {
    return Booking(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      barberId: barberId ?? this.barberId,
      serviceId: serviceId ?? this.serviceId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      platformFee: platformFee ?? this.platformFee,
      barberEarnings: barberEarnings ?? this.barberEarnings,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      locationType: locationType ?? this.locationType,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
      customerAvatar: customerAvatar ?? this.customerAvatar,
      customerPhone: customerPhone ?? this.customerPhone,
      barberName: barberName ?? this.barberName,
      barberAvatar: barberAvatar ?? this.barberAvatar,
      serviceName: serviceName ?? this.serviceName,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      hasReview: hasReview ?? this.hasReview,
    );
  }
}
