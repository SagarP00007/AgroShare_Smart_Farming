import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/equipment.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_card.dart';
import '../widgets/section_title.dart';
import 'main_shell.dart';

/// Full-featured equipment discovery screen with map, search, filters,
/// seasonal suggestions, recommendation engine, and equipment list.
class FindEquipmentScreen extends StatefulWidget {
  const FindEquipmentScreen({super.key});

  @override
  State<FindEquipmentScreen> createState() => _FindEquipmentScreenState();
}

class _FindEquipmentScreenState extends State<FindEquipmentScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  String? _selectedCrop;
  String? _selectedTask;

  LatLng _userLocation = const LatLng(
    LocationService.defaultLat,
    LocationService.defaultLng,
  );

  final MapController _mapController = MapController();
  bool _isLoadingLocation = true;
  bool _isRefreshingLocation = false;
  static const double _mapZoom = 13.0;

  static const _crops = ['Rice', 'Wheat', 'Sugarcane', 'Vegetables'];
  static const _tasks = ['Plowing', 'Harvesting', 'Irrigation', 'Seeding'];

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  /// Fetches real-time GPS position when the map screen loads (no cache).
  Future<void> _loadLocation() async {
    setState(() => _isLoadingLocation = true);
    LocationService.instance.invalidateCache();
    final loc = await LocationService.instance.getCurrentLocationRealtime();
    if (!mounted) return;
    setState(() {
      _userLocation = loc;
      _isLoadingLocation = false;
    });
    _mapController.move(loc, _mapZoom);
  }

  /// Real-time location refresh (e.g. when user taps "My location").
  Future<void> _refreshLocationAndCenter() async {
    if (_isRefreshingLocation) return;
    setState(() => _isRefreshingLocation = true);
    try {
      final loc = await LocationService.instance.getCurrentLocationRealtime();
      if (!mounted) return;
      setState(() {
        _userLocation = loc;
        _isRefreshingLocation = false;
      });
      _mapController.move(loc, _mapZoom);
    } catch (_) {
      if (mounted) setState(() => _isRefreshingLocation = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Find Equipment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MainShell()),
              (route) => false,
            );
          },
        ),
      ),
      body: Column(
        children: [
          // ── Search & filters (fixed at top) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _buildSearch(),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildFilters(),
          const SizedBox(height: AppSpacing.sm),
          // ── Map + list from Firestore (single stream) ──
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirestoreService.instance.equipmentStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load equipment.',
                      style: GoogleFonts.poppins(color: Colors.redAccent),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Loading map & equipment…',
                          style: GoogleFonts.poppins(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                var equipment = docs
                    .map((d) => Equipment.fromMap(
                          d.id,
                          d.data() as Map<String, dynamic>,
                        ))
                    .where((e) => e.isAvailable)
                    .toList();

                if (_searchQuery.isNotEmpty) {
                  equipment = equipment
                      .where((e) => e.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList();
                }
                if (_selectedTask != null) {
                  final taskMap = {
                    'Plowing': ['Tractor', 'Rotavator'],
                    'Harvesting': ['Harvester', 'Sprayer'],
                    'Irrigation': ['Pump', 'Irrigation'],
                    'Seeding': ['Drill', 'Seed'],
                  };
                  final keywords = taskMap[_selectedTask] ?? [];
                  equipment = equipment
                      .where((e) => keywords.any(
                            (k) =>
                                e.name.toLowerCase().contains(k.toLowerCase()),
                          ))
                      .toList();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Map (Google Maps, real equipment markers from Firestore)
                    Expanded(
                      flex: 2,
                      child: _buildMap(equipment),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Equipment list
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: SectionTitle(
                        title: 'Available Equipment',
                        trailing: Text(
                          '${equipment.length} machines',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.sm),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: equipment.isEmpty
                          ? Center(
                              child: Text(
                                'No equipment matches your criteria.',
                                style: GoogleFonts.poppins(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              itemCount: equipment.length,
                              itemBuilder: (context, index) {
                                final item = equipment[index];
                                return _FirestoreEquipmentCard(
                                  equipment: item,
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── MAP (Leaflet-style via flutter_map + OSM, real-time location, Firestore markers) ──
  Widget _buildMap(List<Equipment> equipment) {
    final userMarker = Marker(
      point: _userLocation,
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade600,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withAlpha(80),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
      ),
    );

    final equipmentMarkers = <Marker>[
      for (final e in equipment)
        if (e.latitude != 0.0 || e.longitude != 0.0)
          Marker(
            point: LatLng(e.latitude, e.longitude),
            width: 32,
            height: 32,
            child: Tooltip(
              message: '${e.name}\n₹${e.pricePerHour.toInt()}/hr • ${e.locationName}',
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.agriculture_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(20),
        bottom: Radius.circular(12),
      ),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _userLocation,
              initialZoom: _mapZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.agroshare',
              ),
              MarkerLayer(
                markers: [userMarker, ...equipmentMarkers],
              ),
            ],
            mapController: _mapController,
          ),
          if (_isLoadingLocation)
            const Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Getting location…'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: InkWell(
                onTap: _isRefreshingLocation ? null : _refreshLocationAndCenter,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: _isRefreshingLocation
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryGreen,
                          ),
                        )
                      : Icon(
                          Icons.my_location_rounded,
                          color: AppColors.primaryGreen,
                          size: 26,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SEARCH ──
  Widget _buildSearch() {
    return AgCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search equipment (tractor, harvester, pump...)',
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
          border: InputBorder.none,
          icon: const Icon(Icons.search_rounded, color: AppColors.primaryGreen),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
        style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
      ),
    );
  }

  // ── FILTERS ──
  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'Filter by Task',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              _buildFilterChip('All', _selectedTask == null, () {
                setState(() => _selectedTask = null);
              }),
              ..._tasks.map((task) => _buildFilterChip(
                    task,
                    _selectedTask == task,
                    () => setState(() => _selectedTask = task),
                  )),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'Filter by Crop',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              _buildFilterChip('All', _selectedCrop == null, () {
                setState(() => _selectedCrop = null);
              }),
              ..._crops.map((crop) => _buildFilterChip(
                    crop,
                    _selectedCrop == crop,
                    () => setState(() => _selectedCrop = crop),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryGreen : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primaryGreen : AppColors.divider,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primaryGreen.withAlpha(40),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }

}

/// Card widget for equipment loaded from Firestore.
class _FirestoreEquipmentCard extends StatelessWidget {
  const _FirestoreEquipmentCard({required this.equipment});

  final Equipment equipment;

  static const _imageHeight = 140.0;
  static const _radius = 12.0;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        equipment.imageUrl.isNotEmpty && equipment.imageUrl.startsWith('http');

    return AgCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(_radius),
              ),
              child: SizedBox(
                height: _imageHeight,
                width: double.infinity,
                child: Image.network(
                  equipment.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: _imageHeight,
                      color: AppColors.secondaryGreen.withAlpha(20),
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryGreen,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => _placeholder(),
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(_radius),
              ),
              child: _placeholder(),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  equipment.name,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  equipment.locationName,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₹${equipment.pricePerHour.toInt()}/hr',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Text('•'),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Colors.amber.shade600,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      equipment.rating.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: equipment.isRent ? () {} : null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: equipment.isRent
                                ? AppColors.primaryGreen
                                : AppColors.divider,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                        ),
                        child: Text(
                          'Borrow',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: equipment.isRent
                                ? AppColors.primaryGreen
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: equipment.isSell ? () {} : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: equipment.isSell
                              ? AppColors.primaryGreen
                              : AppColors.divider,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                        ),
                        child: Text(
                          'Buy',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: _imageHeight,
      color: AppColors.secondaryGreen.withAlpha(20),
      child: const Icon(
        Icons.camera_alt_rounded,
        size: 48,
        color: AppColors.primaryGreen,
      ),
    );
  }
}
