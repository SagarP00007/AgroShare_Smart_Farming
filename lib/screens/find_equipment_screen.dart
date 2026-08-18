import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../l10n/app_localizations.dart';
import '../models/equipment.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/chat_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_card.dart';
import '../widgets/reactive_helpers.dart';
import '../widgets/section_title.dart';
import 'equipment_detail_screen.dart';
import 'chat_screen.dart';
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
  Timer? _searchDebounce;
  bool _showSuggestions = false;
  List<String> _searchSuggestions = [];
  bool _isFilterExpanded = false;

  String? _selectedCrop;
  String? _selectedTask;
  final Key _streamKey = UniqueKey();

  // Equipment search suggestions
  static const List<String> _equipmentSuggestions = [
    'tractor',
    'harvester',
    'pump',
    'sprayer',
    'tiller',
    'plow',
    'cultivator',
    'thresher',
    'seed drill',
    'rotavator',
    'mower',
    'baler',
    'tractor 50hp',
    'tractor 75hp',
    'john deere',
    'mahindra tractor',
    'water pump',
    'diesel pump',
    'electric pump',
    'power tiller',
    'zero tillage',
    'laser land leveler',
    'tractor trolley',
    'disc harrow',
    'mould board plow'
  ];

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

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
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
    } catch (e) {
      if (mounted) setState(() => _isRefreshingLocation = false);
      debugPrint('Location refresh error: $e');
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = value);
        _updateSearchSuggestions(value);
      }
    });
  }

  void _updateSearchSuggestions(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _showSuggestions = false;
        _searchSuggestions = [];
      });
      return;
    }

    final suggestions = _equipmentSuggestions
        .where((suggestion) =>
            suggestion.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();

    setState(() {
      _showSuggestions = suggestions.isNotEmpty;
      _searchSuggestions = suggestions;
    });
  }

  void _selectSuggestion(String suggestion) {
    _searchCtrl.text = suggestion;
    _onSearchChanged(suggestion);
    setState(() => _showSuggestions = false);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          L.tr(context, 'find_equipment'),
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
      body: GestureDetector(
        onTap: () {
          // Close search suggestions when tapping outside
          if (_showSuggestions) {
            setState(() => _showSuggestions = false);
          }
          FocusScope.of(context).unfocus();
        },
        child: Column(
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
                key: _streamKey,
                stream: FirestoreService.instance.equipmentStream(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  var equipment = docs
                      .map((d) => Equipment.fromMap(
                            d.id,
                            d.data() as Map<String, dynamic>,
                          ))
                      .where((e) => e.isAvailable)
                      .toList();

                  if (equipment.isEmpty || snapshot.hasError) {
                    equipment = FirestoreService.instance.getFallbackEquipment();
                  }

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
                              (k) => e.name
                                  .toLowerCase()
                                  .contains(k.toLowerCase()),
                            ))
                        .toList();
                  }

                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(
                        top: AppSpacing.sm, bottom: AppSpacing.xxl),
                    children: [
                      SizedBox(
                        height: 280,
                        child: _buildMap(equipment),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        child: SectionTitle(
                          title: L.tr(context, 'available_equipment'),
                          trailing: Text(
                            '${equipment.length} ${L.tr(context, 'machines')}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        ),
                      ),
                      if (equipment.isEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: ReactiveEmptyView(
                            title: L.tr(context, 'no_equipment_matches'),
                            subtitle: L.tr(context, 'try_changing_filters'),
                            icon: Icons.search_off_rounded,
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: equipment.map((item) {
                              return _FirestoreEquipmentCard(
                                equipment: item,
                                userLocation: _userLocation,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EquipmentDetailScreen(
                                          equipment: item),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── MAP (Modern UI/UX with enhanced markers and interactions) ──
  Widget _buildMap(List<Equipment> equipment) {
    final userMarker = Marker(
      point: _userLocation,
      width: 50,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withAlpha(100),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );

    final equipmentMarkers = <Marker>[
      for (final e in equipment)
        if (e.latitude != 0.0 || e.longitude != 0.0)
          Marker(
            point: LatLng(e.latitude, e.longitude),
            width: 40,
            height: 40,
            child: Tooltip(
              message:
                  '${e.name}\n₹${e.pricePerHour.toInt()}/hr • ${e.locationName}',
              child: GestureDetector(
                onTap: () {
                  // Navigate to equipment detail
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EquipmentDetailScreen(equipment: e),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryGreen,
                        AppColors.secondaryGreen,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withAlpha(80),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Icon(
                        Icons.agriculture_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(24),
        bottom: Radius.circular(16),
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
            mapController: _mapController,
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.agroshare',
              ),
              MarkerLayer(
                markers: [userMarker, ...equipmentMarkers],
              ),
            ],
          ),

          // Modern location loading indicator
          if (_isLoadingLocation)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Getting location…',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Modern location refresh button
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap:
                      _isRefreshingLocation ? null : _refreshLocationAndCenter,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    child: _isRefreshingLocation
                        ? SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
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
          ),

          // Equipment count badge
          if (equipment.isNotEmpty)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.secondaryGreen,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withAlpha(40),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.agriculture_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${equipment.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── SEARCH (debounced 300ms for smooth real-time filtering) ──
  Widget _buildSearch() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AgCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            onTap: () => _updateSearchSuggestions(_searchCtrl.text),
            decoration: InputDecoration(
              hintText: L.tr(context, 'search_placeholder'),
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.primaryGreen,
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onSearchChanged('');
                        setState(() => _showSuggestions = false);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    )
                  : null,
            ),
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
          ),
        ),
        // Search suggestions dropdown with proper constraints
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withAlpha(30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _searchSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _searchSuggestions[index];
                return InkWell(
                  onTap: () => _selectSuggestion(suggestion),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_outlined,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ── FILTERS (Amazon-style dropdown) ──
  Widget _buildFilters() {
    final hasActiveFilters = _selectedTask != null || _selectedCrop != null;

    return Column(
      children: [
        // Amazon-style filter box
        GestureDetector(
          onTap: () {
            setState(() => _isFilterExpanded = !_isFilterExpanded);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasActiveFilters
                    ? AppColors.primaryGreen
                    : AppColors.divider,
                width: hasActiveFilters ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: hasActiveFilters
                      ? AppColors.primaryGreen
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getFilterSummary(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (hasActiveFilters)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${(_selectedTask != null ? 1 : 0) + (_selectedCrop != null ? 1 : 0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      _isFilterExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Expanded filter content
        if (_isFilterExpanded)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter by Task
                  Text(
                    L.tr(context, 'filter_by_task'),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(L.tr(context, 'all'), _selectedTask == null, () {
                        setState(() => _selectedTask = null);
                      }),
                      ..._tasks.map((task) => _buildFilterChip(
                            task,
                            _selectedTask == task,
                            () => setState(() => _selectedTask = task),
                          )),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Filter by Crop
                  Text(
                    L.tr(context, 'filter_by_crop'),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(L.tr(context, 'all'), _selectedCrop == null, () {
                        setState(() => _selectedCrop = null);
                      }),
                      ..._crops.map((crop) => _buildFilterChip(
                            crop,
                            _selectedCrop == crop,
                            () => setState(() => _selectedCrop = crop),
                          )),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Clear filters button
                  if (hasActiveFilters)
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedTask = null;
                            _selectedCrop = null;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        child: Text(
                          'Clear All Filters',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _getFilterSummary() {
    final taskFilter = _selectedTask ?? 'Any Task';
    final cropFilter = _selectedCrop ?? 'Any Crop';
    return '$taskFilter • $cropFilter';
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
  const _FirestoreEquipmentCard({
    required this.equipment,
    this.userLocation,
    this.onTap,
  });

  final Equipment equipment;
  final LatLng? userLocation;
  final VoidCallback? onTap;

  static const _imageHeight = 140.0;
  static const _radius = 12.0;

  Future<void> _startChat(BuildContext context) async {
    try {
      // Get or create chat
      final chatId = await ChatService().getOrCreateChat(
        equipment.id,
        equipment.ownerId,
      );

      if (context.mounted) {
        // Navigate to chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chatId,
              equipmentId: equipment.id,
              equipmentName: equipment.name,
              equipmentImage: equipment.imageUrl,
              ownerId: equipment.ownerId,
              ownerName: equipment.ownerName,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage =
        equipment.imageUrl.isNotEmpty && equipment.imageUrl.startsWith('http');
    final distanceText = equipment.formattedDistance(
      userLocation?.latitude,
      userLocation?.longitude,
    );

    return AgCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.zero,
      onTap: onTap,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        equipment.name,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.near_me_rounded,
                            size: 12,
                            color: AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            distanceText,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                        ),
                        child: Text(
                          equipment.isRent
                              ? L.tr(context, 'borrow_equipment')
                              : L.tr(context, 'buy_equipment'),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withAlpha(15),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () => _startChat(context),
                        icon: Icon(
                          Icons.chat_rounded,
                          color: AppColors.primaryGreen,
                          size: 20,
                        ),
                        tooltip: 'Chat with owner',
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
