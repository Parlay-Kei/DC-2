import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/barber.dart';
import '../models/service.dart';
import '../models/review.dart';

final barberServiceProvider = Provider((ref) => BarberService());

class BarberService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Get a single barber by ID with user profile data
  Future<Barber?> getBarber(String barberId) async {
    try {
      // 1. Fetch barber
      final barberResponse = await _client
          .from('barbers')
          .select('*')
          .eq('id', barberId)
          .single();

      // 2. Fetch user profile separately
      final userResponse = await _client
          .from('users')
          .select('id, full_name, avatar_url')
          .eq('id', barberId)
          .maybeSingle();

      // 3. Fetch rating from reviews
      final rating = await _getBarberRating(barberId);

      return _mapToBarber(barberResponse, userResponse, rating);
    } catch (e) {
      debugPrint('Error getting barber $barberId: $e');
      return null;
    }
  }

  /// Get all active barbers with user names
  Future<List<Barber>> getActiveBarbers({int limit = 50}) async {
    try {
      // 1. Fetch barbers
      final barbersResponse = await _client
          .from('barbers')
          .select('*')
          .eq('is_active', true)
          .limit(limit);

      final barbers = barbersResponse as List;
      if (barbers.isEmpty) return [];

      // 2. Fetch user profiles for all barbers
      final userIds = barbers.map((b) => b['id'] as String).toList();
      final usersResponse = await _client
          .from('users')
          .select('id, full_name, avatar_url')
          .inFilter('id', userIds);

      // 3. Fetch ratings for all barbers
      final ratingsMap = await _getBarbersRatings(userIds);

      // 4. Create user lookup map
      final userMap = <String, Map<String, dynamic>>{};
      for (final user in usersResponse as List) {
        userMap[user['id'] as String] = user;
      }

      // 5. Map and return
      return barbers.map((barber) {
        final user = userMap[barber['id']];
        final rating = ratingsMap[barber['id']];
        return _mapToBarber(barber, user, rating);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching active barbers: $e');
      return [];
    }
  }

  /// Search barbers by name or shop name
  Future<List<Barber>> searchBarbers(String query) async {
    try {
      // 1. Fetch all active barbers
      final barbersResponse = await _client
          .from('barbers')
          .select('*')
          .eq('is_active', true);

      final barbers = barbersResponse as List;
      if (barbers.isEmpty) return [];

      // 2. Fetch user profiles
      final userIds = barbers.map((b) => b['id'] as String).toList();
      final usersResponse = await _client
          .from('users')
          .select('id, full_name, avatar_url')
          .inFilter('id', userIds);

      // 3. Create user lookup map
      final userMap = <String, Map<String, dynamic>>{};
      for (final user in usersResponse as List) {
        userMap[user['id'] as String] = user;
      }

      // 4. Filter by query
      final lowerQuery = query.toLowerCase();
      final filteredBarbers = barbers.where((barber) {
        final user = userMap[barber['id']];
        final shopName = (barber['shop_name'] as String? ?? '').toLowerCase();
        final location = (barber['location'] as String? ?? '').toLowerCase();
        final userName = (user?['full_name'] as String? ?? '').toLowerCase();
        
        return shopName.contains(lowerQuery) ||
               location.contains(lowerQuery) ||
               userName.contains(lowerQuery);
      }).toList();

      if (filteredBarbers.isEmpty) return [];

      // 5. Fetch ratings for filtered barbers
      final filteredIds = filteredBarbers.map((b) => b['id'] as String).toList();
      final ratingsMap = await _getBarbersRatings(filteredIds);

      return filteredBarbers.map((barber) {
        final user = userMap[barber['id']];
        final rating = ratingsMap[barber['id']];
        return _mapToBarber(barber, user, rating);
      }).toList();
    } catch (e) {
      debugPrint('Error searching barbers: $e');
      return [];
    }
  }

  /// Get barbers near a location
  Future<List<BarberWithDistance>> getNearbyBarbers({
    required double latitude,
    required double longitude,
    double radiusMiles = 25,
    int limit = 50,
  }) async {
    try {
      debugPrint('BarberService.getNearbyBarbers: Searching near ($latitude, $longitude)');

      // Calculate bounding box for geographic query
      final latDelta = radiusMiles / 69;
      final lngDelta = radiusMiles / (69 * cos(latitude * pi / 180));

      final minLat = latitude - latDelta;
      final maxLat = latitude + latDelta;
      final minLng = longitude - lngDelta;
      final maxLng = longitude + lngDelta;

      debugPrint('BarberService: Bounding box: lat($minLat to $maxLat), lng($minLng to $maxLng)');

      // 1. Fetch barbers within bounding box
      final barbersResponse = await _client
          .from('barbers')
          .select('*')
          .eq('is_active', true)
          .not('latitude', 'is', null)
          .not('longitude', 'is', null)
          .gte('latitude', minLat)
          .lte('latitude', maxLat)
          .gte('longitude', minLng)
          .lte('longitude', maxLng);

      final barbers = barbersResponse as List;
      debugPrint('BarberService: Found ${barbers.length} barbers in bounding box');

      if (barbers.isEmpty) return [];

      // 2. Fetch user profiles
      final userIds = barbers.map((b) => b['id'] as String).toList();
      final usersResponse = await _client
          .from('users')
          .select('id, full_name, avatar_url')
          .inFilter('id', userIds);

      // 3. Create user lookup map
      final userMap = <String, Map<String, dynamic>>{};
      for (final user in usersResponse as List) {
        userMap[user['id'] as String] = user;
      }

      // 4. Fetch ratings
      final ratingsMap = await _getBarbersRatings(userIds);

      // 5. Map, calculate distances, filter by exact radius
      final results = <BarberWithDistance>[];
      
      for (final barberData in barbers) {
        final barberLat = (barberData['latitude'] as num).toDouble();
        final barberLng = (barberData['longitude'] as num).toDouble();
        
        final distance = _calculateDistance(latitude, longitude, barberLat, barberLng);
        
        if (distance <= radiusMiles) {
          final user = userMap[barberData['id']];
          final rating = ratingsMap[barberData['id']];
          final barber = _mapToBarber(barberData, user, rating);
          results.add(BarberWithDistance(barber: barber, distanceMiles: distance));
        }
      }

      // 6. Sort by distance
      results.sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));

      debugPrint('BarberService: Returning ${results.length} barbers within $radiusMiles miles');
      return results.take(limit).toList();
    } catch (e) {
      debugPrint('Error fetching nearby barbers: $e');
      return [];
    }
  }

  /// Get top rated barbers
  Future<List<Barber>> getTopRatedBarbers({int limit = 10}) async {
    try {
      // Get active barbers (we'll sort by rating after fetching)
      final barbersResponse = await _client
          .from('barbers')
          .select('*')
          .eq('is_active', true)
          .eq('is_verified', true)
          .limit(limit);

      final barbers = barbersResponse as List;
      if (barbers.isEmpty) return [];

      final userIds = barbers.map((b) => b['id'] as String).toList();
      final usersResponse = await _client
          .from('users')
          .select('id, full_name, avatar_url')
          .inFilter('id', userIds);

      final userMap = <String, Map<String, dynamic>>{};
      for (final user in usersResponse as List) {
        userMap[user['id'] as String] = user;
      }

      final ratingsMap = await _getBarbersRatings(userIds);

      final results = barbers.map((barber) {
        final user = userMap[barber['id']];
        final rating = ratingsMap[barber['id']];
        return _mapToBarber(barber, user, rating);
      }).toList();

      // Sort by rating descending
      results.sort((a, b) => b.rating.compareTo(a.rating));
      
      return results;
    } catch (e) {
      debugPrint('Error fetching top rated barbers: $e');
      return [];
    }
  }

  /// Get featured barbers (verified)
  Future<List<Barber>> getFeaturedBarbers({int limit = 5}) async {
    try {
      final barbersResponse = await _client
          .from('barbers')
          .select('*')
          .eq('is_active', true)
          .eq('is_verified', true)
          .limit(limit);

      final barbers = barbersResponse as List;
      if (barbers.isEmpty) return [];

      final userIds = barbers.map((b) => b['id'] as String).toList();
      final usersResponse = await _client
          .from('users')
          .select('id, full_name, avatar_url')
          .inFilter('id', userIds);

      final userMap = <String, Map<String, dynamic>>{};
      for (final user in usersResponse as List) {
        userMap[user['id'] as String] = user;
      }

      final ratingsMap = await _getBarbersRatings(userIds);

      return barbers.map((barber) {
        final user = userMap[barber['id']];
        final rating = ratingsMap[barber['id']];
        return _mapToBarber(barber, user, rating);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching featured barbers: $e');
      return [];
    }
  }

  /// Get services offered by a barber
  Future<List<Service>> getBarberServices(String barberId) async {
    try {
      final response = await _client
          .from('services')
          .select('*')
          .eq('barber_id', barberId)
          .eq('is_active', true)
          .order('sort_order');

      return (response as List).map((s) => Service.fromJson(s)).toList();
    } catch (e) {
      debugPrint('Error fetching barber services: $e');
      return [];
    }
  }

  /// Get reviews for a barber
  Future<List<Review>> getBarberReviews(String barberId) async {
    try {
      final response = await _client
          .from('reviews')
          .select('*')
          .eq('barber_id', barberId)
          .order('created_at', ascending: false);

      return (response as List).map((r) => Review.fromJson(r)).toList();
    } catch (e) {
      debugPrint('Error fetching barber reviews: $e');
      return [];
    }
  }

  /// Get portfolio images for a barber
  Future<List<String>> getBarberPortfolio(String barberId) async {
    try {
      final response = await _client
          .from('portfolio_images')
          .select('image_url')
          .eq('barber_id', barberId)
          .order('sort_order');

      return (response as List)
          .map((item) => item['image_url'] as String)
          .toList();
    } catch (e) {
      debugPrint('Error fetching barber portfolio: $e');
      return [];
    }
  }

  // === Private helpers ===

  /// Get rating for a single barber
  Future<Map<String, double>> _getBarberRating(String barberId) async {
    try {
      final response = await _client
          .from('reviews')
          .select('rating')
          .eq('barber_id', barberId);

      final reviews = response as List;
      if (reviews.isEmpty) {
        return {'averageRating': 0, 'totalReviews': 0};
      }

      final total = reviews.fold<double>(0, (sum, r) => sum + (r['rating'] as num).toDouble());
      return {
        'averageRating': total / reviews.length,
        'totalReviews': reviews.length.toDouble(),
      };
    } catch (e) {
      return {'averageRating': 0, 'totalReviews': 0};
    }
  }

  /// Get ratings for multiple barbers
  Future<Map<String, Map<String, double>>> _getBarbersRatings(List<String> barberIds) async {
    final Map<String, Map<String, double>> ratingsMap = {};
    
    if (barberIds.isEmpty) return ratingsMap;

    try {
      final response = await _client
          .from('reviews')
          .select('barber_id, rating')
          .inFilter('barber_id', barberIds);

      final reviews = response as List;
      
      // Group reviews by barber_id
      final Map<String, List<double>> reviewsByBarber = {};
      for (final review in reviews) {
        final barberId = review['barber_id'] as String;
        final rating = (review['rating'] as num).toDouble();
        reviewsByBarber.putIfAbsent(barberId, () => []).add(rating);
      }

      // Calculate averages
      for (final barberId in barberIds) {
        final ratings = reviewsByBarber[barberId] ?? [];
        if (ratings.isEmpty) {
          ratingsMap[barberId] = {'averageRating': 0, 'totalReviews': 0};
        } else {
          final avg = ratings.reduce((a, b) => a + b) / ratings.length;
          ratingsMap[barberId] = {
            'averageRating': avg,
            'totalReviews': ratings.length.toDouble(),
          };
        }
      }
    } catch (e) {
      debugPrint('Error fetching ratings: $e');
      // Return empty ratings for all
      for (final barberId in barberIds) {
        ratingsMap[barberId] = {'averageRating': 0, 'totalReviews': 0};
      }
    }

    return ratingsMap;
  }

  /// Map database row to Barber model
  Barber _mapToBarber(
    Map<String, dynamic> barberData,
    Map<String, dynamic>? userData,
    Map<String, double>? rating,
  ) {
    return Barber(
      id: barberData['id'] as String,
      visibleName: userData?['full_name'] as String?,
      bio: barberData['bio'] as String?,
      profileImageUrl: userData?['avatar_url'] as String?,
      shopName: barberData['shop_name'] as String?,
      shopAddress: barberData['shop_address'] as String?,
      location: barberData['location'] as String?,
      latitude: (barberData['latitude'] as num?)?.toDouble(),
      longitude: (barberData['longitude'] as num?)?.toDouble(),
      serviceRadiusMiles: barberData['service_radius_miles'] as int? ?? 10,
      isMobile: barberData['is_mobile'] as bool? ?? false,
      offersHomeService: barberData['offers_home_service'] as bool? ?? false,
      travelFeePerMile: (barberData['travel_fee_per_mile'] as num?)?.toDouble(),
      travelFee: (barberData['travel_fee'] as num?)?.toDouble(),
      isVerified: barberData['is_verified'] as bool? ?? false,
      isActive: barberData['is_active'] as bool? ?? true,
      rating: rating?['averageRating'] ?? 0,
      totalReviews: (rating?['totalReviews'] ?? 0).toInt(),
      stripeAccountId: barberData['stripe_account_id'] as String?,
      stripeOnboardingComplete: barberData['stripe_onboarding_complete'] as bool? ?? false,
      onboardingComplete: barberData['onboarding_complete'] as bool? ?? false,
      subscriptionTier: barberData['subscription_tier'] as String? ?? 'free',
      createdAt: barberData['created_at'] != null
          ? DateTime.parse(barberData['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusMiles = 3959.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusMiles * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;
}

/// Barber with calculated distance
class BarberWithDistance {
  final Barber barber;
  final double distanceMiles;

  BarberWithDistance({required this.barber, required this.distanceMiles});

  String get formattedDistance {
    if (distanceMiles < 0.1) return '< 0.1 mi';
    return '${distanceMiles.toStringAsFixed(1)} mi';
  }
}
