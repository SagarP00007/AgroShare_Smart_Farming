import '../models/farmer.dart';

/// Dummy farmer profiles used across the community screens.
///
/// Keyed by name for easy lookup from group member lists.
final Map<String, Farmer> farmerDirectory = {
  'Ramesh': const Farmer(
    name: 'Ramesh',
    trustScore: 4.6,
    completedRentals: 18,
    groupPurchases: 3,
  ),
  'Kiran': const Farmer(
    name: 'Kiran',
    trustScore: 4.3,
    completedRentals: 12,
    groupPurchases: 2,
  ),
  'Arjun': const Farmer(
    name: 'Arjun',
    trustScore: 4.8,
    completedRentals: 25,
    groupPurchases: 5,
  ),
  'Suresh': const Farmer(
    name: 'Suresh',
    trustScore: 3.9,
    completedRentals: 7,
    groupPurchases: 1,
  ),
  'Priya': const Farmer(
    name: 'Priya',
    trustScore: 4.5,
    completedRentals: 14,
    groupPurchases: 4,
  ),
  'You': const Farmer(
    name: 'You',
    trustScore: 4.2,
    completedRentals: 10,
    groupPurchases: 2,
  ),
};

/// Look up a farmer by name, returning a default if not found.
Farmer getFarmer(String name) {
  return farmerDirectory[name] ??
      Farmer(
        name: name,
        trustScore: 4.0,
        completedRentals: 0,
        groupPurchases: 0,
      );
}
