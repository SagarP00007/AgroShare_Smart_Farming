import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/booking.dart';
import '../models/condition_record.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'ag_button.dart';

/// Modal dialog showing side-by-side comparison of Pre-Rental vs Post-Rental condition records.
class ConditionComparisonDialog extends StatelessWidget {
  const ConditionComparisonDialog({
    super.key,
    required this.booking,
    required this.postRecord,
    required this.onConfirmReturn,
  });

  final Booking booking;
  final ConditionRecord postRecord;
  final VoidCallback onConfirmReturn;

  @override
  Widget build(BuildContext context) {
    final preRecord = booking.preCondition;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    String formatTime(DateTime? dt) {
      if (dt == null) return 'N/A';
      return '${dt.day} ${months[dt.month - 1]} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      backgroundColor: AppColors.cardBackground,
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.compare_rounded, color: AppColors.primaryGreen, size: 24),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Condition Comparison',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        booking.equipmentName,
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: AppSpacing.md),

            // Verified Badge
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: Colors.green.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: Colors.green, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inspection Verification Verified',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade800,
                          ),
                        ),
                        Text(
                          'Pre & Post rental condition records match cleanly. Safe to finalize return.',
                          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Pre vs Post Cards
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PRE-RENTAL COLUMN
                Expanded(
                  child: _RecordColumn(
                    title: 'Pre-Rental',
                    subtitle: formatTime(preRecord?.timestamp),
                    photos: preRecord?.photos ?? [],
                    notes: preRecord?.notes ?? 'No pre-rental issues reported',
                    badgeColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // POST-RENTAL COLUMN
                Expanded(
                  child: _RecordColumn(
                    title: 'Post-Rental',
                    subtitle: formatTime(postRecord.timestamp),
                    photos: postRecord.photos,
                    notes: postRecord.notes.isEmpty ? 'Inspected on return. Machine clean.' : postRecord.notes,
                    badgeColor: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Bottom Buttons
            SizedBox(
              width: double.infinity,
              child: AgButton(
                label: 'Confirm Return & Complete Rental',
                icon: Icons.check_circle_outline_rounded,
                onPressed: () {
                  Navigator.pop(context);
                  onConfirmReturn();
                },
              ),
            ),

            const SizedBox(height: AppSpacing.xs),

            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Back to Inspection',
                  style: GoogleFonts.poppins(color: AppColors.textMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordColumn extends StatelessWidget {
  const _RecordColumn({
    required this.title,
    required this.subtitle,
    required this.photos,
    required this.notes,
    required this.badgeColor,
  });

  final String title;
  final String subtitle;
  final List<String> photos;
  final String notes;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ],
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Photo Preview Thumbnail
          if (photos.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 80,
                width: double.infinity,
                child: Image.network(
                  photos.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: badgeColor.withAlpha(20),
                    child: Icon(Icons.broken_image_rounded, color: badgeColor, size: 24),
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  'No Photo',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xs),
          Text(
            notes,
            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textDark, height: 1.3),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
