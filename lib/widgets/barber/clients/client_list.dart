import 'package:flutter/material.dart';

import '../../../config/theme.dart';

/// Header for client list showing count and action buttons
/// Inspired by theCut's client management header
class ClientListHeader extends StatelessWidget {
  final int clientCount;
  final VoidCallback? onBroadcast;
  final VoidCallback? onAddClient;
  final ValueChanged<String>? onSearch;
  final TextEditingController? searchController;

  const ClientListHeader({
    super.key,
    required this.clientCount,
    this.onBroadcast,
    this.onAddClient,
    this.onSearch,
    this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              if (onBroadcast != null)
                IconButton(
                  onPressed: onBroadcast,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DCTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: DCTheme.border),
                    ),
                    child: const Icon(
                      Icons.campaign_outlined,
                      color: DCTheme.text,
                      size: 20,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                '$clientCount CLIENTS',
                style: const TextStyle(
                  color: DCTheme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              if (onAddClient != null)
                IconButton(
                  onPressed: onAddClient,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DCTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: DCTheme.border),
                    ),
                    child: const Icon(
                      Icons.person_add_outlined,
                      color: DCTheme.text,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: searchController,
            onChanged: onSearch,
            style: const TextStyle(color: DCTheme.text),
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: const TextStyle(color: DCTheme.textMuted),
              prefixIcon: const Icon(Icons.search, color: DCTheme.textMuted),
              filled: true,
              fillColor: DCTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: DCTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: DCTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: DCTheme.primary),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Individual client row in the list
class ClientRow extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final int visitCount;
  final DateTime? lastVisit;
  final double? lifetimeSpend;
  final String? loyaltyTier;
  final bool isNew;
  final bool isAtRisk;
  final VoidCallback? onTap;
  final VoidCallback? onMessage;
  final VoidCallback? onBook;

  const ClientRow({
    super.key,
    required this.name,
    this.avatarUrl,
    required this.visitCount,
    this.lastVisit,
    this.lifetimeSpend,
    this.loyaltyTier,
    this.isNew = false,
    this.isAtRisk = false,
    this.onTap,
    this.onMessage,
    this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: DCTheme.surfaceSecondary,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: DCTheme.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          if (isNew)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: DCTheme.success,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (isAtRisk && !isNew)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: DCTheme.background, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: DCTheme.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (loyaltyTier != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: DCTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                loyaltyTier!,
                style: const TextStyle(
                  color: DCTheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Row(
        children: [
          Text(
            '$visitCount visits',
            style: const TextStyle(
              color: DCTheme.textMuted,
              fontSize: 12,
            ),
          ),
          if (lifetimeSpend != null) ...[
            const Text(' • ', style: TextStyle(color: DCTheme.textMuted)),
            Text(
              '\$${lifetimeSpend!.toStringAsFixed(0)} total',
              style: const TextStyle(
                color: DCTheme.success,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onMessage != null)
            IconButton(
              onPressed: onMessage,
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              color: DCTheme.textMuted,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          if (onBook != null)
            IconButton(
              onPressed: onBook,
              icon: const Icon(Icons.calendar_today_outlined, size: 20),
              color: DCTheme.primary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
        ],
      ),
    );
  }
}

/// Section header for alphabetical grouping
class ClientSectionHeader extends StatelessWidget {
  final String letter;

  const ClientSectionHeader({super.key, required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        letter,
        style: const TextStyle(
          color: DCTheme.text,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
