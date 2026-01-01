import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/theme.dart';
import '../../providers/barber_crm_provider.dart';

/// Provider for barber's referral link
final barberReferralLinkProvider = Provider<String>((ref) {
  final barberAsync = ref.watch(currentBarberProvider);
  final barber = barberAsync.valueOrNull;
  if (barber == null) return '';

  // Generate referral link with barber ID
  return 'https://directcuts.app/b/${barber.id}';
});

/// Compact referral card for barber dashboard
class ReferralCard extends ConsumerWidget {
  const ReferralCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.withValues(alpha: 0.15),
            Colors.purple.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.share,
              color: Colors.purple,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grow Your Business',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: DCTheme.text,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Share your profile link with clients',
                  style: TextStyle(
                    color: DCTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showShareSheet(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Share',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showShareSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DCTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _ShareReferralSheet(),
    );
  }
}

/// Bottom sheet for sharing referral link
class _ShareReferralSheet extends ConsumerWidget {
  const _ShareReferralSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralLink = ref.watch(barberReferralLinkProvider);
    final barberAsync = ref.watch(currentBarberProvider);
    final barberName = barberAsync.valueOrNull?.displayName ?? 'Your Barber';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: DCTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Header
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.share,
              color: Colors.purple,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Share Your Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: DCTheme.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send this link to clients so they can book with you directly',
            style: const TextStyle(
              color: DCTheme.textMuted,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Link container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DCTheme.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DCTheme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    referralLink,
                    style: const TextStyle(
                      color: DCTheme.text,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: referralLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copied!'),
                        backgroundColor: DCTheme.success,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, color: DCTheme.primary),
                  style: IconButton.styleFrom(
                    backgroundColor: DCTheme.primary.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Share options
          Row(
            children: [
              Expanded(
                child: _ShareOption(
                  icon: Icons.message,
                  label: 'Message',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    Share.share(
                      'Book your next haircut with $barberName on Direct Cuts!\n\n$referralLink',
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ShareOption(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    Share.share(
                      'Book with $barberName\n\nHey! Book your next appointment with me on Direct Cuts.\n\n$referralLink',
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ShareOption(
                  icon: Icons.more_horiz,
                  label: 'More',
                  color: DCTheme.textMuted,
                  onTap: () {
                    Navigator.pop(context);
                    Share.share(
                      'Book your next haircut with $barberName!\n\n$referralLink',
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // QR code hint
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('QR code feature coming soon'),
                  backgroundColor: DCTheme.info,
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code,
                  color: DCTheme.textMuted.withValues(alpha: 0.7),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Show QR Code',
                  style: TextStyle(
                    color: DCTheme.textMuted.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
