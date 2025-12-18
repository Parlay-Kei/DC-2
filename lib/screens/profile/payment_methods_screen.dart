import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../providers/payment_provider.dart';
import '../../services/payment_service.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(savedPaymentMethodsProvider);

    return Scaffold(
      backgroundColor: DCTheme.background,
      appBar: AppBar(
        title: const Text('Payment Methods'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPaymentMethod(context, ref),
          ),
        ],
      ),
      body: methodsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DCTheme.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: DCTheme.error),
              const SizedBox(height: 16),
              Text('Error: $error',
                  style: const TextStyle(color: DCTheme.textMuted),),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(savedPaymentMethodsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (methods) {
          if (methods.isEmpty) {
            return _buildEmptyState(context, ref);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: methods.length,
            itemBuilder: (context, index) {
              final method = methods[index];
              return _PaymentMethodCard(
                method: method,
                onSetDefault: () => _setDefault(context, ref, method.id),
                onDelete: () => _deleteMethod(context, ref, method.id),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card_outlined,
              size: 64,
              color: DCTheme.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Payment Methods',
              style: TextStyle(
                color: DCTheme.text,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a card to easily pay for your appointments',
              style: TextStyle(color: DCTheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddPaymentMethod(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Payment Method'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DCTheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPaymentMethod(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add payment method coming soon'),
      ),
    );
  }

  Future<void> _setDefault(
      BuildContext context, WidgetRef ref, String methodId,) async {
    final service = ref.read(paymentServiceProvider);
    final success = await service.setDefaultPaymentMethod(methodId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Default payment method updated'
              : 'Failed to update default',),
          backgroundColor: success ? DCTheme.success : DCTheme.error,
        ),
      );

      if (success) {
        ref.invalidate(savedPaymentMethodsProvider);
      }
    }
  }

  Future<void> _deleteMethod(
      BuildContext context, WidgetRef ref, String methodId,) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DCTheme.surface,
        title: const Text('Remove Card?',
            style: TextStyle(color: DCTheme.text),),
        content: const Text(
          'Are you sure you want to remove this payment method?',
          style: TextStyle(color: DCTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: DCTheme.textMuted),),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove',
                style: TextStyle(color: DCTheme.error),),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final service = ref.read(paymentServiceProvider);
    final success = await service.removePaymentMethod(methodId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              success ? 'Payment method removed' : 'Failed to remove card',),
          backgroundColor: success ? DCTheme.success : DCTheme.error,
        ),
      );

      if (success) {
        ref.invalidate(savedPaymentMethodsProvider);
      }
    }
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final SavedPaymentMethod method;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  const _PaymentMethodCard({
    required this.method,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: method.isDefault ? DCTheme.primary : DCTheme.border.withValues(alpha: 0.3),
          width: method.isDefault ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: _buildBrandIcon(),
            title: Row(
              children: [
                Text(
                  '•••• ${method.last4}',
                  style: const TextStyle(
                    color: DCTheme.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (method.isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: DCTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Default',
                      style: TextStyle(
                        color: DCTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Row(
              children: [
                Text(
                  method.brand.toUpperCase(),
                  style: const TextStyle(color: DCTheme.textMuted),
                ),
                const SizedBox(width: 16),
                Text(
                  'Expires ${method.expiry}',
                  style: TextStyle(
                    color: method.isExpired ? DCTheme.error : DCTheme.textMuted,
                  ),
                ),
                if (method.isExpired) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.warning, size: 14, color: DCTheme.error),
                ],
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: DCTheme.textMuted),
              color: DCTheme.surface,
              onSelected: (value) {
                if (value == 'default') onSetDefault();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                if (!method.isDefault)
                  const PopupMenuItem(
                    value: 'default',
                    child: Row(
                      children: [
                        Icon(Icons.star_outline, color: DCTheme.text),
                        SizedBox(width: 12),
                        Text('Set as Default',
                            style: TextStyle(color: DCTheme.text),),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: DCTheme.error),
                      SizedBox(width: 12),
                      Text('Remove', style: TextStyle(color: DCTheme.error)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandIcon() {
    IconData icon;
    Color color;

    switch (method.brand.toLowerCase()) {
      case 'visa':
        icon = Icons.credit_card;
        color = Colors.blue;
        break;
      case 'mastercard':
        icon = Icons.credit_card;
        color = Colors.orange;
        break;
      case 'amex':
        icon = Icons.credit_card;
        color = Colors.blueGrey;
        break;
      default:
        icon = Icons.credit_card;
        color = DCTheme.textMuted;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color),
    );
  }
}
