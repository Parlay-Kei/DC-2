import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../config/supabase_config.dart';

/// Payment service handling Stripe integration
class PaymentService {
  final _client = SupabaseConfig.client;

  /// Initialize Stripe with publishable key
  static Future<void> initialize(String publishableKey) async {
    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
  }

  /// Create a payment intent for a booking
  Future<PaymentIntentResult?> createPaymentIntent({
    required double amount,
    required String barberId,
    required String bookingId,
    String currency = 'usd',
  }) async {
    final customerId = SupabaseConfig.currentUserId;
    if (customerId == null) return null;

    try {
      // Call Edge Function to create payment intent
      final response = await _client.functions.invoke(
        'create-payment-intent',
        body: {
          'amount': (amount * 100).toInt(), // Convert to cents
          'currency': currency,
          'customer_id': customerId,
          'barber_id': barberId,
          'booking_id': bookingId,
        },
      );

      if (response.status != 200) {
        debugPrint('Payment intent error: ${response.data}');
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      return PaymentIntentResult(
        clientSecret: data['clientSecret'] as String,
        paymentIntentId: data['paymentIntentId'] as String,
        ephemeralKey: data['ephemeralKey'] as String?,
        customerId: data['customerId'] as String?,
      );
    } catch (e) {
      debugPrint('Create payment intent error: $e');
      return null;
    }
  }

  /// Present payment sheet to user
  Future<PaymentResult> presentPaymentSheet({
    required String clientSecret,
    String? merchantDisplayName,
  }) async {
    try {
      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: merchantDisplayName ?? 'Direct Cuts',
          style: ThemeMode.dark,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFFE63946),
              background: Color(0xFF1A1A1A),
              componentBackground: Color(0xFF2D2D2D),
              primaryText: Color(0xFFFFFFFF),
              secondaryText: Color(0xFF9CA3AF),
              componentText: Color(0xFFFFFFFF),
              icon: Color(0xFF9CA3AF),
            ),
            shapes: PaymentSheetShape(
              borderRadius: 12,
              borderWidth: 1,
            ),
          ),
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();
      
      return PaymentResult.success();
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return PaymentResult.cancelled();
      }
      return PaymentResult.failed(e.error.localizedMessage ?? 'Payment failed');
    } catch (e) {
      return PaymentResult.failed(e.toString());
    }
  }

  /// Confirm payment and update booking
  Future<bool> confirmPayment({
    required String bookingId,
    required String paymentIntentId,
  }) async {
    try {
      await _client.from('appointments').update({
        'payment_status': 'paid',
        'payment_intent_id': paymentIntentId,
        'paid_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);

      return true;
    } catch (e) {
      debugPrint('Confirm payment error: $e');
      return false;
    }
  }

  /// Request refund for a booking
  Future<RefundResult> requestRefund({
    required String bookingId,
    required String paymentIntentId,
    String? reason,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'create-refund',
        body: {
          'payment_intent_id': paymentIntentId,
          'booking_id': bookingId,
          'reason': reason,
        },
      );

      if (response.status != 200) {
        return RefundResult.failed(response.data['error'] ?? 'Refund failed');
      }

      final data = response.data as Map<String, dynamic>;
      return RefundResult.success(
        refundId: data['refundId'] as String,
        amount: (data['amount'] as int) / 100.0,
      );
    } catch (e) {
      return RefundResult.failed(e.toString());
    }
  }

  /// Get saved payment methods for customer
  Future<List<SavedPaymentMethod>> getSavedPaymentMethods() async {
    final customerId = SupabaseConfig.currentUserId;
    if (customerId == null) return [];

    try {
      final response = await _client
          .from('customer_payment_methods')
          .select()
          .eq('customer_id', customerId)
          .eq('is_active', true)
          .order('is_default', ascending: false);

      return (response as List)
          .map((pm) => SavedPaymentMethod.fromJson(pm))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save a new payment method
  Future<bool> savePaymentMethod({
    required String stripePaymentMethodId,
    required String brand,
    required String last4,
    required int expMonth,
    required int expYear,
    bool isDefault = false,
  }) async {
    final customerId = SupabaseConfig.currentUserId;
    if (customerId == null) return false;

    try {
      // If setting as default, unset other defaults
      if (isDefault) {
        await _client
            .from('customer_payment_methods')
            .update({'is_default': false})
            .eq('customer_id', customerId);
      }

      await _client.from('customer_payment_methods').insert({
        'customer_id': customerId,
        'stripe_payment_method_id': stripePaymentMethodId,
        'brand': brand,
        'last4': last4,
        'exp_month': expMonth,
        'exp_year': expYear,
        'is_default': isDefault,
        'is_active': true,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove a saved payment method
  Future<bool> removePaymentMethod(String paymentMethodId) async {
    try {
      await _client
          .from('customer_payment_methods')
          .update({'is_active': false})
          .eq('id', paymentMethodId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Set default payment method
  Future<bool> setDefaultPaymentMethod(String paymentMethodId) async {
    final customerId = SupabaseConfig.currentUserId;
    if (customerId == null) return false;

    try {
      // Unset all defaults
      await _client
          .from('customer_payment_methods')
          .update({'is_default': false})
          .eq('customer_id', customerId);

      // Set new default
      await _client
          .from('customer_payment_methods')
          .update({'is_default': true})
          .eq('id', paymentMethodId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get payment history for customer
  Future<List<PaymentRecord>> getPaymentHistory({int limit = 50}) async {
    final customerId = SupabaseConfig.currentUserId;
    if (customerId == null) return [];

    try {
      final response = await _client
          .from('appointments')
          .select('id, total_price, payment_status, paid_at, scheduled_date')
          .eq('customer_id', customerId)
          .neq('payment_status', 'pending')
          .order('paid_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((p) => PaymentRecord.fromJson(p))
          .toList();
    } catch (e) {
      return [];
    }
  }
}

/// Result from creating a payment intent
class PaymentIntentResult {
  final String clientSecret;
  final String paymentIntentId;
  final String? ephemeralKey;
  final String? customerId;

  PaymentIntentResult({
    required this.clientSecret,
    required this.paymentIntentId,
    this.ephemeralKey,
    this.customerId,
  });
}

/// Result from payment sheet
class PaymentResult {
  final PaymentResultStatus status;
  final String? errorMessage;

  PaymentResult._({required this.status, this.errorMessage});

  factory PaymentResult.success() => PaymentResult._(status: PaymentResultStatus.success);
  factory PaymentResult.cancelled() => PaymentResult._(status: PaymentResultStatus.cancelled);
  factory PaymentResult.failed(String message) => 
      PaymentResult._(status: PaymentResultStatus.failed, errorMessage: message);

  bool get isSuccess => status == PaymentResultStatus.success;
  bool get isCancelled => status == PaymentResultStatus.cancelled;
  bool get isFailed => status == PaymentResultStatus.failed;
}

enum PaymentResultStatus { success, cancelled, failed }

/// Result from refund request
class RefundResult {
  final bool isSuccess;
  final String? refundId;
  final double? amount;
  final String? errorMessage;

  RefundResult._({
    required this.isSuccess,
    this.refundId,
    this.amount,
    this.errorMessage,
  });

  factory RefundResult.success({required String refundId, required double amount}) =>
      RefundResult._(isSuccess: true, refundId: refundId, amount: amount);

  factory RefundResult.failed(String message) =>
      RefundResult._(isSuccess: false, errorMessage: message);
}

/// Saved payment method model
class SavedPaymentMethod {
  final String id;
  final String stripePaymentMethodId;
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;
  final bool isDefault;
  final DateTime createdAt;

  SavedPaymentMethod({
    required this.id,
    required this.stripePaymentMethodId,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    required this.isDefault,
    required this.createdAt,
  });

  factory SavedPaymentMethod.fromJson(Map<String, dynamic> json) {
    return SavedPaymentMethod(
      id: json['id'] as String,
      stripePaymentMethodId: json['stripe_payment_method_id'] as String,
      brand: json['brand'] as String,
      last4: json['last4'] as String,
      expMonth: json['exp_month'] as int,
      expYear: json['exp_year'] as int,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get displayName => '${brand.toUpperCase()} •••• $last4';
  String get expiry => '$expMonth/${expYear.toString().substring(2)}';
  bool get isExpired {
    final now = DateTime.now();
    return expYear < now.year || (expYear == now.year && expMonth < now.month);
  }

  IconData get brandIcon {
    switch (brand.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'amex':
        return Icons.credit_card;
      default:
        return Icons.credit_card;
    }
  }
}

/// Payment record for history
class PaymentRecord {
  final String bookingId;
  final double amount;
  final String status;
  final DateTime? paidAt;
  final DateTime scheduledDate;

  PaymentRecord({
    required this.bookingId,
    required this.amount,
    required this.status,
    this.paidAt,
    required this.scheduledDate,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      bookingId: json['id'] as String,
      amount: (json['total_price'] as num).toDouble(),
      status: json['payment_status'] as String,
      paidAt: json['paid_at'] != null 
          ? DateTime.parse(json['paid_at'] as String) 
          : null,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
    );
  }

  bool get isPaid => status == 'paid';
  bool get isRefunded => status == 'refunded';
}
