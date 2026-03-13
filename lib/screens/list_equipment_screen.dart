import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_button.dart';
import '../widgets/ag_card.dart';
import '../widgets/section_title.dart';
import 'main_shell.dart';

/// Form screen allowing owners to list their equipment for rent or sale.
class ListEquipmentScreen extends StatefulWidget {
  const ListEquipmentScreen({super.key});

  @override
  State<ListEquipmentScreen> createState() => _ListEquipmentScreenState();
}

class _ListEquipmentScreenState extends State<ListEquipmentScreen> {
  // Form state
  String? _selectedEquipment;
  String? _selectedCondition;
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _serviceAreaCtrl = TextEditingController();

  // Availability
  final _days = {
    'Monday': true,
    'Tuesday': true,
    'Wednesday': true,
    'Thursday': true,
    'Friday': true,
    'Saturday': false,
    'Sunday': false,
  };

  // Rental toggles
  bool _fuelIncluded = false;
  bool _driverIncluded = false;

  // Simulated image
  bool _imageUploaded = false;

  // Listing type
  String _listingType = 'rent';
  final _sellingPriceCtrl = TextEditingController();

  // My listed equipment (in-memory)
  final List<_ListedItem> _myListings = [];

  static const _equipmentTypes = [
    'Tractor',
    'Mini Harvester',
    'Rotavator',
    'Seed Drill',
    'Irrigation Pump',
  ];

  static const _conditions = [
    'Excellent',
    'Good',
    'Average',
    'Needs Service',
  ];

  void _addEquipment() {
    // Validate
    if (_selectedEquipment == null) {
      _showError('Please select equipment type');
      return;
    }
    if (_priceCtrl.text.trim().isEmpty) {
      _showError('Please enter price per hour');
      return;
    }
    if (_locationCtrl.text.trim().isEmpty) {
      _showError('Please enter location');
      return;
    }
    if (_selectedCondition == null) {
      _showError('Please select equipment condition');
      return;
    }

    // Add to listings
    setState(() {
      _myListings.add(_ListedItem(
        name: _selectedEquipment!,
        price: _priceCtrl.text.trim(),
        condition: _selectedCondition!,
        location: _locationCtrl.text.trim(),
        fuelIncluded: _fuelIncluded,
        driverIncluded: _driverIncluded,
        availableDays:
            _days.entries.where((e) => e.value).map((e) => e.key).toList(),
      ));

      // Reset form
      _selectedEquipment = null;
      _selectedCondition = null;
      _descCtrl.clear();
      _priceCtrl.clear();
      _locationCtrl.clear();
      _serviceAreaCtrl.clear();
      _fuelIncluded = false;
      _driverIncluded = false;
      _imageUploaded = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Equipment listed successfully!',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _locationCtrl.dispose();
    _serviceAreaCtrl.dispose();
    _sellingPriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'List Equipment',
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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: AppSpacing.lg),
              _buildListingType(),
              const SizedBox(height: AppSpacing.lg),
              _buildDetailsForm(),
              const SizedBox(height: AppSpacing.lg),
              if (_listingType == 'rent') ...[
                _buildAvailability(),
                const SizedBox(height: AppSpacing.lg),
              ],
              _buildCondition(),
              const SizedBox(height: AppSpacing.lg),
              _buildImageUpload(),
              const SizedBox(height: AppSpacing.lg),
              if (_listingType == 'rent') ...[
                _buildRentalOptions(),
                const SizedBox(height: AppSpacing.lg),
              ],
              AgButton(
                label: 'Add Equipment',
                icon: Icons.add_circle_outline_rounded,
                isExpanded: true,
                onPressed: _addEquipment,
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_myListings.isNotEmpty) ...[
                _buildMyListings(),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── HEADER ──
  Widget _buildHeader() {
    return AgCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.secondaryGreen.withAlpha(35),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(
              Icons.agriculture_rounded,
              size: 30,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'List Your Equipment',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Share your farm machines and earn rental income.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // ── LISTING TYPE ──
  Widget _buildListingType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Listing Type',
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
        ),
        AgCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _buildRadioTile(
                value: 'rent',
                icon: Icons.access_time_rounded,
                label: 'Rent Equipment',
                subtitle: 'Allow others to borrow your machine hourly',
              ),
              const Divider(height: 1, color: AppColors.divider),
              _buildRadioTile(
                value: 'sell',
                icon: Icons.sell_rounded,
                label: 'Sell Equipment',
                subtitle: 'Put your machine up for sale',
              ),
            ],
          ),
        ),
        if (_listingType == 'sell') ...[
          const SizedBox(height: AppSpacing.md),
          AgCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextFormField(
              controller: _sellingPriceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Selling Price (₹)',
                hintText: 'e.g. 250000',
                prefixIcon: const Icon(Icons.currency_rupee_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRadioTile({
    required String value,
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    final isSelected = _listingType == value;
    return InkWell(
      onTap: () => setState(() => _listingType = value),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGreen.withAlpha(20)
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppColors.primaryGreen
                    : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primaryGreen
                          : AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryGreen
                      : AppColors.textMuted,
                  width: 2,
                ),
                color: isSelected
                    ? AppColors.primaryGreen
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── DETAILS FORM ──
  Widget _buildDetailsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Equipment Details',
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
        ),
        AgCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              // Equipment type dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedEquipment,
                decoration: InputDecoration(
                  labelText: 'Equipment Type',
                  labelStyle: GoogleFonts.poppins(color: AppColors.textMuted),
                  prefixIcon: const Icon(
                    Icons.category_rounded,
                    color: AppColors.primaryGreen,
                  ),
                ),
                items: _equipmentTypes
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t, style: GoogleFonts.poppins()),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedEquipment = v),
              ),

              const SizedBox(height: AppSpacing.md),

              // Description
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: GoogleFonts.poppins(color: AppColors.textMuted),
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(
                      Icons.description_rounded,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Price
              TextField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Price Per Hour (₹)',
                  labelStyle: GoogleFonts.poppins(color: AppColors.textMuted),
                  prefixIcon: const Icon(
                    Icons.currency_rupee_rounded,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Location
              TextField(
                controller: _locationCtrl,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g. Angondhalli',
                  hintStyle: GoogleFonts.poppins(color: AppColors.textMuted.withAlpha(100)),
                  labelStyle: GoogleFonts.poppins(color: AppColors.textMuted),
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Service area
              TextField(
                controller: _serviceAreaCtrl,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Service Area',
                  hintText: 'e.g. Within 5 km',
                  hintStyle: GoogleFonts.poppins(color: AppColors.textMuted.withAlpha(100)),
                  labelStyle: GoogleFonts.poppins(color: AppColors.textMuted),
                  prefixIcon: const Icon(
                    Icons.radar_rounded,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── AVAILABILITY ──
  Widget _buildAvailability() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Availability',
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
        ),
        AgCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            children: _days.keys.map((day) {
              return CheckboxListTile(
                value: _days[day],
                onChanged: (v) => setState(() => _days[day] = v ?? false),
                title: Text(
                  day,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
                checkColor: AppColors.textLight,
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primaryGreen;
                  }
                  return null;
                }),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── CONDITION ──
  Widget _buildCondition() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Equipment Condition',
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
        ),
        AgCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedCondition,
            decoration: InputDecoration(
              labelText: 'Condition',
              labelStyle: GoogleFonts.poppins(color: AppColors.textMuted),
              prefixIcon: const Icon(
                Icons.build_circle_outlined,
                color: AppColors.primaryGreen,
              ),
            ),
            items: _conditions
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, style: GoogleFonts.poppins()),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedCondition = v),
          ),
        ),
      ],
    );
  }

  // ── IMAGE UPLOAD ──
  Widget _buildImageUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Equipment Photo',
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
        ),
        AgCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(AppSpacing.lg),
          onTap: () => setState(() => _imageUploaded = true),
          child: _imageUploaded
              ? Column(
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      child: Image.asset(
                        'assets/images/tractor.webp',
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          height: 140,
                          color: AppColors.secondaryGreen.withAlpha(20),
                          child: const Icon(
                            Icons.image_rounded,
                            size: 48,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Photo uploaded ✓',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryGreen.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 30,
                        color: AppColors.primaryGreen.withAlpha(150),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Upload Equipment Photo',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to add a photo of your machine',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ── RENTAL OPTIONS ──
  Widget _buildRentalOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Rental Options',
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
        ),
        AgCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            children: [
              SwitchListTile(
                value: _fuelIncluded,
                onChanged: (v) => setState(() => _fuelIncluded = v),
                title: Text(
                  'Fuel Included',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
                subtitle: Text(
                  'Fuel cost covered in rental price',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                activeTrackColor: AppColors.primaryGreen,
                inactiveTrackColor: AppColors.divider,
                secondary: Icon(
                  Icons.local_gas_station_rounded,
                  color: _fuelIncluded
                      ? AppColors.primaryGreen
                      : AppColors.textMuted,
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              SwitchListTile(
                value: _driverIncluded,
                onChanged: (v) => setState(() => _driverIncluded = v),
                title: Text(
                  'Driver Included',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
                subtitle: Text(
                  'Operator provided with equipment',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                activeTrackColor: AppColors.primaryGreen,
                inactiveTrackColor: AppColors.divider,
                secondary: Icon(
                  Icons.person_pin_rounded,
                  color: _driverIncluded
                      ? AppColors.primaryGreen
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── MY LISTINGS ──
  Widget _buildMyListings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'My Listed Equipment',
          trailing: Text(
            '${_myListings.length} ${_myListings.length == 1 ? 'machine' : 'machines'}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        ),
        ..._myListings.asMap().entries.map((entry) {
          final item = entry.value;
          return _ListedItemCard(item: item);
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// DATA
// ─────────────────────────────────────────────

class _ListedItem {
  const _ListedItem({
    required this.name,
    required this.price,
    required this.condition,
    required this.location,
    required this.fuelIncluded,
    required this.driverIncluded,
    required this.availableDays,
  });

  final String name;
  final String price;
  final String condition;
  final String location;
  final bool fuelIncluded;
  final bool driverIncluded;
  final List<String> availableDays;
}

// ─────────────────────────────────────────────
// LISTED ITEM CARD
// ─────────────────────────────────────────────

class _ListedItemCard extends StatelessWidget {
  const _ListedItemCard({required this.item});

  final _ListedItem item;

  IconData get _icon {
    switch (item.name) {
      case 'Tractor':
        return Icons.agriculture_rounded;
      case 'Mini Harvester':
        return Icons.grass_rounded;
      case 'Irrigation Pump':
        return Icons.water_drop_rounded;
      case 'Rotavator':
        return Icons.settings_rounded;
      case 'Seed Drill':
        return Icons.eco_rounded;
      default:
        return Icons.agriculture_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AgCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.secondaryGreen.withAlpha(35),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(_icon, size: 26, color: AppColors.primaryGreen),
          ),
          const SizedBox(width: AppSpacing.md),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${item.price}/hr  •  ${item.location}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    _tag(item.condition, AppColors.primaryGreen),
                    if (item.fuelIncluded) ...[
                      const SizedBox(width: AppSpacing.xs),
                      _tag('Fuel', Colors.orange),
                    ],
                    if (item.driverIncluded) ...[
                      const SizedBox(width: AppSpacing.xs),
                      _tag('Driver', Colors.blue),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.secondaryGreen.withAlpha(20),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              'Available',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
