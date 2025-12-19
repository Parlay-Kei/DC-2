class Barber {
  final String id;
  final String? visibleName; // Display name from profiles table join, or shop_name fallback
  final String? bio;
  final String? phone;
  final String? profileImageUrl;
  final String? shopName;
  final String? shopAddress;
  final String? location; // Legacy location field
  final double? latitude;
  final double? longitude;
  final int serviceRadiusMiles;
  final bool isMobile;
  final bool offersHomeService;
  final double? travelFeePerMile;
  final double? travelFee;
  final bool isVerified;
  final bool isActive;
  final double rating;
  final int totalReviews;
  final String? stripeAccountId;
  final bool stripeOnboardingComplete;
  final bool onboardingComplete;
  final String subscriptionTier;
  final DateTime createdAt;

  Barber({
    required this.id,
    this.visibleName,
    this.bio,
    this.phone,
    this.profileImageUrl,
    this.shopName,
    this.shopAddress,
    this.location,
    this.latitude,
    this.longitude,
    this.serviceRadiusMiles = 10,
    this.isMobile = false,
    this.offersHomeService = false,
    this.travelFeePerMile,
    this.travelFee,
    this.isVerified = false,
    this.isActive = true,
    this.rating = 0,
    this.totalReviews = 0,
    this.stripeAccountId,
    this.stripeOnboardingComplete = false,
    this.onboardingComplete = false,
    this.subscriptionTier = 'free',
    required this.createdAt,
  });

  /// The name to display for this barber
  String get displayName => visibleName ?? shopName ?? 'Barber';

  factory Barber.fromJson(Map<String, dynamic> json) {
    // Handle joined profile data if present
    String? visibleName;
    String? avatarUrl;
    
    final profiles = json['profiles'];
    if (profiles != null && profiles is Map<String, dynamic>) {
      visibleName = profiles['full_name'] as String?;
      avatarUrl = profiles['avatar_url'] as String?;
    }
    
    // Fallback to display_name if it exists (for backwards compatibility)
    visibleName ??= json['display_name'] as String?;
    
    return Barber(
      id: json['id'] as String,
      visibleName: visibleName,
      bio: json['bio'] as String?,
      phone: json['phone'] as String?,
      profileImageUrl: avatarUrl ?? json['profile_image_url'] as String?,
      shopName: json['shop_name'] as String?,
      shopAddress: json['shop_address'] as String?,
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      serviceRadiusMiles: json['service_radius_miles'] as int? ?? 10,
      isMobile: json['is_mobile'] as bool? ?? false,
      offersHomeService: json['offers_home_service'] as bool? ?? false,
      travelFeePerMile: (json['travel_fee_per_mile'] as num?)?.toDouble(),
      travelFee: (json['travel_fee'] as num?)?.toDouble(),
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      stripeAccountId: json['stripe_account_id'] as String?,
      stripeOnboardingComplete: json['stripe_onboarding_complete'] as bool? ?? false,
      onboardingComplete: json['onboarding_complete'] as bool? ?? false,
      subscriptionTier: json['subscription_tier'] as String? ?? 'free',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bio': bio,
      'phone': phone,
      'profile_image_url': profileImageUrl,
      'shop_name': shopName,
      'shop_address': shopAddress,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'service_radius_miles': serviceRadiusMiles,
      'is_mobile': isMobile,
      'offers_home_service': offersHomeService,
      'travel_fee_per_mile': travelFeePerMile,
      'travel_fee': travelFee,
      'is_verified': isVerified,
      'is_active': isActive,
      'rating': rating,
      'total_reviews': totalReviews,
      'stripe_account_id': stripeAccountId,
      'stripe_onboarding_complete': stripeOnboardingComplete,
      'onboarding_complete': onboardingComplete,
      'subscription_tier': subscriptionTier,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get hasLocation => latitude != null && longitude != null;
  bool get canAcceptPayments =>
      stripeOnboardingComplete && stripeAccountId != null;
  
  // Tier helpers using actual column name
  String get tier => subscriptionTier;
  bool get isPro => subscriptionTier == 'pro';
  bool get isFree => subscriptionTier == 'free';

  Barber copyWith({
    String? id,
    String? visibleName,
    String? bio,
    String? phone,
    String? profileImageUrl,
    String? shopName,
    String? shopAddress,
    String? location,
    double? latitude,
    double? longitude,
    int? serviceRadiusMiles,
    bool? isMobile,
    bool? offersHomeService,
    double? travelFeePerMile,
    double? travelFee,
    bool? isVerified,
    bool? isActive,
    double? rating,
    int? totalReviews,
    String? stripeAccountId,
    bool? stripeOnboardingComplete,
    bool? onboardingComplete,
    String? subscriptionTier,
    DateTime? createdAt,
  }) {
    return Barber(
      id: id ?? this.id,
      visibleName: visibleName ?? this.visibleName,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      shopName: shopName ?? this.shopName,
      shopAddress: shopAddress ?? this.shopAddress,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      serviceRadiusMiles: serviceRadiusMiles ?? this.serviceRadiusMiles,
      isMobile: isMobile ?? this.isMobile,
      offersHomeService: offersHomeService ?? this.offersHomeService,
      travelFeePerMile: travelFeePerMile ?? this.travelFeePerMile,
      travelFee: travelFee ?? this.travelFee,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      stripeAccountId: stripeAccountId ?? this.stripeAccountId,
      stripeOnboardingComplete: stripeOnboardingComplete ?? this.stripeOnboardingComplete,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
