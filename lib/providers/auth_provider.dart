import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/profile.dart';

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
    print('DEBUG: Querying profiles table for id: $userId');
    final response = await SupabaseConfig.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    print('DEBUG: Raw profile response: $response');
    return Profile.fromJson(response);
  } catch (e) {
    print('DEBUG: Profile query error: $e');
    return null;
  }
});

// Current user's profile - try getting from auth metadata first
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    print('DEBUG: No current user found');
    return null;
  }
  
  print('DEBUG: User ID: ${user.id}');
  print('DEBUG: User email: ${user.email}');
  print('DEBUG: User metadata: ${user.userMetadata}');
  
  // Try to build profile from auth metadata first
  final metadata = user.userMetadata;
  if (metadata != null && metadata.isNotEmpty) {
    final fullName = metadata['full_name'] as String? ?? metadata['name'] as String?;
    if (fullName != null && fullName.isNotEmpty) {
      print('DEBUG: Building profile from auth metadata: $fullName');
      return Profile(
        id: user.id,
        fullName: fullName,
        email: user.email,
        avatarUrl: metadata['avatar_url'] as String? ?? metadata['picture'] as String?,
        phone: metadata['phone'] as String?,
        role: metadata['role'] as String? ?? 'customer',
        createdAt: user.createdAt != null ? DateTime.parse(user.createdAt!) : DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }
  
  // Fallback: try database query
  print('DEBUG: Trying database query for profile');
  try {
    final profile = await ref.watch(userProfileProvider(user.id).future);
    print('DEBUG: Profile from DB: ${profile?.fullName}');
    return profile;
  } catch (e) {
    print('DEBUG: Profile fetch error: $e');
    // Return minimal profile from auth
    return Profile(
      id: user.id,
      email: user.email,
      role: 'customer',
      createdAt: user.createdAt != null ? DateTime.parse(user.createdAt!) : DateTime.now(),
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
