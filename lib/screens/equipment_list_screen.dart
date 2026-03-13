import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/equipment_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/equipment_card.dart';
import 'equipment_detail_screen.dart';

/// Scrollable marketplace screen listing available farm equipment.
class EquipmentListScreen extends StatelessWidget {
  const EquipmentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Equipment Marketplace',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.textLight,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: dummyEquipment.length,
        itemBuilder: (context, index) {
          final item = dummyEquipment[index];
          return EquipmentCard(
            equipment: item,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EquipmentDetailScreen(equipment: item),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
