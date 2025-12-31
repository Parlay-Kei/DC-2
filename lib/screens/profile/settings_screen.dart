import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: DCTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Profile section
          profileAsync.when(
            loading: () => const _SettingsTile(
              icon: Icons.person_outline,
              title: 'Loading...',
              subtitle: '',
            ),
            error: (_, __) => const _SettingsTile(
              icon: Icons.person_outline,
              title: 'Error loading profile',
              subtitle: '',
            ),
            data: (profile) => _SettingsTile(
              icon: Icons.person_outline,
              title: profile?.fullName ?? 'Your Profile',
              subtitle: profile?.email ?? 'Tap to edit',
              onTap: () => context.push('/settings/edit-profile'),
            ),
          ),
          const Divider(color: DCTheme.border, height: 1),

          // Account section
          const _SectionHeader(title: 'Account'),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () => context.push('/settings/change-password'),
          ),
          _SettingsTile(
            icon: Icons.credit_card_outlined,
            title: 'Payment Methods',
            onTap: () => context.push('/settings/payment-methods'),
          ),
          const Divider(color: DCTheme.border, height: 1),

          // Notifications section
          const _SectionHeader(title: 'Notifications'),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notification Settings',
            onTap: () => context.push('/settings/notifications'),
          ),
          const Divider(color: DCTheme.border, height: 1),

          // Preferences section
          const _SectionHeader(title: 'Preferences'),
          _SettingsTile(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: 'English',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language settings coming soon')),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Appearance',
            subtitle: 'Dark',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theme settings coming soon')),
              );
            },
          ),
          const Divider(color: DCTheme.border, height: 1),

          // Support section
          const _SectionHeader(title: 'Support'),
          _SettingsTile(
            icon: Icons.help_outline,
            title: 'Help Center',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help center coming soon')),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.chat_bubble_outline,
            title: 'Contact Support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support chat coming soon')),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terms of service coming soon')),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy policy coming soon')),
              );
            },
          ),
          const Divider(color: DCTheme.border, height: 1),

          // Danger zone
          const _SectionHeader(title: 'Account Actions'),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Sign Out',
            iconColor: DCTheme.warning,
            onTap: () => _showSignOutDialog(context, ref),
          ),
          _SettingsTile(
            icon: Icons.delete_forever,
            title: 'Delete Account',
            iconColor: DCTheme.error,
            textColor: DCTheme.error,
            onTap: () => context.push('/settings/delete-account'),
          ),
          const SizedBox(height: 32),

          // App info
          Center(
            child: Column(
              children: [
                Text(
                  'Direct Cuts',
                  style: TextStyle(
                    color: DCTheme.textMuted.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 2.0.0',
                  style: TextStyle(
                    color: DCTheme.textMuted.withValues(alpha: 0.3),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DCTheme.surface,
        title: const Text('Sign Out?', style: TextStyle(color: DCTheme.text)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: DCTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: DCTheme.textMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: DCTheme.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: DCTheme.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color textColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor = DCTheme.textMuted,
    this.textColor = DCTheme.text,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: textColor)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(color: DCTheme.textMuted))
          : null,
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: DCTheme.textMuted)
          : null,
      onTap: onTap,
    );
  }
}
