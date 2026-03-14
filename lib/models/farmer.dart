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
    );
  }

  /// Convert to Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'location': location,
      'phone': phone,
      'trustScore': trustScore,
      'completedRentals': completedRentals,
      'groupPurchases': groupPurchases,
    };
  }
}
