import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../utils/constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DCTheme.background,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _openInBrowser(),
            tooltip: 'Open in browser',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                color: DCTheme.text,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: December 2024',
              style: TextStyle(
                color: DCTheme.textMuted.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Information We Collect',
              'We collect information you provide directly to us, including:\n\n'
                  '• Account information (name, email, phone number)\n'
                  '• Profile information (photo, bio, preferences)\n'
                  '• Payment information (processed securely via Stripe)\n'
                  '• Location data (to show nearby barbers)\n'
                  '• Communications (messages between customers and barbers)',
            ),
            _buildSection(
              'How We Use Your Information',
              'We use the information we collect to:\n\n'
                  '• Provide and improve our services\n'
                  '• Process bookings and payments\n'
                  '• Send notifications about appointments\n'
                  '• Facilitate communication between users\n'
                  '• Ensure platform safety and security',
            ),
            _buildSection(
              'Information Sharing',
              'We share information with:\n\n'
                  '• Barbers (when you book appointments)\n'
                  '• Payment processors (Stripe)\n'
                  '• Service providers (hosting, analytics)\n'
                  '• Law enforcement (when legally required)',
            ),
            _buildSection(
              'Data Security',
              'We implement industry-standard security measures to protect your data, '
                  'including encryption, secure servers, and regular security audits.',
            ),
            _buildSection(
              'Your Rights',
              'You have the right to:\n\n'
                  '• Access your personal data\n'
                  '• Correct inaccurate data\n'
                  '• Delete your account and data\n'
                  '• Opt out of marketing communications',
            ),
            _buildSection(
              'Contact Us',
              'If you have questions about this Privacy Policy, please contact us at:\n\n'
                  '${AppConstants.supportEmail}',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: DCTheme.text,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: DCTheme.textMuted,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(AppConstants.privacyPolicyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
