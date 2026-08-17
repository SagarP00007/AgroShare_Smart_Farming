import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_button.dart';
import '../widgets/ag_card.dart';

/// Screen for creating a new equipment group purchase request.
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedEquipment;
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _membersController = TextEditingController();
  final _descriptionController = TextEditingController();

  static const _equipmentOptions = [
    'Tractor',
    'Mini Harvester',
    'Rotavator',
    'Seed Drill',
  ];

  @override
  void dispose() {
    _locationController.dispose();
    _priceController.dispose();
    _membersController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to create a group.')),
        );
        return;
      }
      final uid = user.uid;
      final userDoc = await FirestoreService.instance.getUser(uid);
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};

      final totalPrice =
          double.tryParse(_priceController.text.trim()) ?? 0.0;
      final membersNeeded =
          int.tryParse(_membersController.text.trim()) ?? 5;
      final priceShare =
          membersNeeded > 0 ? totalPrice / membersNeeded : 0.0;

      await FirestoreService.instance.createGroup({
        // New canonical fields as per spec.
        'equipmentName': _selectedEquipment ?? '',
        'location': _locationController.text.trim(),
        'membersNeeded': membersNeeded,
        'currentMembers': 1,
        'priceShare': priceShare,
        'status': 'active',

        // Existing fields kept for backward compatibility with UI.
        'equipmentType': _selectedEquipment ?? '',
        'targetPrice': totalPrice,
        'targetMembers': membersNeeded,
        'description': _descriptionController.text.trim(),
        'createdBy': uid,
        'creatorName': userData['name'] ?? 'Unknown',
        'members': [uid],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Group created successfully.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create group: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Create Equipment Group',
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form card
                AgCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'New Equipment Group',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Fill in the details to start a group purchase.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Equipment Name (dropdown) ──────────────
                      _buildLabel('Equipment Name'),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<String>(
                        value: _selectedEquipment,
                        decoration: _inputDecoration('Select equipment'),
                        items: _equipmentOptions
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedEquipment = value),
                        validator: (value) =>
                            value == null ? 'Please select equipment' : null,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                        dropdownColor: AppColors.cardBackground,
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // ── Location ────────────────────────────────
                      _buildLabel('Location'),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _locationController,
                        decoration: _inputDecoration('e.g. Angondhalli'),
                        style: _fieldTextStyle(),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter a location'
                            : null,
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // ── Total Equipment Price ───────────────────
                      _buildLabel('Total Equipment Price'),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _priceController,
                        decoration: _inputDecoration('e.g. ₹6,00,000'),
                        keyboardType: TextInputType.number,
                        style: _fieldTextStyle(),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter the price'
                            : null,
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // ── Members Needed ──────────────────────────
                      _buildLabel('Members Needed'),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _membersController,
                        decoration: _inputDecoration('e.g. 3'),
                        keyboardType: TextInputType.number,
                        style: _fieldTextStyle(),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter number of members'
                            : null,
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // ── Description ─────────────────────────────
                      _buildLabel('Description'),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: _inputDecoration(
                          'e.g. Need tractor for shared farming use.',
                        ),
                        maxLines: 3,
                        style: _fieldTextStyle(),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter a description'
                            : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Submit Button ──────────────────────────────
                AgButton(
                  label: 'Create Group',
                  icon: Icons.check_circle_outline_rounded,
                  isExpanded: true,
                  onPressed: _handleCreate,
                ),

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: AppColors.textMuted.withAlpha(150),
      ),
      filled: true,
      fillColor: AppColors.lightBackground,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide:
            const BorderSide(color: AppColors.primaryGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  TextStyle _fieldTextStyle() {
    return GoogleFonts.poppins(
      fontSize: 14,
      color: AppColors.textDark,
    );
  }
}
