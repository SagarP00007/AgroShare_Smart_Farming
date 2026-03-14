import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/image_picker_util.dart';
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

  // Equipment photo: local file and Firebase Storage URL after upload
  File? _selectedImageFile;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;

  // Listing type
  String _listingType = 'rent';
  final _sellingPriceCtrl = TextEditingController();

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

  void _addEquipment() async {
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

    try {
      final uid = AuthService.instance.uid;
      final userDoc = await FirestoreService.instance.getUser(uid);
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};

      await FirestoreService.instance.addEquipment({
        'name': _selectedEquipment!,
        // Core fields required by spec.
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0,
        'location': _locationCtrl.text.trim(),
        'ownerId': uid,
        'listingType': _listingType,
        'isAvailable': true,
        'imageUrl': _uploadedImageUrl ?? '',

        // Existing fields used elsewhere in the app.
        'pricePerHour': double.tryParse(_priceCtrl.text.trim()) ?? 0,
        'distance': 0.0,
        'rating': 0.0,
        'reviewCount': 0,
        'ownerName': userData['name'] ?? 'Unknown',
        'description': _descCtrl.text.trim(),
        'locationName': _locationCtrl.text.trim(),
        'latitude': 0.0,
        'longitude': 0.0,
        'purchasePrice': double.tryParse(_sellingPriceCtrl.text.trim()) ?? 0,
        'condition': _selectedCondition!,
        'fuelIncluded': _fuelIncluded,
        'driverIncluded': _driverIncluded,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // Reset form
      setState(() {
        _selectedEquipment = null;
        _selectedCondition = null;
        _descCtrl.clear();
        _priceCtrl.clear();
        _locationCtrl.clear();
        _serviceAreaCtrl.clear();
        _sellingPriceCtrl.clear();
        _fuelIncluded = false;
        _driverIncluded = false;
        _selectedImageFile = null;
        _uploadedImageUrl = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Equipment listed successfully.',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to list equipment: $e');
    }
  }

  Future<void> _pickAndUploadImage() async {
    final file = await pickImageFromSource(context);
    if (file == null || !mounted) return;
    setState(() {
      _selectedImageFile = file;
      _isUploadingImage = true;
    });
    try {
      final url = await StorageService.instance.uploadEquipmentImage(file);
      if (!mounted) return;
      setState(() {
        _uploadedImageUrl = url;
        _isUploadingImage = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      _showError('Upload failed: $e');
    }
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
                label: 'ADD EQUIPMENT',
                icon: Icons.add_circle_outline_rounded,
                isExpanded: true,
                onPressed: _addEquipment,
              ),
              const SizedBox(height: AppSpacing.xl),
              _buildMyListings(),
              const SizedBox(height: AppSpacing.xxl),
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
                value: _selectedEquipment,
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
            value: _selectedCondition,
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
    final hasImage =
        (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty) ||
            _selectedImageFile != null;

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
          onTap: _isUploadingImage ? null : _pickAndUploadImage,
          child: hasImage
              ? Column(
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      child: SizedBox(
                        height: 140,
                        width: double.infinity,
                        child: _uploadedImageUrl != null &&
                                _uploadedImageUrl!.isNotEmpty
                            ? Image.network(
                                _uploadedImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _placeholder(),
                              )
                            : _selectedImageFile != null
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(
                                        _selectedImageFile!,
                                        fit: BoxFit.cover,
                                      ),
                                      if (_isUploadingImage)
                                        Container(
                                          color: Colors.black26,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: AppColors.primaryGreen,
                                            ),
                                          ),
                                        ),
                                    ],
                                  )
                                : _placeholder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _uploadedImageUrl != null &&
                              _uploadedImageUrl!.isNotEmpty
                          ? 'Photo uploaded ✓'
                          : _isUploadingImage
                              ? 'Uploading…'
                              : 'Photo uploaded ✓',
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
                        Icons.add_photo_alternate_rounded,
                        size: 30,
                        color: AppColors.primaryGreen.withAlpha(150),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Add Equipment Photo',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Take Photo or Choose From Gallery',
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

  Widget _placeholder() {
    return Container(
      height: 140,
      color: AppColors.secondaryGreen.withAlpha(20),
      child: const Icon(
        Icons.image_rounded,
        size: 48,
        color: AppColors.primaryGreen,
      ),
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
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'My Listed Equipment',
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirestoreService.instance.userEquipmentStream(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: CircularProgressIndicator(color: AppColors.primaryGreen),
                ),
              );
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return AgCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: Text(
                    'No equipment listed yet.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return AgCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryGreen.withAlpha(35),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(
                          Icons.agriculture_rounded,
                          size: 26,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${(data['pricePerHour'] ?? 0).toInt()}/hr  •  ${data['locationName'] ?? ''}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                          (data['isAvailable'] ?? true) ? 'Available' : 'Rented',
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
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
