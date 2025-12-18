import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../models/booking.dart';

/// Displays the next upcoming appointment with timeline bar and quick actions
/// Inspired by theCut's home dashboard next appointment card
class NextAppointmentCard extends StatelessWidget {
  final Booking? appointment;
  final VoidCallback? onMessage;
  final VoidCallback? onCall;
  final VoidCallback? onViewDetails;
  final DateTime? workDayStart;
  final DateTime? workDayEnd;

  const NextAppointmentCard({
    super.key,
    this.appointment,
    this.onMessage,
    this.onCall,
    this.onViewDetails,
    this.workDayStart,
    this.workDayEnd,
  });

  @override
  Widget build(BuildContext context) {
    if (appointment == null) {
      return _buildEmptyState();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DCTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildTimelineBar(),
          const SizedBox(height: 16),
          _buildClientInfo(),
          const SizedBox(height: 12),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DCTheme.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available,
            size: 48,
            color: DCTheme.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'No upcoming appointments',
            style: TextStyle(
              color: DCTheme.textMuted,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your schedule is clear',
            style: TextStyle(
              color: DCTheme.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Next Appointment',
          style: TextStyle(
            color: DCTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: DCTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '\$${appointment?.totalPrice.toStringAsFixed(0) ?? '0'}',
            style: const TextStyle(
              color: DCTheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineBar() {
    final now = DateTime.now();
    final dayStart = workDayStart ?? DateTime(now.year, now.month, now.day, 9, 0);
    final dayEnd = workDayEnd ?? DateTime(now.year, now.month, now.day, 17, 0);
    
    // Parse appointment time
    final timeParts = appointment!.scheduledTime.split(':');
    final aptHour = int.parse(timeParts[0]);
    final aptMinute = int.parse(timeParts[1]);
    final aptTime = DateTime(now.year, now.month, now.day, aptHour, aptMinute);
    
    final totalMinutes = dayEnd.difference(dayStart).inMinutes;
    final elapsedMinutes = aptTime.difference(dayStart).inMinutes;
    final progress = (elapsedMinutes / totalMinutes).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          children: [
            _buildTimeAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTime(appointment!.scheduledTime),
                    style: const TextStyle(
                      color: DCTheme.text,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              _formatTimeShort(dayStart),
              style: const TextStyle(color: DCTheme.textMuted, fontSize: 11),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: DCTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: DCTheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: progress * 100 - 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      transform: Matrix4.translationValues(0, -2, 0),
                      decoration: const BoxDecoration(
                        color: DCTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTimeShort(dayEnd),
              style: const TextStyle(color: DCTheme.textMuted, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeAvatar() {
    final initial = appointment?.customerName?.isNotEmpty == true
        ? appointment!.customerName![0].toUpperCase()
        : 'C';
    
    return CircleAvatar(
      radius: 24,
      backgroundColor: DCTheme.primary,
      backgroundImage: appointment?.customerAvatar != null
          ? NetworkImage(appointment!.customerAvatar!)
          : null,
      child: appointment?.customerAvatar == null
          ? Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            )
          : null,
    );
  }

  Widget _buildClientInfo() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appointment?.customerName ?? 'Customer',
                style: const TextStyle(
                  color: DCTheme.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                appointment?.serviceName ?? 'Service',
                style: const TextStyle(
                  color: DCTheme.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionIconButton(
              icon: Icons.chat_bubble_outline,
              onTap: onMessage,
            ),
            const SizedBox(width: 8),
            _ActionIconButton(
              icon: Icons.phone_outlined,
              onTap: onCall,
            ),
            const SizedBox(width: 8),
            _ActionIconButton(
              icon: Icons.chevron_right,
              onTap: onViewDetails,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.check_circle_outline,
            label: 'Checkout',
            color: DCTheme.success,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            icon: Icons.person_off_outlined,
            label: 'No-Show',
            color: DCTheme.error,
            outlined: true,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            icon: Icons.close,
            label: 'Cancel',
            color: DCTheme.textMuted,
            outlined: true,
            onTap: () {},
          ),
        ),
      ],
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

  String _formatTimeShort(DateTime time) {
    final hour = time.hour;
    final period = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour$period';
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: DCTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: DCTheme.textMuted),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.outlined = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(10),
          border: outlined ? Border.all(color: color) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: outlined ? color : Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: outlined ? color : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
