import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../models/barber.dart';
import '../../../providers/barber_provider.dart';
import '../../../providers/booking_provider.dart';

class BookingConfirmScreen extends ConsumerStatefulWidget {
  final String barberId;

  const BookingConfirmScreen({super.key, required this.barberId});

  @override
  ConsumerState<BookingConfirmScreen> createState() =>
      _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends ConsumerState<BookingConfirmScreen> {
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barberAsync = ref.watch(barberProvider(widget.barberId));
    final bookingState = ref.watch(bookingFlowProvider);

    return Scaffold(
      backgroundColor: DCTheme.background,
      appBar: AppBar(
        title: const Text('Confirm Booking'),
      ),
      body: barberAsync.when(
        data: (barber) {
          if (barber == null) {
            return const Center(child: Text('Barber not found'));
          }
          return _buildContent(barber, bookingState);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: DCTheme.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: _buildBottomBar(bookingState),
    );
  }

  Widget _buildContent(Barber barber, BookingFlowState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBarberCard(barber),
          const SizedBox(height: 20),
          _buildBookingDetails(state),
          const SizedBox(height: 20),
          _buildPaymentMethod(state),
          const SizedBox(height: 20),
          _buildNotes(),
          const SizedBox(height: 20),
          _buildPriceSummary(state),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBarberCard(Barber barber) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: DCTheme.primary, width: 2),
            ),
            child: ClipOval(
              child: barber.profileImageUrl != null
                  ? Image.network(barber.profileImageUrl!, fit: BoxFit.cover)
                  : Container(
                      color: DCTheme.surfaceSecondary,
                      child: const Icon(Icons.person, color: DCTheme.textMuted),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  barber.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: DCTheme.text,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${barber.rating.toStringAsFixed(1)} (${barber.totalReviews} reviews)',
                      style: const TextStyle(
                          color: DCTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetails(BookingFlowState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appointment Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: DCTheme.text,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.content_cut,
            'Service',
            state.selectedService?.name ?? '-',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.access_time,
            'Duration',
            state.selectedService?.formattedDuration ?? '-',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.calendar_today,
            'Date',
            state.selectedDate != null ? _formatDate(state.selectedDate!) : '-',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.schedule,
            'Time',
            state.selectedTime != null ? _formatTime(state.selectedTime!) : '-',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: DCTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: DCTheme.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: DCTheme.textMuted, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: DCTheme.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod(BookingFlowState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: DCTheme.text,
            ),
          ),
          const SizedBox(height: 16),
          _PaymentOption(
            icon: Icons.credit_card,
            label: 'Card',
            subtitle: 'Pay securely online',
            isSelected: state.paymentMethod == 'card',
            discount: '5% off',
            onTap: () {
              ref.read(bookingFlowProvider.notifier).setPaymentMethod('card');
            },
          ),
          const SizedBox(height: 12),
          _PaymentOption(
            icon: Icons.money,
            label: 'Cash',
            subtitle: 'Pay at the appointment',
            isSelected: state.paymentMethod == 'cash',
            fee: '+\$3 fee',
            onTap: () {
              ref.read(bookingFlowProvider.notifier).setPaymentMethod('cash');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: DCTheme.text,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            style: const TextStyle(color: DCTheme.text),
            decoration: const InputDecoration(
              hintText: 'Any special requests or notes for your barber...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              ref.read(bookingFlowProvider.notifier).setNotes(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary(BookingFlowState state) {
    final basePrice = state.selectedService?.price ?? 0;
    double discount = 0;
    double fee = 0;

    if (state.paymentMethod == 'card') {
      discount = basePrice * 0.05;
    } else {
      fee = 3;
    }

    final total = basePrice - discount + fee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildPriceRow('Subtotal', '\$${basePrice.toStringAsFixed(2)}'),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              'Card Discount (5%)',
              '-\$${discount.toStringAsFixed(2)}',
              isDiscount: true,
            ),
          ],
          if (fee > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow('Cash Fee', '+\$${fee.toStringAsFixed(2)}'),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: DCTheme.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DCTheme.text,
                ),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: DCTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: DCTheme.textMuted)),
        Text(
          value,
          style: TextStyle(
            color: isDiscount ? DCTheme.success : DCTheme.text,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BookingFlowState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleConfirm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              disabledBackgroundColor: DCTheme.surfaceSecondary,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Confirm Booking',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleConfirm() async {
    setState(() => _isSubmitting = true);

    try {
      final booking = await ref
          .read(bookingFlowProvider.notifier)
          .createBooking(widget.barberId);

      if (!mounted) return;

      if (booking != null) {
        // Clear the flow and navigate to success
        context.go('/book/success', extra: booking);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create booking. Please try again.'),
            backgroundColor: DCTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
    return '${days[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}';
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

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final String? discount;
  final String? fee;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    this.discount,
    this.fee,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? DCTheme.primary.withValues(alpha: 0.1)
              : DCTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? DCTheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: DCTheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: DCTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: DCTheme.text,
                        ),
                      ),
                      if (discount != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DCTheme.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            discount!,
                            style: const TextStyle(
                              color: DCTheme.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (fee != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DCTheme.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            fee!,
                            style: const TextStyle(
                              color: DCTheme.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style:
                        const TextStyle(color: DCTheme.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? DCTheme.primary : DCTheme.textMuted,
                  width: 2,
                ),
                color: isSelected ? DCTheme.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
