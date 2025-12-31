import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/booking.dart';

// Barber stats provider
final barberStatsProvider = FutureProvider<BarberStats>((ref) async {
  final barberId = SupabaseConfig.currentUserId;
  if (barberId == null) return BarberStats.empty();

  try {
    final client = Supabase.instance.client;
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Get today's earnings
    final todayEarnings = await client
        .from('appointments')
        .select('total_price, platform_fee')
        .eq('barber_id', barberId)
        .eq('date', todayStr)
        .eq('status', 'completed');

    double todayTotal = 0;
    for (final apt in todayEarnings) {
      todayTotal += (apt['total_price'] ?? 0) - (apt['platform_fee'] ?? 0);
    }

    // Get today's appointments count
    final todayApts = await client
        .from('appointments')
        .select('id')
        .eq('barber_id', barberId)
        .eq('date', todayStr)
        .inFilter('status', ['pending', 'confirmed']);

    // Get week's earnings
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekStartStr =
        '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';

    final weekEarnings = await client
        .from('appointments')
        .select('total_price, platform_fee')
        .eq('barber_id', barberId)
        .gte('date', weekStartStr)
        .eq('status', 'completed');

    double weekTotal = 0;
    for (final apt in weekEarnings) {
      weekTotal += (apt['total_price'] ?? 0) - (apt['platform_fee'] ?? 0);
    }

    // Get month's earnings
    final monthStartStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-01';

    final monthEarnings = await client
        .from('appointments')
        .select('total_price, platform_fee')
        .eq('barber_id', barberId)
        .gte('date', monthStartStr)
        .eq('status', 'completed');

    double monthTotal = 0;
    int monthBookings = 0;
    for (final apt in monthEarnings) {
      monthTotal += (apt['total_price'] ?? 0) - (apt['platform_fee'] ?? 0);
      monthBookings++;
    }

    // Get rating
    final barberData = await client
        .from('barbers')
        .select('rating, total_reviews')
        .eq('id', barberId)
        .single();

    return BarberStats(
      todayEarnings: todayTotal,
      todayAppointments: (todayApts as List).length,
      weekEarnings: weekTotal,
      monthEarnings: monthTotal,
      monthBookings: monthBookings,
      rating: (barberData['rating'] ?? 0).toDouble(),
      totalReviews: barberData['total_reviews'] ?? 0,
    );
  } catch (e) {
    return BarberStats.empty();
  }
});

class BarberStats {
  final double todayEarnings;
  final int todayAppointments;
  final double weekEarnings;
  final double monthEarnings;
  final int monthBookings;
  final double rating;
  final int totalReviews;

  BarberStats({
    required this.todayEarnings,
    required this.todayAppointments,
    required this.weekEarnings,
    required this.monthEarnings,
    required this.monthBookings,
    required this.rating,
    required this.totalReviews,
  });

  factory BarberStats.empty() => BarberStats(
        todayEarnings: 0,
        todayAppointments: 0,
        weekEarnings: 0,
        monthEarnings: 0,
        monthBookings: 0,
        rating: 0,
        totalReviews: 0,
      );
}

// Today's appointments for barber
final barberTodayAppointmentsProvider =
    FutureProvider<List<Booking>>((ref) async {
  final barberId = SupabaseConfig.currentUserId;
  if (barberId == null) return [];

  try {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final response = await Supabase.instance.client
        .from('appointments')
        .select('''
          *,
          profiles!appointments_customer_id_fkey(full_name, avatar_url, phone),
          barber_services(name, duration)
        ''')
        .eq('barber_id', barberId)
        .eq('date', todayStr)
        .inFilter('status', ['pending', 'confirmed', 'completed'])
        .order('time', ascending: true);

    return (response as List).map((data) {
      final profile = data['profiles'];
      final service = data['barber_services'];
      return Booking.fromJson({
        ...data,
        'customer_name': profile?['full_name'],
        'customer_avatar': profile?['avatar_url'],
        'customer_phone': profile?['phone'],
        'service_name': service?['name'],
        'service_duration': service?['duration'],
      });
    }).toList();
  } catch (e) {
    return [];
  }
});

// Upcoming appointments for barber (next 7 days)
final barberUpcomingAppointmentsProvider =
    FutureProvider<List<Booking>>((ref) async {
  final barberId = SupabaseConfig.currentUserId;
  if (barberId == null) return [];

  try {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final weekEnd = today.add(const Duration(days: 7));
    final weekEndStr =
        '${weekEnd.year}-${weekEnd.month.toString().padLeft(2, '0')}-${weekEnd.day.toString().padLeft(2, '0')}';

    final response = await Supabase.instance.client
        .from('appointments')
        .select('''
          *,
          profiles!appointments_customer_id_fkey(full_name, avatar_url, phone),
          barber_services(name, duration)
        ''')
        .eq('barber_id', barberId)
        .gte('date', todayStr)
        .lte('date', weekEndStr)
        .inFilter('status', ['pending', 'confirmed'])
        .order('date', ascending: true)
        .order('time', ascending: true);

    return (response as List).map((data) {
      final profile = data['profiles'];
      final service = data['barber_services'];
      return Booking.fromJson({
        ...data,
        'customer_name': profile?['full_name'],
        'customer_avatar': profile?['avatar_url'],
        'customer_phone': profile?['phone'],
        'service_name': service?['name'],
        'service_duration': service?['duration'],
      });
    }).toList();
  } catch (e) {
    return [];
  }
});

// Pending appointments requiring action
final pendingAppointmentsProvider = FutureProvider<List<Booking>>((ref) async {
  final barberId = SupabaseConfig.currentUserId;
  if (barberId == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('appointments')
        .select('''
          *,
          profiles!appointments_customer_id_fkey(full_name, avatar_url),
          barber_services(name)
        ''')
        .eq('barber_id', barberId)
        .eq('status', 'pending')
        .order('date', ascending: true)
        .order('time', ascending: true)
        .limit(10);

    return (response as List).map((data) {
      final profile = data['profiles'];
      final service = data['barber_services'];
      return Booking.fromJson({
        ...data,
        'customer_name': profile?['full_name'],
        'customer_avatar': profile?['avatar_url'],
        'service_name': service?['name'],
      });
    }).toList();
  } catch (e) {
    return [];
  }
});

// Barber's clients
final barberClientsProvider = FutureProvider<List<ClientInfo>>((ref) async {
  final barberId = SupabaseConfig.currentUserId;
  if (barberId == null) return [];

  try {
    final response =
        await Supabase.instance.client.from('appointments').select('''
          customer_id,
          profiles!appointments_customer_id_fkey(id, full_name, avatar_url, phone)
        ''').eq('barber_id', barberId).eq('status', 'completed');

    // Group by customer and count
    final Map<String, ClientInfo> clientsMap = {};
    for (final apt in response) {
      final profile = apt['profiles'];
      if (profile == null) continue;

      final customerId = profile['id'] as String;
      if (clientsMap.containsKey(customerId)) {
        clientsMap[customerId] = clientsMap[customerId]!.copyWith(
          visitCount: clientsMap[customerId]!.visitCount + 1,
        );
      } else {
        clientsMap[customerId] = ClientInfo(
          id: customerId,
          name: profile['full_name'] ?? 'Unknown',
          avatarUrl: profile['avatar_url'],
          phone: profile['phone'],
          visitCount: 1,
        );
      }
    }

    final clients = clientsMap.values.toList();
    clients.sort((a, b) => b.visitCount.compareTo(a.visitCount));
    return clients;
  } catch (e) {
    return [];
  }
});

class ClientInfo {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? phone;
  final int visitCount;

  ClientInfo({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.phone,
    required this.visitCount,
  });

  ClientInfo copyWith({int? visitCount}) {
    return ClientInfo(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      phone: phone,
      visitCount: visitCount ?? this.visitCount,
    );
  }
}
