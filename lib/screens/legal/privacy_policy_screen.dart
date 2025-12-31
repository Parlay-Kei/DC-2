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
              'Last updated: December 31, 2024',
              style: TextStyle(
                color: DCTheme.textMuted.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Introduction
            _buildSection(
              'Introduction',
              'Direct Cuts LLC ("Direct Cuts," "we," "us," or "our") is committed to protecting your privacy. '
                  'This Privacy Policy explains how we collect, use, disclose, and safeguard your information when '
                  'you use our mobile application, website, and related services.\n\n'
                  'By using the Service, you consent to the collection, use, and disclosure of your information as '
                  'described in this Privacy Policy.',
            ),

            // Information We Collect
            _buildSection(
              '1. Information We Collect',
              'Information You Provide:\n\n'
                  '- Account Information: Name, email, phone number, password, profile photo\n'
                  '- Profile Information: Preferences, addresses (Customers); business name, bio, services, pricing (Barbers)\n'
                  '- Payment Information: Card details processed by Stripe, billing address, transaction history\n'
                  '- Communications: Messages, support inquiries, reviews\n'
                  '- Identity Verification (Barbers): Government ID and barber license for verification\n\n'
                  'Information Collected Automatically:\n\n'
                  '- Device Information: Device type, OS, unique identifiers\n'
                  '- Usage Information: Features used, booking history\n'
                  '- Location Information: Precise location (when enabled), approximate via IP\n'
                  '- Log Data: IP address, access times, app crashes',
            ),

            // How We Use Information
            _buildSection(
              '2. How We Use Your Information',
              '- Provide and operate the Service, including bookings and payments\n'
                  '- Facilitate communication between Customers and Barbers\n'
                  '- Display nearby Barbers based on your location\n'
                  '- Send booking confirmations, reminders, and updates\n'
                  '- Improve and personalize your experience\n'
                  '- Ensure safety, detect fraud, and enforce Terms of Service\n'
                  '- Respond to support requests\n'
                  '- Send promotional communications (with your consent)\n'
                  '- Comply with legal obligations',
            ),

            // Information Sharing
            _buildSection(
              '3. How We Share Your Information',
              'With Other Users:\n'
                  'When you book an appointment, we share your name, contact info, and booking details with the Barber. '
                  'For mobile services, your service address is shared.\n\n'
                  'With Service Providers:\n'
                  '- Stripe: Payment processing\n'
                  '- Cloud Services: Database hosting\n'
                  '- Analytics: Usage patterns (aggregated)\n'
                  '- Communications: Push notifications, email\n\n'
                  'For Legal Purposes:\n'
                  'We may disclose information when required by law, to protect our rights or safety, or to enforce our Terms.',
            ),

            // Data Retention
            _buildSection(
              '4. Data Retention',
              'We retain your information for as long as necessary to maintain your account and comply with legal obligations.\n\n'
                  '- Active account data: While account is active\n'
                  '- Transaction records: 7 years (legal compliance)\n'
                  '- Communications: 3 years after account closure\n\n'
                  'When you delete your account, your profile is removed immediately and personal data is deleted within 30 days, '
                  'except where retention is required by law.',
            ),

            // Your Rights
            _buildSection(
              '5. Your Rights and Choices',
              '- Access: Request access to your personal information\n'
                  '- Correction: Update your information through account settings\n'
                  '- Deletion: Delete your account via settings or contact ${AppConstants.supportEmail}\n'
                  '- Portability: Request a copy of your data\n'
                  '- Communications: Opt out of marketing at any time\n'
                  '- Location: Disable location services in device settings (some features require location)',
            ),

            // California Privacy Rights
            _buildSection(
              '6. California Privacy Rights (CCPA/CPRA)',
              'If you are a California resident, you have additional rights:\n\n'
                  '- Right to Know: Request disclosure of personal information collected\n'
                  '- Right to Delete: Request deletion of your personal information\n'
                  '- Right to Correct: Request correction of inaccurate information\n'
                  '- Right to Opt Out: We do not sell your personal information\n'
                  '- Right to Non-Discrimination: We will not discriminate for exercising your rights\n\n'
                  'To exercise California rights, contact privacy@directcuts.com with subject "California Privacy Rights Request."',
            ),

            // Children's Privacy
            _buildSection(
              '7. Children\'s Privacy',
              'Direct Cuts is not intended for users under 13 years of age. We do not knowingly collect personal '
                  'information from children under 13. If we discover we have collected information from a child under 13, '
                  'we will delete it immediately. Users 13-17 may use Direct Cuts only with parental consent.\n\n'
                  'If you believe we have collected information from a child under 13, contact privacy@directcuts.com.',
            ),

            // Data Security
            _buildSection(
              '8. Data Security',
              'We implement industry-standard security measures:\n\n'
                  '- Encryption of data in transit (TLS/SSL)\n'
                  '- Encryption of sensitive data at rest\n'
                  '- Secure authentication systems\n'
                  '- Regular security assessments\n'
                  '- Access controls and authentication\n\n'
                  'Payment information is handled by Stripe, which is PCI DSS Level 1 certified. We do not store full '
                  'credit card numbers on our servers.',
            ),

            // International Transfers
            _buildSection(
              '9. International Data Transfers',
              'Your information is primarily stored and processed in the United States. By using our Service, you '
                  'consent to the transfer of your information to the United States. We implement appropriate safeguards '
                  'to protect your information in international transfers.',
            ),

            // Changes
            _buildSection(
              '10. Changes to This Privacy Policy',
              'We may update this Privacy Policy from time to time. When we make changes, we will update the '
                  '"Last Updated" date. For material changes, we will notify you via email or in-app notification. '
                  'Your continued use after changes constitutes acceptance of the revised Privacy Policy.',
            ),

            // Contact
            _buildSection(
              '11. Contact Us',
              'If you have questions about this Privacy Policy, contact us:\n\n'
                  'Direct Cuts LLC\n\n'
                  'Privacy Inquiries: privacy@directcuts.com\n'
                  'General Support: ${AppConstants.supportEmail}\n'
                  'Address: [BUSINESS ADDRESS]',
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DCTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DCTheme.border),
              ),
              child: const Text(
                'By using Direct Cuts, you acknowledge that you have read and understood this Privacy Policy.',
                style: TextStyle(
                  color: DCTheme.textMuted,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
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
