import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../config/theme.dart';
import '../../models/barber.dart';
import '../../providers/barber_provider.dart';
import '../../services/barber_service.dart';

class NearbyMapScreen extends ConsumerStatefulWidget {
  const NearbyMapScreen({super.key});

  @override
  ConsumerState<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends ConsumerState<NearbyMapScreen> {
  final _mapController = MapController();
  
  // Default to Las Vegas (matches web app)
  static const _lasVegas = LatLng(36.1699, -115.1398);
  LatLng _currentCenter = _lasVegas;
  double _currentZoom = 11.0;
  
  // Selected distance filter (in miles) - matches web app options
  int _selectedRadius = 25;
  final List<int> _radiusOptions = [10, 25, 50, 100];
  
  // Selected category filter - matches web app
  String _selectedCategory = 'Haircuts';
  final List<String> _categories = ['Haircuts', 'Fades', 'Beard Trims', 'Color'];
  
  // Search query for location
  String _locationText = 'Las Vegas, Nevada';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocation();
    });
  }

  Future<void> _initLocation() async {
    if (mounted) {
      _mapController.move(_lasVegas, _currentZoom);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DCTheme.background,
      body: Stack(
        children: [
          // Map fills entire screen
          Positioned.fill(
            child: _buildMap(),
          ),
          // Header overlay at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeader(),
          ),
          // Map controls (zoom buttons)
          _buildMapControls(),
          // Barber count badge
          _buildBarberCountBadge(),
          // Bottom barber cards carousel
          _buildBottomCarousel(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        // Matches web red-500 header
        color: Color(0xFFEF4444),
      ),
      child: Stack(
        children: [
          // Large Watermark Logo - matching web opacity-20
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.2,
                child: SvgPicture.asset(
                  'assets/images/dc_logo.svg',
                  width: 180,
                  height: 180,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search bar - dark themed matching web (bg-white dark:bg-gray-800)
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937), // gray-800 dark mode
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    // Location icon inside pill (matching web)
                    Icon(
                      Icons.location_on_outlined,
                      color: Colors.grey[500], // gray-500 for dark mode
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    // Location text - white for dark mode
                    Expanded(
                      child: Text(
                        _locationText,
                        style: const TextStyle(
                          color: Colors.white, // white text on dark bg
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Search button - darker gray circle
                    _buildInlineButton(
                      icon: Icons.search,
                      backgroundColor: const Color(0xFF374151), // gray-700
                      iconColor: const Color(0xFF9CA3AF), // gray-400
                      onTap: _showLocationSearch,
                    ),
                    const SizedBox(width: 4),
                    // Navigation button - red circle
                    _buildInlineButton(
                      icon: Icons.navigation,
                      backgroundColor: const Color(0xFFEF4444),
                      iconColor: Colors.white,
                      onTap: _goToCurrentLocation,
                    ),
                    const SizedBox(width: 4),
                    // Close button - darker gray circle
                    _buildInlineButton(
                      icon: Icons.close,
                      backgroundColor: const Color(0xFF374151), // gray-700
                      iconColor: const Color(0xFF9CA3AF), // gray-400
                      onTap: () {},
                      size: 28,
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Category tabs - matching web exactly
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _categories.map((category) {
                  final isSelected = category == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category),
                    child: Column(
                      children: [
                        Text(
                          category,
                          style: TextStyle(
                            color: isSelected 
                                ? Colors.white 
                                : const Color(0xFFFCA5A5), // red-300
                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Underline for selected category
                        Container(
                          height: 2,
                          width: 50,
                          color: isSelected ? Colors.white : Colors.transparent,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              // Radius pills - matching web: selected=white bg, unselected=transparent with border
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _radiusOptions.map((radius) {
                  final isSelected = radius == _selectedRadius;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRadius = radius),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected ? null : Border.all(
                            color: const Color(0xFFFCA5A5), // red-300
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '$radius mi',
                          style: TextStyle(
                            color: isSelected 
                                ? const Color(0xFFEF4444)
                                : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineButton({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
    double size = 32,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: size * 0.45),
      ),
    );
  }

  Widget _buildMap() {
    final nearbyAsync = ref.watch(nearbyBarbersProvider);
    
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _lasVegas,
        initialZoom: _currentZoom,
        minZoom: 8,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // OpenStreetMap tile layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.directcuts.app',
        ),
        // User location marker - DC logo matching web exactly
        MarkerLayer(
          markers: [
            Marker(
              point: _currentCenter,
              width: 60,
              height: 60,
              child: _buildUserLocationMarker(),
            ),
          ],
        ),
        // Barber markers
        nearbyAsync.when(
          data: (barbers) => MarkerLayer(
            markers: barbers.map((barberWithDistance) {
              final barber = barberWithDistance.barber;
              final lat = barber.latitude;
              final lng = barber.longitude;
              if (lat == null || lng == null) return null;
              
              return Marker(
                point: LatLng(lat, lng),
                width: 44,
                height: 44,
                child: GestureDetector(
                  onTap: () => context.push('/barber/${barber.id}'),
                  child: _buildBarberMarker(barber),
                ),
              );
            }).whereType<Marker>().toList(),
          ),
          loading: () => const MarkerLayer(markers: []),
          error: (_, __) => const MarkerLayer(markers: []),
        ),
      ],
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      left: 16,
      top: 200,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            _buildZoomButton(Icons.add, () {
              final newZoom = (_currentZoom + 1).clamp(1.0, 18.0);
              _mapController.move(_currentCenter, newZoom);
              setState(() => _currentZoom = newZoom);
            }),
            Container(height: 1, width: 28, color: Colors.grey[300]),
            _buildZoomButton(Icons.remove, () {
              final newZoom = (_currentZoom - 1).clamp(1.0, 18.0);
              _mapController.move(_currentCenter, newZoom);
              setState(() => _currentZoom = newZoom);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, color: Colors.grey[700], size: 18),
      ),
    );
  }

  /// User location marker - matches web app's icon.png exactly
  /// Uses the same icon from the deployed web app (has transparent background)
  Widget _buildUserLocationMarker() {
    return Image.network(
      'https://direct-cuts.vercel.app/icon.png',
      width: 60,
      height: 60,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _buildFallbackLocationIcon(),
    );
  }

  Widget _buildFallbackLocationIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: const Icon(
        Icons.location_on,
        color: Color(0xFFE63946),
        size: 32,
      ),
    );
  }

  /// Barber marker - red circle with photo, white border
  Widget _buildBarberMarker(Barber barber) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFEF4444),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: barber.profileImageUrl != null
            ? Image.network(
                barber.profileImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _markerFallback(barber),
              )
            : _markerFallback(barber),
      ),
    );
  }

  Widget _markerFallback(Barber barber) {
    return Container(
      color: const Color(0xFFEF4444),
      child: Center(
        child: Text(
          barber.displayName.isNotEmpty ? barber.displayName[0].toUpperCase() : 'B',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildBarberCountBadge() {
    final nearbyAsync = ref.watch(nearbyBarbersProvider);
    
    return nearbyAsync.when(
      data: (barbers) {
        if (barbers.isEmpty) return const SizedBox.shrink();
        return Positioned(
          top: 200,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937), // gray-800 dark mode
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Text(
              '${barbers.length} barber${barbers.length == 1 ? '' : 's'} found',
              style: const TextStyle(
                color: Color(0xFF9CA3AF), // gray-400
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
      loading: () => Positioned(
        top: 200,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937), // gray-800 dark mode
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFEF4444),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Searching...',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF), // gray-400
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Bottom carousel of barber cards - dark theme matching web
  Widget _buildBottomCarousel() {
    final nearbyAsync = ref.watch(nearbyBarbersProvider);
    
    return nearbyAsync.when(
      data: (barbers) {
        if (barbers.isEmpty) return const SizedBox.shrink();
        
        return Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: barbers.length,
              itemBuilder: (context, index) {
                final barberWithDistance = barbers[index];
                final barber = barberWithDistance.barber;
                
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < barbers.length - 1 ? 12 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () => context.push('/barber/${barber.id}'),
                    child: _buildBarberCard(barber, barberWithDistance.formattedDistance),
                  ),
                );
              },
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Barber card - dark theme matching web's dark mode
  Widget _buildBarberCard(Barber barber, String distance) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937), // gray-800 dark card
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with red border
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEF4444), width: 2),
            ),
            child: ClipOval(
              child: barber.profileImageUrl != null
                  ? Image.network(
                      barber.profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _cardAvatarFallback(barber),
                    )
                  : _cardAvatarFallback(barber),
            ),
          ),
          const SizedBox(width: 12),
          // Info section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Name - white text
                Text(
                  barber.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Star rating
                Row(
                  children: [
                    ...List.generate(5, (i) => Text(
                      '★',
                      style: TextStyle(
                        fontSize: 10,
                        color: i < barber.rating.floor() 
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFF4B5563), // gray-600
                      ),
                    )),
                    if (barber.totalReviews > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(${barber.totalReviews})',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                // Distance and shop name
                Row(
                  children: [
                    Text(
                      distance,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      ' · ',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        barber.shopName ?? barber.shopAddress ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardAvatarFallback(Barber barber) {
    return Container(
      color: const Color(0xFF374151), // gray-700
      child: Center(
        child: Text(
          barber.displayName.isNotEmpty ? barber.displayName[0].toUpperCase() : 'B',
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  void _showLocationSearch() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location search coming soon')),
    );
  }

  void _goToCurrentLocation() async {
    await ref.read(userLocationProvider.notifier).refresh();
    final position = ref.read(userLocationProvider).valueOrNull;
    
    if (position != null) {
      final userLocation = LatLng(position.latitude, position.longitude);
      _mapController.move(userLocation, 14.0);
      setState(() {
        _currentCenter = userLocation;
        _currentZoom = 14.0;
      });
      
      ref.read(searchLocationProvider.notifier).state = (
        lat: position.latitude,
        lng: position.longitude,
      );
    } else {
      final granted = await ref.read(userLocationProvider.notifier).requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission required')),
        );
      }
    }
  }
}
