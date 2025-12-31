import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/profile.dart';
import '../utils/logger.dart';

// Auth state stream provider
final authStateProvider = StreamProvider<User?>((ref) {
  return SupabaseConfig.client.auth.onAuthStateChange.map(
    (event) => event.session?.user,
  );
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

// User profile provider
final userProfileProvider =
    FutureProvider.family<Profile?, String>((ref, userId) async {
  try {
    Logger.debug('Querying profiles table');
    final response = await SupabaseConfig.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    Logger.debug('Profile query completed');
    return Profile.fromJson(response);
  } catch (e) {
    Logger.error('Profile query failed', e);
    return null;
  }
});

// Current user's profile - try getting from auth metadata first
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    Logger.debug('No current user found');
    return null;
  }

  Logger.debug('Current user authenticated');

  // Try to build profile from auth metadata first
  final metadata = user.userMetadata;
  if (metadata != null && metadata.isNotEmpty) {
    final fullName = metadata['full_name'] as String? ?? metadata['name'] as String?;
    if (fullName != null && fullName.isNotEmpty) {
      Logger.debug('Building profile from auth metadata');
      return Profile(
        id: user.id,
        fullName: fullName,
        email: user.email,
        avatarUrl: metadata['avatar_url'] as String? ?? metadata['picture'] as String?,
        phone: metadata['phone'] as String?,
        role: metadata['role'] as String? ?? 'customer',
        createdAt: DateTime.parse(user.createdAt!),
        updatedAt: DateTime.now(),
      );
    }
  }

  // Fallback: try database query
  Logger.debug('Fetching profile from database');
  try {
    final profile = await ref.watch(userProfileProvider(user.id).future);
    Logger.debug('Profile loaded from database');
    return profile;
  } catch (e) {
    Logger.error('Profile fetch failed', e);
    // Return minimal profile from auth
    return Profile(
      id: user.id,
      email: user.email,
      role: 'customer',
      createdAt: DateTime.parse(user.createdAt!),
      updatedAt: DateTime.now(),
    );
  }
});

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  final _client = SupabaseConfig.client;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role,
      },
    );
    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
