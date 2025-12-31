import '../config/supabase_config.dart';
import '../models/barber.dart';

class FavoritesService {
  final _client = SupabaseConfig.client;

  /// Get user's favorite barbers
  Future<List<Barber>> getFavorites() async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('user_favorites')
          .select('barber_id, barbers(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .where((f) => f['barbers'] != null)
          .map((f) => Barber.fromJson(f['barbers'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if a barber is favorited
  Future<bool> isFavorite(String barberId) async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return false;

    try {
      final response = await _client
          .from('user_favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('barber_id', barberId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Add barber to favorites
  Future<bool> addFavorite(String barberId) async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return false;

    try {
      await _client.from('user_favorites').insert({
        'user_id': userId,
        'barber_id': barberId,
      });
      return true;
    } catch (e) {
      // Might fail if already favorited (unique constraint)
      return false;
    }
  }

  /// Remove barber from favorites
  Future<bool> removeFavorite(String barberId) async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return false;

    try {
      await _client
          .from('user_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('barber_id', barberId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String barberId) async {
    final isFav = await isFavorite(barberId);
    if (isFav) {
      return removeFavorite(barberId);
    } else {
      return addFavorite(barberId);
    }
  }

  /// Get favorite count for a barber
  Future<int> getFavoriteCount(String barberId) async {
    try {
      final response = await _client
          .from('user_favorites')
          .select('id')
          .eq('barber_id', barberId);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get user's favorite barber IDs (for quick lookup)
  Future<Set<String>> getFavoriteIds() async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return {};

    try {
      final response = await _client
          .from('user_favorites')
          .select('barber_id')
          .eq('user_id', userId);

      return (response as List).map((f) => f['barber_id'] as String).toSet();
    } catch (e) {
      return {};
    }
  }
}
