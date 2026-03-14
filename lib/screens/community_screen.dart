import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_button.dart';
import '../widgets/ag_card.dart';
import '../widgets/reactive_helpers.dart';
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
          'Community',
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
                  'Equipment Groups',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pool resources to buy expensive farm machinery together.',
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
      label: 'Start Equipment Group',
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
        const SectionTitle(
          title: 'Active Equipment Groups',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        StreamBuilder<QuerySnapshot>(
          key: streamKey,
          stream: FirestoreService.instance.groupsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ReactiveErrorView(
                message: 'Failed to load groups.',
                onRetry: onRetry,
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: ReactiveLoadingView(message: 'Loading groups…'),
              );
            }
            final docs = snapshot.data?.docs ?? [];
            final activeDocs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['status'] ?? 'active') == 'active';
            }).toList();
            if (activeDocs.isEmpty) {
              return AgCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.group_off_rounded,
                        size: 40,
                        color: AppColors.textMuted.withAlpha(120),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No active groups yet. Start one above!',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: activeDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _EquipmentGroupCard(
                    groupId: doc.id,
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
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'My Groups',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        StreamBuilder<QuerySnapshot>(
          key: streamKey,
          stream: FirestoreService.instance.groupsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ReactiveErrorView(
                message: 'Failed to load groups.',
                onRetry: onRetry,
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: ReactiveLoadingView(message: 'Loading groups…'),
              );
            }
            final docs = snapshot.data?.docs ?? [];
            final myDocs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final members = List<String>.from(data['members'] ?? []);
              return members.contains(uid);
            }).toList();

            if (myDocs.isEmpty) {
              return AgCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.group_off_rounded,
                        size: 40,
                        color: AppColors.textMuted.withAlpha(120),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        "You haven't joined any groups yet.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: myDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _EquipmentGroupCard(
                    groupId: doc.id,
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
                  child: const Text('View Details'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AgButton(
                  label: hasJoined ? 'Joined ✓' : (isFull ? 'Full' : 'Join Group'),
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
                    'Ready to Purchase!',
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
