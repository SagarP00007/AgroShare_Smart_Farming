import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipment.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/equipment_card.dart';
import '../widgets/location_map_modal.dart';
import '../widgets/reactive_helpers.dart';
import 'equipment_detail_screen.dart';

/// Scrollable marketplace screen listing available farm equipment.
/// Real-time data from Firestore with pull-to-refresh and error handling.
class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  Key _streamKey = UniqueKey();

  void _retry() {
    setState(() => _streamKey = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Equipment Marketplace',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.textLight,
        elevation: 0,
      ),
      body: StreamBuilder(
        key: _streamKey,
        stream: FirestoreService.instance.equipmentStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ReactiveErrorView(
              message: 'Failed to load equipment.',
              onRetry: _retry,
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ReactiveLoadingView(message: 'Loading equipment…');
          }

          final docs = snapshot.data?.docs ?? [];
          final equipment = docs
              .map((d) =>
                  Equipment.fromMap(d.id, d.data() as Map<String, dynamic>))
              .where((e) => e.isAvailable)
              .toList();

          if (equipment.isEmpty) {
            return ReactiveEmptyView(
              title: 'No equipment available',
              subtitle: 'Check back later or list your own equipment.',
              icon: Icons.agriculture_rounded,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 400));
            },
            color: AppColors.primaryGreen,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: equipment.length,
              itemBuilder: (context, index) {
                final item = equipment[index];
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
                  onLocationTap: () => showLocationModal(context, item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
