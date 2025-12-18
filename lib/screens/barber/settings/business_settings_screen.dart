import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../providers/barber_crm_provider.dart';

class BusinessSettingsScreen extends ConsumerStatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  ConsumerState<BusinessSettingsScreen> createState() =>
      _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState
    extends ConsumerState<BusinessSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isInitialized = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _shopNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initializeForm(barber) {
    if (_isInitialized || barber == null) return;

    _displayNameController.text = barber.displayName ?? '';
    _shopNameController.text = barber.shopName ?? '';
    _bioController.text = barber.bio ?? '';
    _phoneController.text = barber.phone ?? '';
    _isInitialized = true;
  }

  Future<void> _saveBusinessInfo() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(barberCrmProvider.notifier);
    final success = await notifier.updateBusinessInfo(
      displayName: _displayNameController.text.trim(),
      shopName: _shopNameController.text.trim(),
      bio: _bioController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business info saved successfully'),
            backgroundColor: DCTheme.success,
          ),
        );
        context.pop();
      } else {
        final error = ref.read(barberCrmProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to save business info'),
            backgroundColor: DCTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final crmState = ref.watch(barberCrmProvider);
    final barber = crmState.barber;

    _initializeForm(barber);

    return Scaffold(
      backgroundColor: DCTheme.background,
      appBar: AppBar(
        title: const Text('Business Info'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: crmState.isSaving ? null : _saveBusinessInfo,
            child: crmState.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DCTheme.primary,
                    ),
                  )
                : const Text('Save',
                    style: TextStyle(color: DCTheme.primary),),
          ),
        ],
      ),
      body: crmState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: DCTheme.primary),)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile completion hint
                    _buildCompletionCard(barber),
                    const SizedBox(height: 24),

                    // Business Identity Section
                    _buildSectionHeader('Business Identity'),
                    const SizedBox(height: 12),
                    _buildBusinessIdentitySection(),
                    const SizedBox(height: 24),

                    // Contact Info Section
                    _buildSectionHeader('Contact Information'),
                    const SizedBox(height: 12),
                    _buildContactSection(),
                    const SizedBox(height: 24),

                    // Bio Section
                    _buildSectionHeader('About Your Business'),
                    const SizedBox(height: 12),
                    _buildBioSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCompletionCard(barber) {
    int completedFields = 0;
    const int totalFields = 4;

    if (barber?.displayName?.isNotEmpty == true) completedFields++;
    if (barber?.shopName?.isNotEmpty == true) completedFields++;
    if (barber?.phone?.isNotEmpty == true) completedFields++;
    if (barber?.bio?.isNotEmpty == true) completedFields++;

    final percentage = (completedFields / totalFields * 100).round();
    final isComplete = completedFields == totalFields;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isComplete
            ? DCTheme.success.withValues(alpha: 0.1)
            : DCTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete
              ? DCTheme.success.withValues(alpha: 0.3)
              : DCTheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isComplete ? Icons.check_circle : Icons.info_outline,
                color: isComplete ? DCTheme.success : DCTheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isComplete
                      ? 'Profile Complete!'
                      : 'Complete Your Profile',
                  style: TextStyle(
                    color: isComplete ? DCTheme.success : DCTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  color: isComplete ? DCTheme.success : DCTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completedFields / totalFields,
              backgroundColor: DCTheme.surface,
              valueColor: AlwaysStoppedAnimation(
                isComplete ? DCTheme.success : DCTheme.primary,
              ),
              minHeight: 6,
            ),
          ),
          if (!isComplete) ...[
            const SizedBox(height: 8),
            const Text(
              'Complete your profile to build trust with clients',
              style: TextStyle(
                color: DCTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: DCTheme.text,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildBusinessIdentitySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _displayNameController,
            style: const TextStyle(color: DCTheme.text),
            decoration: InputDecoration(
              labelText: 'Display Name *',
              labelStyle: const TextStyle(color: DCTheme.textMuted),
              hintText: 'How clients will see your name',
              hintStyle: TextStyle(color: DCTheme.textMuted.withValues(alpha: 0.5)),
              prefixIcon: const Icon(Icons.person, color: DCTheme.textMuted),
              filled: true,
              fillColor: DCTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Display name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _shopNameController,
            style: const TextStyle(color: DCTheme.text),
            decoration: InputDecoration(
              labelText: 'Shop/Business Name',
              labelStyle: const TextStyle(color: DCTheme.textMuted),
              hintText: 'e.g., "Elite Cuts Barbershop"',
              hintStyle: TextStyle(color: DCTheme.textMuted.withValues(alpha: 0.5)),
              prefixIcon: const Icon(Icons.store, color: DCTheme.textMuted),
              filled: true,
              fillColor: DCTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DCTheme.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    color: DCTheme.info.withValues(alpha: 0.8), size: 20,),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'A memorable business name helps clients find and remember you.',
                    style: TextStyle(
                      color: DCTheme.textMuted,
                      fontSize: 12,
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

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _phoneController,
            style: const TextStyle(color: DCTheme.text),
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Business Phone',
              labelStyle: const TextStyle(color: DCTheme.textMuted),
              hintText: '(555) 123-4567',
              hintStyle: TextStyle(color: DCTheme.textMuted.withValues(alpha: 0.5)),
              prefixIcon: const Icon(Icons.phone, color: DCTheme.textMuted),
              filled: true,
              fillColor: DCTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DCTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.privacy_tip_outlined,
                    color: DCTheme.warning.withValues(alpha: 0.8), size: 20,),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Your phone number is only shared with clients who book appointments.',
                    style: TextStyle(
                      color: DCTheme.textMuted,
                      fontSize: 12,
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

  Widget _buildBioSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _bioController,
            style: const TextStyle(color: DCTheme.text),
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'About You',
              labelStyle: const TextStyle(color: DCTheme.textMuted),
              hintText:
                  'Tell clients about your experience, specialties, and what makes you unique...',
              hintStyle: TextStyle(color: DCTheme.textMuted.withValues(alpha: 0.5)),
              alignLabelWithHint: true,
              filled: true,
              fillColor: DCTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              counterStyle: const TextStyle(color: DCTheme.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tips for a great bio:',
            style: TextStyle(
              color: DCTheme.text,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          _buildBioTip(Icons.check_circle_outline, 'Mention your years of experience'),
          _buildBioTip(Icons.check_circle_outline, 'List your specialties (fades, beard work, etc.)'),
          _buildBioTip(Icons.check_circle_outline, 'Share what you love about barbering'),
        ],
      ),
    );
  }

  Widget _buildBioTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: DCTheme.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: DCTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
