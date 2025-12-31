import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../models/booking.dart';
import '../../../providers/barber_dashboard_provider.dart';
import '../../../services/booking_service.dart';

class ScheduleTab extends ConsumerStatefulWidget {
  const ScheduleTab({super.key});

  @override
  ConsumerState<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends ConsumerState<ScheduleTab> {
  late DateTime _selectedDate;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _pageController = PageController(initialPage: 500);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildWeekSelector(),
          const Divider(color: DCTheme.border, height: 1),
          Expanded(child: _buildDaySchedule()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Schedule',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: DCTheme.text,
                ),
              ),
              Text(
                _formatMonthYear(_selectedDate),
                style: const TextStyle(color: DCTheme.textMuted),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.today, color: DCTheme.primary),
                onPressed: () {
                  setState(() => _selectedDate = DateTime.now());
                  _pageController.animateToPage(
                    500,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                tooltip: 'Today',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSelector() {
    return SizedBox(
      height: 90,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          final offset = index - 500;
          final weekStart =
              _getWeekStart(DateTime.now()).add(Duration(days: offset * 7));
          setState(() => _selectedDate = weekStart);
        },
        itemBuilder: (context, index) {
          final offset = index - 500;
          final weekStart =
              _getWeekStart(DateTime.now()).add(Duration(days: offset * 7));
          return _buildWeekDays(weekStart);
        },
      ),
    );
  }

  Widget _buildWeekDays(DateTime weekStart) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final date = weekStart.add(Duration(days: index));
          final isSelected = _isSameDay(date, _selectedDate);
          final isToday = _isSameDay(date, DateTime.now());

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? DCTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getDayName(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : DCTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : DCTheme.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isToday)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.white : DCTheme.primary,
                      ),
                    )
                  else
                    const SizedBox(height: 6),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDaySchedule() {
    final appointmentsAsync = ref.watch(barberUpcomingAppointmentsProvider);

    return appointmentsAsync.when(
      data: (allAppointments) {
        final dayAppointments = allAppointments
            .where((apt) => _isSameDay(apt.scheduledDate, _selectedDate))
            .toList();

        if (dayAppointments.isEmpty) {
          return _buildEmptyDay();
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(barberUpcomingAppointmentsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dayAppointments.length,
            itemBuilder: (context, index) => _ScheduleAppointmentCard(
              booking: dayAppointments[index],
              onComplete: () => _handleComplete(dayAppointments[index]),
              onNoShow: () => _handleNoShow(dayAppointments[index]),
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
            Text('Error: $e', style: const TextStyle(color: DCTheme.textMuted)),
            TextButton(
              onPressed: () =>
                  ref.invalidate(barberUpcomingAppointmentsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDay() {
    final isPast = _selectedDate
        .isBefore(DateTime.now().subtract(const Duration(days: 1)));

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPast ? Icons.history : Icons.event_available,
              size: 64,
              color: DCTheme.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isPast
                  ? 'No appointments on this day'
                  : 'No appointments scheduled',
              style: const TextStyle(
                color: DCTheme.textMuted,
                fontSize: 16,
              ),
            ),
            if (!isPast) ...[
              const SizedBox(height: 8),
              Text(
                _formatFullDate(_selectedDate),
                style: const TextStyle(color: DCTheme.textDark),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleComplete(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DCTheme.surface,
        title: const Text('Complete Appointment?',
            style: TextStyle(color: DCTheme.text)),
        content: const Text(
          'Mark this appointment as completed?',
          style: TextStyle(color: DCTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: DCTheme.success),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = BookingService();
      await service.completeBooking(booking.id);
      ref.invalidate(barberUpcomingAppointmentsProvider);
      ref.invalidate(barberStatsProvider);
    }
  }

  Future<void> _handleNoShow(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DCTheme.surface,
        title: const Text('Mark as No-Show?',
            style: TextStyle(color: DCTheme.text)),
        content: const Text(
          'This will mark the customer as a no-show.',
          style: TextStyle(color: DCTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: DCTheme.error),
            child: const Text('No-Show'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = BookingService();
      await service.markNoShow(booking.id);
      ref.invalidate(barberUpcomingAppointmentsProvider);
    }
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatFullDate(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
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
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}

class _ScheduleAppointmentCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onComplete;
  final VoidCallback onNoShow;

  const _ScheduleAppointmentCard({
    required this.booking,
    required this.onComplete,
    required this.onNoShow,
  });

  @override
  Widget build(BuildContext context) {
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
            child: Row(
              children: [
                _buildTimeColumn(),
                const SizedBox(width: 16),
                _buildCustomerInfo(),
                _buildPrice(),
              ],
            ),
          ),
          if (booking.isConfirmed)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onNoShow,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DCTheme.error,
                        side: const BorderSide(color: DCTheme.error),
                      ),
                      child: const Text('No-Show'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onComplete,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: DCTheme.success),
                      child: const Text('Complete'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn() {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: DCTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            _formatTimeShort(booking.scheduledTime),
            style: const TextStyle(
              color: DCTheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            _getAmPm(booking.scheduledTime),
            style: const TextStyle(
              color: DCTheme.primary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      booking.serviceName ?? 'Service',
                      style: const TextStyle(
                          color: DCTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DCTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes, size: 14, color: DCTheme.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking.notes!,
                      style: const TextStyle(
                          color: DCTheme.textMuted, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '\$${booking.totalPrice.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: DCTheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        _buildStatusBadge(),
      ],
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
      default:
        color = DCTheme.textMuted;
        label = booking.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatTimeShort(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute';
  }

  String _getAmPm(String time) {
    final hour = int.parse(time.split(':')[0]);
    return hour >= 12 ? 'PM' : 'AM';
  }
}
