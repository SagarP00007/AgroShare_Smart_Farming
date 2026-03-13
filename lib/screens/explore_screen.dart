import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/equipment_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_card.dart';
import '../widgets/equipment_card.dart';
import '../widgets/equipment_action_sheet.dart';
import '../widgets/section_title.dart';

/// Explore screen with horizontal "Newly Added" carousel and
/// vertical "All Equipment" list.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Newest items: last 3 added
    final newItems = dummyEquipment.reversed.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Explore Equipment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),

            // ── SECTION 1 — Newly Added ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SectionTitle(
                title: 'Newly Added Equipment',
                trailing: Text(
                  '${newItems.length} new',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              ),
            ),
            SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md),
                itemCount: newItems.length,
                itemBuilder: (context, index) {
                  final item = newItems[index];
                  return _NewEquipmentCard(
                    equipment: item,
                    onTap: () =>
                        showEquipmentActionSheet(context, item),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── SECTION 2 — All Equipment ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SectionTitle(
                title: 'All Equipment',
                trailing: Text(
                  '${dummyEquipment.length} machines',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: dummyEquipment.length,
              itemBuilder: (context, index) {
                final item = dummyEquipment[index];
                return EquipmentCard(
                  equipment: item,
                  onTap: () =>
                      showEquipmentActionSheet(context, item),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HORIZONTAL NEW EQUIPMENT CARD
// ─────────────────────────────────────────────

class _NewEquipmentCard extends StatelessWidget {
  const _NewEquipmentCard({
    required this.equipment,
    required this.onTap,
  });

  final dynamic equipment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        child: AgCard(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusMd),
                ),
                child: SizedBox(
                  height: 100,
                  child: Image.asset(
                    equipment.imageUrl as String,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(
                      color: AppColors.secondaryGreen.withAlpha(20),
                      child: const Icon(
                        Icons.agriculture_rounded,
                        color: AppColors.primaryGreen,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipment.name as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '₹${(equipment.pricePerHour as double).toInt()}/hr',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          equipment.rating.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (equipment.isAvailable as bool)
                            ? AppColors.secondaryGreen.withAlpha(20)
                            : Colors.grey.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (equipment.isAvailable as bool)
                            ? 'Available'
                            : 'Unavailable',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: (equipment.isAvailable as bool)
                              ? AppColors.primaryGreen
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
