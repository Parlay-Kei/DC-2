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
final userProfileProvider = FutureProvider.family<Profile?, String>((ref, userId) async {
  try {
    final response = await SupabaseConfig.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return Profile.fromJson(response);
  } catch (e) {
    return null;
  }
});

// Current user's profile
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  
  return ref.watch(userProfileProvider(user.id).future);
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
