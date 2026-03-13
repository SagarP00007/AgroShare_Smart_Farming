import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/equipment_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/equipment_card.dart';
import '../widgets/equipment_action_sheet.dart';
import '../widgets/section_title.dart';

/// Shows only equipment with [isAvailable] == true.
class FindEquipmentScreen extends StatelessWidget {
  const FindEquipmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final available =
        dummyEquipment.where((e) => e.isAvailable).toList();

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
        automaticallyImplyLeading: false,
      ),
      body: available.isEmpty
          ? Center(
              child: Text(
                'No available equipment right now.',
                style: GoogleFonts.poppins(color: AppColors.textMuted),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: available.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: SectionTitle(
                      title: 'Available Equipment Near You',
                      trailing: Text(
                        '${available.length} machines',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  );
                }
                final item = available[index - 1];
                return EquipmentCard(
                  equipment: item,
                  onTap: () =>
                      showEquipmentActionSheet(context, item),
                );
              },
            ),
    );
  }
}
