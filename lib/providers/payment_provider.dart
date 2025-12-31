import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/payment_service.dart';

/// Payment service provider
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

/// Saved payment methods provider
final savedPaymentMethodsProvider =
    FutureProvider<List<SavedPaymentMethod>>((ref) async {
  final service = ref.watch(paymentServiceProvider);
  return service.getSavedPaymentMethods();
});

/// Payment history provider
final paymentHistoryProvider = FutureProvider<List<PaymentRecord>>((ref) async {
  final service = ref.watch(paymentServiceProvider);
  return service.getPaymentHistory();
});

/// Payment state notifier for checkout flow
class PaymentStateNotifier extends StateNotifier<PaymentState> {
  final PaymentService _service;
  final Ref _ref;

  PaymentStateNotifier(this._service, this._ref)
      : super(PaymentState.initial());

  /// Process payment for a booking
  Future<bool> processPayment({
    required double amount,
    required String barberId,
    required String bookingId,
  }) async {
    state = state.copyWith(isProcessing: true, error: null);

    try {
      // Create payment intent
      final intentResult = await _service.createPaymentIntent(
        amount: amount,
        barberId: barberId,
        bookingId: bookingId,
      );

      if (intentResult == null) {
        state = state.copyWith(
          isProcessing: false,
          error: 'Failed to create payment',
        );
        return false;
      }

      state = state.copyWith(
        clientSecret: intentResult.clientSecret,
        paymentIntentId: intentResult.paymentIntentId,
      );

      // Present payment sheet
      final paymentResult = await _service.presentPaymentSheet(
        clientSecret: intentResult.clientSecret,
      );

      if (paymentResult.isCancelled) {
        state = state.copyWith(isProcessing: false);
        return false;
      }

      if (paymentResult.isFailed) {
        state = state.copyWith(
          isProcessing: false,
          error: paymentResult.errorMessage,
        );
        return false;
      }

      // Confirm payment in database
      await _service.confirmPayment(
        bookingId: bookingId,
        paymentIntentId: intentResult.paymentIntentId,
      );

      state = state.copyWith(
        isProcessing: false,
        isComplete: true,
      );

      // Refresh payment methods
      _ref.invalidate(savedPaymentMethodsProvider);
      _ref.invalidate(paymentHistoryProvider);

      return true;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void reset() {
    state = PaymentState.initial();
  }
}

/// Payment state
class PaymentState {
  final bool isProcessing;
  final bool isComplete;
  final String? clientSecret;
  final String? paymentIntentId;
  final String? error;

  PaymentState({
    required this.isProcessing,
    required this.isComplete,
    this.clientSecret,
    this.paymentIntentId,
    this.error,
  });

  factory PaymentState.initial() => PaymentState(
        isProcessing: false,
        isComplete: false,
      );

  PaymentState copyWith({
    bool? isProcessing,
    bool? isComplete,
    String? clientSecret,
    String? paymentIntentId,
    String? error,
  }) {
    return PaymentState(
      isProcessing: isProcessing ?? this.isProcessing,
      isComplete: isComplete ?? this.isComplete,
      clientSecret: clientSecret ?? this.clientSecret,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      error: error,
    );
  }
}

/// Payment state provider
final paymentStateProvider =
    StateNotifierProvider<PaymentStateNotifier, PaymentState>((ref) {
  final service = ref.watch(paymentServiceProvider);
  return PaymentStateNotifier(service, ref);
});
