import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_button.dart';
import '../widgets/ag_card.dart';
import '../widgets/section_title.dart';
import 'community_screen.dart';
import 'list_equipment_screen.dart';

/// Home dashboard screen for AgroShare.
///
/// Displays a hero banner, quick action grid, and smart farming tip card.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onSwitchTab});

  final void Function(int)? onSwitchTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng? _currentPosition;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    final location = await LocationService.instance.getFastLocation();
    if (mounted) {
      setState(() {
        _currentPosition = location;
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        top: false, // hero extends behind status bar
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeroBanner(context),
              const SizedBox(height: AppSpacing.lg),
              _QuickActionsSection(
                currentPosition: _currentPosition,
                isLoadingLocation: _isLoadingLocation,
                onSwitchTab: widget.onSwitchTab,
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SeasonalRecommendationsSection(),
              const SizedBox(height: AppSpacing.xxl),
              _SmartFarmingTipCard(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HERO BANNER
  // ─────────────────────────────────────────────
  Widget _buildHeroBanner(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;
    // Cap banner height to prevent overflow on short screens
    final bannerHeight = (screenHeight * 0.55).clamp(300.0, 440.0) + topPadding;

    return SizedBox(
      height: bannerHeight,
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

          // ── Header/Location (Top section of banner) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: topPadding + AppSpacing.md,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Location',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLight.withAlpha(200),
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (_isLoadingLocation)
                          SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textLight.withAlpha(200),
                            ),
                          )
                        else if (_currentPosition != null) ...[
                          Text(
                            'Angondhalli, Karnataka',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textLight,
                            ),
                          ),
                          Text(
                            'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)} • Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColors.textLight.withAlpha(180),
                            ),
                          ),
                        ] else
                          Text(
                            'Location unavailable',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                      ],
                    ),
                  ),
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
                    widget.onSwitchTab?.call(1); // Switch to Explore tab
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
  const _QuickActionsSection({
    required this.currentPosition,
    required this.isLoadingLocation,
    this.onSwitchTab,
  });

  final LatLng? currentPosition;
  final bool isLoadingLocation;
  final void Function(int)? onSwitchTab;

  static const _actions = [
    _QuickAction(icon: Icons.search_rounded, label: 'Find Equipment', emoji: '🔍'),
    _QuickAction(icon: Icons.calendar_month_rounded, label: 'My Bookings', emoji: '📅'),
    _QuickAction(icon: Icons.people_rounded, label: 'Community', emoji: '🤝'),
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
          onSwitchTab?.call(2); // Switch to Find tab
        } else if (action.label == 'My Bookings') {
          onSwitchTab?.call(3); // Switch to Bookings tab
        } else if (action.label == 'Community') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CommunityScreen(),
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.secondaryGreen.withAlpha(35),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(action.icon, color: AppColors.primaryGreen, size: 26),
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

// ─────────────────────────────────────────────
// SEASONAL RECOMMENDATIONS
// ─────────────────────────────────────────────

class _SeasonalRecommendationsSection extends StatelessWidget {
  const _SeasonalRecommendationsSection();

  String get _currentSeason {
    final month = DateTime.now().month;
    if (month >= 6 && month <= 9) return 'planting';
    if (month >= 10 || month <= 2) return 'harvesting';
    return 'preparation';
  }

  List<Map<String, String>> _getRecommendations() {
    switch (_currentSeason) {
      case 'harvesting':
        return [
          {
            'name': 'Mini Harvester',
            'emoji': '🌾',
            'desc': 'Best suited for rice harvesting during peak season.'
          },
          {
            'name': 'Paddy Thresher',
            'emoji': '🚜',
            'desc': 'Efficient threshing of paddy crops after harvest.'
          },
        ];
      case 'planting':
        return [
          {
            'name': 'Seed Drill',
            'emoji': '🌱',
            'desc': 'Ensures uniform depth and spacing for planting seeds.'
          },
          {
            'name': 'Rotavator',
            'emoji': '🚜',
            'desc': 'Perfect for secondary tillage and seedbed preparation.'
          },
        ];
      default:
        return [
          {
            'name': 'Mahindra Tractor',
            'emoji': '🚜',
            'desc': 'Reliable power for heavy-duty land preparation.'
          },
          {
            'name': 'Irrigation Pump Set',
            'emoji': '💧',
            'desc': 'Essential water supply management before planting.'
          },
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = _getRecommendations();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Recommended Equipment for This Season',
            padding: EdgeInsets.only(bottom: AppSpacing.md),
          ),
          ...cards.map((item) {
            return AgCard(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withAlpha(20),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: AppColors.primaryGreen.withAlpha(50),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item['emoji']!,
                      style: GoogleFonts.poppins(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name']!,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['desc']!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.primaryGreen.withAlpha(150),
                    size: 16,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
