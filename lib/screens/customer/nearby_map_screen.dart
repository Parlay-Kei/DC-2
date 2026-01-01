import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../config/app_config.dart';
import '../../models/geojson.dart';
import '../../providers/auth_provider.dart';
import '../../providers/barber_provider.dart';
import '../../services/map_service.dart';
import '../../utils/logger.dart';

class NearbyMapScreen extends ConsumerStatefulWidget {
  const NearbyMapScreen({super.key});

  @override
  ConsumerState<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends ConsumerState<NearbyMapScreen> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  bool _mapboxInitialized = false;

  // Default to Las Vegas (matches web app)
  static const _lasVegasLat = 36.1699;
  static const _lasVegasLng = -115.1398;

  double _currentCenterLat = _lasVegasLat;
  double _currentCenterLng = _lasVegasLng;
  double _currentZoom = 11.0;

  // Selected distance filter (in miles) - matches web app options
  int _selectedRadius = 25;
  final List<int> _radiusOptions = [10, 25, 50, 100];

  // Selected category filter - matches web app
  String _selectedCategory = 'Haircuts';
  final List<String> _categories = [
    'Haircuts',
    'Fades',
    'Beard Trims',
    'Color'
  ];

  // Search query for location
  String _locationText = 'Las Vegas, Nevada';

  // Map data
  GeoJSONFeatureCollection? _currentPins;
  bool _isLoadingPins = false;

  // Debug metrics
  int _lastQueryTimeMs = 0;

  @override
  void initState() {
    super.initState();
    _initializeMapbox();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNearbyBarbers();
    });
  }

  /// Initialize Mapbox SDK with access token - MUST be called before MapWidget is built
  void _initializeMapbox() {
    if (AppConfig.isMapboxConfigured && !_mapboxInitialized) {
      MapboxOptions.setAccessToken(AppConfig.mapboxAccessToken);
      _mapboxInitialized = true;
      Logger.debug('Mapbox initialized');
    }
  }

  Future<void> _loadNearbyBarbers() async {
    if (_isLoadingPins) return;

    setState(() {
      _isLoadingPins = true;
    });

    final stopwatch = Stopwatch()..start();

    try {
      // Convert miles to meters
      final radiusMeters = _selectedRadius * 1609.34;

      Logger.debug(
          'Loading nearby barbers: center($_currentCenterLat, $_currentCenterLng), radius: ${_selectedRadius}mi');

      final pins = await MapService.instance.getPinsWithinRadius(
        centerLat: _currentCenterLat,
        centerLng: _currentCenterLng,
        radiusMeters: radiusMeters,
      );

      stopwatch.stop();
      final queryTime = stopwatch.elapsedMilliseconds;

      Logger.debug(
          'Nearby barbers loaded: ${pins.features.length} barbers, ${queryTime}ms');

      setState(() {
        _currentPins = pins;
        _isLoadingPins = false;
        _lastQueryTimeMs = queryTime;
      });

      // Update map markers
      await _updateMapMarkers();

      // Fit bounds to show all pins
      if (pins.features.isNotEmpty) {
        await _fitBoundsToAllPins();
      }
    } catch (e) {
      stopwatch.stop();
      Logger.error('Error loading nearby barbers', e);
      setState(() {
        _isLoadingPins = false;
        _lastQueryTimeMs = stopwatch.elapsedMilliseconds;
      });
    }
  }

  Future<void> _updateMapMarkers() async {
    if (_mapboxMap == null || _currentPins == null) return;

    try {
      // Clear existing annotations
      if (_annotationManager != null) {
        await _annotationManager!.deleteAll();
      } else {
        _annotationManager =
            await _mapboxMap!.annotations.createPointAnnotationManager();
      }

      // Add new markers with DC-1 styling:
      // - Red marker icon (default Mapbox marker)
      // - White label badge with dark text below pin
      final options = <PointAnnotationOptions>[];

      for (final feature in _currentPins!.features) {
        final props = feature.properties;
        final lng = feature.geometry.longitude;
        final lat = feature.geometry.latitude;

        // Determine icon color based on pin type (shop = red, mobile = green)
        final isShop = props.pinType == 'shop';

        // Create marker with styled label matching DC-1 exactly
        // DC-1 uses: teardrop pin with white badge label below
        final option = PointAnnotationOptions(
          geometry: Point(coordinates: Position(lng, lat)),
          // Use default marker but with proper colors matching DC-1
          // Shop pins: Dark blue/navy to match DC-1's appearance
          // DC-1 code shows #007CF (invalid hex), likely meant #0007CF or #1E3A8A (dark blue/navy)
          // Using #1E3A8A (slate-800) which matches the "dark-colored" appearance in DC-1
          iconSize: 1.2, // Slightly larger to match DC-1 pin size
          iconColor: isShop
              ? 0xFF1E3A8A
              : 0xFF10B921, // Dark blue/navy for shops, green for mobile (matches DC-1)
          // Label styling to match DC-1's white badge effect exactly
          // DC-1 uses: white background (rgba(255,255,255,0.95)), 10px font, 600 weight, 4px border-radius
          textField: props.barberName,
          textSize: 10.0, // Matches DC-1's 10px font size exactly
          textOffset: [0, 2.5], // Position below pin (matches DC-1 spacing)
          textColor:
              0xFF1F2937, // Dark gray text (matches DC-1's #1f2937 exactly)
          textHaloColor:
              0xFFFFFFFF, // White halo creates badge background (matches DC-1's white badge)
          textHaloWidth:
              5.0, // Thicker halo for better badge effect (simulates DC-1's padding: 2px 6px)
          textMaxWidth:
              12.0, // Allow slightly wider for longer names (DC-1 uses max-width: 120px)
          textAnchor: TextAnchor.TOP, // Center text below pin
          // Note: Font styling is handled by the map style, not as a parameter
          // The map style should include 'Open Sans Semibold' or 'Arial Unicode MS Bold' for font-weight: 600 effect
        );

        options.add(option);
      }

      await _annotationManager!.createMulti(options);
    } catch (e) {
      Logger.error('Error updating map markers', e);
    }
  }

  Future<void> _fitBoundsToAllPins() async {
    if (_mapboxMap == null ||
        _currentPins == null ||
        _currentPins!.features.isEmpty) {
      return;
    }

    try {
      // Calculate bounds
      double minLat = double.infinity;
      double maxLat = -double.infinity;
      double minLng = double.infinity;
      double maxLng = -double.infinity;

      for (final feature in _currentPins!.features) {
        final lat = feature.geometry.latitude;
        final lng = feature.geometry.longitude;

        if (lat < minLat) minLat = lat;
        if (lat > maxLat) maxLat = lat;
        if (lng < minLng) minLng = lng;
        if (lng > maxLng) maxLng = lng;
      }

      // Add padding
      final latPadding = (maxLat - minLat) * 0.1;
      final lngPadding = (maxLng - minLng) * 0.1;

      final bounds = CoordinateBounds(
        southwest: Point(
            coordinates: Position(minLng - lngPadding, minLat - latPadding)),
        northeast: Point(
            coordinates: Position(maxLng + lngPadding, maxLat + latPadding)),
        infiniteBounds: false,
      );

      final cameraOptions = await _mapboxMap!.cameraForCoordinateBounds(
        bounds,
        MbxEdgeInsets(top: 200, left: 50, bottom: 150, right: 50),
        null,
        null,
        null,
        null,
      );

      await _mapboxMap!.flyTo(
        cameraOptions,
        MapAnimationOptions(duration: 1000, startDelay: 0),
      );
    } catch (e) {
      Logger.error('Error fitting map bounds', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    Logger.debug('Mapbox configured: ${AppConfig.isMapboxConfigured}');

    if (!AppConfig.isMapboxConfigured) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 64, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'Mapbox Not Configured',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Token length: ${AppConfig.mapboxAccessToken.length}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Run with --dart-define=MAPBOX_ACCESS_TOKEN=your-token',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
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
        // Debug strip (only in debug mode)
        if (kDebugMode) _buildDebugStrip(),
        // Map controls (zoom buttons)
        _buildMapControls(),
        // Barber count badge
        _buildBarberCountBadge(),
        // Bottom barber cards carousel
        _buildBottomCarousel(),
        // Loading indicator
        if (_isLoadingPins)
          Positioned(
            top: 200,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
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
                        color: Color(0xFF9CA3AF),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDebugStrip() {
    final isAuthed = ref.watch(currentUserProvider) != null;
    final barberCount = _currentPins?.features.length ?? 0;

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
            border: Border.all(color: const Color(0xFFEF4444), width: 1),
          ),
          child: Text(
            'DEBUG: barbers=$barberCount | queryTime=${_lastQueryTimeMs}ms | auth=$isAuthed',
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
      decoration: const BoxDecoration(
        color: Color(0xFFEF4444),
      ),
      child: Stack(
        children: [
          // Large Watermark Logo
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
                  // Search bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
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
                        Icon(
                          Icons.location_on_outlined,
                          color: Colors.grey[500],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _locationText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildInlineButton(
                          icon: Icons.search,
                          backgroundColor: const Color(0xFF374151),
                          iconColor: const Color(0xFF9CA3AF),
                          onTap: _showLocationSearch,
                        ),
                        const SizedBox(width: 4),
                        _buildInlineButton(
                          icon: Icons.navigation,
                          backgroundColor: const Color(0xFFEF4444),
                          iconColor: Colors.white,
                          onTap: _goToCurrentLocation,
                        ),
                        const SizedBox(width: 4),
                        _buildInlineButton(
                          icon: Icons.close,
                          backgroundColor: const Color(0xFF374151),
                          iconColor: const Color(0xFF9CA3AF),
                          onTap: () => context.pop(),
                          size: 28,
                        ),
                        const SizedBox(width: 6),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Category tabs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _categories.map((category) {
                      final isSelected = category == _selectedCategory;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategory = category),
                        child: Column(
                          children: [
                            Text(
                              category,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFFFCA5A5),
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 2,
                              width: 50,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Radius pills
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _radiusOptions.map((radius) {
                      final isSelected = radius == _selectedRadius;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedRadius = radius);
                            _loadNearbyBarbers();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color: const Color(0xFFFCA5A5),
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
    return MapWidget(
      key: const ValueKey('mapbox'),
      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(_lasVegasLng, _lasVegasLat)),
        zoom: _currentZoom,
      ),
      // Use streets-v12 style URL to match DC-1 web app exactly (light theme with streets)
      // This matches DC-1's mapbox://styles/mapbox/streets-v12 style
      styleUri: 'mapbox://styles/mapbox/streets-v12',
      textureView: true,
      onMapCreated: _onMapCreated,
      onStyleLoadedListener: (_) {
        Logger.debug('Map style loaded successfully');
      },
      onMapLoadErrorListener: (error) {
        // Mapbox will often surface tile-related failures here.
        // Logging more fields helps identify 403/401 root causes (token/scope/restrictions).
        Logger.error('Map load error: ${error.type}', error.message);
      },
      onTapListener: (coordinate) {
        // Handle pin selection via bottom carousel
      },
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _loadNearbyBarbers();
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
            _buildZoomButton(Icons.add, () async {
              if (_mapboxMap != null) {
                final newZoom = (_currentZoom + 1).clamp(1.0, 18.0);
                await _mapboxMap!.setCamera(
                  CameraOptions(zoom: newZoom),
                );
                setState(() => _currentZoom = newZoom);
              }
            }),
            Container(height: 1, width: 28, color: Colors.grey[300]),
            _buildZoomButton(Icons.remove, () async {
              if (_mapboxMap != null) {
                final newZoom = (_currentZoom - 1).clamp(1.0, 18.0);
                await _mapboxMap!.setCamera(
                  CameraOptions(zoom: newZoom),
                );
                setState(() => _currentZoom = newZoom);
              }
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

  Widget _buildBarberCountBadge() {
    if (_currentPins == null || _currentPins!.features.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 200,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
            ),
          ],
        ),
        child: Text(
          '${_currentPins!.features.length} barber${_currentPins!.features.length == 1 ? '' : 's'} found',
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCarousel() {
    if (_currentPins == null || _currentPins!.features.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 16,
      child: SizedBox(
        height: 90,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _currentPins!.features.length,
          itemBuilder: (context, index) {
            final feature = _currentPins!.features[index];
            final props = feature.properties;

            return Padding(
              padding: EdgeInsets.only(
                right: index < _currentPins!.features.length - 1 ? 12 : 0,
              ),
              child: GestureDetector(
                onTap: () => context.push('/barber/${props.barberId}'),
                child: _buildBarberCard(props),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBarberCard(PinProperties props) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
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
              border: Border.all(
                color: props.pinType == 'shop'
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981), // green for mobile
                width: 2,
              ),
            ),
            child: ClipOval(
              child: props.image != null
                  ? Image.network(
                      props.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _cardAvatarFallback(props),
                    )
                  : _cardAvatarFallback(props),
            ),
          ),
          const SizedBox(width: 12),
          // Info section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Name
                Text(
                  props.barberName,
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
                    ...List.generate(
                      5,
                      (i) => Text(
                        '★',
                        style: TextStyle(
                          fontSize: 10,
                          color: i < props.rating.floor()
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                    if (props.reviews > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(${props.reviews})',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                // Distance and type
                Row(
                  children: [
                    Text(
                      props.distanceDisplay ?? '',
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
                        props.pinType == 'shop'
                            ? (props as ShopPinProperties).shopName ?? 'Shop'
                            : 'Mobile',
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

  Widget _cardAvatarFallback(PinProperties props) {
    return Container(
      color: const Color(0xFF374151),
      child: Center(
        child: Text(
          props.barberName.isNotEmpty ? props.barberName[0].toUpperCase() : 'B',
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  void _showLocationSearch() async {
    final result = await showDialog<GeocodeSuggestion>(
      context: context,
      builder: (context) => _LocationSearchDialog(),
    );

    if (result != null) {
      setState(() {
        _locationText = result.displayName;
        _currentCenterLat = result.lat;
        _currentCenterLng = result.lng;
      });

      // Move map to new location
      if (_mapboxMap != null) {
        await _mapboxMap!.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(result.lng, result.lat)),
            zoom: 12.0,
          ),
          MapAnimationOptions(duration: 1000, startDelay: 0),
        );
      }

      // Reload barbers
      _loadNearbyBarbers();
    }
  }

  void _goToCurrentLocation() async {
    await ref.read(userLocationProvider.notifier).refresh();
    final position = ref.read(userLocationProvider).valueOrNull;

    if (position != null && _mapboxMap != null) {
      setState(() {
        _currentCenterLat = position.latitude;
        _currentCenterLng = position.longitude;
        _locationText = 'Current Location';
      });

      await _mapboxMap!.flyTo(
        CameraOptions(
          center: Point(
              coordinates: Position(position.longitude, position.latitude)),
          zoom: 14.0,
        ),
        MapAnimationOptions(duration: 1000, startDelay: 0),
      );

      _loadNearbyBarbers();
    } else {
      final granted =
          await ref.read(userLocationProvider.notifier).requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission required')),
        );
      }
    }
  }
}

class _LocationSearchDialog extends StatefulWidget {
  @override
  State<_LocationSearchDialog> createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends State<_LocationSearchDialog> {
  final _searchController = TextEditingController();
  List<GeocodeSuggestion> _suggestions = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final results = await GeocodingService.instance.autocomplete(
      query: query,
      proximityLng: -115.1398,
      proximityLat: 36.1699,
    );

    setState(() {
      _suggestions = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1F2937),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search field
            TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search location...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                filled: true,
                fillColor: const Color(0xFF374151),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            // Results
            if (_isLoading)
              const CircularProgressIndicator(color: Color(0xFFEF4444))
            else if (_suggestions.isEmpty)
              Text(
                'Start typing to search',
                style: TextStyle(color: Colors.grey[500]),
              )
            else
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on,
                          color: Color(0xFFEF4444)),
                      title: Text(
                        suggestion.displayName,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () => Navigator.of(context).pop(suggestion),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
