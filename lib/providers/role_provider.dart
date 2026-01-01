import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../utils/logger.dart';

/// Result of a role update operation
class RoleUpdateResult {
  final bool success;
  final String? errorMessage;

  const RoleUpdateResult.success() : success = true, errorMessage = null;
  const RoleUpdateResult.failure(this.errorMessage) : success = false;
}

/// Provider for the role service
final roleServiceProvider = Provider<RoleService>((ref) {
  return RoleService();
});

/// Service for managing user role selection and updates
class RoleService {
  final _client = SupabaseConfig.client;

  /// Update the user's role in the profile
  /// Returns a RoleUpdateResult with success status and error message if failed
  Future<RoleUpdateResult> updateUserRole(String role) async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) {
      Logger.error('Update role failed', 'No user ID found');
      return const RoleUpdateResult.failure(
        'You must be logged in to select a role. Please log in and try again.',
      );
    }

    // Validate role
    if (role != 'customer' && role != 'barber' && role != 'admin') {
      Logger.error('Update role failed', 'Invalid role: $role');
      return const RoleUpdateResult.failure('Invalid role selected.');
    }

    try {
      Logger.debug('Updating user role to: $role for user: $userId');

      // Update the role in the profiles table
      // Note: Requires RLS policy "profiles_update_own" on profiles table
      await _client
          .from('profiles')
          .update({
            'role': role,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // CRITICAL: Re-fetch to verify the update actually persisted
      // RLS policies can silently block updates, so we must verify
      final verifyResponse = await _client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();

      final persistedRole = verifyResponse['role'] as String?;
      if (persistedRole != role) {
        Logger.error(
          'Role update verification failed',
          'Expected role=$role but database has role=$persistedRole. '
              'This usually means RLS policies are blocking the update.',
        );
        return const RoleUpdateResult.failure(
          'Role setup failed. The server rejected the update. '
              'Please contact support if this persists.',
        );
      }

      // Also update the user metadata for quick access
      await _client.auth.updateUser(
        UserAttributes(
          data: {'role': role},
        ),
      );

      Logger.debug('Role updated and verified successfully: $role');
      return const RoleUpdateResult.success();
    } on PostgrestException catch (e) {
      // Specific handling for Supabase/Postgres errors
      Logger.error(
        'Role update database error',
        'Code: ${e.code}, Message: ${e.message}, Details: ${e.details}',
      );

      // Check for common RLS-related error codes
      if (e.code == '42501' || e.code == 'PGRST301') {
        return const RoleUpdateResult.failure(
          'Role setup failed. Permission denied by server. '
              'Please contact support.',
        );
      }

      return RoleUpdateResult.failure(
        'Role setup failed: ${e.message}. Please try again.',
      );
    } catch (e) {
      Logger.error('Update role error', e);
      return const RoleUpdateResult.failure(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Get the current user's role from profile
  Future<String?> getCurrentUserRole() async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();

      return response['role'] as String?;
    } catch (e) {
      Logger.error('Get role error', e);
      return null;
    }
  }
}
