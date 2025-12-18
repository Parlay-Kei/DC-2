import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../providers/barber_dashboard_provider.dart';

class ClientsTab extends ConsumerWidget {
  const ClientsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(barberClientsProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Clients',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: DCTheme.text,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Your customer base',
              style: TextStyle(color: DCTheme.textMuted),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: clientsAsync.when(
              data: (clients) {
                if (clients.isEmpty) {
                  return _buildEmptyState();
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(barberClientsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: clients.length,
                    itemBuilder: (context, index) => _ClientCard(client: clients[index]),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: DCTheme.primary),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: DCTheme.error, size: 48),
                    const SizedBox(height: 16),
                    const Text('Error loading clients', style: TextStyle(color: DCTheme.textMuted)),
                    TextButton(
                      onPressed: () => ref.invalidate(barberClientsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
              Icons.people_outline,
              size: 64,
              color: DCTheme.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No clients yet',
              style: TextStyle(
                color: DCTheme.textMuted,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your clients will appear here after their first appointment',
              style: TextStyle(color: DCTheme.textDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final ClientInfo client;

  const _ClientCard({required this.client});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: DCTheme.surfaceSecondary,
            backgroundImage: client.avatarUrl != null
                ? NetworkImage(client.avatarUrl!)
                : null,
            child: client.avatarUrl == null
                ? Text(
                    client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C',
                    style: const TextStyle(
                      color: DCTheme.text,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: DCTheme.text,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.history, size: 14, color: DCTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${client.visitCount} ${client.visitCount == 1 ? 'visit' : 'visits'}',
                      style: const TextStyle(color: DCTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (client.phone != null)
            IconButton(
              icon: const Icon(Icons.phone_outlined, color: DCTheme.primary),
              onPressed: () {
                // Launch phone dialer
              },
            ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: DCTheme.primary),
            onPressed: () {
              // Open chat
            },
          ),
        ],
      ),
    );
  }
}
