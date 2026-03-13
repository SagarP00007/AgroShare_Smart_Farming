import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipment.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_button.dart';
import '../screens/booking_screen.dart';

/// Modal bottom sheet for equipment actions — Rent/Borrow or Buy/Sell.
void showEquipmentActionSheet(BuildContext context, Equipment equipment) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EquipmentActionSheet(equipment: equipment),
  );
}

class _EquipmentActionSheet extends StatelessWidget {
  const _EquipmentActionSheet({required this.equipment});

  final Equipment equipment;

  @override
  Widget build(BuildContext context) {
    final numberFormat = _formatPrice(equipment.purchasePrice);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Equipment image
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Image.asset(
                    equipment.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.secondaryGreen.withAlpha(20),
                      child: const Icon(
                        Icons.agriculture_rounded,
                        size: 48,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Listing type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: equipment.isRent
                      ? AppColors.primaryGreen.withAlpha(20)
                      : Colors.orange.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  equipment.isRent ? 'FOR RENT' : 'FOR SALE',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: equipment.isRent
                        ? AppColors.primaryGreen
                        : Colors.orange.shade700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Name
              Text(
                equipment.name,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Description
              Text(
                equipment.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Price summary — dynamic based on listing type
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: equipment.isRent
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 18, color: AppColors.primaryGreen),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '₹${equipment.pricePerHour.toInt()}/hr',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'rental price',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.sell_rounded,
                              size: 18, color: Colors.orange),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '₹$numberFormat',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'selling price',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Action buttons — dynamic
              if (equipment.isRent)
                AgButton(
                  label: 'Book / Borrow',
                  icon: Icons.access_time_rounded,
                  isExpanded: true,
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BookingScreen(equipment: equipment),
                      ),
                    );
                  },
                )
              else
                AgButton(
                  label: 'Buy Equipment',
                  icon: Icons.shopping_cart_rounded,
                  isExpanded: true,
                  onPressed: () {
                    Navigator.pop(context);
                    _showBuyDialog(context, equipment, numberFormat);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    final p = price.toInt().toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = p.length - 1; i >= 0; i--) {
      buf.write(p[i]);
      count++;
      if (i > 0) {
        if (count == 3 || (count > 3 && (count - 3) % 2 == 0)) {
          buf.write(',');
        }
      }
    }
    return buf.toString().split('').reversed.join();
  }
}

void _showBuyDialog(
    BuildContext context, Equipment equipment, String priceStr) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      title: Text(
        'Purchase ${equipment.name}',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: AppColors.textDark,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Price', '₹$priceStr'),
          const SizedBox(height: AppSpacing.sm),
          _infoRow('Owner', equipment.ownerName),
          const SizedBox(height: AppSpacing.sm),
          _infoRow('Location', '${equipment.distance} km away'),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Contact the owner to negotiate and finalize the purchase.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(color: AppColors.textMuted),
          ),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Owner contact shared.',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                backgroundColor: AppColors.primaryGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
            );
          },
          icon: const Icon(Icons.phone_rounded),
          label: Text(
            'Contact Owner',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
          ),
        ),
      ],
    ),
  );
}

Widget _infoRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: AppColors.textMuted,
        ),
      ),
      Text(
        value,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    ],
  );
}

