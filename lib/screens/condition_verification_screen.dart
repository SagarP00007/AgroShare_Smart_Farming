import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/booking.dart';
import '../models/condition_record.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/image_picker_util.dart';
import '../widgets/ag_button.dart';
import '../widgets/ag_card.dart';

/// Screen for recording Pre-Rental or Post-Rental equipment condition inspection.
///
/// Features photo upload to Cloudinary, interactive inspection checklist,
/// condition notes, loading states, and Firestore save.
class ConditionVerificationScreen extends StatefulWidget {
  const ConditionVerificationScreen({
    super.key,
    required this.booking,
    required this.stage, // 'pre' or 'post'
    this.onCompleted,
  });

  final Booking booking;
  final String stage;
  final VoidCallback? onCompleted;

  @override
  State<ConditionVerificationScreen> createState() =>
      _ConditionVerificationScreenState();
}

class _ConditionVerificationScreenState
    extends State<ConditionVerificationScreen> {
  final List<File> _localPhotos = [];
  final List<String> _uploadedUrls = [];
  final _notesCtrl = TextEditingController();
  late Map<String, bool> _checklist;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _checklist = ConditionRecord.defaultChecklist();

    // If pre-existing condition record exists (for pre stage)
    if (widget.stage == 'pre' && widget.booking.preCondition != null) {
      _uploadedUrls.addAll(widget.booking.preCondition!.photos);
      _notesCtrl.text = widget.booking.preCondition!.notes;
      _checklist = Map.from(widget.booking.preCondition!.checklist);
    } else if (widget.stage == 'post' && widget.booking.postCondition != null) {
      _uploadedUrls.addAll(widget.booking.postCondition!.photos);
      _notesCtrl.text = widget.booking.postCondition!.notes;
      _checklist = Map.from(widget.booking.postCondition!.checklist);
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await pickImageFromSource(context);
    if (file != null) {
      setState(() {
        _localPhotos.add(file);
      });
    }
  }

  Future<void> _saveVerification() async {
    if (_localPhotos.isEmpty && _uploadedUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please capture at least 1 equipment condition photo.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final uid = AuthService.instance.currentUser?.uid ?? 'inspector';

      // 1. Upload local photos to Cloudinary
      for (final photo in _localPhotos) {
        final url = await StorageService.instance.uploadConditionImage(
          photo,
          widget.booking.id,
          widget.stage,
        );
        _uploadedUrls.add(url);
      }

      // 2. Create ConditionRecord
      final record = ConditionRecord(
        photos: _uploadedUrls,
        notes: _notesCtrl.text.trim(),
        checklist: _checklist,
        timestamp: DateTime.now(),
        verifiedBy: uid,
        stage: widget.stage,
      );

      // 3. Save to Firestore
      if (widget.stage == 'pre') {
        await FirestoreService.instance.savePreConditionVerification(
          widget.booking.id,
          record.toMap(),
        );
      } else {
        await FirestoreService.instance.savePostConditionVerification(
          widget.booking.id,
          record.toMap(),
        );
      }

      if (!mounted) return;
      setState(() => _isUploading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.stage == 'pre'
                ? 'Pre-rental condition verified! Rental is now active.'
                : 'Post-rental condition record saved.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.primaryGreen,
        ),
      );

      if (widget.onCompleted != null) {
        widget.onCompleted!();
      } else {
        Navigator.pop(context, record);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification save failed: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleLabel = widget.stage == 'pre'
        ? 'Pre-Rental Inspection'
        : 'Post-Rental Inspection';

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          titleLabel,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.textLight,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Info
                    AgCard(
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.fact_check_rounded,
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
                                  widget.booking.equipmentName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  widget.stage == 'pre'
                                      ? 'Capture condition before taking delivery'
                                      : 'Inspect machine status prior to return',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Condition Photos Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Equipment Photos',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickPhoto,
                          icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                          label: Text(
                            'Add Photo',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    SizedBox(
                      height: 110,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // Add Photo Button Box
                          InkWell(
                            onTap: _pickPhoto,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            child: Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.only(
                                right: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryGreen.withAlpha(25),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                                border: Border.all(
                                  color: AppColors.primaryGreen.withAlpha(80),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.camera_alt_rounded,
                                    color: AppColors.primaryGreen,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Take Photo',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Local photos
                          ..._localPhotos.map(
                            (file) => Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.only(
                                right: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                                image: DecorationImage(
                                  image: FileImage(file),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),

                          // Cloudinary uploaded photos
                          ..._uploadedUrls.map(
                            (url) => Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.only(
                                right: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                                image: DecorationImage(
                                  image: NetworkImage(url),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Inspection Checklist
                    Text(
                      'Inspection Checklist',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    AgCard(
                      margin: EdgeInsets.zero,
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: _checklist.keys.map((key) {
                          final isChecked = _checklist[key] ?? true;
                          return CheckboxListTile(
                            title: Text(
                              key,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textDark,
                              ),
                            ),
                            value: isChecked,
                            activeColor: AppColors.primaryGreen,
                            onChanged: (val) {
                              setState(() {
                                _checklist[key] = val ?? false;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Inspection Notes
                    Text(
                      'Inspection Notes & Remarks',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    TextField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      style: GoogleFonts.poppins(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: widget.stage == 'pre'
                            ? 'Note any pre-existing scratches, fuel status, or operational remarks...'
                            : 'Note return condition, fuel level, or work completed...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(AppSpacing.md),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),

            // Submit Button Bar
            Container(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.md,
                bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: AgButton(
                label: _isUploading
                    ? 'Uploading Photos...'
                    : (widget.stage == 'pre'
                          ? 'Confirm Pre-Rental Inspection'
                          : 'Submit Post-Rental Inspection'),
                icon: Icons.check_circle_rounded,
                isExpanded: true,
                onPressed: _isUploading ? null : _saveVerification,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
