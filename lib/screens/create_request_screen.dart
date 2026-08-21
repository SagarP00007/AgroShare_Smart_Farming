import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_button.dart';
import '../widgets/ag_card.dart';
import '../widgets/section_title.dart';

/// Form screen for farmers to post a new equipment request.
class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  String? _selectedEquipmentType;
  final _taskCropCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  int _durationHours = 4;
  bool _isSubmitting = false;

  static const _equipmentTypes = [
    'Mahindra Tractor 575 DI',
    'Tractor (45+ HP)',
    'Mini Harvester',
    'Rotavator',
    'Seed Drill Machine',
    'Irrigation Pump Set',
    'Power Tiller',
    'Crop Sprayer',
    'Land Leveler',
    'Paddy Thresher',
  ];

  @override
  void dispose() {
    _taskCropCtrl.dispose();
    _locationCtrl.dispose();
    _budgetCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppColors.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppColors.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _submitRequest() async {
    if (_selectedEquipmentType == null) {
      _showError('Please select required equipment type');
      return;
    }
    if (_taskCropCtrl.text.trim().isEmpty) {
      _showError('Please specify farming task/crop');
      return;
    }
    if (_locationCtrl.text.trim().isEmpty) {
      _showError('Please enter location');
      return;
    }
    if (_budgetCtrl.text.trim().isEmpty) {
      _showError('Please enter your max hourly budget');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = AuthService.instance.currentUser;
      final uid = user?.uid ?? 'farmer_demo';
      String requesterName = 'Farmer';

      if (user != null) {
        try {
          final userDoc = await FirestoreService.instance.getUser(uid);
          final userData = userDoc.data() as Map<String, dynamic>? ?? {};
          requesterName = userData['name'] ?? 'Farmer';
        } catch (_) {}
      }

      double latitude = LocationService.defaultLat;
      double longitude = LocationService.defaultLng;

      try {
        final locText = _locationCtrl.text.trim();
        if (locText.isNotEmpty) {
          final locations = await locationFromAddress(locText);
          if (locations.isNotEmpty) {
            latitude = locations.first.latitude;
            longitude = locations.first.longitude;
          }
        }
      } catch (_) {
        try {
          final pos = await LocationService.instance.getFastLocation();
          latitude = pos.latitude;
          longitude = pos.longitude;
        } catch (_) {}
      }

      final reqDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await FirestoreService.instance.createEquipmentRequest({
        'requesterId': uid,
        'requesterName': requesterName,
        'equipmentType': _selectedEquipmentType!,
        'taskCrop': _taskCropCtrl.text.trim(),
        'requiredDate': Timestamp.fromDate(reqDateTime),
        'durationHours': _durationHours,
        'locationName': _locationCtrl.text.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'maxBudgetPerHour': double.tryParse(_budgetCtrl.text.trim()) ?? 0,
        'description': _descCtrl.text.trim(),
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'responseCount': 0,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Equipment Request posted! Owners nearby will be notified.',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showError('Failed to post request: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dateStr =
        '${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year}';
    final timeStr = _selectedTime.format(context);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Post Equipment Request',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.textLight,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              AgCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withAlpha(20),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.mark_unread_chat_alt_rounded,
                        color: AppColors.primaryGreen,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Request Equipment You Need',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Post your task, location & budget. Machinery owners nearby will offer their equipment.',
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
              ),

              const SizedBox(height: AppSpacing.lg),

              // Form fields
              const SectionTitle(
                title: 'Request Details',
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
              ),
              AgCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    // Equipment Type
                    DropdownButtonFormField<String>(
                      initialValue: _selectedEquipmentType,
                      decoration: InputDecoration(
                        labelText: 'Equipment Type Needed',
                        labelStyle: GoogleFonts.poppins(
                          color: AppColors.textMuted,
                        ),
                        prefixIcon: const Icon(
                          Icons.category_rounded,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      items: _equipmentTypes
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(
                                t,
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedEquipmentType = v),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Task / Crop
                    TextField(
                      controller: _taskCropCtrl,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Farming Task / Crop',
                        hintText: 'e.g. Wheat Plowing, Paddy Harvesting',
                        hintStyle: GoogleFonts.poppins(
                          color: AppColors.textMuted.withAlpha(120),
                        ),
                        labelStyle: GoogleFonts.poppins(
                          color: AppColors.textMuted,
                        ),
                        prefixIcon: const Icon(
                          Icons.eco_rounded,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Max Budget per hour
                    TextField(
                      controller: _budgetCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Max Budget Per Hour (₹)',
                        hintText: 'e.g. 500',
                        hintStyle: GoogleFonts.poppins(
                          color: AppColors.textMuted.withAlpha(120),
                        ),
                        labelStyle: GoogleFonts.poppins(
                          color: AppColors.textMuted,
                        ),
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
                        labelText: 'Location / Farm Address',
                        hintText: 'e.g. Angondhalli, Mandya',
                        hintStyle: GoogleFonts.poppins(
                          color: AppColors.textMuted.withAlpha(120),
                        ),
                        labelStyle: GoogleFonts.poppins(
                          color: AppColors.textMuted,
                        ),
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Date & Schedule
              const SectionTitle(
                title: 'Schedule & Duration',
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
              ),
              AgCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 20,
                                  color: AppColors.primaryGreen,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Required Date',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                Text(
                                  dateStr,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 44,
                          color: AppColors.divider,
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: _pickTime,
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 20,
                                  color: AppColors.primaryGreen,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Start Time',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                Text(
                                  timeStr,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: AppSpacing.md),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Duration (Hours):',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _durationHours > 1
                                  ? () => setState(() => _durationHours--)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                              color: AppColors.primaryGreen,
                            ),
                            Text(
                              '$_durationHours hrs',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _durationHours++),
                              icon: const Icon(Icons.add_circle_outline),
                              color: AppColors.primaryGreen,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Description
              const SectionTitle(
                title: 'Additional Notes',
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
              ),
              AgCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText:
                        'e.g. Need 45+ HP tractor with rotavator attachment for 5 acres field.',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              _isSubmitting
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGreen,
                      ),
                    )
                  : AgButton(
                      label: 'Post Equipment Request',
                      icon: Icons.send_rounded,
                      isExpanded: true,
                      onPressed: _submitRequest,
                    ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
