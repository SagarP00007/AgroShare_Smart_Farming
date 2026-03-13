import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_card.dart';
import '../widgets/section_title.dart';

/// Profile screen showing farmer overview, trust score, and activity summary.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section 1: Profile Header ───────────────────────
              _buildProfileHeader(),

              const SizedBox(height: AppSpacing.lg),

              // ── Section 2: Trust Score ──────────────────────────
              _buildTrustScore(),

              const SizedBox(height: AppSpacing.lg),

              // ── Section 3: Activity Summary ────────────────────
              _buildActivitySummary(),

              const SizedBox(height: AppSpacing.lg),

              // ── Section 4: My Equipment ─────────────────────────
              _buildMyEquipment(context),

              const SizedBox(height: AppSpacing.lg),

              // ── Section 5: Community Groups ─────────────────────
              _buildCommunityGroups(),

              const SizedBox(height: AppSpacing.lg),

              // ── Section 6: Reviews ──────────────────────────────
              _buildReviews(),

              const SizedBox(height: AppSpacing.lg),

              // ── Section 7: Settings ─────────────────────────────
              _buildSettings(context),

              const SizedBox(height: AppSpacing.lg),

              // ── Section 8: Language Preferences ─────────────────
              _buildLanguagePreferences(),

              const SizedBox(height: AppSpacing.lg),

              // ── Section 9: Notifications ────────────────────────
              _buildNotifications(),

              const SizedBox(height: AppSpacing.lg),

              // ── Section 10: Safety & Report ─────────────────────
              _buildSafetyReport(context),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section 1: Profile Header ──────────────────────────────────

  Widget _buildProfileHeader() {
    return AgCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          // Avatar with edit badge
          Stack(
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: AppColors.secondaryGreen.withAlpha(40),
                child: const Icon(
                  Icons.person_rounded,
                  size: 42,
                  color: AppColors.primaryGreen,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.cardBackground,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 14,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: AppSpacing.md),

          // Name and location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ramesh Kumar',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Angondhalli, Karnataka',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section 2: Trust Score ─────────────────────────────────────

  Widget _buildTrustScore() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Trust Score',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        AgCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // Star rating row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(30),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      size: 28,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    '4.7',
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '/ 5.0',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),
              const Divider(color: AppColors.divider),
              const SizedBox(height: AppSpacing.md),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: _trustStat(
                      Icons.handshake_outlined,
                      '12',
                      'Completed\nRentals',
                      AppColors.primaryGreen,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 48,
                    color: AppColors.divider,
                  ),
                  Expanded(
                    child: _trustStat(
                      Icons.groups_outlined,
                      '2',
                      'Community\nPurchases',
                      const Color(0xFF1565C0),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _trustStat(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSpacing.xs),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppColors.textMuted,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  // ── Section 3: Activity Summary ────────────────────────────────

  Widget _buildActivitySummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Activity Summary',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _activityCard(
                Icons.receipt_long_rounded,
                '8',
                'Total Rentals',
                AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _activityCard(
                Icons.agriculture_rounded,
                '5',
                'Equipment\nBorrowed',
                const Color(0xFFEF6C00),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _activityCard(
                Icons.inventory_2_rounded,
                '2',
                'Equipment\nListed',
                const Color(0xFF1565C0),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _activityCard(
                Icons.groups_rounded,
                '3',
                'Community\nGroups',
                const Color(0xFF6A1B9A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _activityCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return AgCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMuted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section 4: My Equipment ────────────────────────────────────

  Widget _buildMyEquipment(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'My Equipment',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        _EquipmentListingCard(
          emoji: '🚜',
          name: 'Mahindra Tractor 575 DI',
          pricePerHour: '₹500/hour',
          isAvailable: true,
          onEdit: () => _showSnackbar(context, 'Edit feature coming soon.'),
          onRemove: () =>
              _showSnackbar(context, 'Remove feature coming soon.'),
        ),
        const SizedBox(height: AppSpacing.md),
        _EquipmentListingCard(
          emoji: '💧',
          name: 'Irrigation Pump Set',
          pricePerHour: '₹200/hour',
          isAvailable: false,
          onEdit: () => _showSnackbar(context, 'Edit feature coming soon.'),
          onRemove: () =>
              _showSnackbar(context, 'Remove feature coming soon.'),
        ),
      ],
    );
  }

  // ── Section 5: Community Groups ────────────────────────────────

  Widget _buildCommunityGroups() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Community Groups',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        _CommunityGroupCard(
          emoji: '🚜',
          name: 'Tractor Purchase Group',
          currentMembers: 3,
          targetMembers: 3,
          status: 'Ready to Buy',
        ),
        const SizedBox(height: AppSpacing.md),
        _CommunityGroupCard(
          emoji: '🌾',
          name: 'Harvester Purchase Group',
          currentMembers: 2,
          targetMembers: 4,
          status: null,
        ),
      ],
    );
  }

  // ── Section 6: Reviews ─────────────────────────────────────────

  Widget _buildReviews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Reviews',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        const _ReviewCard(
          rating: 5,
          review: 'Equipment was well maintained. Highly recommend!',
          reviewerName: 'Kiran',
        ),
        const SizedBox(height: AppSpacing.md),
        const _ReviewCard(
          rating: 4,
          review: 'Owner was cooperative and punctual.',
          reviewerName: 'Arjun',
        ),
        const SizedBox(height: AppSpacing.md),
        const _ReviewCard(
          rating: 5,
          review: 'Great tractor, worked perfectly for our fields.',
          reviewerName: 'Suresh',
        ),
      ],
    );
  }

  // ── Section 7: Settings ────────────────────────────────────────

  Widget _buildSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Settings',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        AgCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                label: 'Edit Profile',
                onTap: () =>
                    _showSnackbar(context, 'Edit Profile coming soon.'),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _SettingsTile(
                icon: Icons.agriculture_outlined,
                label: 'Update Farm Details',
                onTap: () =>
                    _showSnackbar(context, 'Farm Details coming soon.'),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _SettingsTile(
                icon: Icons.phone_outlined,
                label: 'Change Phone Number',
                onTap: () =>
                    _showSnackbar(context, 'Phone update coming soon.'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Section 8: Language Preferences ────────────────────────────

  Widget _buildLanguagePreferences() {
    const languages = ['English', 'Hindi', 'Kannada', 'Telugu', 'Tamil'];
    const langIcons = ['🇬🇧', '🇮🇳', '🇮🇳', '🇮🇳', '🇮🇳'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Language Preferences',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        AgCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            children: [
              for (int i = 0; i < languages.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, color: AppColors.divider),
                ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        langIcons[i],
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        languages[i],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    _selectedLanguage == languages[i]
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: _selectedLanguage == languages[i]
                        ? AppColors.primaryGreen
                        : AppColors.textMuted,
                    size: 22,
                  ),
                  onTap: () =>
                      setState(() => _selectedLanguage = languages[i]),
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Section 9: Notifications ───────────────────────────────────

  Widget _buildNotifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Notifications',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        const _NotificationTile(
          icon: Icons.access_time_rounded,
          color: Color(0xFFEF6C00),
          message: 'Your tractor booking starts in 2 hours.',
          time: '10 min ago',
        ),
        const SizedBox(height: AppSpacing.sm),
        const _NotificationTile(
          icon: Icons.group_add_rounded,
          color: Color(0xFF1565C0),
          message: 'Harvester group needs one more member.',
          time: '1 hour ago',
        ),
        const SizedBox(height: AppSpacing.sm),
        const _NotificationTile(
          icon: Icons.payment_rounded,
          color: Color(0xFF2E7D32),
          message: 'Payment received for rental.',
          time: '3 hours ago',
        ),
      ],
    );
  }

  // ── Section 10: Safety & Report ────────────────────────────────

  Widget _buildSafetyReport(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Safety & Report',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        AgCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.flag_outlined,
                label: 'Report Issue',
                color: Colors.redAccent,
                onTap: () =>
                    _showSnackbar(context, 'Report Issue coming soon.'),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _SettingsTile(
                icon: Icons.support_agent_rounded,
                label: 'Contact Support',
                color: const Color(0xFF1565C0),
                onTap: () =>
                    _showSnackbar(context, 'Contact Support coming soon.'),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _SettingsTile(
                icon: Icons.shield_outlined,
                label: 'Safety Guidelines',
                color: const Color(0xFFEF6C00),
                onTap: () =>
                    _showSnackbar(context, 'Safety Guidelines coming soon.'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }
}

// ── Equipment Listing Card ───────────────────────────────────────

class _EquipmentListingCard extends StatelessWidget {
  const _EquipmentListingCard({
    required this.emoji,
    required this.name,
    required this.pricePerHour,
    required this.isAvailable,
    required this.onEdit,
    required this.onRemove,
  });

  final String emoji;
  final String name;
  final String pricePerHour;
  final bool isAvailable;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AgCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pricePerHour,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              // Availability badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? AppColors.primaryGreen.withAlpha(20)
                      : Colors.orange.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isAvailable ? 'Available' : 'Rented Out',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isAvailable ? AppColors.primaryGreen : Colors.orange,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    side: const BorderSide(color: AppColors.primaryGreen),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.buttonRadius,
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.buttonRadius,
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Community Group Card ─────────────────────────────────────────

class _CommunityGroupCard extends StatelessWidget {
  const _CommunityGroupCard({
    required this.emoji,
    required this.name,
    required this.currentMembers,
    required this.targetMembers,
    this.status,
  });

  final String emoji;
  final String name;
  final int currentMembers;
  final int targetMembers;
  final String? status;

  bool get _isFull => currentMembers >= targetMembers;

  @override
  Widget build(BuildContext context) {
    return AgCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (_isFull)
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

          // Members and status
          Row(
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 16,
                color: _isFull ? AppColors.primaryGreen : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Members: $currentMembers / $targetMembers',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: _isFull ? AppColors.primaryGreen : AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (status != null) ...[
                const Spacer(),
                Text(
                  status!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: const BorderSide(color: AppColors.primaryGreen),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                ),
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
        ],
      ),
    );
  }
}

// ── Review Card ──────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.rating,
    required this.review,
    required this.reviewerName,
  });

  final int rating;
  final String review;
  final String reviewerName;

  @override
  Widget build(BuildContext context) {
    return AgCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer and stars
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.secondaryGreen.withAlpha(30),
                child: Text(
                  reviewerName[0],
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                reviewerName,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              // Star rating
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 18,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Review text
          Text(
            '"$review"',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings Tile Helper ─────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tileColor = color ?? AppColors.primaryGreen;

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: tileColor.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: tileColor),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 2,
      ),
    );
  }
}

// ── Notification Tile Helper ─────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.color,
    required this.message,
    required this.time,
  });

  final IconData icon;
  final Color color;
  final String message;
  final String time;

  @override
  Widget build(BuildContext context) {
    return AgCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
