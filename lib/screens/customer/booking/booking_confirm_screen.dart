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
  bool _agreedToPolicy = false;

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
        actions: [
          // Trust badge in app bar
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: DCTheme.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user, size: 14, color: DCTheme.success),
                SizedBox(width: 4),
                Text(
                  'Secure',
                  style: TextStyle(
                    color: DCTheme.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          _buildWhatToExpect(state),
          const SizedBox(height: 20),
          _buildPaymentMethod(state),
          const SizedBox(height: 20),
          _buildNotes(),
          const SizedBox(height: 20),
          _buildPriceSummary(state),
          const SizedBox(height: 20),
          _buildCancellationPolicy(),
          const SizedBox(height: 16),
          _buildPolicyAgreement(),
          const SizedBox(height: 20),
          _buildTrustIndicators(),
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
          Stack(
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
                      ? Image.network(barber.profileImageUrl!,
                          fit: BoxFit.cover)
                      : Container(
                          color: DCTheme.surfaceSecondary,
                          child: const Icon(Icons.person,
                              color: DCTheme.textMuted),
                        ),
                ),
              ),
              // Verified badge
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: DCTheme.info,
                    shape: BoxShape.circle,
                    border: Border.all(color: DCTheme.surface, width: 2),
                  ),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      barber.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: DCTheme.text,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: DCTheme.info.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Verified',
                        style: TextStyle(
                          color: DCTheme.info,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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
          Row(
            children: [
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DCTheme.text,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DCTheme.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 12, color: DCTheme.success),
                    SizedBox(width: 4),
                    Text(
                      'Secure',
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
          const SizedBox(height: 16),
          _PaymentOption(
            icon: Icons.credit_card,
            label: 'Pay with Card',
            subtitle: 'Charged after appointment confirmed',
            details: 'Secure checkout powered by Stripe',
            isSelected: state.paymentMethod == 'card',
            discount: '5% off',
            isRecommended: true,
            onTap: () {
              ref.read(bookingFlowProvider.notifier).setPaymentMethod('card');
            },
          ),
          const SizedBox(height: 12),
          _PaymentOption(
            icon: Icons.money,
            label: 'Pay with Cash',
            subtitle: 'Pay your barber after the service',
            details: 'Bring exact change if possible',
            isSelected: state.paymentMethod == 'cash',
            fee: '+\$3 fee',
            onTap: () {
              ref.read(bookingFlowProvider.notifier).setPaymentMethod('cash');
            },
          ),
          const SizedBox(height: 16),
          // Payment timing explanation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DCTheme.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: DCTheme.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: DCTheme.info, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.paymentMethod == 'card'
                        ? 'Your card won\'t be charged until your barber confirms the appointment. You\'ll receive a notification before any charge.'
                        : 'No payment is needed now. Pay your barber in cash after your haircut is complete.',
                    style: const TextStyle(
                      color: DCTheme.textMuted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
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

  Widget _buildWhatToExpect(BookingFlowState state) {
    final isShop = state.locationType == 'shop';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DCTheme.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DCTheme.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline,
                    color: DCTheme.info, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'What to Expect',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DCTheme.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildExpectationItem(
            Icons.notifications_active,
            'Confirmation',
            'You\'ll receive a confirmation notification immediately',
          ),
          const SizedBox(height: 12),
          _buildExpectationItem(
            Icons.timer,
            'Arrive on time',
            isShop
                ? 'Please arrive 5 minutes before your appointment'
                : 'Barber will arrive at your location on time',
          ),
          const SizedBox(height: 12),
          _buildExpectationItem(
            Icons.chat_bubble_outline,
            'Direct messaging',
            'Chat with your barber if you need to coordinate',
          ),
        ],
      ),
    );
  }

  Widget _buildExpectationItem(
      IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: DCTheme.textMuted, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: DCTheme.text,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: const TextStyle(color: DCTheme.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCancellationPolicy() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.policy, color: DCTheme.warning, size: 20),
              SizedBox(width: 8),
              Text(
                'Cancellation Policy',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DCTheme.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPolicyItem(
            'Free cancellation',
            'Up to 2 hours before appointment',
            DCTheme.success,
          ),
          const SizedBox(height: 8),
          _buildPolicyItem(
            'Late cancellation fee',
            '50% of service price if cancelled within 2 hours',
            DCTheme.warning,
          ),
          const SizedBox(height: 8),
          _buildPolicyItem(
            'No-show fee',
            'Full service price charged for no-shows',
            DCTheme.error,
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: DCTheme.text,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: const TextStyle(color: DCTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyAgreement() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _agreedToPolicy = !_agreedToPolicy;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _agreedToPolicy
              ? DCTheme.success.withValues(alpha: 0.1)
              : DCTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _agreedToPolicy ? DCTheme.success : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _agreedToPolicy ? DCTheme.success : Colors.transparent,
                border: Border.all(
                  color: _agreedToPolicy ? DCTheme.success : DCTheme.textMuted,
                  width: 2,
                ),
              ),
              child: _agreedToPolicy
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'I agree to the cancellation policy and terms of service',
                style: TextStyle(color: DCTheme.text, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustIndicators() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildTrustBadge(Icons.shield, 'Booking\nProtection')),
              Expanded(child: _buildTrustBadge(Icons.lock, 'Secure\nPayment')),
              Expanded(
                  child:
                      _buildTrustBadge(Icons.support_agent, '24/7\nSupport')),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: DCTheme.surfaceSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user, color: DCTheme.success, size: 16),
                SizedBox(width: 8),
                Text(
                  'All barbers are verified and background-checked',
                  style: TextStyle(color: DCTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: DCTheme.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: DCTheme.success, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: DCTheme.textMuted,
            fontSize: 11,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BookingFlowState state) {
    final basePrice = state.selectedService?.price ?? 0;
    double discount = 0;
    double fee = 0;

    if (state.paymentMethod == 'card') {
      discount = basePrice * 0.05;
    } else {
      fee = 3;
    }

    final total = basePrice - discount + fee;
    final canConfirm = _agreedToPolicy && !_isSubmitting;

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
            // Price summary row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(color: DCTheme.textMuted, fontSize: 12),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: DCTheme.text,
                      ),
                    ),
                  ],
                ),
                if (state.paymentMethod == 'card')
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: DCTheme.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.savings, size: 14, color: DCTheme.success),
                        SizedBox(width: 4),
                        Text(
                          'You save 5%',
                          style: TextStyle(
                            color: DCTheme.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canConfirm ? _handleConfirm : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor:
                      canConfirm ? DCTheme.primary : DCTheme.surfaceSecondary,
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock,
                            size: 18,
                            color:
                                canConfirm ? Colors.white : DCTheme.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _agreedToPolicy
                                ? 'Confirm Booking'
                                : 'Agree to Policy First',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color:
                                  canConfirm ? Colors.white : DCTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),
            // Trust text
            const Text(
              'Your booking is protected by Direct Cuts guarantee',
              style: TextStyle(color: DCTheme.textMuted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
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
        // Success - navigate to success screen
        context.go('/book/success', extra: booking);
      } else {
        // Failed - check if slot was taken
        final state = ref.read(bookingFlowProvider);

        if (state.isSlotTaken) {
          // Slot was taken - offer to pick another time
          _showSlotTakenDialog();
        } else {
          // Other error - show message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  state.error ?? 'Failed to create booking. Please try again.'),
              backgroundColor: DCTheme.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSlotTakenDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DCTheme.surface,
        title: const Text(
          'Time Slot Unavailable',
          style: TextStyle(color: DCTheme.text),
        ),
        content: const Text(
          'This time slot was just booked by someone else. Would you like to pick a different time?',
          style: TextStyle(color: DCTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Go back to datetime selection
              context.pop();
            },
            child: const Text('Pick Another Time'),
          ),
        ],
      ),
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
  final String? details;
  final bool isSelected;
  final String? discount;
  final String? fee;
  final bool isRecommended;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.details,
    required this.isSelected,
    this.discount,
    this.fee,
    this.isRecommended = false,
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
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? DCTheme.primary.withValues(alpha: 0.2)
                        : DCTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? DCTheme.primary : DCTheme.textMuted,
                    size: 24,
                  ),
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
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color:
                                  isSelected ? DCTheme.text : DCTheme.textMuted,
                            ),
                          ),
                          if (isRecommended && !isSelected) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: DCTheme.info.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Recommended',
                                style: TextStyle(
                                  color: DCTheme.info,
                                  fontSize: 10,
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
                        style: TextStyle(
                          color:
                              isSelected ? DCTheme.textMuted : DCTheme.textDark,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (discount != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: DCTheme.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          discount!,
                          style: const TextStyle(
                            color: DCTheme.success,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (fee != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: DCTheme.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          fee!,
                          style: const TextStyle(
                            color: DCTheme.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isSelected ? DCTheme.primary : DCTheme.textMuted,
                          width: 2,
                        ),
                        color:
                            isSelected ? DCTheme.primary : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            if (details != null && isSelected) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DCTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon == Icons.credit_card
                          ? Icons.lock
                          : Icons.attach_money,
                      size: 14,
                      color: DCTheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      details!,
                      style: const TextStyle(
                        color: DCTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
