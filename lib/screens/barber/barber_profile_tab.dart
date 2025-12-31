import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/barber_dashboard_provider.dart';
import '../../providers/barber_crm_provider.dart';
import '../../models/barber.dart';

class BarberProfileTab extends ConsumerWidget {
  const BarberProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final stats = ref.watch(barberStatsProvider);
    final crmState = ref.watch(barberCrmProvider);
    final barber = crmState.barber;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProfileHeader(profile, barber),
            const SizedBox(height: 24),
            _buildStatsRow(stats),
            const SizedBox(height: 24),

            // Profile Completion Card
            if (barber != null) _buildProfileCompletionCard(context, barber),
            const SizedBox(height: 24),

            // CRM Menu Sections
            _buildBusinessSection(context),
            const SizedBox(height: 16),
            _buildLocationSection(context, barber),
            const SizedBox(height: 16),
            _buildServicesSection(context),
            const SizedBox(height: 16),
            _buildAccountSection(context),
            const SizedBox(height: 16),
            _buildSupportSection(context),
            const SizedBox(height: 24),

            _buildSignOutButton(context, ref),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AsyncValue profile, Barber? barber) {
    return profile.when(
      data: (p) => Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: DCTheme.primary, width: 3),
            ),
            child: ClipOval(
              child: p?.avatarUrl != null
                  ? Image.network(p!.avatarUrl!, fit: BoxFit.cover)
                  : Container(
                      color: DCTheme.surface,
                      child: Center(
                        child: Text(
                          _getInitials(p?.fullName),
                          style: const TextStyle(
                            color: DCTheme.text,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            barber?.displayName ?? p?.fullName ?? 'Barber',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: DCTheme.text,
            ),
          ),
          if (barber?.shopName != null && barber!.shopName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              barber.shopName!,
              style: const TextStyle(
                color: DCTheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (p?.email != null) ...[
            const SizedBox(height: 4),
            Text(
              p!.email!,
              style: const TextStyle(color: DCTheme.textMuted),
            ),
          ],
          // Location indicator
          if (barber?.hasLocation == true) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: DCTheme.success.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 4),
                Text(
                  'Location set',
                  style: TextStyle(
                    color: DCTheme.success.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
                if (barber?.isMobile == true) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: DCTheme.info.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_car,
                          size: 12,
                          color: DCTheme.info,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Mobile',
                          style: TextStyle(
                            color: DCTheme.info,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off,
                  size: 14,
                  color: DCTheme.warning.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 4),
                Text(
                  'Location not set',
                  style: TextStyle(
                    color: DCTheme.warning.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      loading: () => Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: DCTheme.surface,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 120,
            height: 24,
            decoration: BoxDecoration(
              color: DCTheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
      error: (_, __) => const Text('Error loading profile'),
    );
  }

  Widget _buildStatsRow(AsyncValue<BarberStats> statsAsync) {
    return statsAsync.when(
      data: (stats) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DCTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatColumn(
              value: '\$${stats.monthEarnings.toStringAsFixed(0)}',
              label: 'This Month',
            ),
            Container(width: 1, height: 40, color: DCTheme.border),
            _StatColumn(
              value: '${stats.monthBookings}',
              label: 'Bookings',
            ),
            Container(width: 1, height: 40, color: DCTheme.border),
            _StatColumn(
              value: stats.rating.toStringAsFixed(1),
              label: 'Rating',
              icon: Icons.star,
              iconColor: Colors.amber,
            ),
          ],
        ),
      ),
      loading: () => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DCTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: DCTheme.primary),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildProfileCompletionCard(BuildContext context, Barber barber) {
    int completedItems = 0;
    const int totalItems = 5;

    if (barber.displayName.isNotEmpty) completedItems++;
    if (barber.bio?.isNotEmpty == true) completedItems++;
    if (barber.phone?.isNotEmpty == true) completedItems++;
    if (barber.hasLocation) completedItems++;
    if (barber.shopName?.isNotEmpty == true) completedItems++;

    final percentage = (completedItems / totalItems * 100).round();
    final isComplete = completedItems == totalItems;

    if (isComplete) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DCTheme.primary.withValues(alpha: 0.15),
            DCTheme.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DCTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DCTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: DCTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complete Your Profile',
                      style: TextStyle(
                        color: DCTheme.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Attract more clients',
                      style: TextStyle(
                        color: DCTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: DCTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completedItems / totalItems,
              backgroundColor: DCTheme.surface,
              valueColor: const AlwaysStoppedAnimation(DCTheme.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (barber.displayName.isEmpty) _buildMissingItem('Display Name'),
              if (barber.bio?.isEmpty != false) _buildMissingItem('Bio'),
              if (!barber.hasLocation) _buildMissingItem('Location'),
              if (barber.shopName?.isEmpty != false)
                _buildMissingItem('Shop Name'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissingItem(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: DCTheme.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add_circle_outline,
              size: 14, color: DCTheme.warning),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: DCTheme.warning,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessSection(BuildContext context) {
    return _buildMenuSection(
      title: 'Business',
      icon: Icons.business_center,
      iconColor: DCTheme.primary,
      items: [
        _MenuItem(
          icon: Icons.person_outline,
          label: 'Business Info',
          subtitle: 'Name, bio, contact details',
          onTap: () => context.push('/barber/business-settings'),
        ),
        _MenuItem(
          icon: Icons.content_cut,
          label: 'My Services',
          subtitle: 'Manage your service offerings',
          onTap: () => context.push('/barber/services'),
        ),
        _MenuItem(
          icon: Icons.schedule,
          label: 'Availability',
          subtitle: 'Set your working hours',
          onTap: () => context.push('/barber/availability'),
        ),
      ],
    );
  }

  Widget _buildLocationSection(BuildContext context, Barber? barber) {
    final hasLocation = barber?.hasLocation ?? false;

    return _buildMenuSection(
      title: 'Location & Service Area',
      icon: Icons.location_on,
      iconColor: hasLocation ? DCTheme.success : DCTheme.warning,
      badge: hasLocation ? null : 'Setup Required',
      items: [
        _MenuItem(
          icon: Icons.my_location,
          label: 'Location Settings',
          subtitle: hasLocation
              ? 'Update your business location'
              : 'Set your location to be discovered',
          trailing: hasLocation
              ? const Icon(Icons.check_circle, color: DCTheme.success, size: 20)
              : Icon(
                  Icons.warning_amber,
                  color: DCTheme.warning.withValues(alpha: 0.8),
                  size: 20,
                ),
          onTap: () => context.push('/barber/location-settings'),
        ),
      ],
    );
  }

  Widget _buildServicesSection(BuildContext context) {
    return _buildMenuSection(
      title: 'Earnings & Payments',
      icon: Icons.account_balance_wallet,
      iconColor: DCTheme.success,
      items: [
        _MenuItem(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Earnings & Payouts',
          subtitle: 'View earnings and manage payouts',
          onTap: () => context.push('/barber/earnings'),
        ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return _buildMenuSection(
      title: 'Account',
      icon: Icons.manage_accounts,
      iconColor: DCTheme.info,
      items: [
        _MenuItem(
          icon: Icons.edit,
          label: 'Edit Profile',
          subtitle: 'Update your personal info',
          onTap: () => context.push('/barber/edit-profile'),
        ),
        _MenuItem(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          subtitle: 'Manage notification preferences',
          onTap: () => context.push('/settings/notifications'),
        ),
        _MenuItem(
          icon: Icons.lock_outline,
          label: 'Change Password',
          subtitle: 'Update your password',
          onTap: () => context.push('/settings/change-password'),
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return _buildMenuSection(
      title: 'Support',
      icon: Icons.support_agent,
      iconColor: DCTheme.textMuted,
      items: [
        _MenuItem(
          icon: Icons.help_outline,
          label: 'Help & Support',
          subtitle: 'FAQs and contact support',
          onTap: () => context.push('/help'),
        ),
        _MenuItem(
          icon: Icons.privacy_tip_outlined,
          label: 'Privacy Policy',
          onTap: () => context.push('/privacy-policy'),
        ),
        _MenuItem(
          icon: Icons.description_outlined,
          label: 'Terms of Service',
          onTap: () => context.push('/terms-of-service'),
        ),
      ],
    );
  }

  Widget _buildMenuSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    String? badge,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: DCTheme.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: DCTheme.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildSignOutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await Supabase.instance.client.auth.signOut();
          if (context.mounted) {
            context.go('/login');
          }
        },
        icon: const Icon(Icons.logout, color: DCTheme.error),
        label: const Text('Sign Out', style: TextStyle(color: DCTheme.error)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: DCTheme.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'B';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;

  const _StatColumn({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: iconColor ?? DCTheme.text),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: DCTheme.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: DCTheme.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DCTheme.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: DCTheme.text, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style:
                            const TextStyle(color: DCTheme.text, fontSize: 15),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: DCTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing!
                else
                  const Icon(Icons.chevron_right, color: DCTheme.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
