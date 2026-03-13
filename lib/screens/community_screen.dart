import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/farmer_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_button.dart';
import '../widgets/ag_card.dart';
import '../widgets/section_title.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import 'main_shell.dart';

/// Community screen — foundation of the Farmer Collaboration System.
///
/// Displays active equipment groups, lets farmers start new groups,
/// and shows a "My Groups" section for tracking joined groups.
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

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
              // ── Section 1: Page Header ──────────────────────────
              _buildHeader(),

              const SizedBox(height: AppSpacing.lg),

              // ── Section 2: Start Equipment Group ────────────────
              _buildStartGroupButton(context),

              const SizedBox(height: AppSpacing.lg),

              // ── Section 3: Active Equipment Groups ──────────────
              _buildActiveGroups(),

              const SizedBox(height: AppSpacing.lg),

              // ── Section 4: My Groups ────────────────────────────
              _buildMyGroups(),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section 1 ──────────────────────────────────────────────────

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
                  'Farmer Community',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Connect with farmers to share or buy equipment together.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
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

  // ── Section 2 ──────────────────────────────────────────────────

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

  // ── Section 3 ──────────────────────────────────────────────────

  Widget _buildActiveGroups() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Active Equipment Groups',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        _EquipmentGroupCard(
          emoji: '🚜',
          name: 'Tractor Purchase Group',
          location: 'Angondhalli',
          initialMembers: 2,
          targetMembers: 3,
          sharePerFarmer: '₹2,00,000',
          members: const ['Ramesh', 'Kiran'],
        ),
        const SizedBox(height: AppSpacing.md),
        _EquipmentGroupCard(
          emoji: '🌾',
          name: 'Harvester Sharing Group',
          location: 'Hubballi',
          initialMembers: 1,
          targetMembers: 4,
          sharePerFarmer: '₹75,000',
          members: const ['Arjun'],
        ),
      ],
    );
  }

  // ── Section 4 ──────────────────────────────────────────────────

  Widget _buildMyGroups() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'My Groups',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        AgCard(
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
        ),
      ],
    );
  }
}

// ── Equipment Group Card Widget ──────────────────────────────────

/// A card displaying an active equipment group with join/details buttons.
///
/// Tracks member count locally. When the group is full, displays a
/// "Ready to Purchase" label and a "READY" badge.
class _EquipmentGroupCard extends StatefulWidget {
  const _EquipmentGroupCard({
    required this.emoji,
    required this.name,
    required this.location,
    required this.initialMembers,
    required this.targetMembers,
    required this.sharePerFarmer,
    required this.members,
  });

  final String emoji;
  final String name;
  final String location;
  final int initialMembers;
  final int targetMembers;
  final String sharePerFarmer;
  final List<String> members;

  @override
  State<_EquipmentGroupCard> createState() => _EquipmentGroupCardState();
}

class _EquipmentGroupCardState extends State<_EquipmentGroupCard> {
  late int _currentMembers;
  late List<String> _memberNames;
  bool _hasJoined = false;

  bool get _isFull => _currentMembers >= widget.targetMembers;

  @override
  void initState() {
    super.initState();
    _currentMembers = widget.initialMembers;
    _memberNames = List<String>.from(widget.members);
  }

  void _joinGroup() {
    if (_hasJoined || _isFull) return;
    setState(() {
      _currentMembers++;
      _memberNames.add('You');
      _hasJoined = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AgCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row + READY badge
          Row(
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  widget.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (_isFull) _buildReadyBadge(),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Location
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                widget.location,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Trust score chips for members
          _buildTrustScoreRow(),

          const SizedBox(height: AppSpacing.md),

          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: _isFull
                  ? const Color(0xFFE8F5E9)
                  : AppColors.secondaryGreen.withAlpha(20),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Members
                Row(
                  children: [
                    Icon(
                      _isFull
                          ? Icons.check_circle_rounded
                          : Icons.people_outline_rounded,
                      size: 18,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Members: $_currentMembers / ${widget.targetMembers}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                // Share per farmer
                Text(
                  widget.sharePerFarmer,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Label for share
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Share per Farmer',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ),

          // "Ready to Purchase" label when full
          if (_isFull) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    size: 18,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Ready to Purchase',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // Action buttons
          Row(
            children: [
              // Join Group — outlined style (disabled when joined or full)
              Expanded(
                child: OutlinedButton(
                  onPressed: (_hasJoined || _isFull) ? null : _joinGroup,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    disabledForegroundColor: AppColors.textMuted,
                    side: BorderSide(
                      color: (_hasJoined || _isFull)
                          ? AppColors.divider
                          : AppColors.primaryGreen,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm + 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.buttonRadius,
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(_hasJoined ? 'Joined ✓' : 'Join Group'),
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // View Details — navigates to GroupDetailScreen
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => GroupDetailScreen(
                          emoji: widget.emoji,
                          name: widget.name,
                          location: widget.location,
                          currentMembers: _currentMembers,
                          targetMembers: widget.targetMembers,
                          sharePerFarmer: widget.sharePerFarmer,
                          members: _memberNames,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.textLight,
                    elevation: 2,
                    shadowColor: AppColors.primaryGreen.withAlpha(80),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm + 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.buttonRadius,
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── READY Badge ────────────────────────────────────────────────

  Widget _buildReadyBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withAlpha(60),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'READY',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textLight,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  // ── Trust Score Row ────────────────────────────────────────────

  Widget _buildTrustScoreRow() {
    // Compute average trust score for current members
    final farmers = _memberNames.map(getFarmer).toList();
    final avgScore = farmers.isEmpty
        ? 0.0
        : farmers.fold<double>(0, (sum, f) => sum + f.trustScore) /
            farmers.length;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        // Average badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: Colors.amber.withAlpha(30),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: Colors.amber.withAlpha(80)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
              const SizedBox(width: 3),
              Text(
                'Avg Trust: ${avgScore.toStringAsFixed(1)}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber[800],
                ),
              ),
            ],
          ),
        ),
        // Per-member scores
        ...farmers.map(
          (f) => Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              '${f.name} ⭐${f.trustScore}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
