class NotificationPreferences {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool bookingReminders;
  final bool promotions;
  final bool chatMessages;

  NotificationPreferences({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.bookingReminders = true,
    this.promotions = false,
    this.chatMessages = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) return NotificationPreferences();
    return NotificationPreferences(
      pushEnabled: json['push_enabled'] as bool? ?? true,
      emailEnabled: json['email_enabled'] as bool? ?? true,
      bookingReminders: json['booking_reminders'] as bool? ?? true,
      promotions: json['promotions'] as bool? ?? false,
      chatMessages: json['chat_messages'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'push_enabled': pushEnabled,
      'email_enabled': emailEnabled,
      'booking_reminders': bookingReminders,
      'promotions': promotions,
      'chat_messages': chatMessages,
    };
  }

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? bookingReminders,
    bool? promotions,
    bool? chatMessages,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      bookingReminders: bookingReminders ?? this.bookingReminders,
      promotions: promotions ?? this.promotions,
      chatMessages: chatMessages ?? this.chatMessages,
    );
  }
}

class Profile {
  final String id;
  final String? email;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final String preferredLanguage;
  final NotificationPreferences notificationPreferences;
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
    NotificationPreferences? notificationPreferences,
    required this.createdAt,
    required this.updatedAt,
  }) : notificationPreferences = notificationPreferences ?? NotificationPreferences();

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'customer',
      preferredLanguage: json['preferred_language'] as String? ?? 'en',
      notificationPreferences: NotificationPreferences.fromJson(
        json['notification_preferences'] as Map<String, dynamic>?,
      ),
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
      'notification_preferences': notificationPreferences.toJson(),
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
    NotificationPreferences? notificationPreferences,
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
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
