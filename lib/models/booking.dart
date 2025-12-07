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
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      barberId: json['barber_id'] as String,
      serviceId: json['service_id'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      scheduledTime: json['scheduled_time'] as String,
      status: json['status'] as String,
      totalPrice: (json['total_price'] as num).toDouble(),
      platformFee: (json['platform_fee'] as num).toDouble(),
      barberEarnings: (json['barber_earnings'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      locationType: json['location_type'] as String,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
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
    );
  }
}
