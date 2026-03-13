import '../models/equipment.dart';

/// Dummy equipment catalogue used to populate the marketplace.
final List<Equipment> dummyEquipment = [
  const Equipment(
    id: '1',
    name: 'Mahindra Tractor 575 DI',
    pricePerHour: 500,
    distance: 2.0,
    rating: 4.7,
    imageUrl: 'assets/images/tractor.webp',
    ownerName: 'Rajesh Kumar',
    description:
        'Powerful 45 HP tractor ideal for ploughing, tilling, and '
        'hauling. Well-maintained with AC cabin.',
  ),
  const Equipment(
    id: '2',
    name: 'Mini Harvester',
    pricePerHour: 800,
    distance: 3.0,
    rating: 4.5,
    imageUrl: 'assets/images/harvester.webp',
    ownerName: 'Sunil Patil',
    description:
        'Compact combine harvester suitable for wheat and rice. '
        'High efficiency with low grain loss.',
  ),
  const Equipment(
    id: '3',
    name: 'Irrigation Pump Set',
    pricePerHour: 200,
    distance: 1.5,
    rating: 4.2,
    imageUrl: 'assets/images/pump.webp',
    ownerName: 'Anita Sharma',
    description:
        '5 HP diesel pump with 100m pipe set. Perfect for '
        'field irrigation during dry spells.',
  ),
  const Equipment(
    id: '4',
    name: 'Rotavator',
    pricePerHour: 600,
    distance: 4.0,
    rating: 4.8,
    imageUrl: 'assets/images/rotavator.webp',
    ownerName: 'Vikram Singh',
    description:
        'Heavy-duty rotavator for soil preparation. '
        '48 blades, 6-foot working width.',
  ),
  const Equipment(
    id: '5',
    name: 'Seed Drill Machine',
    pricePerHour: 350,
    distance: 2.5,
    rating: 4.4,
    imageUrl: 'assets/images/seed_drill.webp',
    ownerName: 'Priya Desai',
    description:
        'Precision seed drill with 9-row capacity. '
        'Ensures even seed spacing and depth.',
  ),
  const Equipment(
    id: '6',
    name: 'Crop Sprayer',
    pricePerHour: 250,
    distance: 1.8,
    rating: 4.3,
    imageUrl: 'assets/images/sprayer.webp',
    ownerName: 'Mohan Reddy',
    description:
        'Boom sprayer with 200L tank capacity. '
        'Ideal for pesticide and fertilizer application.',
  ),
];
