class Barber {
  final String id;
  final String userId;
  final String displayName;
  final String? bio;
  final String? phone;
  final String? profileImageUrl;
  final double? latitude;
  final double? longitude;
  final int serviceRadiusMiles;
  final bool isMobile;
  final bool isVerified;
  final bool isActive;
  final double rating;
  final int totalReviews;
  final String? stripeAccountId;
  final bool stripeOnboardingComplete;
  final bool onboardingCompleted;
  final String tier;
  final DateTime createdAt;

  Barber({
    required this.id,
    required this.userId,
    required this.displayName,
    this.bio,
    this.phone,
    this.profileImageUrl,
    this.latitude,
    this.longitude,
    this.serviceRadiusMiles = 10,
    this.isMobile = false,
    this.isVerified = false,
    this.isActive = true,
    this.rating = 0,
    this.totalReviews = 0,
    this.stripeAccountId,
    this.stripeOnboardingComplete = false,
    this.onboardingCompleted = false,
    this.tier = 'beginner',
    required this.createdAt,
  });

  factory Barber.fromJson(Map<String, dynamic> json) {
    return Barber(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      bio: json['bio'] as String?,
      phone: json['phone'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      serviceRadiusMiles: json['service_radius_miles'] as int? ?? 10,
      isMobile: json['is_mobile'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      stripeAccountId: json['stripe_account_id'] as String?,
      stripeOnboardingComplete: json['stripe_onboarding_complete'] as bool? ?? false,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      tier: json['tier'] as String? ?? 'beginner',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'display_name': displayName,
      'bio': bio,
      'phone': phone,
      'profile_image_url': profileImageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'service_radius_miles': serviceRadiusMiles,
      'is_mobile': isMobile,
      'is_verified': isVerified,
      'is_active': isActive,
      'rating': rating,
      'total_reviews': totalReviews,
      'stripe_account_id': stripeAccountId,
      'stripe_onboarding_complete': stripeOnboardingComplete,
      'onboarding_completed': onboardingCompleted,
      'tier': tier,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get hasLocation => latitude != null && longitude != null;
  bool get canAcceptPayments => stripeOnboardingComplete && stripeAccountId != null;

  Barber copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? bio,
    String? phone,
    String? profileImageUrl,
    double? latitude,
    double? longitude,
    int? serviceRadiusMiles,
    bool? isMobile,
    bool? isVerified,
    bool? isActive,
    double? rating,
    int? totalReviews,
    String? stripeAccountId,
    bool? stripeOnboardingComplete,
    bool? onboardingCompleted,
    String? tier,
    DateTime? createdAt,
  }) {
    return Barber(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      serviceRadiusMiles: serviceRadiusMiles ?? this.serviceRadiusMiles,
      isMobile: isMobile ?? this.isMobile,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      stripeAccountId: stripeAccountId ?? this.stripeAccountId,
      stripeOnboardingComplete: stripeOnboardingComplete ?? this.stripeOnboardingComplete,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      tier: tier ?? this.tier,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
