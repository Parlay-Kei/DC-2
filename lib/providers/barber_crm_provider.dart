import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/barber.dart';
import '../services/location_service.dart';

// Current barber's full profile for CRM
final currentBarberProvider = FutureProvider<Barber?>((ref) async {
  final userId = SupabaseConfig.currentUserId;
  if (userId == null) return null;

  try {
    final response = await Supabase.instance.client
        .from('barbers')
        .select()
        .eq('user_id', userId)
        .single();

    return Barber.fromJson(response);
  } catch (e) {
    debugPrint('Get current barber error: $e');
    return null;
  }
});

// Barber CRM state for editing
class BarberCrmState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final Barber? barber;

  const BarberCrmState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.barber,
  });

  BarberCrmState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    Barber? barber,
  }) {
    return BarberCrmState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      barber: barber ?? this.barber,
    );
  }
}

class BarberCrmNotifier extends StateNotifier<BarberCrmState> {
  final Ref _ref;

  BarberCrmNotifier(this._ref) : super(const BarberCrmState()) {
    _loadBarber();
  }

  Future<void> _loadBarber() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final barber = await _ref.read(currentBarberProvider.future);
      state = state.copyWith(isLoading: false, barber: barber);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    _ref.invalidate(currentBarberProvider);
    await _loadBarber();
  }

  Future<bool> updateBusinessInfo({
    String? displayName,
    String? bio,
    String? phone,
    String? shopName,
  }) async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return false;

    state = state.copyWith(isSaving: true, error: null);

    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (phone != null) updates['phone'] = phone;
      if (shopName != null) updates['shop_name'] = shopName;

      if (updates.isEmpty) {
        state = state.copyWith(isSaving: false);
        return true;
      }

      await Supabase.instance.client
          .from('barbers')
          .update(updates)
          .eq('user_id', userId);

      await refresh();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateLocation({
    String? shopAddress,
    double? latitude,
    double? longitude,
  }) async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return false;

    state = state.copyWith(isSaving: true, error: null);

    try {
      final updates = <String, dynamic>{};
      if (shopAddress != null) updates['shop_address'] = shopAddress;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;

      if (updates.isEmpty) {
        state = state.copyWith(isSaving: false);
        return true;
      }

      await Supabase.instance.client
          .from('barbers')
          .update(updates)
          .eq('user_id', userId);

      await refresh();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateServiceSettings({
    bool? isMobile,
    bool? offersHomeService,
    int? serviceRadiusMiles,
    double? travelFeePerMile,
  }) async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return false;

    state = state.copyWith(isSaving: true, error: null);

    try {
      final updates = <String, dynamic>{};
      if (isMobile != null) updates['is_mobile'] = isMobile;
      if (offersHomeService != null) updates['offers_home_service'] = offersHomeService;
      if (serviceRadiusMiles != null) updates['service_radius_miles'] = serviceRadiusMiles;
      if (travelFeePerMile != null) updates['travel_fee_per_mile'] = travelFeePerMile;

      if (updates.isEmpty) {
        state = state.copyWith(isSaving: false);
        return true;
      }

      await Supabase.instance.client
          .from('barbers')
          .update(updates)
          .eq('user_id', userId);

      await refresh();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateLocationFromGPS() async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return false;

    state = state.copyWith(isSaving: true, error: null);

    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();

      if (position == null) {
        state = state.copyWith(
          isSaving: false,
          error: 'Could not get current location. Please check permissions.',
        );
        return false;
      }

      // Get address from coordinates
      final address = await locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final updates = <String, dynamic>{
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
      if (address != null) {
        updates['shop_address'] = address;
      }

      await Supabase.instance.client
          .from('barbers')
          .update(updates)
          .eq('user_id', userId);

      await refresh();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateLocationFromAddress(String address) async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return false;

    state = state.copyWith(isSaving: true, error: null);

    try {
      final locationService = LocationService();
      final coords = await locationService.getCoordinatesFromAddress(address);

      if (coords == null) {
        state = state.copyWith(
          isSaving: false,
          error: 'Could not find coordinates for this address.',
        );
        return false;
      }

      await Supabase.instance.client.from('barbers').update({
        'shop_address': address,
        'latitude': coords.latitude,
        'longitude': coords.longitude,
      }).eq('user_id', userId);

      await refresh();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> clearLocation() async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return false;

    state = state.copyWith(isSaving: true, error: null);

    try {
      await Supabase.instance.client.from('barbers').update({
        'shop_address': null,
        'latitude': null,
        'longitude': null,
      }).eq('user_id', userId);

      await refresh();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

final barberCrmProvider =
    StateNotifierProvider<BarberCrmNotifier, BarberCrmState>((ref) {
  return BarberCrmNotifier(ref);
});
