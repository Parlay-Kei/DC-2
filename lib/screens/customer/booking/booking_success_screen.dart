import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../models/booking.dart';
import '../../../providers/booking_provider.dart';

class BookingSuccessScreen extends ConsumerWidget {
  final Booking booking;

  const BookingSuccessScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DCTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildSuccessIcon(),
              const SizedBox(height: 24),
              const Text(
                'Booking Confirmed!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: DCTheme.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'re all set for your appointment',
                style: TextStyle(
                  color: DCTheme.textMuted.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildBookingCard(context),
              const SizedBox(height: 20),
              _buildWhatsNext(),
              const SizedBox(height: 20),
              _buildQuickActions(context),
              const SizedBox(height: 32),
              _buildActions(context, ref),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: DCTheme.success.withValues(alpha: 0.1),
      ),
      child: Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: DCTheme.success,
          ),
          child: const Icon(
            Icons.check,
            size: 48,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DCTheme.success.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Service and barber header
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: DCTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.content_cut, color: DCTheme.primary),
              ),
              const SizedBox(width: 14),
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
                    const SizedBox(height: 2),
                    Text(
                      'with ${booking.barberName ?? "Your Barber"}',
                      style: const TextStyle(
                        color: DCTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: DCTheme.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: DCTheme.success, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Confirmed',
                      style: TextStyle(
                        color: DCTheme.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: DCTheme.border, height: 1),
          ),
          _buildInfoRow(
            Icons.calendar_today,
            'Date',
            _formatDate(booking.scheduledDate),
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            Icons.access_time,
            'Time',
            _formatTime(booking.scheduledTime),
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            Icons.confirmation_number,
            'Confirmation',
            '#${booking.id.substring(0, 8).toUpperCase()}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: DCTheme.border, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 13,
                      color: DCTheme.textMuted,
                    ),
                  ),
                  Text(
                    '\$${booking.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: DCTheme.primary,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: booking.isPaid
                      ? DCTheme.success.withValues(alpha: 0.15)
                      : DCTheme.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      booking.isPaid ? Icons.check_circle : Icons.info_outline,
                      size: 14,
                      color: booking.isPaid ? DCTheme.success : DCTheme.info,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      booking.isPaid
                          ? 'Paid'
                          : booking.isCashPayment
                              ? 'Pay at appointment'
                              : 'Charged when confirmed',
                      style: TextStyle(
                        color: booking.isPaid ? DCTheme.success : DCTheme.info,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsNext() {
    return Container(
      width: double.infinity,
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
              Icon(Icons.lightbulb_outline, color: DCTheme.warning, size: 20),
              SizedBox(width: 8),
              Text(
                'What\'s Next',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DCTheme.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildNextStep(
            '1',
            'Confirmation sent',
            'Check your email and notifications',
            DCTheme.success,
            true,
          ),
          const SizedBox(height: 12),
          _buildNextStep(
            '2',
            'Reminder',
            'We\'ll remind you 24 hours before',
            DCTheme.info,
            false,
          ),
          const SizedBox(height: 12),
          _buildNextStep(
            '3',
            'Show up',
            'Arrive 5 minutes early',
            DCTheme.primary,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildNextStep(String number, String title, String description,
      Color color, bool isComplete) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isComplete ? color : color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isComplete
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    number,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isComplete ? DCTheme.text : DCTheme.textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  color: DCTheme.textDark,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAction(
            Icons.calendar_month,
            'Add to Calendar',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Calendar integration coming soon'),
                  backgroundColor: DCTheme.info,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAction(
            Icons.copy,
            'Copy Details',
            () {
              final details = '''
Booking Confirmation #${booking.id.substring(0, 8).toUpperCase()}
${booking.serviceName ?? 'Haircut'} with ${booking.barberName ?? 'Your Barber'}
${_formatDate(booking.scheduledDate)} at ${_formatTime(booking.scheduledTime)}
Total: \$${booking.totalPrice.toStringAsFixed(2)}
''';
              Clipboard.setData(ClipboardData(text: details));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking details copied!'),
                  backgroundColor: DCTheme.success,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: DCTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DCTheme.border.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: DCTheme.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: DCTheme.text,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: DCTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: DCTheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: DCTheme.textMuted,
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: DCTheme.text,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Primary action - View My Bookings
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              ref.read(bookingFlowProvider.notifier).reset();
              // Navigate to customer home with bookings tab selected
              context.go('/customer/bookings');
            },
            icon: const Icon(Icons.calendar_today, size: 18),
            label: const Text('View My Bookings'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: DCTheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Secondary action - Back to Home
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ref.read(bookingFlowProvider.notifier).reset();
              context.go('/customer');
            },
            icon: const Icon(Icons.home_outlined, size: 18),
            label: const Text('Back to Home'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Help text
        const Text(
          'Need help? Contact support anytime',
          style: TextStyle(
            color: DCTheme.textDark,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
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
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return '${days[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
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
