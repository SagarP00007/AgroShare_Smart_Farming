/// Data model for a farmer/user in the AgroShare community.
class Farmer {
  const Farmer({
    this.uid = '',
    required this.name,
    this.email = '',
    this.location = '',
    this.phone = '',
    this.profileImage = '',
    required this.trustScore,
    required this.completedRentals,
    required this.groupPurchases,
    this.verifiedReturns = 0,
    this.totalRatingPoints = 0.0,
    this.reviewCount = 0,
  });

  final String uid;
  final String name;
  final String email;
  final String location;
  final String phone;
  final String profileImage;

  /// Trust score out of 5.0.
  final double trustScore;

  /// Number of completed equipment rentals.
  final int completedRentals;

  /// Number of successful group purchases.
  final int groupPurchases;

  /// Number of equipment rentals completed with verified pre & post condition inspection.
  final int verifiedReturns;

  /// Total accumulated rating points for trust score calculation.
  final double totalRatingPoints;

  /// Number of reviews received.
  final int reviewCount;

  /// Calculates dynamic Trust Score based on average rating, completed rentals, and verified returns.
  /// Formula: 70% Avg Rating + 15% Rental Experience + 15% Condition Verification Record
  static double calculateTrustScore({
    required double avgRating,
    required int completedRentals,
    required int verifiedReturns,
  }) {
    final ratingPart = (avgRating.clamp(1.0, 5.0)) * 0.70;
    final rentalBonus = (completedRentals * 0.2).clamp(0.0, 1.5) * 0.15;
    final verifiedBonus = (verifiedReturns * 0.25).clamp(0.0, 1.0) * 0.15;

    // Scale total score out of 5.0
    final rawScore =
        (ratingPart + rentalBonus + verifiedBonus) / 0.70 * 0.85 + 0.75;
    return double.parse(rawScore.clamp(1.0, 5.0).toStringAsFixed(1));
  }

  /// Create from Firestore document.
  factory Farmer.fromMap(String uid, Map<String, dynamic> data) {
    return Farmer(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      location: data['location'] ?? '',
      phone: data['phone'] ?? '',
      profileImage: data['profileImage'] ?? '',
      trustScore: (data['trustScore'] ?? 4.0).toDouble(),
      completedRentals: (data['completedRentals'] ?? 0).toInt(),
      groupPurchases: (data['groupPurchases'] ?? 0).toInt(),
      verifiedReturns:
          (data['verifiedReturns'] ?? (data['completedRentals'] ?? 0)).toInt(),
      totalRatingPoints: (data['totalRatingPoints'] ?? 0.0).toDouble(),
      reviewCount: (data['reviewCount'] ?? 0).toInt(),
    );
  }

  /// Convert to Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'location': location,
      'phone': phone,
      'profileImage': profileImage,
      'trustScore': trustScore,
      'completedRentals': completedRentals,
      'groupPurchases': groupPurchases,
      'verifiedReturns': verifiedReturns,
      'totalRatingPoints': totalRatingPoints,
      'reviewCount': reviewCount,
    };
  }
}
