import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://dskpfnjbgocieoqyiznf.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRza3BmbmpiZ29jaWVvcXlpem5mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxMTkyODcsImV4cCI6MjA3OTY5NTI4N30.PzxcwYFGRYkTHMynjj389AfGmc3iFF9iN49gm0Tainc',
  );

  final client = Supabase.instance.client;

  print('=== Testing Database Queries ===\n');

  // Test 1: Check barbers table
  print('1. Checking barbers table...');
  try {
    final barbersResponse = await client
        .from('barbers')
        .select('id, shop_name, is_active, latitude, longitude')
        .limit(5);

    print('Found ${(barbersResponse as List).length} barbers:');
    for (final barber in barbersResponse) {
      print(
          '  - ${barber['shop_name']} (active: ${barber['is_active']}, lat: ${barber['latitude']}, lng: ${barber['longitude']})');
    }
  } catch (e) {
    print('ERROR: $e');
  }

  print('\n2. Checking active barbers...');
  try {
    final activeResponse = await client
        .from('barbers')
        .select('id, shop_name')
        .eq('is_active', true)
        .limit(5);

    print('Found ${(activeResponse as List).length} active barbers');
  } catch (e) {
    print('ERROR: $e');
  }

  print('\n3. Checking barbers with coordinates...');
  try {
    final coordsResponse = await client
        .from('barbers')
        .select('id, shop_name, latitude, longitude')
        .eq('is_active', true)
        .not('latitude', 'is', null)
        .not('longitude', 'is', null)
        .limit(5);

    print('Found ${(coordsResponse as List).length} barbers with coordinates');
  } catch (e) {
    print('ERROR: $e');
  }

  print('\n4. Checking users table...');
  try {
    final usersResponse =
        await client.from('users').select('id, full_name, role').limit(5);

    print('Found ${(usersResponse as List).length} users');
  } catch (e) {
    print('ERROR: $e');
  }

  print('\n5. Checking appointments...');
  try {
    final apptResponse =
        await client.from('appointments').select('id, status').limit(5);

    print('Found ${(apptResponse as List).length} appointments');
  } catch (e) {
    print('ERROR: $e');
  }

  print('\n=== Tests Complete ===');
}
