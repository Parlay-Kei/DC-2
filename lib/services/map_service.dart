import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/geojson.dart';
import '../utils/logger.dart';

/// Map Service - Provides GeoJSON endpoints for map features
/// Calls DC-1 Edge Functions for authoritative map data
class MapService {
  MapService._();

  static final MapService instance = MapService._();

  // Cache for map data
  final Map<String, _CacheEntry> _cache = {};
  static const int _cacheTtlSeconds = 10;

  // Pending request tracking
  http.Client? _pendingClient;

  /// Get shop pins (barbers with fixed locations) as GeoJSON
  /// Uses Edge Function: /map-shops-bbox
  Future<GeoJSONFeatureCollection> getShops({
    required BoundingBox bbox,
    double? centerLat,
    double? centerLng,
    int limit = 500,
  }) async {
    // Create cache key (round bbox to 4 decimals to prevent cache misses)
    final cacheKey = 'shops:${bbox.toBBoxString()}';

    // Check cache
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired) {
      Logger.debug('MapService: Cache hit for shops');
      return cached.data;
    }

    // Cancel pending request
    _pendingClient?.close();
    _pendingClient = http.Client();

    try {
      final url = Uri.parse(
        '${AppConfig.supabaseFunctionsUrl}/map-shops-bbox?bbox=${bbox.toBBoxString()}&limit=$limit',
      );

      Logger.debug('MapService: Fetching shops from edge function');

      final response = await _pendingClient!.get(url).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }

      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      final geojson = GeoJSONFeatureCollection.fromJson(jsonData);

      // Add distance if center point provided
      if (centerLat != null && centerLng != null) {
        for (final feature in geojson.features) {
          if (feature.properties is ShopPinProperties) {
            final props = feature.properties as ShopPinProperties;
            final distance = _calculateDistance(
              centerLat,
              centerLng,
              feature.geometry.latitude,
              feature.geometry.longitude,
            );

            // Create new properties with distance (immutable pattern)
            final updatedProps = ShopPinProperties(
              pinType: props.pinType,
              barberId: props.barberId,
              barberName: props.barberName,
              shopName: props.shopName,
              specialty: props.specialty,
              rating: props.rating,
              reviews: props.reviews,
              price: props.price,
              priceRange: props.priceRange,
              address: props.address,
              city: props.city,
              state: props.state,
              zip: props.zip,
              image: props.image,
              featured: props.featured,
              isVerified: props.isVerified,
              isAvailable: props.isAvailable,
              distance: distance,
              distanceDisplay: _formatDistance(distance),
            );

            // Replace properties (need to reconstruct feature)
            final updatedFeature = GeoJSONFeature(
              type: feature.type,
              id: feature.id,
              geometry: feature.geometry,
              properties: updatedProps,
            );

            // Replace in list
            final index = geojson.features.indexOf(feature);
            geojson.features[index] = updatedFeature;
          }
        }

        // Sort by distance
        geojson.features.sort((a, b) {
          final distA = a.properties.distance ?? double.infinity;
          final distB = b.properties.distance ?? double.infinity;
          return distA.compareTo(distB);
        });
      }

      // Cache result
      _cache[cacheKey] = _CacheEntry(geojson);

      // Clean old cache entries (keep last 50)
      if (_cache.length > 50) {
        final entries = _cache.entries.toList();
        entries.sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
        for (var i = 0; i < 10; i++) {
          _cache.remove(entries[i].key);
        }
      }

      Logger.debug('MapService: Found ${geojson.features.length} shops');
      return geojson;
    } catch (e) {
      Logger.error('MapService: Failed to fetch shops', e);
      return GeoJSONFeatureCollection.empty();
    } finally {
      _pendingClient = null;
    }
  }

  /// Get mobile barber pins as GeoJSON
  /// Uses Edge Function: /map-mobile-barbers-point
  Future<GeoJSONFeatureCollection> getMobileBarbers({
    required double lng,
    required double lat,
    double? centerLat,
    double? centerLng,
    int limit = 500,
  }) async {
    // Create cache key (round coordinates to 4 decimals)
    final roundLng = (lng * 10000).round() / 10000;
    final roundLat = (lat * 10000).round() / 10000;
    final cacheKey = 'mobile:$roundLng,$roundLat';

    // Check cache
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired) {
      Logger.debug('MapService: Cache hit for mobile barbers');
      return cached.data;
    }

    try {
      final url = Uri.parse(
        '${AppConfig.supabaseFunctionsUrl}/map-mobile-barbers-point?lng=$lng&lat=$lat&limit=$limit',
      );

      Logger.debug('MapService: Fetching mobile barbers from edge function');

      final response = await http.get(url).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }

      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      final geojson = GeoJSONFeatureCollection.fromJson(jsonData);

      // Add distance if center point provided
      if (centerLat != null && centerLng != null) {
        for (final feature in geojson.features) {
          if (feature.properties is MobileBarberPinProperties) {
            final props = feature.properties as MobileBarberPinProperties;
            final distance = _calculateDistance(
              centerLat,
              centerLng,
              feature.geometry.latitude,
              feature.geometry.longitude,
            );

            // Create new properties with distance
            final updatedProps = MobileBarberPinProperties(
              pinType: props.pinType,
              barberId: props.barberId,
              barberName: props.barberName,
              specialty: props.specialty,
              rating: props.rating,
              reviews: props.reviews,
              price: props.price,
              priceRange: props.priceRange,
              serviceRadiusMiles: props.serviceRadiusMiles,
              travelFee: props.travelFee,
              currentLocation: props.currentLocation,
              image: props.image,
              featured: props.featured,
              isVerified: props.isVerified,
              isAvailable: props.isAvailable,
              isOnline: props.isOnline,
              distance: distance,
              distanceDisplay: _formatDistance(distance),
            );

            // Replace properties
            final updatedFeature = GeoJSONFeature(
              type: feature.type,
              id: feature.id,
              geometry: feature.geometry,
              properties: updatedProps,
            );

            final index = geojson.features.indexOf(feature);
            geojson.features[index] = updatedFeature;
          }
        }

        // Sort by distance
        geojson.features.sort((a, b) {
          final distA = a.properties.distance ?? double.infinity;
          final distB = b.properties.distance ?? double.infinity;
          return distA.compareTo(distB);
        });
      }

      // Cache result
      _cache[cacheKey] = _CacheEntry(geojson);

      Logger.debug(
          'MapService: Found ${geojson.features.length} mobile barbers');
      return geojson;
    } catch (e) {
      Logger.error('MapService: Failed to fetch mobile barbers', e);
      return GeoJSONFeatureCollection.empty();
    }
  }

  /// Get all pins (shops + mobile barbers) as GeoJSON
  Future<GeoJSONFeatureCollection> getAllPins({
    required BoundingBox bbox,
    required double centerLat,
    required double centerLng,
  }) async {
    final results = await Future.wait([
      getShops(
        bbox: bbox,
        centerLat: centerLat,
        centerLng: centerLng,
      ),
      getMobileBarbers(
        lng: centerLng,
        lat: centerLat,
        centerLat: centerLat,
        centerLng: centerLng,
      ),
    ]);

    final shops = results[0];
    final mobileBarbers = results[1];

    return GeoJSONFeatureCollection(
      type: 'FeatureCollection',
      features: [...shops.features, ...mobileBarbers.features],
    );
  }

  /// Get pins within a radius using bounding box approximation
  Future<GeoJSONFeatureCollection> getPinsWithinRadius({
    required double centerLat,
    required double centerLng,
    required double radiusMeters,
  }) async {
    final bbox = BoundingBox.fromCenterAndRadius(
      centerLat: centerLat,
      centerLng: centerLng,
      radiusMeters: radiusMeters,
    );

    return getAllPins(
      bbox: bbox,
      centerLat: centerLat,
      centerLng: centerLng,
    );
  }

  /// Clear cache (useful for forced refresh)
  void clearCache() {
    _cache.clear();
  }

  // =====================================================
  // Helper Functions
  // =====================================================

  /// Calculate distance between two points in meters (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const R = 6371000.0; // Earth's radius in meters
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  /// Format distance for display
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    final miles = meters / 1609.34;
    if (miles < 1) {
      return '${(miles * 10).toStringAsFixed(1)} mi';
    }
    return '${miles.toStringAsFixed(1)} mi';
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}

class _CacheEntry {
  final GeoJSONFeatureCollection data;
  final DateTime timestamp;

  _CacheEntry(this.data) : timestamp = DateTime.now();

  bool get isExpired {
    return DateTime.now().difference(timestamp).inSeconds >
        MapService._cacheTtlSeconds;
  }
}

/// Geocoding Service - Mapbox Geocoding API via Edge Functions
class GeocodingService {
  GeocodingService._();

  static final GeocodingService instance = GeocodingService._();

  // Cache for geocoding results
  final Map<String, _GeocodeCacheEntry> _cache = {};
  static const int _cacheTtlSeconds = 3600; // 1 hour

  /// Autocomplete address search
  /// Uses Edge Function: /geo-autocomplete
  Future<List<GeocodeSuggestion>> autocomplete({
    required String query,
    double? proximityLng,
    double? proximityLat,
  }) async {
    if (query.length < 2) {
      return [];
    }

    // Create cache key
    final proximityKey = proximityLng != null && proximityLat != null
        ? '@$proximityLng,$proximityLat'
        : '';
    final cacheKey = 'autocomplete:${query.toLowerCase()}$proximityKey';

    // Check cache
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.suggestions;
    }

    try {
      var url =
          '${AppConfig.supabaseFunctionsUrl}/geo-autocomplete?q=${Uri.encodeComponent(query)}';
      if (proximityLng != null && proximityLat != null) {
        url += '&proximity=$proximityLng,$proximityLat';
      }

      Logger.debug('GeocodingService: Fetching autocomplete suggestions');

      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 5),
          );

      if (response.statusCode != 200) {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }

      final jsonData = json.decode(response.body) as List<dynamic>;
      final suggestions = jsonData
          .map((e) => GeocodeSuggestion.fromJson(e as Map<String, dynamic>))
          .toList();

      // Cache result
      _cache[cacheKey] = _GeocodeCacheEntry(suggestions);

      // Clean old cache entries
      if (_cache.length > 500) {
        final entries = _cache.entries.toList();
        entries.sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
        for (var i = 0; i < 100; i++) {
          _cache.remove(entries[i].key);
        }
      }

      return suggestions;
    } catch (e) {
      Logger.error(
          'GeocodingService: Failed to fetch autocomplete suggestions', e);
      return [];
    }
  }

  /// Reverse geocode coordinates to address
  /// Uses Edge Function: /geo-reverse
  Future<ReverseGeocodeResult?> reverse({
    required double lng,
    required double lat,
  }) async {
    // Round coordinates for cache key
    final roundLng = (lng * 1000).round() / 1000;
    final roundLat = (lat * 1000).round() / 1000;
    final cacheKey = 'reverse:$roundLat,$roundLng';

    // Check cache
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired && cached.reverseResult != null) {
      return cached.reverseResult;
    }

    try {
      final url =
          '${AppConfig.supabaseFunctionsUrl}/geo-reverse?lng=$lng&lat=$lat';

      Logger.debug('GeocodingService: Fetching reverse geocode result');

      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 5),
          );

      if (response.statusCode != 200) {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }

      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      final result = ReverseGeocodeResult.fromJson(jsonData);

      // Cache result
      _cache[cacheKey] = _GeocodeCacheEntry.reverse(result);

      return result;
    } catch (e) {
      Logger.error(
          'GeocodingService: Failed to fetch reverse geocode result', e);
      return null;
    }
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
  }
}

class GeocodeSuggestion {
  final double lat;
  final double lng;
  final String displayName;
  final String? placeName;
  final String? address;

  GeocodeSuggestion({
    required this.lat,
    required this.lng,
    required this.displayName,
    this.placeName,
    this.address,
  });

  factory GeocodeSuggestion.fromJson(Map<String, dynamic> json) {
    return GeocodeSuggestion(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      displayName: json['displayName'] as String,
      placeName: json['placeName'] as String?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'displayName': displayName,
      'placeName': placeName,
      'address': address,
    };
  }
}

class ReverseGeocodeResult {
  final String city;
  final String state;
  final String country;
  final String? displayName;

  ReverseGeocodeResult({
    required this.city,
    required this.state,
    required this.country,
    this.displayName,
  });

  factory ReverseGeocodeResult.fromJson(Map<String, dynamic> json) {
    return ReverseGeocodeResult(
      city: json['city'] as String,
      state: json['state'] as String,
      country: json['country'] as String,
      displayName: json['displayName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'state': state,
      'country': country,
      'displayName': displayName,
    };
  }
}

class _GeocodeCacheEntry {
  final List<GeocodeSuggestion> suggestions;
  final ReverseGeocodeResult? reverseResult;
  final DateTime timestamp;

  _GeocodeCacheEntry(this.suggestions)
      : reverseResult = null,
        timestamp = DateTime.now();

  _GeocodeCacheEntry.reverse(this.reverseResult)
      : suggestions = [],
        timestamp = DateTime.now();

  bool get isExpired {
    return DateTime.now().difference(timestamp).inSeconds >
        GeocodingService._cacheTtlSeconds;
  }
}
