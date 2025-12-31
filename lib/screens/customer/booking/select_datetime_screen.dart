import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../models/availability.dart';
import '../../../providers/booking_provider.dart';

class SelectDateTimeScreen extends ConsumerStatefulWidget {
  final String barberId;

  const SelectDateTimeScreen({super.key, required this.barberId});

  @override
  ConsumerState<SelectDateTimeScreen> createState() =>
      _SelectDateTimeScreenState();
}

class _SelectDateTimeScreenState extends ConsumerState<SelectDateTimeScreen> {
  late DateTime _selectedDate;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingFlowProvider);
    final selectedTime = bookingState.selectedTime;

    return Scaffold(
      backgroundColor: DCTheme.background,
      appBar: AppBar(
        title: const Text('Select Date & Time'),
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          const Divider(color: DCTheme.border, height: 1),
          Expanded(child: _buildTimeSlots()),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, selectedTime),
    );
  }

  Widget _buildDateSelector() {
    final now = DateTime.now();
    final dates = List.generate(14, (i) => now.add(Duration(days: i)));

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = _isSameDay(date, _selectedDate);
          final isToday = _isSameDay(date, now);

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
              ref.read(bookingFlowProvider.notifier).selectDate(date);
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? DCTheme.primary : DCTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? DCTheme.primary : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDayName(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : DCTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : DCTheme.text,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.white : DCTheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSlots() {
    final request = AvailabilityRequest(
      barberId: widget.barberId,
      date: _selectedDate,
    );
    final slotsAsync = ref.watch(availableSlotsProvider(request));
    final selectedTime = ref.watch(bookingFlowProvider).selectedTime;

    return slotsAsync.when(
      data: (schedule) {
        if (!schedule.isWorkingDay) {
          return _buildClosedDay();
        }
        if (!schedule.hasAvailability) {
          return _buildNoAvailability();
        }
        return _buildSlotsGrid(schedule.slots, selectedTime);
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
            const Text('Error loading times',
                style: TextStyle(color: DCTheme.textMuted)),
            TextButton(
              onPressed: () => ref.invalidate(availableSlotsProvider(request)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotsGrid(List<TimeSlot> slots, String? selectedTime) {
    // Group by morning/afternoon/evening
    final morning = slots.where((s) => _getHour(s.time) < 12).toList();
    final afternoon = slots
        .where((s) => _getHour(s.time) >= 12 && _getHour(s.time) < 17)
        .toList();
    final evening = slots.where((s) => _getHour(s.time) >= 17).toList();

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        if (morning.isNotEmpty) ...[
          _buildTimeSection('Morning', morning, selectedTime),
          const SizedBox(height: 24),
        ],
        if (afternoon.isNotEmpty) ...[
          _buildTimeSection('Afternoon', afternoon, selectedTime),
          const SizedBox(height: 24),
        ],
        if (evening.isNotEmpty)
          _buildTimeSection('Evening', evening, selectedTime),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildTimeSection(
      String title, List<TimeSlot> slots, String? selectedTime) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: DCTheme.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: slots.map((slot) {
            final isSelected = selectedTime == slot.time;
            return _TimeSlotChip(
              slot: slot,
              isSelected: isSelected,
              onTap: slot.isAvailable
                  ? () {
                      ref
                          .read(bookingFlowProvider.notifier)
                          .selectTime(slot.time);
                    }
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildClosedDay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: DCTheme.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Closed on this day',
            style: TextStyle(
              color: DCTheme.textMuted,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please select a different date',
            style: TextStyle(color: DCTheme.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAvailability() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 64,
            color: DCTheme.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No available slots',
            style: TextStyle(
              color: DCTheme.textMuted,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'All times are booked for this day',
            style: TextStyle(color: DCTheme.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, String? selectedTime) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedTime != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(_selectedDate),
                    style: const TextStyle(color: DCTheme.text),
                  ),
                  Text(
                    _formatTime(selectedTime),
                    style: const TextStyle(
                      color: DCTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedTime != null
                    ? () => context.push('/book/${widget.barberId}/confirm')
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: DCTheme.surfaceSecondary,
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getDayName(DateTime date) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[date.weekday % 7];
  }

  int _getHour(String time) {
    return int.parse(time.split(':')[0]);
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
      'Dec',
    ];
    return '${_getDayName(date)}, ${months[date.month - 1]} ${date.day}';
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

class _TimeSlotChip extends StatelessWidget {
  final TimeSlot slot;
  final bool isSelected;
  final VoidCallback? onTap;

  const _TimeSlotChip({
    required this.slot,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = slot.isAvailable;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? DCTheme.primary
              : isAvailable
                  ? DCTheme.surface
                  : DCTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? DCTheme.primary
                : isAvailable
                    ? DCTheme.border
                    : Colors.transparent,
          ),
        ),
        child: Text(
          slot.formattedTime,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : isAvailable
                    ? DCTheme.text
                    : DCTheme.textDark,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
            decoration: isAvailable ? null : TextDecoration.lineThrough,
          ),
        ),
      ),
    );
  }
}
