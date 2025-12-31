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
              'Last updated: December 31, 2024',
              style: TextStyle(
                color: DCTheme.textMuted.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Acceptance of Terms
            _buildSection(
              '1. Acceptance of Terms',
              'By accessing or using the Direct Cuts mobile application, website, or any related services '
                  '(collectively, the "Service"), you agree to be bound by these Terms of Service ("Terms"). '
                  'If you do not agree to these Terms, you may not access or use the Service.\n\n'
                  'These Terms constitute a legally binding agreement between you and Direct Cuts LLC. '
                  'By using the Service, you represent that you are at least 18 years of age.',
            ),

            // Description of Service
            _buildSection(
              '2. Description of Service',
              'Direct Cuts is a mobile marketplace platform that connects customers seeking barbering services '
                  '("Customers") with independent professional barbers ("Barbers"). We facilitate discovery, '
                  'booking, communication, and payment for barbering services.\n\n'
                  'IMPORTANT: Direct Cuts is a technology platform, not a barbering service provider. '
                  'Barbers are independent contractors who operate their own businesses. We are not responsible '
                  'for the quality, safety, or legality of services provided by Barbers.',
            ),

            // User Accounts
            _buildSection(
              '3. User Accounts',
              'When creating an account, you agree to:\n\n'
                  '- Provide accurate, current, and complete information\n'
                  '- Maintain the security of your account credentials\n'
                  '- Accept responsibility for all activities under your account\n'
                  '- Notify us immediately of any unauthorized use\n\n'
                  'You may maintain only one account per person.\n\n'
                  'Identity Verification: Barbers must complete our identity verification process before '
                  'offering services. This verifies identity to help ensure platform safety but does not '
                  'constitute an endorsement of skills or qualifications.',
            ),

            // Customer Terms
            _buildSection(
              '4. Customer Terms',
              'Booking Appointments:\n'
                  '- You agree to pay the listed price for selected services\n'
                  '- Prices are set by individual Barbers\n'
                  '- Bookings are subject to Barber availability\n\n'
                  'Customer Responsibilities:\n'
                  '- Arrive on time for scheduled appointments\n'
                  '- Provide accurate location information for mobile services\n'
                  '- Treat Barbers with respect and professionalism\n'
                  '- Communicate special requirements in advance\n'
                  '- Pay for services as agreed through the platform',
            ),

            // Barber Terms
            _buildSection(
              '5. Barber Terms',
              'Independent Contractor Status:\n'
                  'Barbers are independent contractors, not employees of Direct Cuts. You are responsible for:\n'
                  '- Setting your own prices, services, and availability\n'
                  '- Complying with all laws and licensing requirements\n'
                  '- Maintaining appropriate business licenses and insurance\n'
                  '- Paying your own taxes and business expenses\n'
                  '- The quality and safety of services you provide\n\n'
                  'Barber Responsibilities:\n'
                  '- Complete identity verification\n'
                  '- Maintain a valid barber license\n'
                  '- Provide services as described\n'
                  '- Honor confirmed bookings\n'
                  '- Maintain professional conduct',
            ),

            // Payments
            _buildSection(
              '6. Payments',
              'Payment Processing:\n'
                  'All payments are processed securely through Stripe. By using payment services, '
                  'you agree to Stripe\'s terms of service.\n\n'
                  'Pricing:\n'
                  '- Barbers set their own prices\n'
                  '- All prices in US dollars unless specified\n'
                  '- Travel fees may apply for mobile services\n\n'
                  'Platform Fee:\n'
                  'Direct Cuts charges ${(AppConstants.platformFeePercent * 100).toInt()}% on each '
                  'completed transaction, deducted from Barber earnings before payout.\n\n'
                  'Payment Methods:\n'
                  'Credit cards, debit cards, Apple Pay, and Google Pay (where available).',
            ),

            // Cancellations
            _buildSection(
              '7. Cancellations, Refunds, and No-Shows',
              'Customer Cancellations:\n'
                  '- More than ${AppConstants.cancellationWindowHours} hours before: Full refund\n'
                  '- 2-${AppConstants.cancellationWindowHours} hours before: 50% refund (may vary)\n'
                  '- Less than 2 hours before: No refund\n\n'
                  'Barber Cancellations:\n'
                  'Customer receives full refund automatically. Excessive cancellations may result in penalties.\n\n'
                  'No-Shows:\n'
                  '15-minute grace period applies. Customer no-shows result in full charge. '
                  'Barber no-shows result in full refund and potential account penalties.',
            ),

            // Prohibited Conduct
            _buildSection(
              '8. Prohibited Conduct',
              'Users may not:\n\n'
                  '- Violate any applicable laws or regulations\n'
                  '- Post false, misleading, or fraudulent content\n'
                  '- Harass, threaten, or abuse other users\n'
                  '- Discriminate based on protected characteristics\n'
                  '- Circumvent platform payments (off-platform transactions)\n'
                  '- Distribute spam or malware\n'
                  '- Scrape or collect user information without authorization\n'
                  '- Interfere with Service operation\n'
                  '- Create multiple accounts or impersonate others\n\n'
                  'Violations may result in warnings, suspension, termination, or legal action.',
            ),

            // Intellectual Property
            _buildSection(
              '9. Intellectual Property',
              'The Service, including its design, features, and functionality, is owned by Direct Cuts '
                  'and protected by intellectual property laws.\n\n'
                  'You retain ownership of content you submit. By submitting content, you grant Direct Cuts '
                  'a worldwide, non-exclusive, royalty-free license to use, reproduce, modify, and display '
                  'that content in connection with operating the Service.',
            ),

            // Privacy
            _buildSection(
              '10. Privacy',
              'Your privacy is important to us. Please review our Privacy Policy, which explains how we '
                  'collect, use, and protect your information. By using the Service, you agree to our Privacy Policy.',
            ),

            // Disclaimers
            _buildSection(
              '11. Disclaimers',
              'THE SERVICE IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, '
                  'INCLUDING MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.\n\n'
                  'We do not guarantee the Service will be uninterrupted or error-free. We are not responsible '
                  'for actions of third parties, including Barbers and payment processors.',
            ),

            // Limitation of Liability
            _buildSection(
              '12. Limitation of Liability',
              'TO THE MAXIMUM EXTENT PERMITTED BY LAW, DIRECT CUTS SHALL NOT BE LIABLE FOR ANY INDIRECT, '
                  'INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING LOSS OF PROFITS, '
                  'PERSONAL INJURY, DISPUTES BETWEEN USERS, OR QUALITY OF BARBERING SERVICES.\n\n'
                  'TOTAL LIABILITY SHALL NOT EXCEED THE GREATER OF: (A) AMOUNT PAID IN THE 12 MONTHS '
                  'PRECEDING THE CLAIM, OR (B) \$100.',
            ),

            // Indemnification
            _buildSection(
              '13. Indemnification',
              'You agree to indemnify and hold harmless Direct Cuts and its officers, directors, employees, '
                  'and affiliates from any claims, damages, losses, or expenses arising from your use of the '
                  'Service, violation of these Terms, or violation of any third-party rights.',
            ),

            // Termination
            _buildSection(
              '14. Termination',
              'By You: Delete your account via app settings or contact ${AppConstants.supportEmail}.\n\n'
                  'By Direct Cuts: We may suspend or terminate accounts for violation of these Terms, '
                  'fraudulent activity, or extended inactivity.\n\n'
                  'Upon termination, your right to use the Service ceases. For Barbers, pending payouts '
                  'will be processed according to standard schedule.',
            ),

            // Dispute Resolution
            _buildSection(
              '15. Dispute Resolution',
              'Before filing formal legal action, contact legal@directcuts.com to attempt informal resolution.\n\n'
                  'ARBITRATION AGREEMENT: Disputes shall be resolved through binding arbitration. '
                  'YOU WAIVE ANY RIGHT TO PARTICIPATE IN A CLASS ACTION LAWSUIT OR CLASS-WIDE ARBITRATION.',
            ),

            // Governing Law
            _buildSection(
              '16. Governing Law',
              'These Terms shall be governed by and construed in accordance with the laws of the State of '
                  '[STATE], without regard to conflict of law provisions.',
            ),

            // Changes
            _buildSection(
              '17. Changes to Terms',
              'We may modify these Terms at any time. We will update the "Last Updated" date and notify '
                  'you of material changes via email or in-app notification. Continued use after changes '
                  'constitutes acceptance of revised Terms.',
            ),

            // Contact
            _buildSection(
              '18. Contact Information',
              'Direct Cuts LLC\n\n'
                  'Legal Inquiries: legal@directcuts.com\n'
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
                'By using Direct Cuts, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
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
    final uri = Uri.parse(AppConstants.termsOfServiceUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
