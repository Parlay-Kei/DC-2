import 'dart:math';


import '../config/supabase_config.dart';
import '../models/barber.dart';
import '../models/service.dart';
import '../models/review.dart';

class BarberService {
  final _client = SupabaseConfig.client;

  /// Get a single barber by ID with profile data
  Future<Barber?> getBarber(String barberId) async {
    try {
      final response = await _client
          .from('barbers')
          .select('*, profiles:id(full_name, avatar_url)')
          .eq('id', barberId)
          .single();

      return Barber.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Get all active barbers
  Future<List<Barber>> getActiveBarbers({int limit = 50}) async {
    try {
      final response = await _client
          .from('barbers')
          .select()
          .eq('is_active', true)
          .order('rating', ascending: false)
          .limit(limit);

      return (response as List).map((b) => Barber.fromJson(b)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Search barbers by name or shop name
  Future<List<Barber>> searchBarbers(String query) async {
    try {
      final response = await _client
          .from('barbers')
          .select()
          .eq('is_active', true)
          .or('display_name.ilike.%$query%,shop_name.ilike.%$query%')
          .order('rating', ascending: false)
          .limit(20);

      return (response as List).map((b) => Barber.fromJson(b)).toList();
    } catch (e) {
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
      // Get all active barbers with location
      final response = await _client
          .from('barbers')
          .select()
          .eq('is_active', true)
          .not('latitude', 'is', null)
          .not('longitude', 'is', null);

      final barbers = (response as List).map((b) => Barber.fromJson(b)).toList();

      // Calculate distance and filter
      final barbersWithDistance = barbers
          .map((barber) {
            final distance = _calculateDistance(
              latitude,
              longitude,
              barber.latitude!,
              barber.longitude!,
            );
            return BarberWithDistance(barber: barber, distanceMiles: distance);
          })
          .where((b) => b.distanceMiles <= radiusMiles)
          .toList();

      // Sort by distance
      barbersWithDistance.sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));

      return barbersWithDistance.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get top-rated barbers
  Future<List<Barber>> getTopRatedBarbers({int limit = 10}) async {
    try {
      final response = await _client
          .from('barbers')
          .select()
          .eq('is_active', true)
          .gte('total_reviews', 3) // At least 3 reviews
          .order('rating', ascending: false)
          .limit(limit);

      return (response as List).map((b) => Barber.fromJson(b)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get barber's services
  Future<List<Service>> getBarberServices(String barberId) async {
    try {
      final response = await _client
          .from('barber_services')
          .select()
          .eq('barber_id', barberId)
          .eq('is_active', true)
          .order('price', ascending: true);

      return (response as List).map((s) => Service.fromJson(s)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get barber's reviews
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

  /// Get barber's portfolio images
  Future<List<String>> getBarberPortfolio(String barberId) async {
    try {
      final response = await _client
          .from('portfolio_images')
          .select('image_url')
          .eq('barber_id', barberId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((p) => p['image_url'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Update barber profile (for barber users)
  Future<bool> updateBarberProfile(
    String barberId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _client.from('barbers').update(updates).eq('id', barberId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Toggle barber active status
  Future<bool> setBarberActive(String barberId, bool isActive) async {
    return updateBarberProfile(barberId, {'is_active': isActive});
  }

  // Haversine formula for distance calculation
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMiles = 3958.8;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMiles * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;
}

class BarberWithDistance {
  final Barber barber;
  final double distanceMiles;

  BarberWithDistance({
    required this.barber,
    required this.distanceMiles,
  });

  String get formattedDistance {
    if (distanceMiles < 0.1) {
      return 'Nearby';
    } else if (distanceMiles < 1) {
      return '${(distanceMiles * 5280).round()} ft';
    } else {
      return '${distanceMiles.toStringAsFixed(1)} mi';
    }
  }
}
