import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/profile.dart';
import '../utils/logger.dart';

/// Service for managing user profiles
class ProfileService {
  final _client = SupabaseConfig.client;

  /// Get current user's profile
  Future<Profile?> getCurrentProfile() async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return null;

    try {
      final response =
          await _client.from('profiles').select().eq('id', userId).single();

      return Profile.fromJson(response);
    } catch (e) {
      Logger.error('Get profile error', e);
      return null;
    }
  }

  /// Update profile information
  Future<Profile?> updateProfile({
    String? fullName,
    String? phone,
    String? email,
    String? bio,
    String? preferredLanguage,
    Map<String, dynamic>? notificationPreferences,
  }) async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return null;

    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (email != null) updates['email'] = email;
      if (bio != null) updates['bio'] = bio;
      if (preferredLanguage != null)
        updates['preferred_language'] = preferredLanguage;
      if (notificationPreferences != null) {
        updates['notification_preferences'] = notificationPreferences;
      }

      final response = await _client
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return Profile.fromJson(response);
    } catch (e) {
      Logger.error('Update profile error', e);
      return null;
    }
  }

  /// Upload avatar from File
  Future<String?> uploadAvatar(File file) async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return null;

    try {
      final ext = file.path.split('.').last;
      final filename =
          '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _client.storage
          .from('avatars')
          .upload(filename, file, fileOptions: const FileOptions(upsert: true));

      final avatarUrl = _client.storage.from('avatars').getPublicUrl(filename);

      // Update profile with new avatar URL
      await _client
          .from('profiles')
          .update({'avatar_url': avatarUrl}).eq('id', userId);

      return avatarUrl;
    } catch (e) {
      Logger.error('Upload avatar error', e);
      return null;
    }
  }

  /// Upload avatar from bytes (for web)
  Future<String?> uploadAvatarFromBytes(
      Uint8List bytes, String filename) async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return null;

    try {
      final ext = filename.split('.').last;
      final path =
          '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _client.storage.from('avatars').uploadBinary(path, bytes,
          fileOptions: const FileOptions(upsert: true));

      final avatarUrl = _client.storage.from('avatars').getPublicUrl(path);

      // Update profile with new avatar URL
      await _client
          .from('profiles')
          .update({'avatar_url': avatarUrl}).eq('id', userId);

      return avatarUrl;
    } catch (e) {
      Logger.error('Upload avatar error', e);
      return null;
    }
  }

  /// Delete current avatar
  Future<bool> deleteAvatar() async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return false;

    try {
      // Get current profile to find avatar path
      final profile = await getCurrentProfile();
      if (profile?.avatarUrl != null) {
        // Extract path from URL and delete
        final url = profile!.avatarUrl!;
        final pathMatch = RegExp(r'avatars/(.+)').firstMatch(url);
        if (pathMatch != null) {
          await _client.storage.from('avatars').remove([pathMatch.group(1)!]);
        }
      }

      // Clear avatar URL in profile
      await _client
          .from('profiles')
          .update({'avatar_url': null}).eq('id', userId);

      return true;
    } catch (e) {
      Logger.error('Delete avatar error', e);
      return false;
    }
  }

  /// Update notification preferences
  Future<bool> updateNotificationPreferences({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    bool? bookingReminders,
    bool? promotions,
    bool? messages,
  }) async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return false;

    try {
      final profile = await getCurrentProfile();
      final currentPrefs =
          profile?.notificationPreferences.toJson() ?? <String, dynamic>{};

      final newPrefs = {
        ...currentPrefs,
        if (pushEnabled != null) 'push_enabled': pushEnabled,
        if (emailEnabled != null) 'email_enabled': emailEnabled,
        if (smsEnabled != null) 'sms_enabled': smsEnabled,
        if (bookingReminders != null) 'booking_reminders': bookingReminders,
        if (promotions != null) 'promotions': promotions,
        if (messages != null) 'messages': messages,
      };

      await _client
          .from('profiles')
          .update({'notification_preferences': newPrefs}).eq('id', userId);

      return true;
    } catch (e) {
      Logger.error('Update notification prefs error', e);
      return false;
    }
  }

  /// Change password
  Future<PasswordChangeResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Verify current password by re-authenticating
      final email = _client.auth.currentUser?.email;
      if (email == null) {
        return PasswordChangeResult.failed('No email found');
      }

      // Try to sign in with current password
      try {
        await _client.auth.signInWithPassword(
          email: email,
          password: currentPassword,
        );
      } catch (e) {
        return PasswordChangeResult.failed('Current password is incorrect');
      }

      // Update password
      await _client.auth.updateUser(UserAttributes(password: newPassword));

      return PasswordChangeResult.success();
    } on AuthException catch (e) {
      return PasswordChangeResult.failed(e.message);
    } catch (e) {
      return PasswordChangeResult.failed(e.toString());
    }
  }

  /// Request password reset email
  Future<bool> requestPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      Logger.error('Password reset error', e);
      return false;
    }
  }

  /// Delete account
  Future<AccountDeleteResult> deleteAccount({
    required String password,
    String? reason,
  }) async {
    try {
      final email = _client.auth.currentUser?.email;
      if (email == null) {
        return AccountDeleteResult.failed('No email found');
      }

      // Verify password
      try {
        await _client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        return AccountDeleteResult.failed('Password is incorrect');
      }

      // Call Edge Function to handle deletion
      final response = await _client.functions.invoke(
        'delete-account',
        body: {
          'reason': reason,
        },
      );

      if (response.status != 200) {
        return AccountDeleteResult.failed(
          response.data['error'] ?? 'Failed to delete account',
        );
      }

      // Sign out
      await _client.auth.signOut();

      return AccountDeleteResult.success();
    } catch (e) {
      return AccountDeleteResult.failed(e.toString());
    }
  }

  /// Get barber-specific profile (if user is a barber)
  Future<BarberProfile?> getBarberProfile() async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('barber_profiles')
          .select()
          .eq('id', userId)
          .single();

      return BarberProfile.fromJson(response);
    } catch (e) {
      Logger.error('Get barber profile error', e);
      return null;
    }
  }

  /// Update barber-specific profile
  Future<BarberProfile?> updateBarberProfile({
    String? displayName,
    String? bio,
    String? phone,
    bool? isMobile,
    double? travelRadius,
    double? travelFeePerMile,
    String? shopAddress,
    double? shopLatitude,
    double? shopLongitude,
  }) async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return null;

    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (displayName != null) updates['display_name'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (phone != null) updates['phone'] = phone;
      if (isMobile != null) updates['is_mobile'] = isMobile;
      if (travelRadius != null) updates['travel_radius'] = travelRadius;
      if (travelFeePerMile != null)
        updates['travel_fee_per_mile'] = travelFeePerMile;
      if (shopAddress != null) updates['shop_address'] = shopAddress;
      if (shopLatitude != null) updates['shop_latitude'] = shopLatitude;
      if (shopLongitude != null) updates['shop_longitude'] = shopLongitude;

      final response = await _client
          .from('barber_profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return BarberProfile.fromJson(response);
    } catch (e) {
      Logger.error('Update barber profile error', e);
      return null;
    }
  }

  /// Upload barber profile image
  Future<String?> uploadBarberProfileImage(File file) async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return null;

    try {
      final ext = file.path.split('.').last;
      final filename =
          '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _client.storage
          .from('barber-images')
          .upload(filename, file, fileOptions: const FileOptions(upsert: true));

      final imageUrl =
          _client.storage.from('barber-images').getPublicUrl(filename);

      // Update barber profile with new image URL
      await _client
          .from('barber_profiles')
          .update({'profile_image_url': imageUrl}).eq('id', userId);

      return imageUrl;
    } catch (e) {
      Logger.error('Upload barber image error', e);
      return null;
    }
  }
}

/// Result from password change
class PasswordChangeResult {
  final bool isSuccess;
  final String? errorMessage;

  PasswordChangeResult._({required this.isSuccess, this.errorMessage});

  factory PasswordChangeResult.success() =>
      PasswordChangeResult._(isSuccess: true);

  factory PasswordChangeResult.failed(String message) =>
      PasswordChangeResult._(isSuccess: false, errorMessage: message);
}

/// Result from account deletion
class AccountDeleteResult {
  final bool isSuccess;
  final String? errorMessage;

  AccountDeleteResult._({required this.isSuccess, this.errorMessage});

  factory AccountDeleteResult.success() =>
      AccountDeleteResult._(isSuccess: true);

  factory AccountDeleteResult.failed(String message) =>
      AccountDeleteResult._(isSuccess: false, errorMessage: message);
}

/// Barber-specific profile model
class BarberProfile {
  final String id;
  final String? displayName;
  final String? bio;
  final String? phone;
  final String? profileImageUrl;
  final bool isMobile;
  final double? travelRadius;
  final double? travelFeePerMile;
  final String? shopAddress;
  final double? shopLatitude;
  final double? shopLongitude;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BarberProfile({
    required this.id,
    this.displayName,
    this.bio,
    this.phone,
    this.profileImageUrl,
    this.isMobile = false,
    this.travelRadius,
    this.travelFeePerMile,
    this.shopAddress,
    this.shopLatitude,
    this.shopLongitude,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isVerified = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory BarberProfile.fromJson(Map<String, dynamic> json) {
    return BarberProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      bio: json['bio'] as String?,
      phone: json['phone'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      isMobile: json['is_mobile'] as bool? ?? false,
      travelRadius: (json['travel_radius'] as num?)?.toDouble(),
      travelFeePerMile: (json['travel_fee_per_mile'] as num?)?.toDouble(),
      shopAddress: json['shop_address'] as String?,
      shopLatitude: (json['shop_latitude'] as num?)?.toDouble(),
      shopLongitude: (json['shop_longitude'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
