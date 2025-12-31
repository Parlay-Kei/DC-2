import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/profile_service.dart';

/// Profile service provider
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

/// Barber profile provider (if user is a barber)
final barberProfileProvider = FutureProvider<BarberProfile?>((ref) async {
  final service = ref.watch(profileServiceProvider);
  return service.getBarberProfile();
});

/// Profile state notifier for updates
class ProfileStateNotifier extends StateNotifier<ProfileState> {
  final ProfileService _service;
  final Ref _ref;

  ProfileStateNotifier(this._service, this._ref)
      : super(ProfileState.initial());

  /// Update basic profile
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? email,
    String? bio,
    String? preferredLanguage,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final profile = await _service.updateProfile(
        fullName: fullName,
        phone: phone,
        email: email,
        bio: bio,
        preferredLanguage: preferredLanguage,
      );

      if (profile == null) {
        state =
            state.copyWith(isLoading: false, error: 'Failed to update profile');
        return false;
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Upload avatar
  Future<String?> uploadAvatar(File file) async {
    state = state.copyWith(isUploadingAvatar: true, error: null);

    try {
      final url = await _service.uploadAvatar(file);

      if (url == null) {
        state = state.copyWith(
          isUploadingAvatar: false,
          error: 'Failed to upload avatar',
        );
        return null;
      }

      state = state.copyWith(isUploadingAvatar: false);
      return url;
    } catch (e) {
      state = state.copyWith(isUploadingAvatar: false, error: e.toString());
      return null;
    }
  }

  /// Delete avatar
  Future<bool> deleteAvatar() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _service.deleteAvatar();

      if (!success) {
        state =
            state.copyWith(isLoading: false, error: 'Failed to delete avatar');
        return false;
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _service.updateNotificationPreferences(
        pushEnabled: pushEnabled,
        emailEnabled: emailEnabled,
        smsEnabled: smsEnabled,
        bookingReminders: bookingReminders,
        promotions: promotions,
        messages: messages,
      );

      if (!success) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update preferences',
        );
        return false;
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Change password
  Future<PasswordChangeResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _service.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      state = state.copyWith(
        isLoading: false,
        error: result.errorMessage,
      );

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return PasswordChangeResult.failed(e.toString());
    }
  }

  /// Request password reset
  Future<bool> requestPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _service.requestPasswordReset(email);
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete account
  Future<AccountDeleteResult> deleteAccount({
    required String password,
    String? reason,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _service.deleteAccount(
        password: password,
        reason: reason,
      );

      state = state.copyWith(
        isLoading: false,
        error: result.errorMessage,
      );

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return AccountDeleteResult.failed(e.toString());
    }
  }

  /// Update barber profile
  Future<bool> updateBarberProfile({
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
    state = state.copyWith(isLoading: true, error: null);

    try {
      final profile = await _service.updateBarberProfile(
        displayName: displayName,
        bio: bio,
        phone: phone,
        isMobile: isMobile,
        travelRadius: travelRadius,
        travelFeePerMile: travelFeePerMile,
        shopAddress: shopAddress,
        shopLatitude: shopLatitude,
        shopLongitude: shopLongitude,
      );

      if (profile == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update barber profile',
        );
        return false;
      }

      state = state.copyWith(isLoading: false);
      _ref.invalidate(barberProfileProvider);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Upload barber profile image
  Future<String?> uploadBarberProfileImage(File file) async {
    state = state.copyWith(isUploadingAvatar: true, error: null);

    try {
      final url = await _service.uploadBarberProfileImage(file);

      if (url == null) {
        state = state.copyWith(
          isUploadingAvatar: false,
          error: 'Failed to upload image',
        );
        return null;
      }

      state = state.copyWith(isUploadingAvatar: false);
      _ref.invalidate(barberProfileProvider);
      return url;
    } catch (e) {
      state = state.copyWith(isUploadingAvatar: false, error: e.toString());
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Profile state
class ProfileState {
  final bool isLoading;
  final bool isUploadingAvatar;
  final String? error;

  ProfileState({
    required this.isLoading,
    required this.isUploadingAvatar,
    this.error,
  });

  factory ProfileState.initial() => ProfileState(
        isLoading: false,
        isUploadingAvatar: false,
      );

  ProfileState copyWith({
    bool? isLoading,
    bool? isUploadingAvatar,
    String? error,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      error: error,
    );
  }
}

/// Profile state provider
final profileStateProvider =
    StateNotifierProvider<ProfileStateNotifier, ProfileState>((ref) {
  final service = ref.watch(profileServiceProvider);
  return ProfileStateNotifier(service, ref);
});
