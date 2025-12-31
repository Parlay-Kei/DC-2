import 'dart:math' as math;

/// GeoJSON Types for Map Enhancement
/// Matches DC-1 web app GeoJSON contract
///
/// GeoJSON Feature Collection for map pins
/// Used by Mapbox GL JS (web) and Mapbox Flutter SDK (mobile)

class GeoJSONFeatureCollection {
  final String type;
  final List<GeoJSONFeature> features;

  GeoJSONFeatureCollection({
    required this.type,
    required this.features,
  });

  factory GeoJSONFeatureCollection.fromJson(Map<String, dynamic> json) {
    return GeoJSONFeatureCollection(
      type: json['type'] as String? ?? 'FeatureCollection',
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => GeoJSONFeature.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'features': features.map((e) => e.toJson()).toList(),
    };
  }

  static GeoJSONFeatureCollection empty() {
    return GeoJSONFeatureCollection(
      type: 'FeatureCollection',
      features: [],
    );
  }
}

class GeoJSONFeature {
  final String type;
  final String id;
  final GeoJSONPoint geometry;
  final PinProperties properties;

  GeoJSONFeature({
    required this.type,
    required this.id,
    required this.geometry,
    required this.properties,
  });

  factory GeoJSONFeature.fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final pinType = props['pinType'] as String?;

    PinProperties properties;
    if (pinType == 'mobile') {
      properties = MobileBarberPinProperties.fromJson(props);
    } else {
      properties = ShopPinProperties.fromJson(props);
    }

    return GeoJSONFeature(
      type: json['type'] as String? ?? 'Feature',
      id: json['id'] as String,
      geometry: GeoJSONPoint.fromJson(json['geometry'] as Map<String, dynamic>),
      properties: properties,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'geometry': geometry.toJson(),
      'properties': properties.toJson(),
    };
  }
}

class GeoJSONPoint {
  final String type;
  final List<double> coordinates; // [longitude, latitude]

  GeoJSONPoint({
    required this.type,
    required this.coordinates,
  });

  double get longitude => coordinates[0];
  double get latitude => coordinates[1];

  factory GeoJSONPoint.fromJson(Map<String, dynamic> json) {
    return GeoJSONPoint(
      type: json['type'] as String? ?? 'Point',
      coordinates: (json['coordinates'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
    };
  }
}

/// Base class for all pin properties
abstract class PinProperties {
  String get pinType;
  String get barberId;
  String get barberName;
  double get rating;
  int get reviews;
  double get price;
  String? get image;
  bool get isVerified;
  bool get isAvailable;
  double? get distance;
  String? get distanceDisplay;

  Map<String, dynamic> toJson();
}

/// Properties for shop pins (barbers with fixed locations)
class ShopPinProperties implements PinProperties {
  @override
  final String pinType;
  @override
  final String barberId;
  @override
  final String barberName;
  final String? shopName;
  final String? specialty;
  @override
  final double rating;
  @override
  final int reviews;
  @override
  final double price;
  final String? priceRange;
  final String address;
  final String? city;
  final String? state;
  final String? zip;
  @override
  final String? image;
  final bool? featured;
  @override
  final bool isVerified;
  @override
  final bool isAvailable;
  @override
  final double? distance;
  @override
  final String? distanceDisplay;

  ShopPinProperties({
    required this.pinType,
    required this.barberId,
    required this.barberName,
    this.shopName,
    this.specialty,
    required this.rating,
    required this.reviews,
    required this.price,
    this.priceRange,
    required this.address,
    this.city,
    this.state,
    this.zip,
    this.image,
    this.featured,
    required this.isVerified,
    required this.isAvailable,
    this.distance,
    this.distanceDisplay,
  });

  factory ShopPinProperties.fromJson(Map<String, dynamic> json) {
    return ShopPinProperties(
      pinType: json['pinType'] as String? ?? 'shop',
      barberId: json['barberId'] as String,
      barberName: json['barberName'] as String,
      shopName: json['shopName'] as String?,
      specialty: json['specialty'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: (json['reviews'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      priceRange: json['priceRange'] as String?,
      address: json['address'] as String? ?? '',
      city: json['city'] as String?,
      state: json['state'] as String?,
      zip: json['zip'] as String?,
      image: json['image'] as String?,
      featured: json['featured'] as bool?,
      isVerified: json['isVerified'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
      distance: (json['distance'] as num?)?.toDouble(),
      distanceDisplay: json['distanceDisplay'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'pinType': pinType,
      'barberId': barberId,
      'barberName': barberName,
      'shopName': shopName,
      'specialty': specialty,
      'rating': rating,
      'reviews': reviews,
      'price': price,
      'priceRange': priceRange,
      'address': address,
      'city': city,
      'state': state,
      'zip': zip,
      'image': image,
      'featured': featured,
      'isVerified': isVerified,
      'isAvailable': isAvailable,
      'distance': distance,
      'distanceDisplay': distanceDisplay,
    };
  }
}

/// Properties for mobile barber pins (barbers who travel)
class MobileBarberPinProperties implements PinProperties {
  @override
  final String pinType;
  @override
  final String barberId;
  @override
  final String barberName;
  final String? specialty;
  @override
  final double rating;
  @override
  final int reviews;
  @override
  final double price;
  final String? priceRange;
  final double serviceRadiusMiles;
  final double? travelFee;
  final Map<String, double>? currentLocation;
  @override
  final String? image;
  final bool? featured;
  @override
  final bool isVerified;
  @override
  final bool isAvailable;
  final bool? isOnline;
  @override
  final double? distance;
  @override
  final String? distanceDisplay;

  MobileBarberPinProperties({
    required this.pinType,
    required this.barberId,
    required this.barberName,
    this.specialty,
    required this.rating,
    required this.reviews,
    required this.price,
    this.priceRange,
    required this.serviceRadiusMiles,
    this.travelFee,
    this.currentLocation,
    this.image,
    this.featured,
    required this.isVerified,
    required this.isAvailable,
    this.isOnline,
    this.distance,
    this.distanceDisplay,
  });

  factory MobileBarberPinProperties.fromJson(Map<String, dynamic> json) {
    Map<String, double>? currentLoc;
    if (json['currentLocation'] != null) {
      final loc = json['currentLocation'] as Map<String, dynamic>;
      currentLoc = {
        'lat': (loc['lat'] as num).toDouble(),
        'lng': (loc['lng'] as num).toDouble(),
      };
    }

    return MobileBarberPinProperties(
      pinType: json['pinType'] as String? ?? 'mobile',
      barberId: json['barberId'] as String,
      barberName: json['barberName'] as String,
      specialty: json['specialty'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: (json['reviews'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      priceRange: json['priceRange'] as String?,
      serviceRadiusMiles:
          (json['serviceRadiusMiles'] as num?)?.toDouble() ?? 0.0,
      travelFee: (json['travelFee'] as num?)?.toDouble(),
      currentLocation: currentLoc,
      image: json['image'] as String?,
      featured: json['featured'] as bool?,
      isVerified: json['isVerified'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
      isOnline: json['isOnline'] as bool?,
      distance: (json['distance'] as num?)?.toDouble(),
      distanceDisplay: json['distanceDisplay'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'pinType': pinType,
      'barberId': barberId,
      'barberName': barberName,
      'specialty': specialty,
      'rating': rating,
      'reviews': reviews,
      'price': price,
      'priceRange': priceRange,
      'serviceRadiusMiles': serviceRadiusMiles,
      'travelFee': travelFee,
      'currentLocation': currentLocation,
      'image': image,
      'featured': featured,
      'isVerified': isVerified,
      'isAvailable': isAvailable,
      'isOnline': isOnline,
      'distance': distance,
      'distanceDisplay': distanceDisplay,
    };
  }
}

/// Type guards
extension PinPropertiesTypeGuard on PinProperties {
  bool get isShopPin => pinType == 'shop';
  bool get isMobileBarberPin => pinType == 'mobile';
}

/// Bounding box for map viewport queries
class BoundingBox {
  final double minLng;
  final double minLat;
  final double maxLng;
  final double maxLat;

  BoundingBox({
    required this.minLng,
    required this.minLat,
    required this.maxLng,
    required this.maxLat,
  });

  String toBBoxString() {
    return '$minLng,$minLat,$maxLng,$maxLat';
  }

  factory BoundingBox.fromCenterAndRadius({
    required double centerLat,
    required double centerLng,
    required double radiusMeters,
  }) {
    // Approximate conversion: 1 degree latitude ≈ 111,000 meters
    // 1 degree longitude ≈ 111,000 * cos(latitude) meters
    final latDelta = radiusMeters / 111000;
    final lngDelta = radiusMeters / (111000 * math.cos(_toRadians(centerLat)));

    return BoundingBox(
      minLng: centerLng - lngDelta,
      minLat: centerLat - latDelta,
      maxLng: centerLng + lngDelta,
      maxLat: centerLat + latDelta,
    );
  }

  static double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}
