import '../models/equipment.dart';

/// Dummy equipment catalogue used to populate the marketplace.
final List<Equipment> dummyEquipment = [
  const Equipment(
    id: '1',
    name: 'Mahindra Tractor 575 DI',
    pricePerHour: 500,
    distance: 2.0,
    rating: 4.7,
    reviewCount: 24,
    imageUrl: 'assets/images/tractor.webp',
    ownerName: 'Rajesh Kumar',
    description:
        'Powerful 45 HP tractor ideal for ploughing, tilling, and '
        'hauling. Well-maintained with AC cabin.',
    locationName: 'Angondhalli',
    latitude: 12.9650,
    longitude: 77.6000,
    isAvailable: true,
    purchasePrice: 250000,
    listingType: 'rent',
  ),
  const Equipment(
    id: '2',
    name: 'Mini Harvester',
    pricePerHour: 800,
    distance: 3.0,
    rating: 4.5,
    reviewCount: 12,
    imageUrl: 'assets/images/harvester.webp',
    ownerName: 'Sunil Patil',
    description:
        'Compact combine harvester suitable for wheat and rice. '
        'High efficiency with low grain loss.',
    locationName: 'Ramapur',
    latitude: 12.9800,
    longitude: 77.5850,
    isAvailable: false,
    purchasePrice: 350000,
    listingType: 'sell',
  ),
  const Equipment(
    id: '3',
    name: 'Irrigation Pump Set',
    pricePerHour: 200,
    distance: 1.5,
    rating: 4.2,
    reviewCount: 8,
    imageUrl: 'assets/images/pump.webp',
    ownerName: 'Anita Sharma',
    description:
        '5 HP diesel pump with 100m pipe set. Perfect for '
        'field irrigation during dry spells.',
    locationName: 'Kengeri',
    latitude: 12.9550,
    longitude: 77.5700,
    isAvailable: true,
    purchasePrice: 45000,
    listingType: 'rent',
  ),
  const Equipment(
    id: '4',
    name: 'Rotavator',
    pricePerHour: 600,
    distance: 4.0,
    rating: 4.8,
    reviewCount: 36,
    imageUrl: 'assets/images/rotavator.webp',
    ownerName: 'Vikram Singh',
    description:
        'Heavy-duty rotavator for soil preparation. '
        '48 blades, 6-foot working width.',
    locationName: 'Yelahanka',
    latitude: 12.9900,
    longitude: 77.6100,
    isAvailable: true,
    purchasePrice: 180000,
    listingType: 'sell',
  ),
  const Equipment(
    id: '5',
    name: 'Seed Drill Machine',
    pricePerHour: 350,
    distance: 2.5,
    rating: 4.4,
    reviewCount: 15,
    imageUrl: 'assets/images/seed_drill.webp',
    ownerName: 'Priya Desai',
    description:
        'Precision seed drill with 9-row capacity. '
        'Ensures even seed spacing and depth.',
    locationName: 'Whitefield',
    latitude: 12.9750,
    longitude: 77.6200,
    isAvailable: false,
    purchasePrice: 120000,
    listingType: 'rent',
  ),
  const Equipment(
    id: '6',
    name: 'Crop Sprayer',
    pricePerHour: 250,
    distance: 1.8,
    rating: 4.3,
    reviewCount: 19,
    imageUrl: 'assets/images/sprayer.webp',
    ownerName: 'Mohan Reddy',
    description:
        'Boom sprayer with 200L tank capacity. '
        'Ideal for pesticide and fertilizer application.',
    locationName: 'Hebbal',
    latitude: 12.9600,
    longitude: 77.5800,
    isAvailable: true,
    purchasePrice: 75000,
    listingType: 'sell',
  ),
];

