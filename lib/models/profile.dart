class Profile {
  final String id;
  final String? email;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final String preferredLanguage;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    this.email,
    this.fullName,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.preferredLanguage = 'en',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'customer',
      preferredLanguage: json['preferred_language'] as String? ?? 'en',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role,
      'preferred_language': preferredLanguage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isCustomer => role == 'customer';
  bool get isBarber => role == 'barber';
  bool get isAdmin => role == 'admin';

  Profile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? role,
    String? preferredLanguage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
