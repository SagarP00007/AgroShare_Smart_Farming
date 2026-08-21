import 'package:geolocator/geolocator.dart';

/// Data model for a piece of farm equipment available for sharing.
class Equipment {
  const Equipment({
    required this.id,
    required this.name,
    required this.pricePerHour,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.ownerName,
    required this.description,
    this.ownerId = '',
    this.locationName = 'Unknown Location',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.isAvailable = true,
    this.purchasePrice = 0,
    this.listingType = 'rent',
    this.contactNumber = '',
  });

  final String id;
  final String name;
  final double pricePerHour;
  final double distance; // in km
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final String ownerName;
  final String ownerId;
  final String description;
  final String locationName;
  final double latitude;
  final double longitude;
  final bool isAvailable;
  final double purchasePrice;
  final String listingType; // 'rent' or 'buy'
  final String contactNumber;

  bool get isRent => listingType == 'rent';
  bool get isSell => listingType == 'buy';

  /// Calculates dynamic geodesic distance (in km) from user's current GPS position
  double calculateDistanceKm(double? userLat, double? userLng) {
    if (userLat == null ||
        userLng == null ||
        (latitude == 0.0 && longitude == 0.0)) {
      return distance;
    }
    final meters = Geolocator.distanceBetween(
      userLat,
      userLng,
      latitude,
      longitude,
    );
    final km = meters / 1000.0;
    return double.parse(km.toStringAsFixed(1));
  }

  /// Returns user-friendly formatted distance string e.g. "2.3 km away"
  String formattedDistance(double? userLat, double? userLng) {
    final dist = calculateDistanceKm(userLat, userLng);
    return '$dist km away';
  }

  /// Create from Firestore document.
  factory Equipment.fromMap(String id, Map<String, dynamic> data) {
    return Equipment(
      id: id,
      name: data['name'] ?? '',
      pricePerHour: (data['pricePerHour'] ?? 0).toDouble(),
      distance: (data['distance'] ?? 0).toDouble(),
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: (data['reviewCount'] ?? 0).toInt(),
      imageUrl: data['imageUrl'] ?? '',
      ownerName: data['ownerName'] ?? '',
      ownerId: data['ownerId'] ?? '',
      description: data['description'] ?? '',
      locationName: data['locationName'] ?? 'Unknown Location',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      isAvailable: data['isAvailable'] ?? true,
      purchasePrice: (data['purchasePrice'] ?? 0).toDouble(),
      listingType: data['listingType'] ?? 'rent',
      contactNumber: data['contactNumber'] ?? '',
    );
  }

  /// Convert to Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'pricePerHour': pricePerHour,
      'distance': distance,
      'rating': rating,
      'reviewCount': reviewCount,
      'imageUrl': imageUrl,
      'ownerName': ownerName,
      'ownerId': ownerId,
      'description': description,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'isAvailable': isAvailable,
      'purchasePrice': purchasePrice,
      'listingType': listingType,
      'contactNumber': contactNumber,
    };
  }
}
