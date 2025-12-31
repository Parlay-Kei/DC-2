import 'package:supabase_flutter/supabase_flutter.dart';

import 'logger.dart';

/// Seed test barbers in Las Vegas area for development
class BarberSeeder {
  static final _client = Supabase.instance.client;

  /// Seed Las Vegas test barbers
  static Future<void> seedLasVegasBarbers() async {
    final testBarbers = [
      {
        'display_name': 'James Wilson',
        'shop_name': 'Elite Cuts LV',
        'shop_address': '2800 W Sahara Ave, Las Vegas, NV',
        'bio':
            'Master barber with 10+ years experience. Specializing in fades and designs.',
        'latitude': 36.1447,
        'longitude': -115.1728,
        'is_mobile': false,
        'is_active': true,
        'is_verified': true,
        'service_radius_miles': 0,
        'tier': 'professional',
      },
      {
        'display_name': 'Marcus Thompson',
        'shop_name': 'Fresh Fades',
        'shop_address': '3900 Paradise Rd, Las Vegas, NV',
        'bio': 'Your style, perfected. Classic and modern cuts.',
        'latitude': 36.1190,
        'longitude': -115.1520,
        'is_mobile': true,
        'is_active': true,
        'is_verified': true,
        'service_radius_miles': 15,
        'tier': 'professional',
      },
      {
        'display_name': 'DeShawn Roberts',
        'shop_name': 'The Barbershop LV',
        'shop_address': '4850 W Flamingo Rd, Las Vegas, NV',
        'bio': 'Precision cuts and hot towel shaves. Walk-ins welcome!',
        'latitude': 36.1152,
        'longitude': -115.2103,
        'is_mobile': false,
        'is_active': true,
        'is_verified': false,
        'service_radius_miles': 0,
        'tier': 'standard',
      },
      {
        'display_name': 'Anthony Garcia',
        'shop_name': 'Vegas Mobile Cuts',
        'shop_address': 'Mobile - Las Vegas Area',
        'bio': 'I come to you! Professional mobile barber service.',
        'latitude': 36.1699,
        'longitude': -115.1398,
        'is_mobile': true,
        'is_active': true,
        'is_verified': true,
        'service_radius_miles': 25,
        'tier': 'standard',
      },
      {
        'display_name': 'Kevin Johnson',
        'shop_name': 'Classic Cuts Henderson',
        'shop_address': '1000 N Green Valley Pkwy, Henderson, NV',
        'bio': 'Traditional barbering with a modern touch.',
        'latitude': 36.0395,
        'longitude': -115.0630,
        'is_mobile': false,
        'is_active': true,
        'is_verified': false,
        'service_radius_miles': 0,
        'tier': 'beginner',
      },
    ];

    for (final barber in testBarbers) {
      try {
        final displayName = barber['display_name'] as String;

        // Check if barber already exists by name
        final existing = await _client
            .from('barbers')
            .select('id')
            .eq('display_name', displayName)
            .maybeSingle();

        if (existing == null) {
          // Create a dummy user_id (in production this would be a real auth user)
          final userId =
              'test-${displayName.toLowerCase().replaceAll(' ', '-')}';

          await _client.from('barbers').insert({
            ...barber,
            'user_id': userId,
          });
          Logger.debug('Added test barber');
        } else {
          // Update existing barber with location data
          await _client.from('barbers').update({
            'latitude': barber['latitude'],
            'longitude': barber['longitude'],
            'shop_address': barber['shop_address'],
            'is_active': true,
          }).eq('display_name', displayName);
          Logger.debug('Updated test barber');
        }
      } catch (e) {
        Logger.error('Error seeding barber', e);
      }
    }
  }

  /// Clear all test barbers
  static Future<void> clearTestBarbers() async {
    try {
      await _client.from('barbers').delete().like('user_id', 'test-%');
      Logger.debug('Cleared test barbers');
    } catch (e) {
      Logger.error('Error clearing test barbers', e);
    }
  }
}
