import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/logger.dart';
import 'barber_list_screen.dart';
import 'bookings_tab.dart';
import 'messages_tab.dart';
import 'nearby_map_screen.dart';

// Provider to fetch trending barbers
final trendingBarbersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    Logger.debug('Fetching trending barbers');
    final response = await Supabase.instance.client
        .from('barbers')
        .select('*')
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(10);

    final barbers = List<Map<String, dynamic>>.from(response as List);
    Logger.debug('Found ${barbers.length} trending barbers');

    final result = barbers.map((b) {
      return {
        ...b,
        'full_name': b['shop_name'] ?? 'Unknown Barber',
        'rating': 0.0,
      };
    }).toList();

    return result;
  } catch (e, stack) {
    Logger.error('Failed to fetch trending barbers', e, stack);
    // Return empty list instead of rethrowing to prevent infinite loading
    return [];
  }
});

// Provider to fetch user stats
final userStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    Logger.debug('No authenticated user for stats');
    return {'bookings': 0, 'favorites': 0, 'spent': 0};
  }

  try {
    Logger.debug('Fetching user stats');

    final bookings = await Supabase.instance.client
        .from('appointments')
        .select('id')
        .eq('customer_id', user.id);

    final favorites = await Supabase.instance.client
        .from('user_favorites')
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

    final result = {
      'bookings': (bookings as List).length,
      'favorites': (favorites as List).length,
      'spent': totalSpent,
    };

    Logger.debug('User stats loaded successfully');
    return result;
  } catch (e, stack) {
    Logger.error('Failed to fetch user stats', e, stack);
    return {'bookings': 0, 'favorites': 0, 'spent': 0};
  }
});

// Provider to fetch upcoming appointments
final upcomingAppointmentsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    Logger.debug('No authenticated user for appointments');
    return [];
  }

  try {
    Logger.debug('Fetching upcoming appointments');
    final today = DateTime.now().toIso8601String().split('T')[0];

    final response = await Supabase.instance.client
        .from('appointments')
        .select('id, start_time, status, barber_id')
        .eq('customer_id', user.id)
        .inFilter('status', ['pending', 'confirmed'])
        .gte('start_time', today)
        .order('start_time', ascending: true)
        .limit(3);

    final result = List<Map<String, dynamic>>.from(response as List).map((apt) {
      final startTime = DateTime.tryParse(apt['start_time'] ?? '');
      return {
        ...apt,
        'date': startTime?.toIso8601String().split('T')[0] ?? '',
        'time': startTime != null
            ? '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}'
            : '',
      };
    }).toList();

    Logger.debug('Found ${result.length} upcoming appointments');
    return result;
  } catch (e, stack) {
    Logger.error('Failed to fetch upcoming appointments', e, stack);
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
  final Map<int, Widget> _cachedTabs = {};

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  Widget _buildCurrentTab() {
    // Tab mapping: 0=Home, 1=Nearby, 2=Bookings (center FAB), 3=Favorites, 4=Profile
    if (!_cachedTabs.containsKey(_currentIndex)) {
      _cachedTabs[_currentIndex] = switch (_currentIndex) {
        0 => _HomeTab(onNavigate: _navigateToTab),
        1 => const _NearbyTab(),
        2 => const _BookingsTabWrapper(),
        3 => const _FavoritesTab(),
        4 => const _ProfileTab(),
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
    final isFabSelected = _currentIndex == 2;

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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
              GestureDetector(
                onTap: () => _navigateToTab(2),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isFabSelected
                          ? [const Color(0xFFFFFFFF), const Color(0xFFF3F4F6)]
                          : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                    ),
                    border: isFabSelected
                        ? Border.all(color: const Color(0xFFEF4444), width: 3)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: isFabSelected
                            ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                            : const Color(0xFFEF4444).withValues(alpha: 0.4),
                        blurRadius: isFabSelected ? 16 : 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isFabSelected
                        ? const _BarberPoleIconSelected()
                        : const _BarberPoleIcon(),
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.star_outline,
                activeIcon: Icons.star,
                label: 'Favorites',
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
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, AsyncValue profile) {
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
          Positioned(
            right: -40,
            top: 10,
            bottom: 10,
            child: Opacity(
              opacity: 0.15,
              child: SvgPicture.asset(
                'assets/images/dc_logo.svg',
                width: 140,
                height: 140,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAvatar(profile),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        profile.when(
                          data: (p) => Text(
                            _getGreeting(p?.fullName?.split(' ').first),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          loading: () => const Text('Hey there!',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          error: (_, __) => const Text('Hey there!',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getSubtitle(),
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
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
                              content: Text('Notifications coming soon')),
                        );
                      },
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
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: profile.when(
          data: (p) {
            if (p?.avatarUrl != null && p!.avatarUrl!.isNotEmpty) {
              return Image.network(p.avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _avatarFallback(p.fullName));
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
          child: Text(initials,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18))),
    );
  }

  Widget _buildStatsCard(AsyncValue<Map<String, dynamic>> stats) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: DCTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: stats.when(
          data: (data) {
            final spentValue = ((data['spent'] ?? 0) as num).toStringAsFixed(0);
            return Row(
              children: [
                Expanded(
                    child: _StatItem(
                        icon: Icons.calendar_today,
                        iconBgColor: DCTheme.primary.withValues(alpha: 0.2),
                        iconColor: DCTheme.primary,
                        value: '${data['bookings']}',
                        label: 'Bookings')),
                Container(
                    width: 1,
                    height: 50,
                    color: Colors.white.withValues(alpha: 0.1)),
                Expanded(
                    child: _StatItem(
                        icon: Icons.star,
                        iconBgColor: Colors.amber.withValues(alpha: 0.2),
                        iconColor: Colors.amber,
                        value: '${data['favorites']}',
                        label: 'Favorites')),
                Container(
                    width: 1,
                    height: 50,
                    color: Colors.white.withValues(alpha: 0.1)),
                Expanded(
                    child: _StatItem(
                        icon: Icons.trending_up,
                        iconBgColor: DCTheme.info.withValues(alpha: 0.2),
                        iconColor: DCTheme.info,
                        value: '\$$spentValue',
                        label: 'Spent')),
              ],
            );
          },
          loading: () => const SizedBox(
              height: 80,
              child: Center(
                  child: CircularProgressIndicator(color: DCTheme.primary))),
          error: (_, __) => Row(
            children: [
              Expanded(
                  child: _StatItem(
                      icon: Icons.calendar_today,
                      iconBgColor: DCTheme.primary.withValues(alpha: 0.2),
                      iconColor: DCTheme.primary,
                      value: '0',
                      label: 'Bookings')),
              Container(
                  width: 1,
                  height: 50,
                  color: Colors.white.withValues(alpha: 0.1)),
              Expanded(
                  child: _StatItem(
                      icon: Icons.star,
                      iconBgColor: Colors.amber.withValues(alpha: 0.2),
                      iconColor: Colors.amber,
                      value: '0',
                      label: 'Favorites')),
              Container(
                  width: 1,
                  height: 50,
                  color: Colors.white.withValues(alpha: 0.1)),
              Expanded(
                  child: _StatItem(
                      icon: Icons.trending_up,
                      iconBgColor: DCTheme.info.withValues(alpha: 0.2),
                      iconColor: DCTheme.info,
                      value: '\$0',
                      label: 'Spent')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingSection(BuildContext context,
      AsyncValue<List<Map<String, dynamic>>> appointments) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Upcoming',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DCTheme.text)),
              GestureDetector(
                onTap: () => onNavigate(2),
                child: const Row(
                  children: [
                    Text('View All',
                        style: TextStyle(
                            color: DCTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right, color: DCTheme.primary, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          appointments.when(
            data: (list) {
              if (list.isEmpty) return _buildEmptyAppointments(context);
              return Column(
                  children: list
                      .map((apt) => _AppointmentCard(appointment: apt))
                      .toList());
            },
            loading: () => Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: DCTheme.surface,
                  borderRadius: BorderRadius.circular(12)),
              child: const Center(
                  child: CircularProgressIndicator(color: DCTheme.primary)),
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
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
          color: DCTheme.surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 36, color: DCTheme.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          const Text('No upcoming appointments',
              style: TextStyle(color: DCTheme.textMuted, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => onNavigate(1),
            style: ElevatedButton.styleFrom(
                backgroundColor: DCTheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0),
            child: const Text('Book Now',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingBarbersSection(
      BuildContext context, AsyncValue<List<Map<String, dynamic>>> barbers) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Trending Barbers',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: DCTheme.text)),
                GestureDetector(
                  onTap: () => onNavigate(1),
                  child: const Row(
                    children: [
                      Text('See All',
                          style: TextStyle(
                              color: DCTheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right,
                          color: DCTheme.primary, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          barbers.when(
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: DCTheme.surface,
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 36,
                            color: DCTheme.textMuted.withValues(alpha: 0.3)),
                        const SizedBox(height: 10),
                        const Text('No barbers found nearby',
                            style: TextStyle(
                                color: DCTheme.textMuted, fontSize: 14)),
                      ],
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final barber = list[index];
                    return Padding(
                      padding: EdgeInsets.only(
                          right: index < list.length - 1 ? 10 : 0),
                      child: _BarberCard(
                        id: barber['id'] ?? '',
                        name: barber['full_name'] ??
                            barber['shop_name'] ??
                            'Unknown',
                        avatarUrl: barber['avatar_url'],
                        rating: ((barber['rating'] ?? 0) as num).toDouble(),
                        specialty: barber['shop_name'] ?? 'Barber',
                        onTap: () => context.push('/barber/${barber['id']}'),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 3,
                itemBuilder: (_, i) => Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                  child: Container(
                      width: 120,
                      decoration: BoxDecoration(
                          color: DCTheme.surface,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Center(
                          child: CircularProgressIndicator(
                              color: DCTheme.primary, strokeWidth: 2))),
                ),
              ),
            ),
            error: (e, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: DCTheme.surface,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('Error: $e',
                      style:
                          const TextStyle(color: DCTheme.error, fontSize: 12))),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'DC';
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty)
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  static const _morningGreetings = [
    'Good morning',
    'Morning',
    'Hey there',
    "What's good",
    'Hello'
  ];
  static const _afternoonGreetings = [
    'Good afternoon',
    'Hey there',
    "What's up",
    'Afternoon',
    'Hey',
    "What's good"
  ];
  static const _eveningGreetings = [
    'Good evening',
    'Evening',
    'Hey there',
    "What's good"
  ];
  static const _lateNightGreetings = [
    'Hey there',
    "What's good",
    'Still up',
    'Hey night owl'
  ];

  static const _subtexts = [
    'Ready for a fresh cut?',
    "Let's get you looking sharp",
    'Fresh cuts, fresh starts',
    'Your next look awaits',
    'Stay sharp, stay fresh',
    'The chair is waiting',
    'Confidence starts here',
    'Sharp lines, sharp mind',
    'Your style, elevated',
    'Precision cuts await',
  ];

  String _getGreeting(String? firstName) {
    final hour = DateTime.now().hour;
    List<String> greetings;
    if (hour < 12) {
      greetings = _morningGreetings;
    } else if (hour < 17) {
      greetings = _afternoonGreetings;
    } else if (hour < 21) {
      greetings = _eveningGreetings;
    } else {
      greetings = _lateNightGreetings;
    }
    final randomIndex = DateTime.now().minute % greetings.length;
    final greeting = greetings[randomIndex];
    if (firstName != null && firstName.isNotEmpty)
      return '$greeting, $firstName!';
    return 'Hey there!';
  }

  String _getSubtitle() {
    final randomIndex = DateTime.now().minute % _subtexts.length;
    return _subtexts[randomIndex];
  }
}

// ============ NEARBY TAB ============
class _NearbyTab extends StatefulWidget {
  const _NearbyTab();

  @override
  State<_NearbyTab> createState() => _NearbyTabState();
}

class _NearbyTabState extends State<_NearbyTab> {
  bool _showMap = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DCTheme.background,
      body: Column(
        children: [
          _buildViewToggle(),
          Expanded(
            child:
                _showMap ? const NearbyMapScreen() : const BarberListScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      color: DCTheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                  child: _ViewToggleBtn(
                      icon: Icons.map_outlined,
                      label: 'Map',
                      isSelected: _showMap,
                      onTap: () => setState(() => _showMap = true))),
              const SizedBox(width: 8),
              Expanded(
                  child: _ViewToggleBtn(
                      icon: Icons.list_outlined,
                      label: 'List',
                      isSelected: !_showMap,
                      onTap: () => setState(() => _showMap = false))),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewToggleBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewToggleBtn(
      {required this.icon,
      required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? DCTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? null
              : Border.all(color: DCTheme.textMuted.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18, color: isSelected ? Colors.white : DCTheme.textMuted),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.white : DCTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ============ BOOKINGS TAB WRAPPER ============
class _BookingsTabWrapper extends StatelessWidget {
  const _BookingsTabWrapper();

  @override
  Widget build(BuildContext context) => const BookingsTab();
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
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text('Favorites',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: DCTheme.text)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Your favorite barbers',
                style: TextStyle(color: DCTheme.textMuted, fontSize: 15)),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_outline,
                      size: 64,
                      color: DCTheme.textMuted.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text('No favorites yet',
                      style: TextStyle(
                          color: DCTheme.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Tap the heart on a barber to add them here',
                      style: TextStyle(color: DCTheme.textMuted, fontSize: 14)),
                ],
              ),
            ),
          ),
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
                    border: Border.all(color: DCTheme.primary, width: 3)),
                child: ClipOval(
                  child: p?.avatarUrl != null
                      ? Image.network(p!.avatarUrl!, fit: BoxFit.cover)
                      : Container(
                          color: DCTheme.surface,
                          child: Center(
                              child: Text(_getInitials(p?.fullName),
                                  style: const TextStyle(
                                      color: DCTheme.text,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold)))),
                ),
              ),
              loading: () => Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: DCTheme.surface)),
              error: (_, __) => Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: DCTheme.surface),
                  child: const Icon(Icons.person,
                      size: 48, color: DCTheme.textMuted)),
            ),
            const SizedBox(height: 16),
            profile.when(
              data: (p) => Text(p?.fullName ?? 'Guest',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: DCTheme.text)),
              loading: () => const Text('Loading...',
                  style: TextStyle(color: DCTheme.textMuted)),
              error: (_, __) =>
                  const Text('Error', style: TextStyle(color: DCTheme.error)),
            ),
            const SizedBox(height: 32),
            _ProfileMenuItem(
                icon: Icons.person_outline,
                label: 'Edit Profile',
                onTap: () {}),
            _ProfileMenuItem(
                icon: Icons.favorite_outline, label: 'Favorites', onTap: () {}),
            _ProfileMenuItem(
                icon: Icons.payment_outlined,
                label: 'Payment Methods',
                onTap: () {}),
            _ProfileMenuItem(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () {}),
            _ProfileMenuItem(
                icon: Icons.help_outline,
                label: 'Help & Support',
                onTap: () {}),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async =>
                    await Supabase.instance.client.auth.signOut(),
                icon: const Icon(Icons.logout, color: DCTheme.error),
                label: const Text('Sign Out',
                    style: TextStyle(color: DCTheme.error)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: DCTheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
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

  const _ProfileMenuItem(
      {required this.icon, required this.label, required this.onTap});

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

  const _StatItem(
      {required this.icon,
      required this.iconBgColor,
      required this.iconColor,
      required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: iconBgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18)),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: DCTheme.text)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: DCTheme.textMuted.withValues(alpha: 0.8))),
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

  const _NavItem(
      {required this.icon,
      required this.activeIcon,
      required this.label,
      required this.isActive,
      required this.onTap});

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
            Icon(isActive ? activeIcon : icon,
                color: isActive ? DCTheme.primary : DCTheme.textMuted,
                size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? DCTheme.primary : DCTheme.textMuted)),
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

  const _BarberCard(
      {required this.id,
      required this.name,
      this.avatarUrl,
      required this.rating,
      required this.specialty,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: DCTheme.surface, borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: DCTheme.primary, width: 2)),
              child: ClipOval(
                child: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? Image.network(avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallback())
                    : _fallback(),
              ),
            ),
            const SizedBox(height: 10),
            Text(name,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DCTheme.text),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.star, color: Colors.amber, size: 12),
              const SizedBox(width: 3),
              Text(rating.toStringAsFixed(1),
                  style:
                      const TextStyle(fontSize: 11, color: DCTheme.textMuted))
            ]),
            const SizedBox(height: 2),
            Text(specialty,
                style: TextStyle(
                    fontSize: 10,
                    color: DCTheme.textMuted.withValues(alpha: 0.7)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _fallback() => Container(
      color: DCTheme.surfaceSecondary,
      child: const Center(
          child: Icon(Icons.content_cut, color: DCTheme.textMuted, size: 24)));
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
          color: DCTheme.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: DCTheme.surfaceSecondary),
              child: const Icon(Icons.content_cut, color: DCTheme.textMuted)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Appointment',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: DCTheme.text)),
                const SizedBox(height: 4),
                Text('${appointment['date']} at ${appointment['time']}',
                    style: const TextStyle(
                        color: DCTheme.textMuted, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: status == 'confirmed'
                    ? DCTheme.success.withValues(alpha: 0.2)
                    : Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8)),
            child: Text(status,
                style: TextStyle(
                    color:
                        status == 'confirmed' ? DCTheme.success : Colors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
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
    return SizedBox(
        width: 30,
        height: 30,
        child: CustomPaint(painter: _BarberPolePainter()));
  }
}

class _BarberPoleIconSelected extends StatelessWidget {
  const _BarberPoleIconSelected();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 30,
        height: 30,
        child: CustomPaint(painter: _BarberPolePainterSelected()));
  }
}

class _BarberPolePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 32;

    final poleRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(13 * scale, 4 * scale, 6 * scale, 24 * scale),
        Radius.circular(3 * scale));
    final polePaint = Paint()
      ..shader = const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFFE8E8E8), Color(0xFFFFFFFF), Color(0xFFD0D0D0)])
          .createShader(poleRect.outerRect);
    canvas.drawRRect(poleRect, polePaint);

    canvas.save();
    canvas.clipRRect(poleRect);

    final redPaint1 = Paint()
      ..color = const Color(0xFFDC2626).withValues(alpha: 0.95);
    final redPaint2 = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.9);

    for (int i = 0; i < 5; i++) {
      final path = Path()
        ..moveTo(13 * scale, (6 + i * 4) * scale)
        ..lineTo(19 * scale, (9 + i * 4) * scale)
        ..lineTo(19 * scale, (12 + i * 4) * scale)
        ..lineTo(13 * scale, (9 + i * 4) * scale)
        ..close();
      canvas.drawPath(path, i % 2 == 0 ? redPaint1 : redPaint2);
    }

    final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(17.5 * scale, 5 * scale, 0.8 * scale, 22 * scale),
            Radius.circular(0.4 * scale)),
        highlightPaint);
    canvas.restore();

    final topCapPaint1 = Paint()..color = const Color(0xFFF3F4F6);
    final topCapPaint2 = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(16 * scale, 4 * scale),
            width: 7 * scale,
            height: 3.6 * scale),
        topCapPaint1);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(16 * scale, 4 * scale),
            width: 5 * scale,
            height: 2.4 * scale),
        topCapPaint2);

    final bottomCapPaint1 = Paint()..color = const Color(0xFFD1D5DB);
    final bottomCapPaint2 = Paint()..color = const Color(0xFFE5E7EB);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(16 * scale, 28 * scale),
            width: 7 * scale,
            height: 3.6 * scale),
        bottomCapPaint1);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(16 * scale, 28 * scale),
            width: 5 * scale,
            height: 2.4 * scale),
        bottomCapPaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BarberPolePainterSelected extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 32;

    final poleRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(13 * scale, 4 * scale, 6 * scale, 24 * scale),
        Radius.circular(3 * scale));
    final polePaint = Paint()
      ..shader = const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFFE5E7EB), Color(0xFFF9FAFB), Color(0xFFD1D5DB)])
          .createShader(poleRect.outerRect);
    canvas.drawRRect(poleRect, polePaint);

    canvas.save();
    canvas.clipRRect(poleRect);

    final redPaint1 = Paint()..color = const Color(0xFFB91C1C);
    final redPaint2 = Paint()..color = const Color(0xFFDC2626);

    for (int i = 0; i < 5; i++) {
      final path = Path()
        ..moveTo(13 * scale, (6 + i * 4) * scale)
        ..lineTo(19 * scale, (9 + i * 4) * scale)
        ..lineTo(19 * scale, (12 + i * 4) * scale)
        ..lineTo(13 * scale, (9 + i * 4) * scale)
        ..close();
      canvas.drawPath(path, i % 2 == 0 ? redPaint1 : redPaint2);
    }

    canvas.restore();

    final topCapPaint1 = Paint()..color = const Color(0xFFD1D5DB);
    final topCapPaint2 = Paint()..color = const Color(0xFFE5E7EB);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(16 * scale, 4 * scale),
            width: 7 * scale,
            height: 3.6 * scale),
        topCapPaint1);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(16 * scale, 4 * scale),
            width: 5 * scale,
            height: 2.4 * scale),
        topCapPaint2);

    final bottomCapPaint1 = Paint()..color = const Color(0xFF9CA3AF);
    final bottomCapPaint2 = Paint()..color = const Color(0xFFD1D5DB);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(16 * scale, 28 * scale),
            width: 7 * scale,
            height: 3.6 * scale),
        bottomCapPaint1);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(16 * scale, 28 * scale),
            width: 5 * scale,
            height: 2.4 * scale),
        bottomCapPaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
