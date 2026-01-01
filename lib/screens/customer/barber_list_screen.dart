import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/barber.dart';
import '../../providers/auth_provider.dart';
import '../../providers/barber_provider.dart';

class BarberListScreen extends ConsumerStatefulWidget {
  const BarberListScreen({super.key});

  @override
  ConsumerState<BarberListScreen> createState() => _BarberListScreenState();
}

class _BarberListScreenState extends ConsumerState<BarberListScreen> {
  final _searchController = TextEditingController();
  int _lastQueryTimeMs = 0;
  int _lastBarberCount = 0;

  @override
  void initState() {
    super.initState();
    // Initialize location on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userLocationProvider.notifier).initIfNeeded();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DCTheme.background,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildBarberList()),
            ],
          ),
          if (kDebugMode) _buildDebugStrip(),
        ],
      ),
    );
  }

  Widget _buildDebugStrip() {
    final isAuthed = ref.watch(currentUserProvider) != null;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 120,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DCTheme.primary, width: 1),
          ),
          child: Text(
            'DEBUG: barbers=$_lastBarberCount | queryTime=${_lastQueryTimeMs}ms | auth=$isAuthed',
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: DCTheme.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              // Title row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Find a Barber',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: DCTheme.text,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.navigation, color: DCTheme.text),
                    onPressed: () async {
                      await ref
                          .read(userLocationProvider.notifier)
                          .requestPermission();
                    },
                    tooltip: 'Get my location',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: DCTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: DCTheme.text),
                  decoration: InputDecoration(
                    hintText: 'Search barbers...',
                    hintStyle: const TextStyle(color: DCTheme.textMuted),
                    prefixIcon:
                        const Icon(Icons.search, color: DCTheme.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: DCTheme.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchQueryProvider.notifier).state = '';
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).state = value;
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarberList() {
    final searchQuery = ref.watch(searchQueryProvider);
    final locationAsync = ref.watch(userLocationProvider);
    final nearbyAsync = ref.watch(nearbyBarbersProvider);

    // If searching, show search results
    if (searchQuery.isNotEmpty) {
      final searchResults = ref.watch(barberSearchProvider(searchQuery));
      return searchResults.when(
        data: (barbers) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _lastBarberCount = barbers.length;
              });
            }
          });
          return _buildBarberListView(barbers);
        },
        loading: () => _buildLoadingList(),
        error: (e, _) => _buildError(e.toString()),
      );
    }

    // Otherwise show nearby barbers
    return locationAsync.when(
      data: (position) {
        if (position == null) {
          return _buildLocationPermissionPrompt();
        }
        return nearbyAsync.when(
          data: (barbers) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _lastBarberCount = barbers.length;
                });
              }
            });
            return _buildBarberListView(
              barbers.map((b) => b.barber).toList(),
              distances: {
                for (var b in barbers) b.barber.id: b.formattedDistance
              },
            );
          },
          loading: () => _buildLoadingList(),
          error: (e, _) => _buildError(e.toString()),
        );
      },
      loading: () => _buildLoadingList(),
      error: (e, _) => _buildLocationPermissionPrompt(),
    );
  }

  Widget _buildBarberListView(
    List<Barber> barbers, {
    Map<String, String>? distances,
  }) {
    if (barbers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: DCTheme.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No barbers found',
              style: TextStyle(color: DCTheme.textMuted, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your search or location',
              style: TextStyle(color: DCTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: DCTheme.primary,
      onRefresh: () async {
        ref.invalidate(activeBarbersProvider);
        ref.invalidate(nearbyBarbersProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: barbers.length,
        itemBuilder: (context, index) {
          final barber = barbers[index];
          return _BarberListTile(
            barber: barber,
            distance: distances?[barber.id],
            onTap: () => context.push('/barber/${barber.id}'),
          );
        },
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: 5,
      itemBuilder: (_, __) => const _BarberListTileSkeleton(),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: DCTheme.error),
          const SizedBox(height: 16),
          const Text(
            'Error loading barbers',
            style: TextStyle(color: DCTheme.textMuted),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(activeBarbersProvider);
              ref.invalidate(nearbyBarbersProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DCTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPermissionPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: DCTheme.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Enable Location',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: DCTheme.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Allow location access to find barbers near you',
              textAlign: TextAlign.center,
              style: TextStyle(color: DCTheme.textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await ref
                    .read(userLocationProvider.notifier)
                    .requestPermission();
              },
              icon: const Icon(Icons.location_on),
              label: const Text('Enable Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DCTheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarberListTile extends StatelessWidget {
  final Barber barber;
  final String? distance;
  final VoidCallback onTap;

  const _BarberListTile({
    required this.barber,
    this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: 16),
                Expanded(child: _buildInfo()),
                const Icon(Icons.chevron_right, color: DCTheme.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: DCTheme.primary, width: 2),
      ),
      child: ClipOval(
        child: barber.profileImageUrl != null
            ? Image.network(
                barber.profileImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarFallback(),
              )
            : _avatarFallback(),
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: DCTheme.surfaceSecondary,
      child: Center(
        child: Text(
          barber.displayName.isNotEmpty
              ? barber.displayName[0].toUpperCase()
              : 'B',
          style: const TextStyle(
            color: DCTheme.text,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                barber.displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DCTheme.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (barber.isVerified)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.verified, color: DCTheme.info, size: 18),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(
              barber.rating.toStringAsFixed(1),
              style: const TextStyle(
                color: DCTheme.text,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              ' (${barber.totalReviews})',
              style: const TextStyle(color: DCTheme.textMuted, fontSize: 13),
            ),
            if (distance != null) ...[
              const SizedBox(width: 12),
              const Icon(Icons.location_on, color: DCTheme.textMuted, size: 14),
              const SizedBox(width: 2),
              Text(
                distance!,
                style: const TextStyle(color: DCTheme.textMuted, fontSize: 13),
              ),
            ],
          ],
        ),
        if (barber.bio != null && barber.bio!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            barber.bio!,
            style: const TextStyle(color: DCTheme.textMuted, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (barber.isMobile || barber.tier == 'professional') ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (barber.isMobile)
                _buildTag('Mobile', Icons.directions_car, DCTheme.info),
              if (barber.tier == 'professional')
                _buildTag('Pro', Icons.workspace_premium, DCTheme.gold),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTag(String label, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _BarberListTileSkeleton extends StatelessWidget {
  const _BarberListTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: DCTheme.surfaceSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: DCTheme.surfaceSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: DCTheme.surfaceSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 160,
                  height: 12,
                  decoration: BoxDecoration(
                    color: DCTheme.surfaceSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
