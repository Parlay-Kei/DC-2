import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

// Provider to fetch trending barbers
final trendingBarbersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final profilesResponse = await Supabase.instance.client
        .from('profiles')
        .select('id, full_name, avatar_url')
        .eq('role', 'barber')
        .limit(10);

    final profiles = List<Map<String, dynamic>>.from(profilesResponse);

    if (profiles.isEmpty) return [];

    final profileIds = profiles.map((p) => p['id'] as String).toList();

    final barbersResponse = await Supabase.instance.client
        .from('barbers')
        .select('*')
        .inFilter('id', profileIds)
        .eq('is_active', true);

    final barbers = List<Map<String, dynamic>>.from(barbersResponse);

    final profileMap = Map.fromEntries(
      profiles.map((p) => MapEntry(p['id'] as String, p)),
    );

    return barbers.map((barber) {
      final profile = profileMap[barber['id']];
      return {
        ...barber,
        'full_name': profile?['full_name'] ?? 'Unknown Barber',
        'avatar_url': profile?['avatar_url'],
      };
    }).toList();
  } catch (e) {
    final response = await Supabase.instance.client
        .from('barbers')
        .select('*')
        .eq('is_active', true)
        .limit(10);

    return List<Map<String, dynamic>>.from(response).map((b) {
      return {
        ...b,
        'full_name': b['shop_name'] ?? 'Unknown Barber',
      };
    }).toList();
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
        .select('id, date, time, status, barber_id')
        .eq('customer_id', user.id)
        .inFilter('status', ['pending', 'confirmed'])
        .gte('date', today)
        .order('date', ascending: true)
        .limit(3);

    return List<Map<String, dynamic>>.from(response);
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

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DCTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(onNavigate: _navigateToTab),
          const _ExploreTab(),
          const _BookingsTab(),
          const _MessagesTab(),
          const _ProfileTab(),
        ],
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
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore,
                label: 'Explore',
                isActive: _currentIndex == 1,
                onTap: () => _navigateToTab(1),
              ),
              _NavItem(
                icon: Icons.calendar_today_outlined,
                activeIcon: Icons.calendar_today,
                label: 'Bookings',
                isActive: _currentIndex == 2,
                onTap: () => _navigateToTab(2),
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'Messages',
                isActive: _currentIndex == 3,
                onTap: () => _navigateToTab(3),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                isActive: _currentIndex == 4,
                onTap: () => _navigateToTab(4),
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
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.2,
                child: SvgPicture.asset(
                  'assets/images/dc_logo.svg',
                  width: 200,
                  height: 200,
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildAvatar(profile),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          color: Colors.white,
                          iconSize: 22,
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
                  const SizedBox(height: 20),
                  profile.when(
                    data: (p) => Text(
                      _getGreeting(p?.fullName?.split(' ').first),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    loading: () => const Text(
                      'Hey there! 👋',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    error: (_, __) => const Text(
                      'Hey there! 👋',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ready for a fresh cut?',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.85),
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

  Widget _buildAvatar(AsyncValue profile) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
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
          loading: () => Container(
            color: Colors.white.withValues(alpha: 0.2),
          ),
          error: (_, __) => _avatarFallback(null),
        ),
      ),
    );
  }

  Widget _avatarFallback(String? name) {
    final initials = _getInitials(name);
    return Container(
      color: Colors.white.withValues(alpha: 0.2),
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
      offset: const Offset(0, -24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
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
                  height: 60,
                  color: Colors.white.withValues(alpha: 0.1),
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
                  height: 60,
                  color: Colors.white.withValues(alpha: 0.1),
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
                  height: 60,
                  color: Colors.white.withValues(alpha: 0.1),
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
                  height: 60,
                  color: Colors.white.withValues(alpha: 0.1),
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
                          Icons.person_search,
                          size: 44,
                          color: DCTheme.textMuted.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No barbers available',
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'View ${barber['full_name'] ?? barber['shop_name']}\'s profile',
                              ),
                            ),
                          );
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
      timeGreeting = 'Good morning';
    } else if (hour < 17) {
      timeGreeting = 'Good afternoon';
    } else {
      timeGreeting = 'Good evening';
    }
    if (firstName != null && firstName.isNotEmpty) {
      return '$timeGreeting, $firstName! 👋';
    }
    return 'Hey there! 👋';
  }
}

// ============ EXPLORE TAB ============
class _ExploreTab extends StatelessWidget {
  const _ExploreTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Explore',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: DCTheme.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Find your perfect barber',
              style: TextStyle(color: DCTheme.textMuted, fontSize: 15),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: DCTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const TextField(
                style: TextStyle(color: DCTheme.text),
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: DCTheme.textMuted),
                  hintText: 'Search barbers...',
                  hintStyle: TextStyle(color: DCTheme.textMuted),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: DCTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 64,
                        color: DCTheme.textMuted.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Map View Coming Soon',
                        style:
                            TextStyle(color: DCTheme.textMuted, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ BOOKINGS TAB ============
class _BookingsTab extends StatelessWidget {
  const _BookingsTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bookings',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: DCTheme.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your appointments',
              style: TextStyle(color: DCTheme.textMuted, fontSize: 15),
            ),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: DCTheme.textMuted.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No bookings yet',
                    style: TextStyle(color: DCTheme.textMuted, fontSize: 16),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// ============ MESSAGES TAB ============
class _MessagesTab extends StatelessWidget {
  const _MessagesTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Messages',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: DCTheme.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chat with barbers',
              style: TextStyle(color: DCTheme.textMuted, fontSize: 15),
            ),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: DCTheme.textMuted.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No messages yet',
                    style: TextStyle(color: DCTheme.textMuted, fontSize: 16),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
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
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: DCTheme.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: DCTheme.textMuted.withValues(alpha: 0.8),
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
