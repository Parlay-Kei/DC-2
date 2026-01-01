import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../services/barber_service.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';
import '../models/barber.dart';
import '../models/service.dart';
import '../models/review.dart';
import '../models/geojson.dart';
import '../utils/logger.dart';

// Location service provider
final locationServiceProvider = Provider((ref) => LocationService());

// Map service provider
final mapServiceProvider = Provider((ref) => MapService.instance);

// Get a single barber by ID
final barberProvider = FutureProvider.family<Barber?, String>((ref, barberId) {
  return ref.read(barberServiceProvider).getBarber(barberId);
});

// Get all active barbers
final activeBarbersProvider = FutureProvider<List<Barber>>((ref) {
  return ref.read(barberServiceProvider).getActiveBarbers();
});

// Top-rated barbers
final topRatedBarbersProvider = FutureProvider<List<Barber>>((ref) {
  return ref.read(barberServiceProvider).getTopRatedBarbers();
});

// Search barbers
final barberSearchProvider =
    FutureProvider.family<List<Barber>, String>((ref, query) {
  if (query.isEmpty) return Future.value([]);
  return ref.read(barberServiceProvider).searchBarbers(query);
});

// Barber services
final barberServicesProvider =
    FutureProvider.family<List<Service>, String>((ref, barberId) {
  return ref.read(barberServiceProvider).getBarberServices(barberId);
});

// Barber reviews
final barberReviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, barberId) {
  return ref.read(barberServiceProvider).getBarberReviews(barberId);
});

// Barber portfolio
final barberPortfolioProvider =
    FutureProvider.family<List<String>, String>((ref, barberId) {
  return ref.read(barberServiceProvider).getBarberPortfolio(barberId);
});

// User location state
final userLocationProvider =
    StateNotifierProvider<UserLocationNotifier, AsyncValue<Position?>>((ref) {
  return UserLocationNotifier(ref.read(locationServiceProvider));
});

class UserLocationNotifier extends StateNotifier<AsyncValue<Position?>> {
  final LocationService _locationService;
  bool _initialized = false;

  UserLocationNotifier(this._locationService)
      : super(const AsyncValue.data(null)) {
    // Don't auto-init - let UI trigger when needed
  }

  Future<void> initIfNeeded() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final position = await _locationService.getCurrentPosition();
      state = AsyncValue.data(position);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> requestPermission() async {
    final permission = await _locationService.requestPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      await refresh();
      return true;
    }
    return false;
  }
}

// Las Vegas coordinates (our launch market)
const _lasVegasLat = 36.1699;
const _lasVegasLng = -115.1398;

// Search location state - allows UI to override default
final searchLocationProvider = StateProvider<({double lat, double lng})>((ref) {
  return (lat: _lasVegasLat, lng: _lasVegasLng);
});

// RPC timeout - if exceeded, fall back to directory list
const _rpcTimeoutSeconds = 5;
const _rpcSlowThresholdMs = 2000;

// Nearby barbers - uses PUBLIC RPC for anon + authed access
// Uses searchLocationProvider for coordinates
// Falls back to directory list (without distance) if RPC is slow/fails
final nearbyBarbersProvider =
    FutureProvider.autoDispose<List<BarberWithDistance>>((ref) async {
  final location = ref.watch(searchLocationProvider);
  final stopwatch = Stopwatch()..start();

  Logger.debug(
      'NearbyBarbersProvider: Starting PUBLIC search at (${location.lat}, ${location.lng})',
  );

  try {
    // Use PUBLIC RPC method with timeout - works for both anon and authed users
    final results = await ref
        .read(barberServiceProvider)
        .getPublicNearbyBarbers(
          latitude: location.lat,
          longitude: location.lng,
          radiusMiles: 100, // Wide radius to catch all Vegas barbers
        )
        .timeout(
          const Duration(seconds: _rpcTimeoutSeconds),
          onTimeout: () {
            Logger.debug(
                'NearbyBarbersProvider: RPC timeout after ${_rpcTimeoutSeconds}s, falling back to directory',
            );
            throw TimeoutException('RPC timeout');
          },
        );

    stopwatch.stop();
    final elapsed = stopwatch.elapsedMilliseconds;

    // Warn if slow but still succeeded
    if (elapsed > _rpcSlowThresholdMs) {
      Logger.debug(
          'WARNING: NearbyBarbersProvider slow response: ${elapsed}ms (threshold: ${_rpcSlowThresholdMs}ms)',
      );
    }

    Logger.debug(
        'NearbyBarbersProvider: Found ${results.length} barbers in ${elapsed}ms',
    );

    if (results.isEmpty) {
      Logger.debug(
          'WARNING: Zero barbers returned - check database seeding and run migrations',
      );
    }

    return results;
  } on TimeoutException {
    // Fallback: fetch directory list without distance sorting
    stopwatch.stop();
    Logger.debug(
        'NearbyBarbersProvider: Timeout fallback - fetching directory list',
    );
    return _fetchDirectoryFallback(ref);
  } catch (e, stack) {
    stopwatch.stop();
    Logger.error(
        'NearbyBarbersProvider: Error fetching barbers (${stopwatch.elapsedMilliseconds}ms)',
        e,
        stack,
    );
    // Fallback to directory list on any error
    return _fetchDirectoryFallback(ref);
  }
});

/// Fallback when nearby RPC fails/times out - returns barbers without distance
Future<List<BarberWithDistance>> _fetchDirectoryFallback(Ref ref) async {
  try {
    final barbers = await ref.read(barberServiceProvider).getPublicBarbers();
    // Return with null-ish distance to indicate "distance unavailable"
    return barbers
        .map((b) => BarberWithDistance(barber: b, distanceMiles: -1))
        .toList();
  } catch (e) {
    Logger.error('NearbyBarbersProvider: Fallback also failed', e);
    return [];
  }
}

// Public barbers list (no location required) - for directory view
final publicBarbersProvider =
    FutureProvider.autoDispose<List<Barber>>((ref) async {
  Logger.debug('PublicBarbersProvider: Fetching all public barbers');

  try {
    final results = await ref.read(barberServiceProvider).getPublicBarbers();
    Logger.debug('PublicBarbersProvider: Found ${results.length} barbers');
    return results;
  } catch (e, stack) {
    Logger.error('PublicBarbersProvider: Error', e, stack);
    return [];
  }
});

// Search state for explore screen
final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredBarbersProvider = FutureProvider<List<Barber>>((ref) {
  final query = ref.watch(searchQueryProvider);

  if (query.isEmpty) {
    return ref.read(barberServiceProvider).getActiveBarbers();
  }
  return ref.read(barberServiceProvider).searchBarbers(query);
});

// Selected barber for booking flow
final selectedBarberProvider = StateProvider<Barber?>((ref) => null);

// GeoJSON nearby barbers (using MapService for enhanced mapping)
// Returns raw GeoJSON data from Edge Functions
final geoJsonNearbyBarbersProvider = FutureProvider.autoDispose.family<
    GeoJSONFeatureCollection,
    ({double lat, double lng, double radiusMiles})>((ref, params) async {
  final mapService = ref.read(mapServiceProvider);
  final radiusMeters = params.radiusMiles * 1609.34;

  try {
    final result = await mapService.getPinsWithinRadius(
      centerLat: params.lat,
      centerLng: params.lng,
      radiusMeters: radiusMeters,
    );

    Logger.debug(
        'geoJsonNearbyBarbersProvider: Found ${result.features.length} barbers',
    );
    return result;
  } catch (e, stack) {
    Logger.error(
        'geoJsonNearbyBarbersProvider: Error fetching GeoJSON',
        e,
        stack,
    );
    return GeoJSONFeatureCollection.empty();
  }
});
