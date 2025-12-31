import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _smsEnabled = false;
  bool _bookingReminders = true;
  bool _promotions = false;
  bool _messages = true;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    final profileAsync = ref.read(currentProfileProvider);
    profileAsync.whenData((profile) {
      if (profile != null && !_isInitialized) {
        final prefs = profile.notificationPreferences;
        setState(() {
          _pushEnabled = prefs.pushEnabled;
          _emailEnabled = prefs.emailEnabled;
          _bookingReminders = prefs.bookingReminders;
          _promotions = prefs.promotions;
          _messages = prefs.chatMessages;
          _isInitialized = true;
        });
      }
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final notifier = ref.read(profileStateProvider.notifier);

    final success = await notifier.updateNotificationPreferences(
      pushEnabled: key == 'push_enabled' ? value : null,
      emailEnabled: key == 'email_enabled' ? value : null,
      smsEnabled: key == 'sms_enabled' ? value : null,
      bookingReminders: key == 'booking_reminders' ? value : null,
      promotions: key == 'promotions' ? value : null,
      messages: key == 'messages' ? value : null,
    );

    if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update preference'),
          backgroundColor: DCTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileStateProvider);

    return Scaffold(
      backgroundColor: DCTheme.background,
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        children: [
          // Delivery methods section
          _buildSectionHeader('Delivery Methods'),
          _buildSwitchTile(
            title: 'Push Notifications',
            subtitle: 'Receive notifications on your device',
            icon: Icons.notifications_outlined,
            value: _pushEnabled,
            onChanged: (value) {
              setState(() => _pushEnabled = value);
              _savePreference('push_enabled', value);
            },
            isLoading: state.isLoading,
          ),
          _buildSwitchTile(
            title: 'Email Notifications',
            subtitle: 'Receive updates via email',
            icon: Icons.email_outlined,
            value: _emailEnabled,
            onChanged: (value) {
              setState(() => _emailEnabled = value);
              _savePreference('email_enabled', value);
            },
            isLoading: state.isLoading,
          ),
          _buildSwitchTile(
            title: 'SMS Notifications',
            subtitle: 'Receive text messages',
            icon: Icons.sms_outlined,
            value: _smsEnabled,
            onChanged: (value) {
              setState(() => _smsEnabled = value);
              _savePreference('sms_enabled', value);
            },
            isLoading: state.isLoading,
          ),
          const Divider(color: DCTheme.border, height: 32),

          // Notification types section
          _buildSectionHeader('Notification Types'),
          _buildSwitchTile(
            title: 'Booking Reminders',
            subtitle: 'Get reminded about upcoming appointments',
            icon: Icons.calendar_today_outlined,
            value: _bookingReminders,
            onChanged: (value) {
              setState(() => _bookingReminders = value);
              _savePreference('booking_reminders', value);
            },
            isLoading: state.isLoading,
          ),
          _buildSwitchTile(
            title: 'Messages',
            subtitle: 'New message notifications',
            icon: Icons.chat_bubble_outline,
            value: _messages,
            onChanged: (value) {
              setState(() => _messages = value);
              _savePreference('messages', value);
            },
            isLoading: state.isLoading,
          ),
          _buildSwitchTile(
            title: 'Promotions & Offers',
            subtitle: 'Deals and special offers from barbers',
            icon: Icons.local_offer_outlined,
            value: _promotions,
            onChanged: (value) {
              setState(() => _promotions = value);
              _savePreference('promotions', value);
            },
            isLoading: state.isLoading,
          ),
          const SizedBox(height: 32),

          // Info text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'You can change these settings at any time. Some notifications, like booking confirmations, cannot be disabled.',
              style: TextStyle(
                color: DCTheme.textMuted.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isLoading,
  }) {
    return ListTile(
      leading: Icon(icon, color: DCTheme.textMuted),
      title: Text(title, style: const TextStyle(color: DCTheme.text)),
      subtitle:
          Text(subtitle, style: const TextStyle(color: DCTheme.textMuted)),
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: DCTheme.primary,
              ),
            )
          : Switch(
              value: value,
              onChanged: onChanged,
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return DCTheme.primary;
                }
                return null;
              }),
            ),
    );
  }
}
