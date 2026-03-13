/// Data model for a farmer in the AgroShare community.
class Farmer {
  const Farmer({
    required this.name,
    required this.trustScore,
    required this.completedRentals,
    required this.groupPurchases,
  });

  final String name;

  /// Trust score out of 5.0.
  final double trustScore;

  /// Number of completed equipment rentals.
  final int completedRentals;

  /// Number of successful group purchases.
  final int groupPurchases;
}
