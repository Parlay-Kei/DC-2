/// App-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Direct Cuts';
  static const String appVersion = '2.0.0';
  static const String appBuildNumber = '1';
  static const String appBundle = 'com.directcuts.app';

  // Platform Fees
  static const double platformFeePercent = 0.15; // 15%
  static const double stripeFeePercent = 0.029; // 2.9%
  static const double stripeFeeFixed = 0.30; // $0.30

  // Booking Constraints
  static const int minBookingLeadTimeMinutes = 60; // 1 hour minimum
  static const int maxBookingLeadTimeDays = 30; // 30 days maximum
  static const int defaultServiceDurationMinutes = 30;
  static const int bookingSlotIntervalMinutes = 15;
  static const int cancellationWindowHours = 24;

  // Distance & Location
  static const double defaultSearchRadiusMiles = 10.0;
  static const double maxSearchRadiusMiles = 50.0;
  static const double maxTravelRadiusMiles = 25.0;
  static const double defaultTravelFeePerMile = 2.0;

  // UI Constraints
  static const int maxReviewLength = 500;
  static const int maxBioLength = 200;
  static const int maxServiceNameLength = 50;
  static const int maxServiceDescriptionLength = 200;
  static const int maxMessageLength = 1000;

  // File Constraints
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxAvatarSizeBytes = 2 * 1024 * 1024; // 2MB
  static const List<String> allowedImageTypes = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp'
  ];

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Durations
  static const Duration barberCacheDuration = Duration(minutes: 5);
  static const Duration serviceCacheDuration = Duration(minutes: 10);
  static const Duration profileCacheDuration = Duration(minutes: 15);

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(seconds: 60);
  static const Duration locationTimeout = Duration(seconds: 10);

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Realtime
  static const Duration typingIndicatorDuration = Duration(seconds: 3);
  static const Duration messagePollingInterval = Duration(seconds: 30);

  // Rating
  static const int minRating = 1;
  static const int maxRating = 5;

  // Business Hours
  static const String defaultOpenTime = '09:00';
  static const String defaultCloseTime = '17:00';

  // URLs
  static const String privacyPolicyUrl = 'https://directcuts.com/privacy';
  static const String termsOfServiceUrl = 'https://directcuts.com/terms';
  static const String helpCenterUrl = 'https://directcuts.com/help';
  static const String supportEmail = 'support@directcuts.com';

  // Deep Links
  static const String deepLinkScheme = 'directcuts';
  static const String universalLinkDomain = 'directcuts.com';

  // Storage Buckets
  static const String avatarsBucket = 'avatars';
  static const String barberImagesBucket = 'barber-images';
  static const String chatMediaBucket = 'chat-media';
  static const String serviceImagesBucket = 'service-images';

  // Notification Channels (Android)
  static const String bookingChannelId = 'booking_notifications';
  static const String messageChannelId = 'message_notifications';
  static const String promotionChannelId = 'promotion_notifications';
}

/// Booking status values
class BookingStatus {
  BookingStatus._();

  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String noShow = 'no_show';

  static const List<String> all = [
    pending,
    confirmed,
    completed,
    cancelled,
    noShow,
  ];

  static bool isActive(String status) {
    return status == pending || status == confirmed;
  }

  static bool canCancel(String status) {
    return status == pending || status == confirmed;
  }

  static bool canReview(String status) {
    return status == completed;
  }
}

/// Payment status values
class PaymentStatus {
  PaymentStatus._();

  static const String pending = 'pending';
  static const String paid = 'paid';
  static const String refunded = 'refunded';
  static const String failed = 'failed';

  static const List<String> all = [
    pending,
    paid,
    refunded,
    failed,
  ];
}

/// User role values
class UserRole {
  UserRole._();

  static const String customer = 'customer';
  static const String barber = 'barber';
  static const String admin = 'admin';
}

/// Day of week values (matching Postgres)
class DayOfWeek {
  DayOfWeek._();

  static const int sunday = 0;
  static const int monday = 1;
  static const int tuesday = 2;
  static const int wednesday = 3;
  static const int thursday = 4;
  static const int friday = 5;
  static const int saturday = 6;

  static const List<String> names = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  static const List<String> shortNames = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  static String getName(int day) => names[day];
  static String getShortName(int day) => shortNames[day];
}
