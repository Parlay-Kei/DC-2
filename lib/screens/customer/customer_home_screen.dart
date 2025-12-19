import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import 'nearby_map_screen.dart';
import 'bookings_tab.dart';
import 'messages_tab.dart';

// Provider to fetch trending barbers
final trendingBarbersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    // Query barbers table - rating is calculated from reviews, not stored in table
    final response = await Supabase.instance.client
        .from('barbers')
        .select('*')
        .eq('is_active', true)
        .eq('is_verified', true)
        .limit(10);

    final barbers = List<Map<String, dynamic>>.from(response);
    
    // Get user profiles for names
    if (barbers.isEmpty) return [];
    
    final userIds = barbers.map((b) => b['id'] as String).toList();
    final usersResponse = await Supabase.instance.client
        .from('users')
        .select('id, full_name, avatar_url')
        .inFilter('id', userIds);
    
    final userMap = <String, Map<String, dynamic>>{};
    for (final user in usersResponse as List) {
      userMap[user['id'] as String] = user;
    }
    
    return barbers.map((b) {
      final user = userMap[b['id']];
      return {
        ...b,
        'full_name': user?['full_name'] ?? b['shop_name'] ?? 'Unknown Barber',
        'avatar_url': user?['avatar_url'],
        'rating': 4.5, // Default rating until we fetch from reviews
      };
    }).toList();
  } catch (e) {
    print('DEBUG: Error fetching barbers: $e');
    return [];
  }
});

// Provider to fetch user stats
final userStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return {'bookings': 0, 'favorites': 0, 'spent': 0};

  try {
    final bookings = await Supabase.instance.client
        .from('appointments')
        .select('id')
        .eq('customer_id', user.id);

    final favorites = await Supabase.instance.client
        .from('favorites')
        .select('id')
        .eq('user_id', user.id);

    final spent = await Supabase.instance.client
        .from('appointments')
        .select('total_price')
        .eq('customer_id', user.id)
        .eq('status', 'completed');

    final totalSpent = (spent as List).fold<double>(
      0,
      (sum, apt) => sum + (apt['total_price'] ?? 0).toDouble(),
    );

    return {
      'bookings': (bookings as List).length,
      'favorites': (favorites as List).length,
      'spent': totalSpent,
    };
  } catch (e) {
    return {'bookings': 0, 'favorites': 0, 'spent': 0};
  }
});

// Provider to fetch upcoming appointments
final upcomingAppointmentsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final today = DateTime.now().toIso8601String().split('T')[0];

    final response = await Supabase.instance.client
        .from('appointments')
        .select('id, scheduled_date, scheduled_time, status, barber_id')
        .eq('customer_id', user.id)
        .inFilter('status', ['pending', 'confirmed'])
        .gte('scheduled_date', today)
        .order('scheduled_date', ascending: true)
        .limit(3);

    // Map to expected format for backwards compatibility
    return List<Map<String, dynamic>>.from(response).map((apt) => {
      ...apt,
      'date': apt['scheduled_date'],
      'time': apt['scheduled_time'],
    }).toList();
  } catch (e) {
    return [];
  }
});

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  int _currentIndex = 0;
  // Cache built tabs for smoother navigation
  final Map<int, Widget> _cachedTabs = {};

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  Widget _buildCurrentTab() {
    // Use lazy loading - only build the current tab
    if (!_cachedTabs.containsKey(_currentIndex)) {
      _cachedTabs[_currentIndex] = switch (_currentIndex) {
        0 => _HomeTab(onNavigate: _navigateToTab),
        1 => const _ExploreTab(),
        2 => const _FavoritesTab(),
        3 => const _ProfileTab(),
        _ => const SizedBox.shrink(),
      };
    }
    return _cachedTabs[_currentIndex]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DCTheme.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _buildCurrentTab(),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: DCTheme.surface,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                isActive: _currentIndex == 0,
                onTap: () => _navigateToTab(0),
              ),
              _NavItem(
                icon: Icons.location_on_outlined,
                activeIcon: Icons.location_on,
                label: 'Nearby',
                isActive: _currentIndex == 1,
                onTap: () => _navigateToTab(1),
              ),
              // Center FAB - Barber Pole
              GestureDetector(
                onTap: () => _navigateToTab(1), // Go to Explore/Book
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFEF4444), // red-500
                        Color(0xFFDC2626), // red-600
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: _BarberPoleIcon(),
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.star_outline,
                activeIcon: Icons.star,
                label: 'Favorites',
                isActive: _currentIndex == 2,
                onTap: () => _navigateToTab(2),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                isActive: _currentIndex == 3,
                onTap: () => _navigateToTab(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ HOME TAB ============
class _HomeTab extends ConsumerWidget {
  final void Function(int) onNavigate;

  const _HomeTab({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final stats = ref.watch(userStatsProvider);
    final barbers = ref.watch(trendingBarbersProvider);
    final appointments = ref.watch(upcomingAppointmentsProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ref, profile),
          _buildStatsCard(stats),
          _buildUpcomingSection(context, appointments),
          _buildTrendingBarbersSection(context, barbers),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    AsyncValue profile,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: DCTheme.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Stack(
        children: [
          // Large Watermark Logo - matching web opacity-20
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.2,
                child: SvgPicture.asset(
                  'assets/images/dc_logo.svg',
                  width: 180,
                  height: 180,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row with avatar and notification
                  Row(
                    children: [
                      // Avatar - matching web w-12 h-12
                      _buildAvatar(profile),
                      const SizedBox(width: 12),
                      // Title and subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            profile.when(
                              data: (p) => Text(
                                _getGreeting(p?.fullName?.split(' ').first),
                                style: const TextStyle(
                                  fontSize: 20, // text-xl
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              loading: () => const Text(
                                'Hey there!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              error: (_, __) => const Text(
                                'Hey there!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              _getSubtitle(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.8), // text-red-100
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Notification button
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          color: Colors.white,
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Notifications coming soon'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(AsyncValue profile) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: profile.when(
          data: (p) {
            if (p?.avatarUrl != null && p!.avatarUrl!.isNotEmpty) {
              return Image.network(
                p.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarFallback(p.fullName),
              );
            }
            return _avatarFallback(p?.fullName);
          },
          loading: () => _avatarFallback(null),
          error: (_, __) => _avatarFallback(null),
        ),
      ),
    );
  }

  Widget _avatarFallback(String? name) {
    final initials = _getInitials(name);
    return Container(
      color: const Color(0xFF2A2A2A),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(AsyncValue<Map<String, dynamic>> stats) {
    return Transform.translate(
      offset: const Offset(0, -16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            // gray-800 with 90% opacity - matching web bg-gray-800/90
            color: const Color(0xFF1F2937).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: stats.when(
            data: (data) => Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.calendar_today,
                    iconBgColor: DCTheme.primary.withValues(alpha: 0.2),
                    iconColor: DCTheme.primary,
                    value: '${data['bookings']}',
                    label: 'Bookings',
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: const Color(0xFF374151), // border-gray-700
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.star,
                    iconBgColor: Colors.amber.withValues(alpha: 0.2),
                    iconColor: Colors.amber,
                    value: '${data['favorites']}',
                    label: 'Favorites',
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: const Color(0xFF374151), // border-gray-700
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.trending_up,
                    iconBgColor: DCTheme.info.withValues(alpha: 0.2),
                    iconColor: DCTheme.info,
                    value:
                        '\$${((data['spent'] ?? 0) as num).toStringAsFixed(0)}',
                    label: 'Spent',
                  ),
                ),
              ],
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: DCTheme.primary),
            ),
            error: (_, __) => Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.calendar_today,
                    iconBgColor: DCTheme.primary.withValues(alpha: 0.2),
                    iconColor: DCTheme.primary,
                    value: '0',
                    label: 'Bookings',
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: const Color(0xFF374151),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.star,
                    iconBgColor: Colors.amber.withValues(alpha: 0.2),
                    iconColor: Colors.amber,
                    value: '0',
                    label: 'Favorites',
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: const Color(0xFF374151),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.trending_up,
                    iconBgColor: DCTheme.info.withValues(alpha: 0.2),
                    iconColor: DCTheme.info,
                    value: '\$0',
                    label: 'Spent',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingSection(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> appointments,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DCTheme.text,
                ),
              ),
              GestureDetector(
                onTap: () => onNavigate(2),
                child: const Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: DCTheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right, color: DCTheme.primary, size: 20),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          appointments.when(
            data: (list) {
              if (list.isEmpty) {
                return _buildEmptyAppointments(context);
              }
              return Column(
                children: list
                    .map((apt) => _AppointmentCard(appointment: apt))
                    .toList(),
              );
            },
            loading: () => Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: DCTheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: DCTheme.primary),
              ),
            ),
            error: (_, __) => _buildEmptyAppointments(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAppointments(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 44,
            color: DCTheme.textMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No upcoming appointments',
            style: TextStyle(color: DCTheme.textMuted, fontSize: 15),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => onNavigate(1),
            style: ElevatedButton.styleFrom(
              backgroundColor: DCTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Book Now',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingBarbersSection(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> barbers,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trending Barbers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: DCTheme.text,
                  ),
                ),
                GestureDetector(
                  onTap: () => onNavigate(1),
                  child: const Row(
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(
                          color: DCTheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        color: DCTheme.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          barbers.when(
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: DCTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 44,
                          color: DCTheme.textMuted.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No barbers found nearby',
                          style: TextStyle(color: DCTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final barber = list[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < list.length - 1 ? 12 : 0,
                      ),
                      child: _BarberCard(
                        id: barber['id'] ?? '',
                        name: barber['full_name'] ??
                            barber['shop_name'] ??
                            'Unknown',
                        avatarUrl: barber['avatar_url'],
                        rating: ((barber['rating'] ?? 0) as num).toDouble(),
                        specialty: barber['shop_name'] ?? 'Barber',
                        onTap: () {
                          context.push('/barber/${barber['id']}');
                        },
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 3,
                itemBuilder: (_, i) => Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 12 : 0),
                  child: Container(
                    width: 130,
                    decoration: BoxDecoration(
                      color: DCTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: DCTheme.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            error: (e, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: DCTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: DCTheme.error, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'DC';
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _getGreeting(String? firstName) {
    final hour = DateTime.now().hour;
    String timeGreeting;
    if (hour < 12) {
      timeGreeting = 'Bright and early';
    } else if (hour < 17) {
      timeGreeting = "What's good";
    } else {
      timeGreeting = 'Good evening';
    }
    if (firstName != null && firstName.isNotEmpty) {
      return '$timeGreeting, $firstName!';
    }
    return 'Hey there!';
  }

  String _getSubtitle() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Precision cuts await';
    } else if (hour < 17) {
      return 'Your next look awaits';
    } else {
      return 'End your day sharp';
    }
  }
}

// ============ EXPLORE TAB ============
class _ExploreTab extends StatelessWidget {
  const _ExploreTab();

  @override
  Widget build(BuildContext context) {
    return const NearbyMapScreen();
  }
}

// ============ BOOKINGS TAB ============
class _BookingsTab extends StatelessWidget {
  const _BookingsTab();

  @override
  Widget build(BuildContext context) {
    return const BookingsTab();
  }
}

// ============ MESSAGES TAB ============
class _MessagesTab extends StatelessWidget {
  const _MessagesTab();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'Messages',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: DCTheme.text,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Chat with your barbers',
              style: TextStyle(color: DCTheme.textMuted, fontSize: 15),
            ),
          ),
          SizedBox(height: 8),
          Expanded(child: CustomerMessagesTab()),
        ],
      ),
    );
  }
}

// ============ PROFILE TAB ============
class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            profile.when(
              data: (p) => Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: DCTheme.primary, width: 3),
                ),
                child: ClipOval(
                  child: p?.avatarUrl != null
                      ? Image.network(p!.avatarUrl!, fit: BoxFit.cover)
                      : Container(
                          color: DCTheme.surface,
                          child: Center(
                            child: Text(
                              _getInitials(p?.fullName),
                              style: const TextStyle(
                                color: DCTheme.text,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              loading: () => Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: DCTheme.surface,
                ),
              ),
              error: (_, __) => Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: DCTheme.surface,
                ),
                child: const Icon(
                  Icons.person,
                  size: 48,
                  color: DCTheme.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 16),
            profile.when(
              data: (p) => Text(
                p?.fullName ?? 'Guest',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: DCTheme.text,
                ),
              ),
              loading: () => const Text(
                'Loading...',
                style: TextStyle(color: DCTheme.textMuted),
              ),
              error: (_, __) => const Text(
                'Error',
                style: TextStyle(color: DCTheme.error),
              ),
            ),
            const SizedBox(height: 32),
            _ProfileMenuItem(
              icon: Icons.person_outline,
              label: 'Edit Profile',
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.favorite_outline,
              label: 'Favorites',
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.payment_outlined,
              label: 'Payment Methods',
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.help_outline,
              label: 'Help & Support',
              onTap: () {},
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                },
                icon: const Icon(Icons.logout, color: DCTheme.error),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(color: DCTheme.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: DCTheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'DC';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: DCTheme.text),
        title: Text(label, style: const TextStyle(color: DCTheme.text)),
        trailing: const Icon(Icons.chevron_right, color: DCTheme.textMuted),
        tileColor: DCTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ============ SHARED WIDGETS ============
class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40, // w-10
          height: 40, // h-10
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(12), // rounded-xl
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24, // text-2xl
            fontWeight: FontWeight.bold,
            color: DCTheme.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12, // text-xs
            color: Color(0xFF9CA3AF), // text-gray-400
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? DCTheme.primary : DCTheme.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? DCTheme.primary : DCTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarberCard extends StatelessWidget {
  final String id;
  final String name;
  final String? avatarUrl;
  final double rating;
  final String specialty;
  final VoidCallback onTap;

  const _BarberCard({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.rating,
    required this.specialty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DCTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: DCTheme.primary, width: 2),
              ),
              child: ClipOval(
                child: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? Image.network(
                        avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallback(),
                      )
                    : _fallback(),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DCTheme.text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 12,
                    color: DCTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              specialty,
              style: TextStyle(
                fontSize: 11,
                color: DCTheme.textMuted.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: DCTheme.surfaceSecondary,
      child: const Center(
        child: Icon(Icons.content_cut, color: DCTheme.textMuted, size: 28),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final status = appointment['status'] ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: DCTheme.surfaceSecondary,
            ),
            child: const Icon(Icons.content_cut, color: DCTheme.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Appointment',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: DCTheme.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${appointment['date']} at ${appointment['time']}',
                  style: const TextStyle(
                    color: DCTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'confirmed'
                  ? DCTheme.success.withValues(alpha: 0.2)
                  : Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: status == 'confirmed' ? DCTheme.success : Colors.amber,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ FAVORITES TAB ============
class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'Favorites',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: DCTheme.text,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Your favorite barbers',
              style: TextStyle(color: DCTheme.textMuted, fontSize: 15),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_outline,
                    size: 64,
                    color: DCTheme.textMuted.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No favorites yet',
                    style: TextStyle(
                      color: DCTheme.textMuted,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the heart on a barber to add them here',
                    style: TextStyle(
                      color: DCTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ BARBER POLE ICON ============
class _BarberPoleIcon extends StatelessWidget {
  const _BarberPoleIcon();

  @override
  Widget build(BuildContext context) {
    // Match DC-1 web barber pole SVG exactly
    return SizedBox(
      width: 30,
      height: 30,
      child: CustomPaint(
        painter: _BarberPolePainter(),
      ),
    );
  }
}

class _BarberPolePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Scale factor for 30x30 from 32x32 viewBox
    final scale = size.width / 32;
    
    // Main pole body - white/gray gradient cylinder
    final poleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(13 * scale, 4 * scale, 6 * scale, 24 * scale),
      Radius.circular(3 * scale),
    );
    
    // Pole gradient (light 3D effect)
    final polePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFFE8E8E8),
          const Color(0xFFFFFFFF),
          const Color(0xFFD0D0D0),
        ],
      ).createShader(poleRect.outerRect);
    canvas.drawRRect(poleRect, polePaint);
    
    // Clip to pole shape for stripes
    canvas.save();
    canvas.clipRRect(poleRect);
    
    // Red spiral stripes - matching web SVG paths
    final redPaint1 = Paint()..color = const Color(0xFFDC2626).withValues(alpha: 0.95);
    final redPaint2 = Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.9);
    
    // Stripe 1
    final path1 = Path()
      ..moveTo(13 * scale, 6 * scale)
      ..lineTo(19 * scale, 9 * scale)
      ..lineTo(19 * scale, 12 * scale)
      ..lineTo(13 * scale, 9 * scale)
      ..close();
    canvas.drawPath(path1, redPaint1);
    
    // Stripe 2
    final path2 = Path()
      ..moveTo(13 * scale, 10 * scale)
      ..lineTo(19 * scale, 13 * scale)
      ..lineTo(19 * scale, 16 * scale)
      ..lineTo(13 * scale, 13 * scale)
      ..close();
    canvas.drawPath(path2, redPaint2);
    
    // Stripe 3
    final path3 = Path()
      ..moveTo(13 * scale, 14 * scale)
      ..lineTo(19 * scale, 17 * scale)
      ..lineTo(19 * scale, 20 * scale)
      ..lineTo(13 * scale, 17 * scale)
      ..close();
    canvas.drawPath(path3, redPaint1);
    
    // Stripe 4
    final path4 = Path()
      ..moveTo(13 * scale, 18 * scale)
      ..lineTo(19 * scale, 21 * scale)
      ..lineTo(19 * scale, 24 * scale)
      ..lineTo(13 * scale, 21 * scale)
      ..close();
    canvas.drawPath(path4, redPaint2);
    
    // Stripe 5
    final path5 = Path()
      ..moveTo(13 * scale, 22 * scale)
      ..lineTo(19 * scale, 25 * scale)
      ..lineTo(19 * scale, 27 * scale)
      ..lineTo(13 * scale, 24 * scale)
      ..close();
    canvas.drawPath(path5, redPaint1);
    
    // Glossy highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(17.5 * scale, 5 * scale, 0.8 * scale, 22 * scale),
        Radius.circular(0.4 * scale),
      ),
      highlightPaint,
    );
    
    canvas.restore();
    
    // Top cap (ellipse)
    final topCapPaint1 = Paint()..color = const Color(0xFFF3F4F6);
    final topCapPaint2 = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(16 * scale, 4 * scale),
        width: 7 * scale,
        height: 3.6 * scale,
      ),
      topCapPaint1,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(16 * scale, 4 * scale),
        width: 5 * scale,
        height: 2.4 * scale,
      ),
      topCapPaint2,
    );
    
    // Bottom cap (ellipse)
    final bottomCapPaint1 = Paint()..color = const Color(0xFFD1D5DB);
    final bottomCapPaint2 = Paint()..color = const Color(0xFFE5E7EB);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(16 * scale, 28 * scale),
        width: 7 * scale,
        height: 3.6 * scale,
      ),
      bottomCapPaint1,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(16 * scale, 28 * scale),
        width: 5 * scale,
        height: 2.4 * scale,
      ),
      bottomCapPaint2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
