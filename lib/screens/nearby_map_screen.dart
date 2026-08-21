import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../models/equipment.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_card.dart';
import '../widgets/equipment_action_sheet.dart';
import '../data/equipment_data.dart'; // Just to pick base equipment info to clone

/// Represents simulated equipment placed on the map relative to user location.
class _MapEquipment {
  _MapEquipment({
    required this.equipment,
    required this.location,
    required this.distanceKm,
  });

  final Equipment equipment;
  final LatLng location;
  final double distanceKm;
}

class NearbyMapScreen extends StatefulWidget {
  const NearbyMapScreen({super.key, required this.userLocation});

  final LatLng userLocation;

  @override
  State<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends State<NearbyMapScreen> {
  final MapController _mapController = MapController();
  late List<_MapEquipment> _nearbyItems;

  @override
  void initState() {
    super.initState();
    _generateDummyEquipment();
  }

  void _generateDummyEquipment() {
    _nearbyItems = [];
    final uLat = widget.userLocation.latitude;
    final uLng = widget.userLocation.longitude;

    // Hardcoded items as requested in prompt
    final mockData = [
      {
        'name': 'Tractor',
        'latOff': 0.008,
        'lngOff': 0.005,
        'dist': 1.5,
        'price': 400.0,
      },
      {
        'name': 'Harvester',
        'latOff': -0.006,
        'lngOff': 0.009,
        'dist': 2.0,
        'price': 650.0,
      },
      {
        'name': 'Rotavator',
        'latOff': 0.004,
        'lngOff': -0.007,
        'dist': 2.5,
        'price': 300.0,
      },
      {
        'name': 'Seeder',
        'latOff': -0.009,
        'lngOff': -0.004,
        'dist': 2.2,
        'price': 350.0,
      },
      {
        'name': 'Sprayer',
        'latOff': 0.006,
        'lngOff': 0.008,
        'dist': 1.8,
        'price': 250.0,
      },
    ];

    for (int i = 0; i < mockData.length; i++) {
      final data = mockData[i];
      final equipLoc = LatLng(
        uLat + (data['latOff'] as double),
        uLng + (data['lngOff'] as double),
      );

      // We fallback to a generic image if we can't find a matching one in dummy data
      String imageUrl = '';
      if (dummyEquipment.isNotEmpty) {
        imageUrl = dummyEquipment.first.imageUrl;
        for (var e in dummyEquipment) {
          if (e.name.contains(data['name'] as String)) {
            imageUrl = e.imageUrl;
            break;
          }
        }
      }

      final mappedEquip = Equipment(
        id: 'nearby_$i',
        name: data['name'] as String,
        pricePerHour: data['price'] as double,
        distance: data['dist'] as double,
        rating: 4.8,
        reviewCount: 15,
        imageUrl: imageUrl,
        ownerName: 'Local Farmer',
        description:
            'Great condition ${data['name']} available for immediate pickup.',
        locationName: 'Local Farm',
        latitude: equipLoc.latitude,
        longitude: equipLoc.longitude,
        isAvailable: true,
        purchasePrice: (data['price'] as double) * 1000,
      );

      _nearbyItems.add(
        _MapEquipment(
          equipment: mappedEquip,
          location: equipLoc,
          distanceKm: data['dist'] as double,
        ),
      );
    }
  }

  void _recenter() {
    _mapController.move(widget.userLocation, 14.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Stack(
        children: [
          // ── MAP LAYER ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.userLocation,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.agroshare.app',
              ),
              MarkerLayer(
                markers: [
                  // User Location Marker
                  Marker(
                    point: widget.userLocation,
                    width: 100,
                    height: 50,
                    alignment: Alignment.topCenter,
                    child: const _UserMarker(),
                  ),

                  // Equipment Markers
                  ..._nearbyItems.map(
                    (item) => Marker(
                      point: item.location,
                      width: 130,
                      height: 60,
                      alignment: Alignment.topCenter,
                      child: _EquipmentMarker(
                        item: item,
                        onTap: () =>
                            showEquipmentActionSheet(context, item.equipment),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── HEADER OVERLAY ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildMapHeader(context),
          ),

          // ── RECENTER FAB ──
          Positioned(
            bottom: AppSpacing.xl,
            right: AppSpacing.lg,
            child: FloatingActionButton.extended(
              onPressed: _recenter,
              backgroundColor: AppColors.primaryGreen,
              icon: const Icon(
                Icons.my_location_rounded,
                color: AppColors.textLight,
              ),
              label: Text(
                'Recenter Map',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.sm,
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.textDark.withAlpha(200),
            AppColors.textDark.withAlpha(100),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textDark,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nearby Equipment',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textLight,
                    shadows: [
                      const Shadow(color: Colors.black45, blurRadius: 4),
                    ],
                  ),
                ),
                Text(
                  'Machines available within 3 km of your farm.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textLight.withAlpha(230),
                    shadows: [
                      const Shadow(color: Colors.black45, blurRadius: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// USER MARKER
// ─────────────────────────────────────────────

class _UserMarker extends StatelessWidget {
  const _UserMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade600,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade900.withAlpha(80),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'You are here',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.blue.shade500,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade500.withAlpha(100),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// EQUIPMENT MARKER
// ─────────────────────────────────────────────

class _EquipmentMarker extends StatelessWidget {
  const _EquipmentMarker({required this.item, required this.onTap});

  final _MapEquipment item;
  final VoidCallback onTap;

  IconData get _icon {
    final n = item.equipment.name;
    if (n.contains('Tractor')) return Icons.agriculture_rounded;
    if (n.contains('Harvester')) return Icons.grass_rounded;
    if (n.contains('Pump')) return Icons.water_drop_rounded;
    if (n.contains('Rotavator')) return Icons.settings_rounded;
    if (n.contains('Drill')) return Icons.eco_rounded;
    return Icons.agriculture_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bubble
          AgCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryGreen.withAlpha(35),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(_icon, size: 14, color: AppColors.primaryGreen),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.equipment.name.split(' ').take(2).join(' '),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        '${item.distanceKm} km away',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Connector line/pin
          Container(width: 2, height: 10, color: AppColors.primaryGreen),
          // Dot on exact location
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withAlpha(100),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
