import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/profile.dart';
import '../utils/logger.dart';

// Startup state class
class StartupState {
  final bool hasSeenWelcome;
  final User? user;
  final Profile? profile;

  StartupState({
    required this.hasSeenWelcome,
    this.user,
    this.profile,
  });

  bool get hasSession => user != null;
  String? get role => profile?.role;

  StartupState copyWith({
    bool? hasSeenWelcome,
    User? user,
    Profile? profile,
  }) {
    return StartupState(
      hasSeenWelcome: hasSeenWelcome ?? this.hasSeenWelcome,
      user: user ?? this.user,
      profile: profile ?? this.profile,
    );
  }
}

// Shared preferences provider
final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// Has seen welcome flag provider
final hasSeenWelcomeProvider = FutureProvider<bool>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return prefs.getBool('hasSeenWelcome') ?? false;
});

// Startup provider - combines all startup data
final appStartupProvider = FutureProvider<StartupState>((ref) async {
  try {
    // Load SharedPreferences flag
    final hasSeenWelcome = await ref.watch(hasSeenWelcomeProvider.future);

    // Get current auth session
    final session = SupabaseConfig.client.auth.currentSession;
    final user = session?.user;

    // If no user, return early
    if (user == null) {
      Logger.debug('No authenticated user found');
      return StartupState(
        hasSeenWelcome: hasSeenWelcome,
        user: null,
        profile: null,
      );
    }

    Logger.debug('User authenticated, loading profile');

    // Try to get profile from auth metadata first
    Profile? profile;
    final metadata = user.userMetadata;

    if (metadata != null && metadata.isNotEmpty) {
      final fullName =
          metadata['full_name'] as String? ?? metadata['name'] as String?;
      if (fullName != null && fullName.isNotEmpty) {
        Logger.debug('Building profile from auth metadata');
        profile = Profile(
          id: user.id,
          fullName: fullName,
          email: user.email,
          avatarUrl: metadata['avatar_url'] as String? ??
              metadata['picture'] as String?,
          phone: metadata['phone'] as String?,
          role: metadata['role'] as String? ?? 'customer',
          createdAt: DateTime.parse(user.createdAt),
          updatedAt: DateTime.now(),
        );
      }
    }

    // Fallback: try database query
    if (profile == null) {
      Logger.debug('Fetching profile from database');
      try {
        final response = await SupabaseConfig.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();
        profile = Profile.fromJson(response);
        Logger.debug('Profile loaded from database');
      } catch (e) {
        Logger.error('Profile fetch failed', e);
        // Return minimal profile from auth
        profile = Profile(
          id: user.id,
          email: user.email,
          role: 'customer',
          createdAt: DateTime.parse(user.createdAt),
          updatedAt: DateTime.now(),
        );
      }
    }

    return StartupState(
      hasSeenWelcome: hasSeenWelcome,
      user: user,
      profile: profile,
    );
  } catch (e) {
    Logger.error('Startup provider error', e);
    // Return safe default state
    return StartupState(
      hasSeenWelcome: false,
      user: null,
      profile: null,
    );
  }
});

// Service to update welcome flag
class StartupService {
  static Future<void> markWelcomeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcome', true);
    Logger.debug('Welcome screen marked as seen');
  }
}
