import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipment.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_button.dart';
import '../widgets/ag_card.dart';
import '../widgets/section_title.dart';

/// Detail screen for a selected piece of equipment.
///
/// Shows image banner, info card, description, weekly availability,
/// and a booking button.
class EquipmentDetailScreen extends StatelessWidget {
  const EquipmentDetailScreen({super.key, required this.equipment});

  final Equipment equipment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ImageBanner(equipment: equipment),
                    const SizedBox(height: AppSpacing.lg),
                    _EquipmentInfoCard(equipment: equipment),
                    const SizedBox(height: AppSpacing.lg),
                    _DescriptionCard(description: equipment.description),
                    const SizedBox(height: AppSpacing.lg),
                    const _AvailabilitySection(),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),

            // Fixed bottom booking button
            _BookingBar(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// IMAGE BANNER
// ─────────────────────────────────────────────

class _ImageBanner extends StatelessWidget {
  const _ImageBanner({required this.equipment});

  final Equipment equipment;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: 300 + topPadding,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Equipment image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
            child: Image.asset(
              equipment.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryGreen.withAlpha(180),
                      AppColors.secondaryGreen.withAlpha(120),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.agriculture_rounded,
                    size: 80,
                    color: AppColors.textLight.withAlpha(120),
                  ),
                ),
              ),
            ),
          ),

          // Bottom gradient for readability
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(130),
                  ],
                ),
              ),
            ),
          ),

          // Back button
          Positioned(
            top: topPadding + 8,
            left: AppSpacing.md,
            child: _CircleIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),

          // Equipment name overlay
          Positioned(
            bottom: AppSpacing.lg,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: Text(
              equipment.name,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha(60),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(icon, color: AppColors.textLight, size: 22),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EQUIPMENT INFO CARD
// ─────────────────────────────────────────────

class _EquipmentInfoCard extends StatelessWidget {
  const _EquipmentInfoCard({required this.equipment});

  final Equipment equipment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: AgCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Owner row
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.secondaryGreen.withAlpha(40),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.primaryGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipment.ownerName,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Equipment Owner',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: AppSpacing.md),

            // Stats row
            Row(
              children: [
                _StatItem(
                  icon: Icons.currency_rupee_rounded,
                  value: '₹${equipment.pricePerHour.toInt()}',
                  label: 'per hour',
                ),
                _statDivider(),
                _StatItem(
                  icon: Icons.location_on_outlined,
                  value: '${equipment.distance} km',
                  label: 'away',
                ),
                _statDivider(),
                _StatItem(
                  icon: Icons.star_rounded,
                  iconColor: Colors.amber,
                  value: equipment.rating.toString(),
                  label: 'rating',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.divider,
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: iconColor ?? AppColors.primaryGreen),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DESCRIPTION CARD
// ─────────────────────────────────────────────

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Description',
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
          ),
          AgCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// AVAILABILITY SECTION
// ─────────────────────────────────────────────

class _AvailabilitySection extends StatelessWidget {
  const _AvailabilitySection();

  static const _schedule = [
    _DaySlot('Mon', true),
    _DaySlot('Tue', false),
    _DaySlot('Wed', true),
    _DaySlot('Thu', true),
    _DaySlot('Fri', false),
    _DaySlot('Sat', true),
    _DaySlot('Sun', true),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Availability',
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
          ),
          AgCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              children: _schedule
                  .map((slot) => _buildDayRow(slot))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayRow(_DaySlot slot) {
    final available = slot.isAvailable;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              slot.day,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 4,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: available
                  ? AppColors.secondaryGreen.withAlpha(25)
                  : Colors.grey.withAlpha(20),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  available
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 16,
                  color: available
                      ? AppColors.primaryGreen
                      : Colors.grey,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  available ? 'Available' : 'Booked',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: available
                        ? AppColors.primaryGreen
                        : Colors.grey,
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

class _DaySlot {
  const _DaySlot(this.day, this.isAvailable);
  final String day;
  final bool isAvailable;
}

// ─────────────────────────────────────────────
// BOTTOM BOOKING BAR
// ─────────────────────────────────────────────

class _BookingBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: AgButton(
        label: 'Book Machine',
        icon: Icons.calendar_today_rounded,
        isExpanded: true,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Booking feature coming soon!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.primaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
          );
        },
      ),
    );
  }
}
