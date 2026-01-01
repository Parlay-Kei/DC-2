import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../config/profile_menu.dart';
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
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DCTheme.primary),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: DCTheme.error),
              const SizedBox(height: 16),
              Text(
                'Error loading profile',
                style: const TextStyle(color: DCTheme.text, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: DCTheme.textMuted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (profile) {
          // Determine which menu sections to show based on role
          final menuSections = profile?.isBarber == true
              ? barberMenuSections
              : customerMenuSections;

          return ListView(
            children: [
              // Profile header
              _ProfileHeader(
                fullName: profile?.fullName ?? 'User',
                email: profile?.email ?? '',
                role: profile?.role ?? 'customer',
              ),
              const Divider(color: DCTheme.border, height: 1),

              // Dynamic menu sections based on role
              ...menuSections.map((section) => _buildMenuSection(
                    context,
                    section,
                  )),

              // Account Actions section
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
                      'Version 2.0.2',
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
          );
        },
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, ProfileMenuSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: section.title),
        ...section.items.map((item) => _SettingsTile(
              icon: item.icon,
              title: item.title,
              iconColor: item.iconColor ?? DCTheme.textMuted,
              textColor: item.textColor ?? DCTheme.text,
              showComingSoonBadge: item.comingSoon,
              onTap: () {
                if (item.comingSoon) {
                  context.push(
                    '/coming-soon',
                    extra: item.title,
                  );
                } else {
                  context.push(item.route);
                }
              },
            )),
        const Divider(color: DCTheme.border, height: 1),
      ],
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

class _ProfileHeader extends StatelessWidget {
  final String fullName;
  final String email;
  final String role;

  const _ProfileHeader({
    required this.fullName,
    required this.email,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: DCTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Center(
              child: Text(
                fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: DCTheme.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    color: DCTheme.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: DCTheme.textMuted,
                    fontSize: 14,
                  ),
                ),
                if (role == 'barber') ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: DCTheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Barber',
                      style: TextStyle(
                        color: DCTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
  final bool showComingSoonBadge;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor = DCTheme.textMuted,
    this.textColor = DCTheme.text,
    this.showComingSoonBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Row(
        children: [
          Text(title, style: TextStyle(color: textColor)),
          if (showComingSoonBadge) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: DCTheme.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'SOON',
                style: TextStyle(
                  color: DCTheme.warning,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
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
