import 'package:flutter/material.dart';

import '../../../config/theme.dart';

/// Individual day cell for the week strip
/// Shows day name, date number, and optional indicators
class DayCell extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool hasAppointments;
  final double? earnings;
  final VoidCallback onTap;

  const DayCell({
    super.key,
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.hasAppointments,
    this.earnings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? DCTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getDayAbbreviation(date.weekday),
              style: TextStyle(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.8)
                    : DCTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday && !isSelected
                    ? DCTheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : isToday
                            ? DCTheme.primary
                            : DCTheme.text,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (hasAppointments)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.white : DCTheme.primary,
                ),
              )
            else if (earnings != null && earnings! > 0)
              Text(
                '\$${earnings!.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.8)
                      : DCTheme.success,
                ),
              )
            else
              const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  String _getDayAbbreviation(int weekday) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[weekday - 1];
  }
}

/// Horizontal week strip with swipe navigation
/// Inspired by theCut's schedule view week selector
class WeekStrip extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Map<DateTime, bool> appointmentDays;
  final Map<DateTime, double>? earningsPerDay;

  const WeekStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.appointmentDays = const {},
    this.earningsPerDay,
  });

  @override
  State<WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<WeekStrip> {
  late PageController _pageController;
  late DateTime _currentWeekStart;

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getWeekStart(widget.selectedDate);
    _pageController = PageController(initialPage: 500);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            _formatMonthYear(_currentWeekStart),
            style: const TextStyle(
              color: DCTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        SizedBox(
          height: 90,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              final offset = index - 500;
              final weekStart =
                  _getWeekStart(DateTime.now()).add(Duration(days: offset * 7));
              setState(() => _currentWeekStart = weekStart);
            },
            itemBuilder: (context, index) {
              final offset = index - 500;
              final weekStart =
                  _getWeekStart(DateTime.now()).add(Duration(days: offset * 7));
              return _buildWeek(weekStart);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeek(DateTime weekStart) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (index) {
          final date = weekStart.add(Duration(days: index));
          final dateKey = DateTime(date.year, date.month, date.day);
          final hasAppointments = widget.appointmentDays[dateKey] ?? false;
          final earnings = widget.earningsPerDay?[dateKey];

          return DayCell(
            date: date,
            isSelected: _isSameDay(date, widget.selectedDate),
            isToday: _isSameDay(date, DateTime.now()),
            hasAppointments: hasAppointments,
            earnings: earnings,
            onTap: () => widget.onDateSelected(date),
          );
        }),
      ),
    );
  }
}
