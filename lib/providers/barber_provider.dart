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
final userLocationProvider = StateNotifierProvider<UserLocationNotifier, AsyncValue<Position?>>((ref) {
  return UserLocationNotifier(ref.read(locationServiceProvider));
});

class UserLocationNotifier extends StateNotifier<AsyncValue<Position?>> {
  final LocationService _locationService;
  bool _initialized = false;

  UserLocationNotifier(this._locationService) : super(const AsyncValue.data(null)) {
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

// Nearby barbers - uses searchLocationProvider for coordinates
// This ensures we only search once per location change
final nearbyBarbersProvider = FutureProvider.autoDispose<List<BarberWithDistance>>((ref) async {
  final location = ref.watch(searchLocationProvider);

  Logger.debug('NearbyBarbersProvider: Searching for barbers');

  try {
    final results = await ref.read(barberServiceProvider).getNearbyBarbers(
      latitude: location.lat,
      longitude: location.lng,
      radiusMiles: 100, // Wide radius to catch all Vegas barbers
    );

    Logger.debug('NearbyBarbersProvider: Found ${results.length} barbers');
    return results;
  } catch (e, stack) {
    Logger.error('NearbyBarbersProvider: Error fetching barbers', e, stack);
    // Return empty list to prevent infinite loading
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
    GeoJSONFeatureCollection, ({double lat, double lng, double radiusMiles})
>((ref, params) async {
  final mapService = ref.read(mapServiceProvider);
  final radiusMeters = params.radiusMiles * 1609.34;

  try {
    final result = await mapService.getPinsWithinRadius(
      centerLat: params.lat,
      centerLng: params.lng,
      radiusMeters: radiusMeters,
    );

    Logger.debug('geoJsonNearbyBarbersProvider: Found ${result.features.length} barbers');
    return result;
  } catch (e, stack) {
    Logger.error('geoJsonNearbyBarbersProvider: Error fetching GeoJSON', e, stack);
    return GeoJSONFeatureCollection.empty();
  }
});
