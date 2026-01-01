import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/common/branded_header.dart';

class BookingsTab extends ConsumerStatefulWidget {
  const BookingsTab({super.key});

  @override
  ConsumerState<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends ConsumerState<BookingsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Greeting arrays matching web greetingUtils.ts
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
    // Use a seeded random based on current minute to have some consistency during a session
    final randomIndex = DateTime.now().minute % greetings.length;
    final greeting = greetings[randomIndex];
    if (firstName != null && firstName.isNotEmpty)
      return '$greeting, $firstName!';
    return 'Hey there!';
  }

  String _getSubtitle() {
    // Use a seeded random based on current minute
    final randomIndex = DateTime.now().minute % _subtexts.length;
    return _subtexts[randomIndex];
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    final upcomingBookings = ref.watch(upcomingBookingsProvider);
    final bookingHistory = ref.watch(bookingHistoryProvider);

    // Get counts from the providers
    final upcomingCount = upcomingBookings.maybeWhen(
      data: (bookings) => bookings.length,
      orElse: () => 0,
    );
    final historyCount = bookingHistory.maybeWhen(
      data: (bookings) => bookings.length,
      orElse: () => 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Branded header with personalized greeting - matching web PageHeader
        profile.when(
          data: (p) => BrandedHeader(
            title: _getGreeting(p?.fullName?.split(' ').first),
            subtitle: _getSubtitle(),
          ),
          loading: () => BrandedHeader(
            title: 'Hey there!',
            subtitle: _getSubtitle(),
          ),
          error: (_, __) => BrandedHeader(
            title: 'Hey there!',
            subtitle: _getSubtitle(),
          ),
        ),

        // Section title - matching web "Upcoming Appointments" title
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Text(
            'Upcoming Appointments',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: DCTheme.text,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),

        // Tabs - matching web dark background with white active pill
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: DCTheme.surface, // gray-800 equivalent
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              // Upcoming Tab
              Expanded(
                child: GestureDetector(
                  onTap: () => _tabController.animateTo(0),
                  child: AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      final isActive = _tabController.index == 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          'Upcoming ($upcomingCount)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isActive
                                ? const Color(0xFF1F2937)
                                : DCTheme.textMuted,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Past Tab
              Expanded(
                child: GestureDetector(
                  onTap: () => _tabController.animateTo(1),
                  child: AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      final isActive = _tabController.index == 1;
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          'Past ($historyCount)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isActive
                                ? const Color(0xFF1F2937)
                                : DCTheme.textMuted,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _UpcomingBookings(),
              _BookingHistory(),
            ],
          ),
        ),
      ],
    );
  }
}

class _UpcomingBookings extends ConsumerWidget {
  const _UpcomingBookings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(upcomingBookingsProvider);

    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.calendar_today_outlined,
            title: 'No upcoming appointments',
            subtitle: 'Book your next haircut today!',
            buttonLabel: 'Find a Barber',
            onPressed: () => context.push('/nearby'),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(upcomingBookingsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: bookings.length,
            itemBuilder: (context, index) => _BookingCard(
              booking: bookings[index],
              showActions: true,
            ),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: DCTheme.primary),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: DCTheme.error, size: 48),
            const SizedBox(height: 16),
            const Text('Error loading bookings',
                style: TextStyle(color: DCTheme.textMuted)),
            TextButton(
              onPressed: () => ref.invalidate(upcomingBookingsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingHistory extends ConsumerWidget {
  const _BookingHistory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(bookingHistoryProvider);

    return historyAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.history,
            title: 'No past appointments',
            subtitle: 'Your booking history will appear here',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(bookingHistoryProvider),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: bookings.length,
            itemBuilder: (context, index) => _BookingCard(
              booking: bookings[index],
              showActions: false,
            ),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: DCTheme.primary),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: DCTheme.error, size: 48),
            const SizedBox(height: 16),
            const Text('Error loading history',
                style: TextStyle(color: DCTheme.textMuted)),
            TextButton(
              onPressed: () => ref.invalidate(bookingHistoryProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildEmptyState(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  String? buttonLabel,
  VoidCallback? onPressed,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: DCTheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 40,
              color: DCTheme.textMuted.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: DCTheme.text,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: DCTheme.textMuted,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (buttonLabel != null && onPressed != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: DCTheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _BookingCard extends ConsumerWidget {
  final Booking booking;
  final bool showActions;

  const _BookingCard({
    required this.booking,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DCTheme.surfaceSecondary,
                        border: Border.all(color: DCTheme.primary, width: 2),
                      ),
                      child: const Icon(
                        Icons.content_cut,
                        color: DCTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.serviceName ?? 'Haircut',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: DCTheme.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'with Barber',
                            style: TextStyle(
                              color: DCTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: DCTheme.border, height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.calendar_today,
                        _formatDate(booking.scheduledDate),
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.access_time,
                        _formatTime(booking.scheduledTime),
                      ),
                    ),
                    Text(
                      '\$${booking.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: DCTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showActions && (booking.isPending || booking.isConfirmed))
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showCancelDialog(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DCTheme.error,
                        side: const BorderSide(color: DCTheme.error),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showRescheduleSheet(context),
                      child: const Text('Reschedule'),
                    ),
                  ),
                ],
              ),
            ),
          if (!showActions && booking.isCompleted && !booking.hasReview)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showReviewSheet(context),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Leave a Review'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String label;

    switch (booking.status) {
      case 'confirmed':
        color = DCTheme.success;
        label = 'Confirmed';
        break;
      case 'pending':
        color = Colors.amber;
        label = 'Pending';
        break;
      case 'completed':
        color = DCTheme.info;
        label = 'Completed';
        break;
      case 'cancelled':
        color = DCTheme.error;
        label = 'Cancelled';
        break;
      case 'expired':
        color = DCTheme.textDark;
        label = 'Expired';
        break;
      case 'no_show':
        color = DCTheme.textMuted;
        label = 'No Show';
        break;
      default:
        color = DCTheme.textMuted;
        label = booking.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: DCTheme.textMuted),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: DCTheme.text, fontSize: 13),
        ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DCTheme.surface,
        title: const Text('Cancel Booking?',
            style: TextStyle(color: DCTheme.text)),
        content: const Text(
          'Are you sure you want to cancel this appointment? This action cannot be undone.',
          style: TextStyle(color: DCTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final service = ref.read(bookingServiceProvider);
              await service.cancelBooking(booking.id);
              ref.invalidate(upcomingBookingsProvider);
              ref.invalidate(bookingHistoryProvider);
            },
            style: ElevatedButton.styleFrom(backgroundColor: DCTheme.error),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }

  void _showRescheduleSheet(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reschedule coming soon')),
    );
  }

  void _showReviewSheet(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review coming soon')),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
