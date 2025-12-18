import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../utils/constants.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DCTheme.background,
      appBar: AppBar(
        title: const Text('Terms of Service'),
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
              'Terms of Service',
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
              '1. Acceptance of Terms',
              'By accessing or using Direct Cuts, you agree to be bound by these Terms of Service. '
                  'If you do not agree to these terms, please do not use our service.',
            ),
            _buildSection(
              '2. Description of Service',
              'Direct Cuts is a peer-to-peer marketplace connecting customers with independent barbers. '
                  'We facilitate bookings, payments, and communication but are not responsible for the '
                  'actual barbering services provided.',
            ),
            _buildSection(
              '3. User Accounts',
              '• You must provide accurate information when creating an account\n'
                  '• You are responsible for maintaining account security\n'
                  '• You must be at least 18 years old to use our service\n'
                  '• One person may only maintain one account',
            ),
            _buildSection(
              '4. Bookings & Payments',
              '• Customers pay through the app at time of booking\n'
                  '• A ${(AppConstants.platformFeePercent * 100).toInt()}% platform fee is charged on each transaction\n'
                  '• Cancellations made less than ${AppConstants.cancellationWindowHours} hours before the appointment may be non-refundable\n'
                  '• Barbers receive payment after service completion',
            ),
            _buildSection(
              '5. Barber Responsibilities',
              '• Barbers are independent contractors, not employees\n'
                  '• Barbers must maintain appropriate licenses and insurance\n'
                  '• Barbers set their own prices, schedules, and services\n'
                  '• Barbers must complete services as described',
            ),
            _buildSection(
              '6. Customer Responsibilities',
              '• Arrive on time for appointments\n'
                  '• Provide accurate contact information\n'
                  '• Treat barbers with respect\n'
                  '• Pay for services as agreed',
            ),
            _buildSection(
              '7. Prohibited Conduct',
              'Users may not:\n\n'
                  '• Violate any laws or regulations\n'
                  '• Harass, abuse, or harm other users\n'
                  '• Submit false or misleading information\n'
                  '• Attempt to circumvent platform payments\n'
                  '• Use the platform for illegal activities',
            ),
            _buildSection(
              '8. Intellectual Property',
              'All content, features, and functionality of Direct Cuts are owned by us and protected '
                  'by copyright, trademark, and other intellectual property laws.',
            ),
            _buildSection(
              '9. Limitation of Liability',
              'Direct Cuts is provided "as is" without warranties. We are not liable for:\n\n'
                  '• Quality of barbering services\n'
                  '• Disputes between users\n'
                  '• Loss of data or service interruptions\n'
                  '• Indirect or consequential damages',
            ),
            _buildSection(
              '10. Termination',
              'We may suspend or terminate accounts that violate these terms. Users may delete '
                  'their accounts at any time through the app settings.',
            ),
            _buildSection(
              '11. Changes to Terms',
              'We may update these terms at any time. Continued use of the service after changes '
                  'constitutes acceptance of the new terms.',
            ),
            _buildSection(
              '12. Contact',
              'For questions about these Terms of Service, contact us at:\n\n'
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
    final uri = Uri.parse(AppConstants.termsOfServiceUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
