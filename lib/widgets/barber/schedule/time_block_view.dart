import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../models/booking.dart';

/// Appointment block displayed within the time grid
/// Shows client info, service, time, and status
class AppointmentBlock extends StatelessWidget {
  final Booking booking;
  final double topOffset;
  final double height;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onNoShow;

  const AppointmentBlock({
    super.key,
    required this.booking,
    required this.topOffset,
    required this.height,
    this.onTap,
    this.onComplete,
    this.onNoShow,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Positioned(
      top: topOffset,
      left: 70,
      right: 16,
      height: height,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(color: statusColor, width: 3),
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      booking.customerName ?? 'Customer',
                      style: const TextStyle(
                        color: DCTheme.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (height > 50) ...[
                      const SizedBox(height: 2),
                      Text(
                        booking.serviceName ?? 'Service',
                        style: const TextStyle(
                          color: DCTheme.textMuted,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTimeRange(),
                    style: const TextStyle(
                      color: DCTheme.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _buildStatusBadge(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (booking.status) {
      case 'confirmed':
        return DCTheme.success;
      case 'pending':
        return Colors.amber;
      case 'completed':
        return DCTheme.textMuted;
      case 'cancelled':
        return DCTheme.error;
      default:
        return DCTheme.textMuted;
    }
  }

  Widget _buildStatusBadge() {
    final color = _getStatusColor();
    final label = booking.status[0].toUpperCase() + booking.status.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatTimeRange() {
    final startParts = booking.scheduledTime.split(':');
    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);
    
    final duration = booking.durationMinutes ?? 30;
    final endMinutes = startHour * 60 + startMinute + duration;
    final endHour = endMinutes ~/ 60;
    final endMinute = endMinutes % 60;

    return '${_formatHour(startHour, startMinute)} - ${_formatHour(endHour, endMinute)}';
  }

  String _formatHour(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')}$period';
  }
}

/// Vertical time grid showing appointments as blocks
/// Inspired by theCut's schedule day view
class TimeBlockView extends StatelessWidget {
  final List<Booking> appointments;
  final int startHour;
  final int endHour;
  final double hourHeight;
  final Function(Booking)? onAppointmentTap;
  final Function(Booking)? onComplete;
  final Function(Booking)? onNoShow;

  const TimeBlockView({
    super.key,
    required this.appointments,
    this.startHour = 9,
    this.endHour = 18,
    this.hourHeight = 60,
    this.onAppointmentTap,
    this.onComplete,
    this.onNoShow,
  });

  @override
  Widget build(BuildContext context) {
    final totalHours = endHour - startHour;
    final totalHeight = totalHours * hourHeight;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          children: [
            // Time labels and grid lines
            ...List.generate(totalHours + 1, (index) {
              final hour = startHour + index;
              return Positioned(
                top: index * hourHeight,
                left: 0,
                right: 0,
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        _formatHourLabel(hour),
                        style: const TextStyle(
                          color: DCTheme.textMuted,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: DCTheme.border.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              );
            }),
            // Current time indicator
            _buildCurrentTimeIndicator(),
            // Appointment blocks
            ...appointments.map((apt) {
              final timeParts = apt.scheduledTime.split(':');
              final hour = int.parse(timeParts[0]);
              final minute = int.parse(timeParts[1]);
              
              final topOffset = ((hour - startHour) * hourHeight) + (minute / 60 * hourHeight);
              final duration = apt.durationMinutes ?? 30;
              final blockHeight = (duration / 60) * hourHeight;

              return AppointmentBlock(
                booking: apt,
                topOffset: topOffset,
                height: blockHeight.clamp(40, hourHeight * 2),
                onTap: onAppointmentTap != null ? () => onAppointmentTap!(apt) : null,
                onComplete: onComplete != null ? () => onComplete!(apt) : null,
                onNoShow: onNoShow != null ? () => onNoShow!(apt) : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTimeIndicator() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    if (currentHour < startHour || currentHour >= endHour) {
      return const SizedBox.shrink();
    }

    final topOffset = ((currentHour - startHour) * hourHeight) + (currentMinute / 60 * hourHeight);

    return Positioned(
      top: topOffset,
      left: 55,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: DCTheme.primary,
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              color: DCTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatHourLabel(int hour) {
    if (hour == 12) return '12 PM';
    if (hour == 0) return '12 AM';
    return hour > 12 ? '${hour - 12} PM' : '$hour AM';
  }
}
