import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/profile_provider.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _passwordController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _showPassword = false;
  bool _confirmed = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your password'),
          backgroundColor: DCTheme.error,
        ),
      );
      return;
    }

    if (!_confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm that you understand this action'),
          backgroundColor: DCTheme.error,
        ),
      );
      return;
    }

    // Show final confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DCTheme.surface,
        title: const Row(
          children: [
            Icon(Icons.warning, color: DCTheme.error),
            SizedBox(width: 12),
            Text('Final Warning', style: TextStyle(color: DCTheme.text)),
          ],
        ),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone.\n\nAre you absolutely sure?',
          style: TextStyle(color: DCTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: DCTheme.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete Forever',
              style: TextStyle(color: DCTheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final notifier = ref.read(profileStateProvider.notifier);
    final result = await notifier.deleteAccount(
      password: _passwordController.text,
      reason: _reasonController.text.isNotEmpty ? _reasonController.text : null,
    );

    if (mounted) {
      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted. We\'re sorry to see you go.'),
            backgroundColor: DCTheme.success,
          ),
        );
        context.go('/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Failed to delete account'),
            backgroundColor: DCTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileStateProvider);

    return Scaffold(
      backgroundColor: DCTheme.background,
      appBar: AppBar(
        title: const Text('Delete Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DCTheme.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DCTheme.error.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: DCTheme.error,
                    size: 32,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Warning: This action is irreversible',
                          style: TextStyle(
                            color: DCTheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Once deleted, your account and all data cannot be recovered.',
                          style: TextStyle(color: DCTheme.error, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // What will be deleted
            const Text(
              'What will be deleted:',
              style: TextStyle(
                color: DCTheme.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildDeleteItem('Your profile and account information'),
            _buildDeleteItem('All booking history'),
            _buildDeleteItem('Saved payment methods'),
            _buildDeleteItem('Chat messages and conversations'),
            _buildDeleteItem('Reviews you\'ve written'),
            _buildDeleteItem('Favorite barbers'),
            const SizedBox(height: 24),

            // Reason (optional)
            const Text(
              'Why are you leaving? (Optional)',
              style: TextStyle(color: DCTheme.textMuted),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              style: const TextStyle(color: DCTheme.text),
              decoration: InputDecoration(
                hintText: 'Help us improve by sharing your reason...',
                hintStyle: const TextStyle(color: DCTheme.textMuted),
                filled: true,
                fillColor: DCTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Password confirmation
            const Text(
              'Enter your password to confirm',
              style: TextStyle(color: DCTheme.textMuted),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: !_showPassword,
              style: const TextStyle(color: DCTheme.text),
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: const TextStyle(color: DCTheme.textMuted),
                prefixIcon:
                    const Icon(Icons.lock_outline, color: DCTheme.textMuted),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                    color: DCTheme.textMuted,
                  ),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
                filled: true,
                fillColor: DCTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Confirmation checkbox
            CheckboxListTile(
              value: _confirmed,
              onChanged: (value) => setState(() => _confirmed = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: DCTheme.error,
              title: const Text(
                'I understand that this action is permanent and cannot be undone',
                style: TextStyle(color: DCTheme.text, fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),

            // Delete button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.isLoading ? null : _deleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DCTheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Delete My Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Cancel option
            Center(
              child: TextButton(
                onPressed: () => context.pop(),
                child: const Text(
                  'Cancel, keep my account',
                  style: TextStyle(color: DCTheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.remove_circle_outline,
            size: 18,
            color: DCTheme.error,
          ),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: DCTheme.textMuted)),
        ],
      ),
    );
  }
}
