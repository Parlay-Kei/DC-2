class Service {
  final String id;
  final String barberId;
  final String name;
  final String? description;
  final double price;
  final int durationMinutes;
  final bool isActive;
  final String? category;
  final DateTime createdAt;

  Service({
    required this.id,
    required this.barberId,
    required this.name,
    this.description,
    required this.price,
    required this.durationMinutes,
    this.isActive = true,
    this.category,
    required this.createdAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      barberId: json['barber_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      durationMinutes: json['duration_minutes'] as int,
      isActive: json['is_active'] as bool? ?? true,
      category: json['category'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barber_id': barberId,
      'name': name,
      'description': description,
      'price': price,
      'duration_minutes': durationMinutes,
      'is_active': isActive,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Alias for durationMinutes for convenience
  int get duration => durationMinutes;

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  String get formattedDuration {
    if (durationMinutes < 60) {
      return '$durationMinutes min';
    }
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (mins == 0) {
      return '$hours hr';
    }
    return '$hours hr $mins min';
  }

  Service copyWith({
    String? id,
    String? barberId,
    String? name,
    String? description,
    double? price,
    int? durationMinutes,
    bool? isActive,
    String? category,
    DateTime? createdAt,
  }) {
    return Service(
      id: id ?? this.id,
      barberId: barberId ?? this.barberId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isActive: isActive ?? this.isActive,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
