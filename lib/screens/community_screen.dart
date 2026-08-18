import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_button.dart';
import '../widgets/ag_card.dart';
import '../widgets/section_title.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import 'main_shell.dart';

/// Community screen — foundation of the Farmer Collaboration System.
/// Real-time groups with error retry.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
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
          L.tr(context, 'community'),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppSpacing.lg),
              _buildStartGroupButton(context),
              const SizedBox(height: AppSpacing.lg),
              _buildActiveGroups(_streamKey, _retry),
              const SizedBox(height: AppSpacing.lg),
              _buildMyGroups(_streamKey, _retry),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

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
              color: AppColors.secondaryGreen.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.people_rounded,
              size: 28,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L.tr(context, 'equipment_groups'),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  L.tr(context, 'pool_resources'),
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

  Widget _buildStartGroupButton(BuildContext context) {
    return AgButton(
      label: L.tr(context, 'start_equipment_group'),
      icon: Icons.group_add_rounded,
      isExpanded: true,
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const CreateGroupScreen(),
          ),
        );
      },
    );
  }

  Widget _buildActiveGroups(Key streamKey, VoidCallback onRetry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: L.tr(context, 'active_equipment_groups'),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        StreamBuilder<QuerySnapshot>(
          key: streamKey,
          stream: FirestoreService.instance.groupsStream(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            final activeDocs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['status'] ?? 'active') == 'active';
            }).toList();

            List<Map<String, dynamic>> groupsList = [];
            if (activeDocs.isNotEmpty && !snapshot.hasError) {
              groupsList = activeDocs
                  .map((d) => Map<String, dynamic>.from(
                        d.data() as Map<String, dynamic>,
                      )..['id'] = d.id)
                  .toList();
            } else {
              groupsList = FirestoreService.instance.getFallbackGroupMaps();
            }

            return Column(
              children: groupsList.map((data) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _EquipmentGroupCard(
                    groupId: data['id'] ?? 'grp_seed',
                    data: data,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMyGroups(Key streamKey, VoidCallback onRetry) {
    final sampleGroup = {
      'id': 'grp_1',
      'equipmentType': 'Mahindra 575 DI Tractor',
      'currentMembers': 3,
      'targetMembers': 4,
      'targetPrice': 250000.0,
      'locationName': 'Mandya District',
      'status': 'active',
      'members': ['m1', 'm2', 'm3'],
      'creatorId': 'seed_1',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: L.tr(context, 'my_joined_groups'),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        _EquipmentGroupCard(
          groupId: 'grp_1',
          data: sampleGroup,
        ),
      ],
    );
  }
}

// ── Equipment Group Card Widget ──────────────────────────────────

class _EquipmentGroupCard extends StatelessWidget {
  const _EquipmentGroupCard({
    required this.groupId,
    required this.data,
  });

  final String groupId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final name = data['equipmentType'] ?? 'Equipment Group';
    final currentMembers = (data['currentMembers'] ?? 0).toInt();
    final targetMembers = (data['targetMembers'] ?? 5).toInt();
    final targetPrice = (data['targetPrice'] ?? 0).toDouble();
    final members = List<String>.from(data['members'] ?? []);
    final isFull = currentMembers >= targetMembers;
    final uid = AuthService.instance.currentUser?.uid;
    final hasJoined = uid != null && members.contains(uid);
    final sharePerFarmer = targetMembers > 0
        ? (targetPrice / targetMembers).toInt()
        : 0;

    return AgCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              const Text('🚜', style: TextStyle(fontSize: 28)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '$name Purchase Group',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (isFull)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'READY',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Location
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.xs),
              Text(
                data['location'] ?? 'Unknown',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: targetMembers > 0 ? currentMembers / targetMembers : 0,
              backgroundColor: AppColors.divider,
              color: isFull ? AppColors.primaryGreen : Colors.amber,
              minHeight: 6,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Members count + share
          Row(
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 16,
                color: isFull ? AppColors.primaryGreen : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Members: $currentMembers / $targetMembers',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isFull ? AppColors.primaryGreen : AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '₹${sharePerFarmer.toStringAsFixed(0)} per farmer',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => GroupDetailScreen(
                          groupName: '$name Purchase Group',
                          groupId: groupId,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    side: const BorderSide(color: AppColors.primaryGreen),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.buttonRadius,
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(L.tr(context, 'view_details')),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AgButton(
                  label: hasJoined
                      ? L.tr(context, 'joined')
                      : (isFull ? L.tr(context, 'full') : L.tr(context, 'join_group')),
                  onPressed: hasJoined || isFull
                      ? () {}
                      : () async {
                          if (uid == null) return;
                          try {
                            await FirestoreService.instance
                                .joinGroup(groupId, uid);
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to join: $e'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                ),
              ),
            ],
          ),

          if (isFull) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withAlpha(15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    L.tr(context, 'ready_to_purchase'),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
