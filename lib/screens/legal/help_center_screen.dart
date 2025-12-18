import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../utils/constants.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DCTheme.background,
      appBar: AppBar(
        title: const Text('Help Center'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: DCTheme.primary.withValues(alpha: 0.1),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 48,
                    color: DCTheme.primary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'How can we help?',
                    style: TextStyle(
                      color: DCTheme.text,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Find answers to common questions or contact support',
                    style: TextStyle(color: DCTheme.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      color: DCTheme.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          icon: Icons.email_outlined,
                          label: 'Email Us',
                          onTap: () => _sendEmail(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          icon: Icons.language,
                          label: 'Visit Website',
                          onTap: () => _openWebsite(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(color: DCTheme.border, height: 1),

            // FAQ Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      color: DCTheme.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFaqItem(
                    'How do I book an appointment?',
                    'Browse barbers in your area, select services and a time slot, '
                        'then confirm your booking with payment. You\'ll receive a '
                        'confirmation notification.',
                  ),
                  _buildFaqItem(
                    'How do I cancel a booking?',
                    'Go to your Bookings tab, select the appointment, and tap Cancel. '
                        'Cancellations made at least ${AppConstants.cancellationWindowHours} hours before '
                        'the appointment are fully refundable.',
                  ),
                  _buildFaqItem(
                    'How do payments work?',
                    'Payments are processed securely through Stripe at the time of booking. '
                        'Barbers receive payment after completing the service, minus the '
                        '${(AppConstants.platformFeePercent * 100).toInt()}% platform fee.',
                  ),
                  _buildFaqItem(
                    'How do I become a barber on Direct Cuts?',
                    'Contact us at ${AppConstants.supportEmail} to apply. You\'ll need to '
                        'provide proof of licensing and complete our onboarding process.',
                  ),
                  _buildFaqItem(
                    'What if I have an issue with my service?',
                    'Contact us immediately through the app or email. We\'ll work with '
                        'you and the barber to resolve any issues.',
                  ),
                  _buildFaqItem(
                    'How do I update my payment method?',
                    'Go to Settings > Payment Methods to add, remove, or change your '
                        'default payment method.',
                  ),
                  _buildFaqItem(
                    'How do I delete my account?',
                    'Go to Settings > Delete Account. This will permanently remove your '
                        'account and all associated data.',
                  ),
                ],
              ),
            ),

            // Contact Info
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DCTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DCTheme.border),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.support_agent,
                    size: 40,
                    color: DCTheme.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Still need help?',
                    style: TextStyle(
                      color: DCTheme.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Our support team is here to help you',
                    style: TextStyle(color: DCTheme.textMuted),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _sendEmail(),
                      icon: const Icon(Icons.email),
                      label: const Text('Contact Support'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DCTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: DCTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DCTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: DCTheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: DCTheme.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        question,
        style: const TextStyle(
          color: DCTheme.text,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      iconColor: DCTheme.primary,
      collapsedIconColor: DCTheme.textMuted,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            answer,
            style: const TextStyle(
              color: DCTheme.textMuted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppConstants.supportEmail,
      queryParameters: {
        'subject': 'Direct Cuts Support Request',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWebsite() async {
    final uri = Uri.parse(AppConstants.helpCenterUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
