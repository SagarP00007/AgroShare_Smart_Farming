import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_button.dart';
import '../widgets/ag_card.dart';
import '../widgets/section_title.dart';
import 'equipment_list_screen.dart';
import 'list_equipment_screen.dart';
import 'map_screen.dart';
import 'my_bookings_screen.dart';

/// Home dashboard screen for AgroShare.
///
/// Displays a hero banner, quick action grid, and smart farming tip card.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        top: false, // hero extends behind status bar
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroBanner(),
              const SizedBox(height: AppSpacing.lg),
              _QuickActionsSection(),
              const SizedBox(height: AppSpacing.lg),
              _SmartFarmingTipCard(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HERO BANNER
// ─────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: 440 + topPadding,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image ──
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            child: Image.asset(
              'assets/images/farm_hero.webp',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1B5E20),
                      AppColors.primaryGreen,
                      AppColors.secondaryGreen,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Dark-green gradient overlay ──
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.35, 1.0],
                colors: [
                  const Color(0xFF1B5E20).withAlpha(120),
                  Colors.black.withAlpha(60),
                  Colors.black.withAlpha(200),
                ],
              ),
            ),
          ),

          // ── Content ──
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.xl + 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App name
                Text(
                  'AgroShare',
                  style: GoogleFonts.poppins(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textLight,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                // Subtitle
                Text(
                  'Smart Farm Equipment Sharing Platform',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textLight.withAlpha(230),
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Description
                Text(
                  'Find nearby tractors, harvesters, and farming\n'
                  'equipment easily.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textLight.withAlpha(190),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Primary CTA
                AgButton(
                  label: 'Explore Equipment',
                  icon: Icons.search_rounded,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EquipmentListScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// QUICK ACTIONS
// ─────────────────────────────────────────────

class _QuickActionsSection extends StatelessWidget {
  static const _actions = [
    _QuickAction(icon: Icons.agriculture_rounded, label: 'Find Equipment', emoji: '🚜'),
    _QuickAction(icon: Icons.calendar_month_rounded, label: 'My Bookings', emoji: '📅'),
    _QuickAction(icon: Icons.location_on_rounded, label: 'Nearby Machines', emoji: '📍'),
    _QuickAction(icon: Icons.add_circle_outline_rounded, label: 'List Equipment', emoji: '➕'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Quick Actions',
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.65,
            children: _actions.map((a) => _buildActionTile(a, context)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(_QuickAction action, BuildContext context) {
    return AgCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () {
        if (action.label == 'Find Equipment') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EquipmentListScreen(),
            ),
          );
        } else if (action.label == 'My Bookings') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MyBookingsScreen(),
            ),
          );
        } else if (action.label == 'Nearby Machines') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MapScreen(),
            ),
          );
        } else if (action.label == 'List Equipment') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ListEquipmentScreen(),
            ),
          );
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container with tinted background
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.secondaryGreen.withAlpha(35),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              action.icon,
              color: AppColors.primaryGreen,
              size: 26,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            action.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.emoji,
  });

  final IconData icon;
  final String label;
  final String emoji;
}

// ─────────────────────────────────────────────
// SMART FARMING TIP
// ─────────────────────────────────────────────

class _SmartFarmingTipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Smart Farming Tip',
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
          ),
          AgCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leaf icon with tinted background
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.secondaryGreen.withAlpha(50),
                        AppColors.primaryGreen.withAlpha(30),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: AppColors.primaryGreen,
                    size: 28,
                  ),
                ),

                const SizedBox(width: AppSpacing.md),

                // Tip text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Harvest Season Alert 🌾',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Harvest season is approaching.\n'
                        'Book harvesters early to avoid price surge.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textMuted,
                          height: 1.55,
                        ),
                      ),
                    ],
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
