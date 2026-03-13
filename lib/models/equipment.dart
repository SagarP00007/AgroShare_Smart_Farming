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
    this.locationName = 'Unknown Location',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.isAvailable = true,
    this.purchasePrice = 0,
    this.listingType = 'rent',
  });

  final String id;
  final String name;
  final double pricePerHour;
  final double distance; // in km
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final String ownerName;
  final String description;
  final String locationName;
  final double latitude;
  final double longitude;
  final bool isAvailable;
  final double purchasePrice;

  /// 'rent' or 'sell'
  final String listingType;

  bool get isRent => listingType == 'rent';
  bool get isSell => listingType == 'sell';
}
