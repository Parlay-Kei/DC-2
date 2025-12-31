import '../config/supabase_config.dart';
import '../models/review.dart';

class ReviewService {
  final _client = SupabaseConfig.client;

  /// Create a review for a completed booking
  Future<Review?> createReview({
    required String bookingId,
    required String barberId,
    required int rating,
    String? comment,
  }) async {
    final customerId = SupabaseConfig.currentUserId;
    if (customerId == null) return null;

    try {
      // Verify the booking exists and is completed
      final booking = await _client
          .from('appointments')
          .select('id, status')
          .eq('id', bookingId)
          .eq('customer_id', customerId)
          .single();

      if (booking['status'] != 'completed') {
        throw Exception('Can only review completed appointments');
      }

      // Check if review already exists
      final existing = await _client
          .from('reviews')
          .select('id')
          .eq('booking_id', bookingId)
          .maybeSingle();

      if (existing != null) {
        throw Exception('Review already exists for this booking');
      }

      // Create the review
      final response = await _client
          .from('reviews')
          .insert({
            'booking_id': bookingId,
            'customer_id': customerId,
            'barber_id': barberId,
            'rating': rating,
            'comment': comment,
          })
          .select()
          .single();

      // Update barber's average rating
      await _updateBarberRating(barberId);

      return Review.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Get reviews for a barber
  Future<List<Review>> getBarberReviews(
    String barberId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('reviews')
          .select('*, profiles:customer_id(full_name, avatar_url)')
          .eq('barber_id', barberId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((r) => Review.fromJson(r)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get reviews by the current user
  Future<List<Review>> getMyReviews() async {
    final customerId = SupabaseConfig.currentUserId;
    if (customerId == null) return [];

    try {
      final response = await _client
          .from('reviews')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      return (response as List).map((r) => Review.fromJson(r)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get review for a specific booking
  Future<Review?> getBookingReview(String bookingId) async {
    try {
      final response = await _client
          .from('reviews')
          .select('*, profiles:customer_id(full_name, avatar_url)')
          .eq('booking_id', bookingId)
          .maybeSingle();

      if (response == null) return null;
      return Review.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Check if user can review a booking
  Future<bool> canReview(String bookingId) async {
    final customerId = SupabaseConfig.currentUserId;
    if (customerId == null) return false;

    try {
      // Check booking status
      final booking = await _client
          .from('appointments')
          .select('status')
          .eq('id', bookingId)
          .eq('customer_id', customerId)
          .maybeSingle();

      if (booking == null || booking['status'] != 'completed') {
        return false;
      }

      // Check if review already exists
      final existing = await _client
          .from('reviews')
          .select('id')
          .eq('booking_id', bookingId)
          .maybeSingle();

      return existing == null;
    } catch (e) {
      return false;
    }
  }

  /// Add barber response to a review
  Future<bool> respondToReview(String reviewId, String response) async {
    final barberId = SupabaseConfig.currentUserId;
    if (barberId == null) return false;

    try {
      await _client
          .from('reviews')
          .update({
            'barber_response': response,
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reviewId)
          .eq('barber_id', barberId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get rating statistics for a barber
  Future<RatingStats> getBarberRatingStats(String barberId) async {
    try {
      final response = await _client
          .from('reviews')
          .select('rating')
          .eq('barber_id', barberId);

      final reviews = response as List;
      if (reviews.isEmpty) {
        return RatingStats.empty();
      }

      final ratings = reviews.map((r) => r['rating'] as int).toList();
      final total = ratings.length;
      final sum = ratings.reduce((a, b) => a + b);
      final average = sum / total;

      // Count by rating
      final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (final rating in ratings) {
        distribution[rating] = (distribution[rating] ?? 0) + 1;
      }

      return RatingStats(
        average: average,
        total: total,
        distribution: distribution,
      );
    } catch (e) {
      return RatingStats.empty();
    }
  }

  /// Update barber's average rating
  Future<void> _updateBarberRating(String barberId) async {
    try {
      final stats = await getBarberRatingStats(barberId);

      await _client.from('barbers').update({
        'rating': stats.average,
        'total_reviews': stats.total,
      }).eq('id', barberId);
    } catch (e) {
      // Ignore errors
    }
  }
}

class RatingStats {
  final double average;
  final int total;
  final Map<int, int> distribution;

  RatingStats({
    required this.average,
    required this.total,
    required this.distribution,
  });

  factory RatingStats.empty() {
    return RatingStats(
      average: 0,
      total: 0,
      distribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
    );
  }

  int get fiveStars => distribution[5] ?? 0;
  int get fourStars => distribution[4] ?? 0;
  int get threeStars => distribution[3] ?? 0;
  int get twoStars => distribution[2] ?? 0;
  int get oneStar => distribution[1] ?? 0;

  double percentageFor(int stars) {
    if (total == 0) return 0;
    return ((distribution[stars] ?? 0) / total) * 100;
  }
}
