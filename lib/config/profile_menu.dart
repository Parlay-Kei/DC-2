import 'package:flutter/material.dart';

class ProfileMenuItem {
  final String title;
  final IconData icon;
  final String route;
  final bool comingSoon;
  final Color? iconColor;
  final Color? textColor;

  const ProfileMenuItem({
    required this.title,
    required this.icon,
    required this.route,
    this.comingSoon = false,
    this.iconColor,
    this.textColor,
  });
}

class ProfileMenuSection {
  final String title;
  final List<ProfileMenuItem> items;

  const ProfileMenuSection({
    required this.title,
    required this.items,
  });
}

// Customer menu configuration
final List<ProfileMenuSection> customerMenuSections = [
  const ProfileMenuSection(
    title: 'Account',
    items: [
      ProfileMenuItem(
        title: 'Your Profile',
        icon: Icons.person_outline,
        route: '/settings/edit-profile',
      ),
      ProfileMenuItem(
        title: 'Change Password',
        icon: Icons.lock_outline,
        route: '/settings/change-password',
      ),
      ProfileMenuItem(
        title: 'Payment Methods',
        icon: Icons.credit_card_outlined,
        route: '/settings/payment-methods',
      ),
    ],
  ),
  const ProfileMenuSection(
    title: 'Activity',
    items: [
      ProfileMenuItem(
        title: 'Booking History',
        icon: Icons.history,
        route: '/settings/booking-history',
        comingSoon: true,
      ),
      ProfileMenuItem(
        title: 'Favorites',
        icon: Icons.favorite_outline,
        route: '/settings/favorites',
        comingSoon: true,
      ),
    ],
  ),
  const ProfileMenuSection(
    title: 'Notifications',
    items: [
      ProfileMenuItem(
        title: 'Notification Settings',
        icon: Icons.notifications_outlined,
        route: '/settings/notifications',
      ),
    ],
  ),
  const ProfileMenuSection(
    title: 'Support',
    items: [
      ProfileMenuItem(
        title: 'Help Center',
        icon: Icons.help_outline,
        route: '/help',
      ),
      ProfileMenuItem(
        title: 'Contact Support',
        icon: Icons.chat_bubble_outline,
        route: '/settings/contact-support',
        comingSoon: true,
      ),
      ProfileMenuItem(
        title: 'Terms of Service',
        icon: Icons.description_outlined,
        route: '/terms-of-service',
      ),
      ProfileMenuItem(
        title: 'Privacy Policy',
        icon: Icons.privacy_tip_outlined,
        route: '/privacy-policy',
      ),
      ProfileMenuItem(
        title: 'Build Info',
        icon: Icons.info_outline,
        route: '/settings/build-info',
      ),
    ],
  ),
];

// Barber menu configuration
final List<ProfileMenuSection> barberMenuSections = [
  const ProfileMenuSection(
    title: 'Account',
    items: [
      ProfileMenuItem(
        title: 'Your Profile',
        icon: Icons.person_outline,
        route: '/settings/edit-profile',
      ),
      ProfileMenuItem(
        title: 'Change Password',
        icon: Icons.lock_outline,
        route: '/settings/change-password',
      ),
    ],
  ),
  const ProfileMenuSection(
    title: 'Business',
    items: [
      ProfileMenuItem(
        title: 'Business Settings',
        icon: Icons.business,
        route: '/barber/business-settings',
      ),
      ProfileMenuItem(
        title: 'Location Settings',
        icon: Icons.location_on_outlined,
        route: '/barber/location-settings',
      ),
      ProfileMenuItem(
        title: 'Services & Pricing',
        icon: Icons.content_cut,
        route: '/barber/services',
      ),
      ProfileMenuItem(
        title: 'Availability',
        icon: Icons.calendar_today,
        route: '/barber/availability',
      ),
      ProfileMenuItem(
        title: 'Earnings',
        icon: Icons.attach_money,
        route: '/barber/earnings',
      ),
    ],
  ),
  const ProfileMenuSection(
    title: 'Notifications',
    items: [
      ProfileMenuItem(
        title: 'Notification Settings',
        icon: Icons.notifications_outlined,
        route: '/settings/notifications',
      ),
    ],
  ),
  const ProfileMenuSection(
    title: 'Support',
    items: [
      ProfileMenuItem(
        title: 'Help Center',
        icon: Icons.help_outline,
        route: '/help',
      ),
      ProfileMenuItem(
        title: 'Terms of Service',
        icon: Icons.description_outlined,
        route: '/terms-of-service',
      ),
      ProfileMenuItem(
        title: 'Privacy Policy',
        icon: Icons.privacy_tip_outlined,
        route: '/privacy-policy',
      ),
      ProfileMenuItem(
        title: 'Build Info',
        icon: Icons.info_outline,
        route: '/settings/build-info',
      ),
    ],
  ),
];
