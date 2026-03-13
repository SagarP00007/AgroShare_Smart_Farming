import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../data/equipment_data.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_card.dart';
import '../widgets/equipment_action_sheet.dart';
import '../widgets/equipment_card.dart';
import '../widgets/location_map_modal.dart';
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

  // Filters
  String? _selectedCrop;
  String? _selectedTask;

  // Location
  LatLng _userLocation = const LatLng(
    LocationService.defaultLat,
    LocationService.defaultLng,
  );

  static const _crops = ['Rice', 'Wheat', 'Sugarcane', 'Vegetables'];
  static const _tasks = ['Plowing', 'Harvesting', 'Irrigation', 'Seeding'];

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final loc = await LocationService.instance.getFastLocation();
    if (mounted) setState(() => _userLocation = loc);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    // Filter equipment
    var filtered = dummyEquipment.where((e) => e.isAvailable).toList();
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase()))
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
      filtered = filtered
          .where((e) => keywords.any(
                (k) => e.name.toLowerCase().contains(k.toLowerCase()),
              ))
          .toList();
    }

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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── SECTION 1 — Map ──
            _buildMap(),

            const SizedBox(height: AppSpacing.md),

            // ── SECTION 2 — Search ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _buildSearch(),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── SECTION 3 — Filters ──
            _buildFilters(),

            const SizedBox(height: AppSpacing.lg),

            // ── SECTION 6 — Equipment List ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SectionTitle(
                title: 'Available Equipment',
                trailing: Text(
                  '${filtered.length} machines',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              ),
            ),

            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: Text(
                    'No equipment matches your criteria.',
                    style: GoogleFonts.poppins(color: AppColors.textMuted),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  return EquipmentCard(
                    equipment: item,
                    onTap: () => showEquipmentActionSheet(context, item),
                    onLocationTap: () => showLocationModal(context, item),
                  );
                },
              ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  // ── MAP ──
  Widget _buildMap() {
    return SizedBox(
      height: 200,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: _userLocation,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.agroshare.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
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
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              // Dummy equipment markers
              ...List.generate(4, (i) {
                final offsets = [
                  [0.008, 0.005],
                  [-0.006, 0.009],
                  [0.004, -0.007],
                  [-0.009, -0.004],
                ];
                return Marker(
                  point: LatLng(
                    _userLocation.latitude + offsets[i][0],
                    _userLocation.longitude + offsets[i][1],
                  ),
                  width: 30,
                  height: 30,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.agriculture_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                );
              }),
            ],
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
