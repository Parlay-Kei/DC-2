import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';

/// Quick action bar with 4 primary actions: Charge, Schedule, Invite, Blast
/// Inspired by theCut's home dashboard quick actions
class QuickActionBar extends StatelessWidget {
  final VoidCallback? onCharge;
  final VoidCallback? onSchedule;
  final VoidCallback? onInvite;
  final VoidCallback? onBlast;

  const QuickActionBar({
    super.key,
    this.onCharge,
    this.onSchedule,
    this.onInvite,
    this.onBlast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _QuickActionButton(
            icon: Icons.point_of_sale_rounded,
            label: 'Charge',
            onTap: onCharge ?? () => _showComingSoon(context, 'POS Checkout'),
          ),
          _QuickActionButton(
            icon: Icons.calendar_month_rounded,
            label: 'Schedule',
            onTap: onSchedule ?? () => context.push('/barber/appointments'),
          ),
          _QuickActionButton(
            icon: Icons.person_add_rounded,
            label: 'Invite',
            onTap: onInvite ?? () => _showInviteSheet(context),
          ),
          _QuickActionButton(
            icon: Icons.campaign_rounded,
            label: 'Blast',
            onTap: onBlast ?? () => _showComingSoon(context, 'Client Blast'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: DCTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInviteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DCTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DCTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Invite Clients',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: DCTheme.text,
              ),
            ),
            const SizedBox(height: 24),
            _InviteOption(
              icon: Icons.link,
              title: 'Share Profile Link',
              subtitle: 'Copy your booking link',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link copied to clipboard!'),
                    backgroundColor: DCTheme.success,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _InviteOption(
              icon: Icons.qr_code,
              title: 'Show QR Code',
              subtitle: 'Let clients scan to book',
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context, 'QR Code');
              },
            ),
            const SizedBox(height: 12),
            _InviteOption(
              icon: Icons.share,
              title: 'Share via...',
              subtitle: 'SMS, Email, Social Media',
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context, 'Share');
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: DCTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DCTheme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: DCTheme.primary, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: DCTheme.text,
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

class _InviteOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _InviteOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: DCTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: DCTheme.primary),
      ),
      title: Text(title, style: const TextStyle(color: DCTheme.text, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: DCTheme.textMuted, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: DCTheme.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: DCTheme.border),
      ),
    );
  }
}
