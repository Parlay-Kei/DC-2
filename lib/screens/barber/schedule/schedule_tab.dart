import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
              // Block Time button
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: () => _showBlockTimeSheet(),
                  icon: const Icon(Icons.block, size: 18),
                  label: const Text('Block'),
                  style: TextButton.styleFrom(
                    foregroundColor: DCTheme.warning,
                    backgroundColor: DCTheme.warning.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
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
              IconButton(
                icon: const Icon(Icons.settings, color: DCTheme.textMuted),
                onPressed: () => context.push('/barber/availability'),
                tooltip: 'Manage Hours',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBlockTimeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BlockTimeSheet(
        selectedDate: _selectedDate,
        onSave: (reason, startTime, endTime, isAllDay) {
          // TODO: Save blocked time to database
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAllDay
                ? 'Blocked all day: ${reason ?? "Personal time"}'
                : 'Blocked $startTime - $endTime: ${reason ?? "Personal time"}'),
              backgroundColor: DCTheme.success,
            ),
          );
          // Refresh the schedule
          ref.invalidate(barberUpcomingAppointmentsProvider);
        },
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Day status card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: DCTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  isPast ? Icons.history : Icons.event_available,
                  size: 48,
                  color: DCTheme.success.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  isPast
                      ? 'No appointments on this day'
                      : 'All Clear!',
                  style: const TextStyle(
                    color: DCTheme.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPast
                      ? _formatFullDate(_selectedDate)
                      : 'No appointments scheduled for ${_formatFullDate(_selectedDate)}',
                  style: const TextStyle(color: DCTheme.textMuted, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (!isPast) ...[
            const SizedBox(height: 16),
            // Availability summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DCTheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.access_time, color: DCTheme.info, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Today\'s Availability',
                        style: TextStyle(
                          color: DCTheme.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Visual timeline
                  _buildAvailabilityTimeline(),
                  const SizedBox(height: 16),
                  // Quick stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickStat(
                          'Open Slots',
                          '8',
                          DCTheme.success,
                          Icons.check_circle_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickStat(
                          'Working Hours',
                          '9 AM - 5 PM',
                          DCTheme.info,
                          Icons.schedule,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Quick actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showBlockTimeSheet(),
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text('Block Time'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DCTheme.warning,
                      side: const BorderSide(color: DCTheme.warning),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/barber/availability'),
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('Edit Hours'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvailabilityTimeline() {
    // Simplified timeline showing 9 AM to 5 PM
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: DCTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: List.generate(8, (index) {
          // Each block represents 1 hour from 9 AM to 5 PM
          final hour = 9 + index;
          // All slots available when no appointments
          return Expanded(
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: DCTheme.success.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '$hour',
                  style: const TextStyle(
                    color: DCTheme.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: DCTheme.textMuted, fontSize: 11),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
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

class _BlockTimeSheet extends StatefulWidget {
  final DateTime selectedDate;
  final Function(String? reason, String startTime, String endTime, bool isAllDay) onSave;

  const _BlockTimeSheet({
    required this.selectedDate,
    required this.onSave,
  });

  @override
  State<_BlockTimeSheet> createState() => _BlockTimeSheetState();
}

class _BlockTimeSheetState extends State<_BlockTimeSheet> {
  final _reasonController = TextEditingController();
  bool _isAllDay = false;
  String _startTime = '12:00';
  String _endTime = '13:00';
  String? _selectedReason;

  final List<String> _quickReasons = [
    'Lunch Break',
    'Personal Time',
    'Appointment',
    'Day Off',
    'Vacation',
    'Other',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DCTheme.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DCTheme.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.block, color: DCTheme.warning),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Block Time',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: DCTheme.text,
                      ),
                    ),
                    Text(
                      _formatDate(widget.selectedDate),
                      style: const TextStyle(color: DCTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // All day toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DCTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: DCTheme.textMuted, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Block entire day',
                      style: TextStyle(color: DCTheme.text),
                    ),
                  ),
                  Switch(
                    value: _isAllDay,
                    onChanged: (value) => setState(() => _isAllDay = value),
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return DCTheme.warning;
                      }
                      return null;
                    }),
                  ),
                ],
              ),
            ),
            // Time selectors (only show if not all day)
            if (!_isAllDay) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeSelector('From', _startTime, (time) {
                      setState(() => _startTime = time);
                    }),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.arrow_forward, color: DCTheme.textMuted),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeSelector('To', _endTime, (time) {
                      setState(() => _endTime = time);
                    }),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            // Reason quick select
            const Text(
              'Reason',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DCTheme.text,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickReasons.map((reason) {
                final isSelected = _selectedReason == reason;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedReason = reason;
                      if (reason != 'Other') {
                        _reasonController.text = reason;
                      } else {
                        _reasonController.clear();
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? DCTheme.warning.withValues(alpha: 0.15)
                          : DCTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? DCTheme.warning : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      reason,
                      style: TextStyle(
                        color: isSelected ? DCTheme.warning : DCTheme.text,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            // Custom reason input (only if "Other" selected)
            if (_selectedReason == 'Other') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                style: const TextStyle(color: DCTheme.text),
                decoration: const InputDecoration(
                  hintText: 'Enter custom reason...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final reason = _selectedReason == 'Other'
                          ? _reasonController.text
                          : _selectedReason;
                      widget.onSave(
                        reason,
                        _startTime,
                        _endTime,
                        _isAllDay,
                      );
                    },
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text('Block Time'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DCTheme.warning,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(String label, String time, Function(String) onChanged) {
    return GestureDetector(
      onTap: () async {
        final parts = time.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: DCTheme.warning,
                  surface: DCTheme.surface,
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          final newTime =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          onChanged(newTime);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: DCTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: DCTheme.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(time),
              style: const TextStyle(
                color: DCTheme.text,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatDate(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}
