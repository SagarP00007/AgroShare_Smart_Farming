/// Data model for a piece of farm equipment available for sharing.
class Equipment {
  const Equipment({
    required this.id,
    required this.name,
    required this.pricePerHour,
    required this.distance,
    required this.rating,
    required this.imageUrl,
    required this.ownerName,
    required this.description,
    this.isAvailable = true,
    this.purchasePrice = 0,
  });

  final String id;
  final String name;
  final double pricePerHour;
  final double distance; // in km
  final double rating;
  final String imageUrl;
  final String ownerName;
  final String description;
  final bool isAvailable;
  final double purchasePrice;
}
