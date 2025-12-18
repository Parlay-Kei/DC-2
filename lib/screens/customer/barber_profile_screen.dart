import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/barber.dart';
import '../../models/service.dart';
import '../../models/review.dart';
import '../../providers/barber_provider.dart';
import '../../providers/data_providers.dart';
import '../../providers/booking_provider.dart';
import '../../providers/message_provider.dart';

class BarberProfileScreen extends ConsumerStatefulWidget {
  final String barberId;

  const BarberProfileScreen({super.key, required this.barberId});

  @override
  ConsumerState<BarberProfileScreen> createState() => _BarberProfileScreenState();
}

class _BarberProfileScreenState extends ConsumerState<BarberProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barberAsync = ref.watch(barberProvider(widget.barberId));

    return barberAsync.when(
      data: (barber) {
        if (barber == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Barber not found')),
          );
        }
        return _buildProfile(barber);
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator(color: DCTheme.primary)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildProfile(Barber barber) {
    return Scaffold(
      backgroundColor: DCTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(barber),
          SliverToBoxAdapter(child: _buildProfileHeader(barber)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: DCTheme.primary,
                unselectedLabelColor: DCTheme.textMuted,
                indicatorColor: DCTheme.primary,
                tabs: const [
                  Tab(text: 'Services'),
                  Tab(text: 'Portfolio'),
                  Tab(text: 'Reviews'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _ServicesTab(barberId: widget.barberId),
            _PortfolioTab(barberId: widget.barberId),
            _ReviewsTab(barberId: widget.barberId),
          ],
        ),
      ),
      bottomNavigationBar: _buildBookButton(barber),
    );
  }

  Widget _buildSliverAppBar(Barber barber) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: barber.profileImageUrl != null
            ? Image.network(
                barber.profileImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultBg(),
              )
            : _buildDefaultBg(),
      ),
      actions: [
        _FavoriteButton(barberId: widget.barberId),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDefaultBg() {
    return Container(
      color: DCTheme.surfaceSecondary,
      child: const Center(
        child: Icon(Icons.content_cut, size: 64, color: DCTheme.textMuted),
      ),
    );
  }

  Widget _buildProfileHeader(Barber barber) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  barber.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: DCTheme.text,
                  ),
                ),
              ),
              if (barber.isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DCTheme.info.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: DCTheme.info, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(color: DCTheme.info, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatChip(
                Icons.star,
                Colors.amber,
                '${barber.rating.toStringAsFixed(1)} (${barber.totalReviews})',
              ),
              const SizedBox(width: 12),
              if (barber.isMobile)
                _buildStatChip(Icons.directions_car, DCTheme.info, 'Mobile'),
              if (barber.hasLocation) ...[
                const SizedBox(width: 12),
                _buildStatChip(
                  Icons.location_on,
                  DCTheme.textMuted,
                  '${barber.serviceRadiusMiles} mi radius',
                ),
              ],
            ],
          ),
          if (barber.bio != null && barber.bio!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              barber.bio!,
              style: const TextStyle(color: DCTheme.textMuted, height: 1.5),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MessageButton(
                  barberId: widget.barberId,
                  barberName: barber.displayName,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: barber.phone != null
                      ? () {
                          // Launch phone
                        }
                      : null,
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  label: const Text('Call'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: DCTheme.text, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton(Barber barber) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () {
            ref.read(selectedBarberProvider.notifier).state = barber;
            context.push('/book/${barber.id}');
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Book Appointment',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _MessageButton extends ConsumerStatefulWidget {
  final String barberId;
  final String barberName;

  const _MessageButton({
    required this.barberId,
    required this.barberName,
  });

  @override
  ConsumerState<_MessageButton> createState() => _MessageButtonState();
}

class _MessageButtonState extends ConsumerState<_MessageButton> {
  bool _isLoading = false;

  Future<void> _startChat() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final service = ref.read(messageServiceProvider);
      final conversation = await service.getOrCreateConversation(widget.barberId);
      
      if (conversation != null && mounted) {
        context.push('/chat/${conversation.id}', extra: widget.barberName);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to start conversation'),
            backgroundColor: DCTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: DCTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _startChat,
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chat_bubble_outline, size: 18),
      label: const Text('Message'),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  final String barberId;

  const _FavoriteButton({required this.barberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavAsync = ref.watch(isFavoriteProvider(barberId));

    return isFavAsync.when(
      data: (isFav) => IconButton(
        icon: Icon(
          isFav ? Icons.favorite : Icons.favorite_border,
          color: isFav ? DCTheme.primary : null,
        ),
        onPressed: () async {
          final service = ref.read(favoritesServiceProvider);
          await service.toggleFavorite(barberId);
          ref.invalidate(isFavoriteProvider(barberId));
          ref.invalidate(favoriteBarbersProvider);
        },
      ),
      loading: () => const IconButton(
        icon: Icon(Icons.favorite_border),
        onPressed: null,
      ),
      error: (_, __) => const IconButton(
        icon: Icon(Icons.favorite_border),
        onPressed: null,
      ),
    );
  }
}

class _ServicesTab extends ConsumerWidget {
  final String barberId;

  const _ServicesTab({required this.barberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider(barberId));

    return servicesAsync.when(
      data: (services) {
        if (services.isEmpty) {
          return const Center(
            child: Text('No services available', style: TextStyle(color: DCTheme.textMuted)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: services.length,
          itemBuilder: (context, index) => _ServiceTile(
            service: services[index],
            onTap: () {
              ref.read(bookingFlowProvider.notifier).selectService(services[index]);
              context.push('/book/$barberId');
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: DCTheme.primary)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final Service service;
  final VoidCallback onTap;

  const _ServiceTile({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          service.name,
          style: const TextStyle(fontWeight: FontWeight.w600, color: DCTheme.text),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (service.description != null) ...[
              const SizedBox(height: 4),
              Text(
                service.description!,
                style: const TextStyle(color: DCTheme.textMuted, fontSize: 13),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              service.formattedDuration,
              style: const TextStyle(color: DCTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              service.formattedPrice,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: DCTheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            const Icon(Icons.chevron_right, color: DCTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

class _PortfolioTab extends ConsumerWidget {
  final String barberId;

  const _PortfolioTab({required this.barberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(barberPortfolioProvider(barberId));

    return portfolioAsync.when(
      data: (images) {
        if (images.isEmpty) {
          return const Center(
            child: Text('No portfolio images', style: TextStyle(color: DCTheme.textMuted)),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) => ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              images[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: DCTheme.surfaceSecondary,
                child: const Icon(Icons.broken_image, color: DCTheme.textMuted),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: DCTheme.primary)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _ReviewsTab extends ConsumerWidget {
  final String barberId;

  const _ReviewsTab({required this.barberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(reviewsProvider(barberId));
    final statsAsync = ref.watch(ratingStatsProvider(barberId));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: statsAsync.when(
            data: (stats) => _RatingStats(stats: stats),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
        reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return const SliverFillRemaining(
                child: Center(
                  child: Text('No reviews yet', style: TextStyle(color: DCTheme.textMuted)),
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ReviewTile(review: reviews[index]),
                childCount: reviews.length,
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: DCTheme.primary)),
          ),
          error: (e, _) => SliverFillRemaining(
            child: Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}

class _RatingStats extends StatelessWidget {
  final dynamic stats;

  const _RatingStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                stats.average.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: DCTheme.text,
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < stats.average.round() ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '${stats.total} reviews',
                style: const TextStyle(color: DCTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((stars) {
                final percentage = stats.percentageFor(stars);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('$stars', style: const TextStyle(color: DCTheme.textMuted)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: DCTheme.surfaceSecondary,
                            valueColor: const AlwaysStoppedAnimation(Colors.amber),
                            minHeight: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: DCTheme.surfaceSecondary,
                backgroundImage: review.customerAvatar != null
                    ? NetworkImage(review.customerAvatar!)
                    : null,
                child: review.customerAvatar == null
                    ? Text(
                        review.customerName?.isNotEmpty == true
                            ? review.customerName![0].toUpperCase()
                            : 'U',
                        style: const TextStyle(color: DCTheme.text),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName ?? 'Anonymous',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: DCTheme.text,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          return Icon(
                            i < review.rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 14,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          review.timeAgo,
                          style: const TextStyle(
                            color: DCTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.hasComment) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: const TextStyle(color: DCTheme.text, height: 1.4),
            ),
          ],
          if (review.hasResponse) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DCTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Barber Response',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: DCTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.barberResponse!,
                    style: const TextStyle(color: DCTheme.text),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: DCTheme.background,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
