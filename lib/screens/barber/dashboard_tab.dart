import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/barber_dashboard_provider.dart';
import '../../services/booking_service.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final stats = ref.watch(barberStatsProvider);
    final todayApts = ref.watch(barberTodayAppointmentsProvider);
    final pendingApts = ref.watch(pendingAppointmentsProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(barberStatsProvider);
          ref.invalidate(barberTodayAppointmentsProvider);
          ref.invalidate(pendingAppointmentsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(profile),
              const SizedBox(height: 24),
              _buildStatsGrid(stats),
              const SizedBox(height: 24),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              _buildPendingSection(ref, pendingApts),
              const SizedBox(height: 24),
              _buildTodaySection(ref, todayApts),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue profile) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              profile.when(
                data: (p) => Text(
                  '$greeting, ${p?.fullName?.split(' ').first ?? 'Barber'}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: DCTheme.text,
                  ),
                ),
                loading: () => Text(
                  '$greeting!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: DCTheme.text,
                  ),
                ),
                error: (_, __) => Text(
                  '$greeting!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: DCTheme.text,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(DateTime.now()),
                style: const TextStyle(color: DCTheme.textMuted),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: DCTheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: DCTheme.text,
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(AsyncValue<BarberStats> statsAsync) {
    return statsAsync.when(
      data: (stats) => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: "Today's Earnings",
                  value: '\$${stats.todayEarnings.toStringAsFixed(0)}',
                  icon: Icons.attach_money,
                  color: DCTheme.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Appointments',
                  value: '${stats.todayAppointments}',
                  icon: Icons.calendar_today,
                  color: DCTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'This Week',
                  value: '\$${stats.weekEarnings.toStringAsFixed(0)}',
                  icon: Icons.trending_up,
                  color: DCTheme.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Rating',
                  value: stats.rating.toStringAsFixed(1),
                  subtitle: '${stats.totalReviews} reviews',
                  icon: Icons.star,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: DCTheme.primary),
        ),
      ),
      error: (_, __) => const Center(
        child:
            Text('Error loading stats', style: TextStyle(color: DCTheme.error)),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DCTheme.text,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.edit_calendar,
                label: 'Availability',
                onTap: () => context.push('/barber/availability'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                icon: Icons.list_alt,
                label: 'Services',
                onTap: () => context.push('/barber/services'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                icon: Icons.account_balance_wallet,
                label: 'Earnings',
                onTap: () => context.push('/barber/earnings'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPendingSection(
      WidgetRef ref, AsyncValue<List<Booking>> pendingAsync) {
    return pendingAsync.when(
      data: (pending) {
        if (pending.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Pending Approval',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: DCTheme.text,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: DCTheme.warning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${pending.length}',
                        style: const TextStyle(
                          color: DCTheme.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...pending.take(3).map(
                  (booking) => _PendingBookingCard(
                    booking: booking,
                    onAccept: () => _handleAccept(ref, booking),
                    onDecline: () => _handleDecline(ref, booking),
                  ),
                ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildTodaySection(
      WidgetRef ref, AsyncValue<List<Booking>> todayAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Schedule",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DCTheme.text,
          ),
        ),
        const SizedBox(height: 12),
        todayAsync.when(
          data: (bookings) {
            if (bookings.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: DCTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 48,
                      color: DCTheme.textMuted.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No appointments today',
                      style: TextStyle(color: DCTheme.textMuted),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enjoy your free time!',
                      style: TextStyle(color: DCTheme.textDark, fontSize: 13),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children:
                  bookings.map((b) => _AppointmentCard(booking: b)).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: DCTheme.primary),
            ),
          ),
          error: (_, __) => const Center(
            child: Text('Error loading appointments'),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAccept(WidgetRef ref, Booking booking) async {
    final service = BookingService();
    await service.confirmBooking(booking.id);
    ref.invalidate(pendingAppointmentsProvider);
    ref.invalidate(barberTodayAppointmentsProvider);
    ref.invalidate(barberStatsProvider);
  }

  Future<void> _handleDecline(WidgetRef ref, Booking booking) async {
    final service = BookingService();
    await service.cancelBooking(booking.id);
    ref.invalidate(pendingAppointmentsProvider);
  }

  String _formatDate(DateTime date) {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
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
    return '${days[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style:
                      const TextStyle(color: DCTheme.textMuted, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: DCTheme.text,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(color: DCTheme.textMuted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: DCTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: DCTheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: DCTheme.text,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingBookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _PendingBookingCard({
    required this.booking,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DCTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: DCTheme.surfaceSecondary,
                backgroundImage: booking.customerAvatar != null
                    ? NetworkImage(booking.customerAvatar!)
                    : null,
                child: booking.customerAvatar == null
                    ? Text(
                        booking.customerName?.isNotEmpty == true
                            ? booking.customerName![0].toUpperCase()
                            : 'C',
                        style: const TextStyle(color: DCTheme.text),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.customerName ?? 'Customer',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: DCTheme.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.serviceName ?? 'Service',
                      style: const TextStyle(
                          color: DCTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDate(booking.scheduledDate),
                    style: const TextStyle(color: DCTheme.text, fontSize: 13),
                  ),
                  Text(
                    _formatTime(booking.scheduledTime),
                    style: const TextStyle(
                      color: DCTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DCTheme.error,
                    side: const BorderSide(color: DCTheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DCTheme.success,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
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

class _AppointmentCard extends StatelessWidget {
  final Booking booking;

  const _AppointmentCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: DCTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  _formatTime(booking.scheduledTime),
                  style: const TextStyle(
                    color: DCTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundColor: DCTheme.surfaceSecondary,
            backgroundImage: booking.customerAvatar != null
                ? NetworkImage(booking.customerAvatar!)
                : null,
            child: booking.customerAvatar == null
                ? Text(
                    booking.customerName?.isNotEmpty == true
                        ? booking.customerName![0].toUpperCase()
                        : 'C',
                    style: const TextStyle(color: DCTheme.text, fontSize: 14),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.customerName ?? 'Customer',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: DCTheme.text,
                  ),
                ),
                Text(
                  booking.serviceName ?? 'Service',
                  style:
                      const TextStyle(color: DCTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          _buildStatusBadge(),
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
        label = 'Done';
        break;
      default:
        color = DCTheme.textMuted;
        label = booking.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute\n$period';
  }
}
