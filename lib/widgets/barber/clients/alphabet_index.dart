import 'package:flutter/material.dart';

import '../../../config/theme.dart';

/// Vertical A-Z alphabet index for quick scrolling
/// Inspired by theCut's client list quick scroll
class AlphabetIndex extends StatefulWidget {
  final ValueChanged<String> onLetterSelected;
  final Set<String> availableLetters;

  const AlphabetIndex({
    super.key,
    required this.onLetterSelected,
    this.availableLetters = const {},
  });

  @override
  State<AlphabetIndex> createState() => _AlphabetIndexState();
}

class _AlphabetIndexState extends State<AlphabetIndex> {
  String? _selectedLetter;
  bool _isDragging = false;

  static const _letters = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    '#',
  ];

  void _handleDrag(Offset globalPosition, BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(globalPosition);
    final letterHeight = box.size.height / _letters.length;
    final index =
        (localPosition.dy / letterHeight).floor().clamp(0, _letters.length - 1);
    final letter = _letters[index];

    if (letter != _selectedLetter) {
      setState(() => _selectedLetter = letter);
      widget.onLetterSelected(letter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: (details) {
        setState(() => _isDragging = true);
        _handleDrag(details.globalPosition, context);
      },
      onVerticalDragUpdate: (details) {
        _handleDrag(details.globalPosition, context);
      },
      onVerticalDragEnd: (_) {
        setState(() {
          _isDragging = false;
          _selectedLetter = null;
        });
      },
      child: Container(
        width: 24,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: _isDragging
              ? DCTheme.surface.withValues(alpha: 0.9)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _letters.map((letter) {
            final isAvailable = widget.availableLetters.isEmpty ||
                widget.availableLetters.contains(letter);
            final isSelected = _selectedLetter == letter;

            return Container(
              width: 20,
              height: 16,
              decoration: BoxDecoration(
                color: isSelected ? DCTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : isAvailable
                            ? DCTheme.textMuted
                            : DCTheme.textMuted.withValues(alpha: 0.3),
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Client list with alphabetical grouping and quick scroll index
class ClientListWithIndex extends StatefulWidget {
  final List<ClientData> clients;
  final Function(ClientData)? onClientTap;
  final Function(ClientData)? onMessage;
  final Function(ClientData)? onBook;
  final VoidCallback? onBroadcast;
  final VoidCallback? onAddClient;

  const ClientListWithIndex({
    super.key,
    required this.clients,
    this.onClientTap,
    this.onMessage,
    this.onBook,
    this.onBroadcast,
    this.onAddClient,
  });

  @override
  State<ClientListWithIndex> createState() => _ClientListWithIndexState();
}

class _ClientListWithIndexState extends State<ClientListWithIndex> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, double> _sectionOffsets = {};
  List<ClientData> _filteredClients = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredClients = widget.clients;
    _calculateSectionOffsets();
  }

  @override
  void didUpdateWidget(ClientListWithIndex oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clients != widget.clients) {
      _filterClients();
      _calculateSectionOffsets();
    }
  }

  void _calculateSectionOffsets() {
    _sectionOffsets.clear();
    double offset = 120; // Header height
    String? currentLetter;

    for (final client in _filteredClients) {
      final letter =
          client.name.isNotEmpty ? client.name[0].toUpperCase() : '#';

      if (letter != currentLetter) {
        _sectionOffsets[letter] = offset;
        currentLetter = letter;
        offset += 40; // Section header height
      }
      offset += 72; // Row height
    }
  }

  void _filterClients() {
    if (_searchQuery.isEmpty) {
      _filteredClients = widget.clients;
    } else {
      _filteredClients = widget.clients
          .where(
              (c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    _calculateSectionOffsets();
  }

  void _scrollToLetter(String letter) {
    final offset = _sectionOffsets[letter];
    if (offset != null) {
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group clients by first letter
    final grouped = <String, List<ClientData>>{};
    for (final client in _filteredClients) {
      final letter =
          client.name.isNotEmpty ? client.name[0].toUpperCase() : '#';
      grouped.putIfAbsent(letter, () => []).add(client);
    }
    final sortedKeys = grouped.keys.toList()..sort();

    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: _ClientListHeader(
                clientCount: widget.clients.length,
                onBroadcast: widget.onBroadcast,
                onAddClient: widget.onAddClient,
                searchController: _searchController,
                onSearch: (query) {
                  setState(() {
                    _searchQuery = query;
                    _filterClients();
                  });
                },
              ),
            ),
            ...sortedKeys.expand((letter) {
              final clients = grouped[letter]!;
              return [
                SliverToBoxAdapter(
                  child: _ClientSectionHeader(letter: letter),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final client = clients[index];
                      return _ClientRow(
                        client: client,
                        onTap: widget.onClientTap != null
                            ? () => widget.onClientTap!(client)
                            : null,
                        onMessage: widget.onMessage != null
                            ? () => widget.onMessage!(client)
                            : null,
                        onBook: widget.onBook != null
                            ? () => widget.onBook!(client)
                            : null,
                      );
                    },
                    childCount: clients.length,
                  ),
                ),
              ];
            }),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
        Positioned(
          right: 4,
          top: 120,
          bottom: 100,
          child: AlphabetIndex(
            onLetterSelected: _scrollToLetter,
            availableLetters: sortedKeys.toSet(),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

class _ClientListHeader extends StatelessWidget {
  final int clientCount;
  final VoidCallback? onBroadcast;
  final VoidCallback? onAddClient;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  const _ClientListHeader({
    required this.clientCount,
    this.onBroadcast,
    this.onAddClient,
    required this.searchController,
    required this.onSearch,
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
                _ActionButton(
                  icon: Icons.campaign_outlined,
                  onTap: onBroadcast!,
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
                _ActionButton(
                  icon: Icons.person_add_outlined,
                  onTap: onAddClient!,
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
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: DCTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: DCTheme.border),
        ),
        child: Icon(icon, color: DCTheme.text, size: 20),
      ),
    );
  }
}

class _ClientSectionHeader extends StatelessWidget {
  final String letter;

  const _ClientSectionHeader({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: DCTheme.background,
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

class _ClientRow extends StatelessWidget {
  final ClientData client;
  final VoidCallback? onTap;
  final VoidCallback? onMessage;
  final VoidCallback? onBook;

  const _ClientRow({
    required this.client,
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
            backgroundImage: client.avatarUrl != null
                ? NetworkImage(client.avatarUrl!)
                : null,
            child: client.avatarUrl == null
                ? Text(
                    client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: DCTheme.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          if (client.isNew)
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
        ],
      ),
      title: Text(
        client.name,
        style: const TextStyle(
          color: DCTheme.text,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${client.visitCount} visits',
        style: const TextStyle(color: DCTheme.textMuted, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onMessage != null)
            IconButton(
              onPressed: onMessage,
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              color: DCTheme.textMuted,
              constraints: const BoxConstraints(minWidth: 36),
            ),
          if (onBook != null)
            IconButton(
              onPressed: onBook,
              icon: const Icon(Icons.calendar_today_outlined, size: 20),
              color: DCTheme.primary,
              constraints: const BoxConstraints(minWidth: 36),
            ),
        ],
      ),
    );
  }
}

/// Data model for client list
class ClientData {
  final String id;
  final String name;
  final String? avatarUrl;
  final int visitCount;
  final DateTime? lastVisit;
  final double? lifetimeSpend;
  final String? loyaltyTier;
  final bool isNew;
  final bool isAtRisk;

  const ClientData({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.visitCount,
    this.lastVisit,
    this.lifetimeSpend,
    this.loyaltyTier,
    this.isNew = false,
    this.isAtRisk = false,
  });
}
