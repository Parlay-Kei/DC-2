import 'package:flutter/material.dart';

import '../../../config/theme.dart';

/// Profile header with avatar, name, and edit button
/// Inspired by theCut's profile tab header
class ProfileHeader extends StatelessWidget {
  final String name;
  final String? role;
  final String? avatarUrl;
  final VoidCallback? onEditProfile;
  final VoidCallback? onQRCode;
  final VoidCallback? onSettings;

  const ProfileHeader({
    super.key,
    required this.name,
    this.role,
    this.avatarUrl,
    this.onEditProfile,
    this.onQRCode,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (onSettings != null)
                IconButton(
                  onPressed: onSettings,
                  icon: const Icon(Icons.settings_outlined, color: DCTheme.text),
                )
              else
                const SizedBox(width: 48),
              Column(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: DCTheme.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (role != null)
                    Text(
                      role!,
                      style: const TextStyle(
                        color: DCTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
              if (onQRCode != null)
                IconButton(
                  onPressed: onQRCode,
                  icon: const Icon(Icons.qr_code, color: DCTheme.text),
                )
              else
                const SizedBox(width: 48),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onEditProfile,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: DCTheme.surfaceSecondary,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: DCTheme.text,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: DCTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: DCTheme.background, width: 2),
                  ),
                  child: const Icon(Icons.edit, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (onEditProfile != null)
          TextButton(
            onPressed: onEditProfile,
            child: const Text(
              'EDIT BARBER PROFILE',
              style: TextStyle(
                color: DCTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }
}

/// Subscription status card showing plan and renewal date
class SubscriptionCard extends StatelessWidget {
  final String planName;
  final DateTime? renewalDate;
  final bool isActive;
  final VoidCallback? onTap;

  const SubscriptionCard({
    super.key,
    required this.planName,
    this.renewalDate,
    this.isActive = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DCTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DCTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DCTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: DCTheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subscription',
                    style: TextStyle(
                      color: DCTheme.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (renewalDate != null)
                    Text(
                      'Renews on ${_formatDate(renewalDate!)}',
                      style: const TextStyle(
                        color: DCTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              planName,
              style: const TextStyle(
                color: DCTheme.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? DCTheme.success : DCTheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day} ${date.year}';
  }
}

/// Settings section container with title
class SettingsSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DCTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                title!,
                style: const TextStyle(
                  color: DCTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}

/// Individual settings row with icon, label, value, and optional toggle
class SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String? value;
  final String? subtitle;
  final bool? toggleValue;
  final ValueChanged<bool>? onToggleChanged;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool isDestructive;

  const SettingsRow({
    super.key,
    required this.icon,
    this.iconColor,
    required this.label,
    this.value,
    this.subtitle,
    this.toggleValue,
    this.onToggleChanged,
    this.onTap,
    this.showChevron = true,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? DCTheme.error : iconColor ?? DCTheme.primary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isDestructive ? DCTheme.error : DCTheme.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: DCTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (toggleValue != null)
              Switch(
                value: toggleValue!,
                onChanged: onToggleChanged,
                activeThumbColor: DCTheme.primary,
              )
            else if (value != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value!,
                    style: TextStyle(
                      color: value!.startsWith('\$')
                          ? DCTheme.success
                          : DCTheme.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (showChevron) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: DCTheme.success,
                      ),
                    ),
                  ],
                ],
              )
            else if (showChevron)
              const Icon(
                Icons.chevron_right,
                color: DCTheme.textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

/// Complete barber profile hub page
/// Inspired by theCut's profile/settings tab
class BarberProfileHub extends StatelessWidget {
  final String name;
  final String? role;
  final String? avatarUrl;
  final String subscriptionPlan;
  final DateTime? subscriptionRenewal;
  final bool bookingsEnabled;
  final int newClients;
  final double paymentBalance;
  final VoidCallback? onEditProfile;
  final VoidCallback? onSettings;
  final VoidCallback? onQRCode;
  final VoidCallback? onSubscription;
  final VoidCallback? onBookings;
  final VoidCallback? onGrowth;
  final VoidCallback? onPayments;
  final VoidCallback? onReferBarber;
  final VoidCallback? onInviteClients;
  final VoidCallback? onClientReferral;
  final VoidCallback? onLoyaltyProgram;
  final VoidCallback? onHelp;
  final VoidCallback? onLogout;
  final ValueChanged<bool>? onBookingsToggle;

  const BarberProfileHub({
    super.key,
    required this.name,
    this.role = 'Barber',
    this.avatarUrl,
    this.subscriptionPlan = 'Free',
    this.subscriptionRenewal,
    this.bookingsEnabled = true,
    this.newClients = 0,
    this.paymentBalance = 0,
    this.onEditProfile,
    this.onSettings,
    this.onQRCode,
    this.onSubscription,
    this.onBookings,
    this.onGrowth,
    this.onPayments,
    this.onReferBarber,
    this.onInviteClients,
    this.onClientReferral,
    this.onLoyaltyProgram,
    this.onHelp,
    this.onLogout,
    this.onBookingsToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ProfileHeader(
            name: name,
            role: role,
            avatarUrl: avatarUrl,
            onEditProfile: onEditProfile,
            onQRCode: onQRCode,
            onSettings: onSettings,
          ),
          const SizedBox(height: 16),
          SubscriptionCard(
            planName: subscriptionPlan,
            renewalDate: subscriptionRenewal,
            onTap: onSubscription,
          ),
          SettingsSection(
            children: [
              SettingsRow(
                icon: Icons.calendar_month,
                iconColor: Colors.blue,
                label: 'Bookings',
                subtitle: 'Configure your booking preferences',
                value: bookingsEnabled ? 'On' : 'Off',
                onTap: onBookings,
              ),
              const Divider(height: 1, indent: 60),
              SettingsRow(
                icon: Icons.trending_up,
                iconColor: Colors.purple,
                label: 'Growth',
                subtitle: '$newClients new client(s)',
                value: 'On',
                onTap: onGrowth,
              ),
              const Divider(height: 1, indent: 60),
              SettingsRow(
                icon: Icons.account_balance_wallet,
                iconColor: Colors.green,
                label: 'Payments',
                value: '\$${paymentBalance.toStringAsFixed(0)}',
                onTap: onPayments,
              ),
            ],
          ),
          SettingsSection(
            title: 'GROWTH TOOLS',
            children: [
              SettingsRow(
                icon: Icons.person_add_alt_1,
                label: 'Refer a Barber',
                onTap: onReferBarber,
              ),
              const Divider(height: 1, indent: 60),
              SettingsRow(
                icon: Icons.group_add,
                label: 'Invite Your Clients',
                onTap: onInviteClients,
              ),
              const Divider(height: 1, indent: 60),
              SettingsRow(
                icon: Icons.card_giftcard,
                label: 'Client Referral Program',
                onTap: onClientReferral,
              ),
              const Divider(height: 1, indent: 60),
              SettingsRow(
                icon: Icons.loyalty,
                label: 'Client Loyalty Program',
                onTap: onLoyaltyProgram,
              ),
            ],
          ),
          SettingsSection(
            children: [
              SettingsRow(
                icon: Icons.help_outline,
                iconColor: Colors.blue,
                label: 'Help & Resources',
                onTap: onHelp,
              ),
              const Divider(height: 1, indent: 60),
              SettingsRow(
                icon: Icons.logout,
                label: 'Log Out',
                isDestructive: true,
                showChevron: false,
                onTap: onLogout,
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
