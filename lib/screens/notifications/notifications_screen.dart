import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../services/notification_service.dart';

/// Provider for notifications
final notificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  return NotificationService.instance.getPendingNotifications();
});

/// Provider for unread count
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  return NotificationService.instance.getUnreadCount();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: DCTheme.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => _markAllAsRead(context, ref),
            child: const Text(
              'Mark all read',
              style: TextStyle(color: DCTheme.primary),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DCTheme.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: DCTheme.error),
              const SizedBox(height: 16),
              Text(
                'Error: $error',
                style: const TextStyle(color: DCTheme.textMuted),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(notificationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
            },
            color: DCTheme.primary,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationTile(
                  notification: notification,
                  onTap: () =>
                      _handleNotificationTap(context, ref, notification),
                  onDismiss: () => _dismissNotification(ref, notification.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: DCTheme.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Notifications',
              style: TextStyle(
                color: DCTheme.text,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You\'re all caught up! Check back later for updates.',
              style: TextStyle(color: DCTheme.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAllAsRead(BuildContext context, WidgetRef ref) async {
    final success = await NotificationService.instance.markAllAsRead();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'All notifications marked as read'
                : 'Failed to mark notifications',
          ),
          backgroundColor: success ? DCTheme.success : DCTheme.error,
        ),
      );

      if (success) {
        ref.invalidate(notificationsProvider);
        ref.invalidate(unreadNotificationCountProvider);
      }
    }
  }

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    // Mark as read
    NotificationService.instance.markAsRead(notification.id);
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);

    // Navigate based on type
    final data = notification.data;
    switch (notification.type) {
      case 'booking_confirmed':
      case 'booking_cancelled':
      case 'booking_reminder':
        // Navigate to booking details
        if (data?['booking_id'] != null) {
          // context.push('/booking/${data!['booking_id']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Booking: ${data!['booking_id']}')),
          );
        }
        break;
      case 'new_message':
        // Navigate to chat
        if (data?['conversation_id'] != null) {
          // context.push('/chat/${data!['conversation_id']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chat: ${data!['conversation_id']}')),
          );
        }
        break;
      case 'new_review':
        // Navigate to reviews
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('View review')),
        );
        break;
    }
  }

  Future<void> _dismissNotification(
      WidgetRef ref, String notificationId) async {
    await NotificationService.instance.markAsRead(notificationId);
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: DCTheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.transparent
              : DCTheme.primary.withValues(alpha: 0.05),
          border: Border(
            bottom: BorderSide(color: DCTheme.border.withValues(alpha: 0.3)),
          ),
        ),
        child: ListTile(
          onTap: onTap,
          leading: _buildIcon(),
          title: Text(
            notification.title,
            style: TextStyle(
              color: DCTheme.text,
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.body,
                style: const TextStyle(color: DCTheme.textMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                notification.timeAgo,
                style: TextStyle(
                  color: notification.isRead
                      ? DCTheme.textMuted.withValues(alpha: 0.7)
                      : DCTheme.primary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: notification.isRead
              ? null
              : Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: DCTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (notification.type) {
      case 'booking_confirmed':
        icon = Icons.check_circle_outline;
        color = DCTheme.success;
        break;
      case 'booking_cancelled':
        icon = Icons.cancel_outlined;
        color = DCTheme.error;
        break;
      case 'booking_reminder':
        icon = Icons.access_time;
        color = DCTheme.warning;
        break;
      case 'new_message':
        icon = Icons.chat_bubble_outline;
        color = DCTheme.primary;
        break;
      case 'new_review':
        icon = Icons.star_outline;
        color = Colors.amber;
        break;
      default:
        icon = Icons.notifications_outlined;
        color = DCTheme.textMuted;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
