import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../models/equipment.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_button.dart';
import '../widgets/ag_card.dart';
import '../widgets/section_title.dart';
import 'booking_screen.dart';
import 'chat_screen.dart';
import 'main_shell.dart';
import 'upi_payment_screen.dart';

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
                physics: const BouncingScrollPhysics(),
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
            _BookingBar(equipment: equipment),
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
          // Equipment image (asset or network for real-time listings)
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
            child: _buildDetailImage(equipment),
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
                  colors: [Colors.transparent, Colors.black.withAlpha(130)],
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
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MainShell()),
                  (route) => false,
                );
              },
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

  Widget _buildDetailImage(Equipment equipment) {
    final isNetwork =
        equipment.imageUrl.isNotEmpty && equipment.imageUrl.startsWith('http');
    final placeholder = Container(
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
    );
    if (isNetwork) {
      return Image.network(
        equipment.imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppColors.primaryGreen.withAlpha(50),
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: AppColors.textLight,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }
    return Image.asset(
      equipment.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
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
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equipment.ownerName,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chatId: '', // Will be created by ChatService
                          equipmentId: equipment.id,
                          equipmentName: equipment.name,
                          equipmentImage: equipment.imageUrl,
                          ownerId: equipment.ownerId.isEmpty
                              ? 'unknown'
                              : equipment.ownerId,
                          ownerName: equipment.ownerName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: Text(
                    'Message',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _showContactDialog(context),
                  icon: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                  tooltip: 'Call Owner',
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
                  label: L.tr(context, 'per_hour'),
                ),
                _statDivider(),
                _StatItem(
                  icon: Icons.location_on_outlined,
                  value: '${equipment.distance} km',
                  label: L.tr(context, 'away'),
                ),
                _statDivider(),
                _StatItem(
                  icon: Icons.star_rounded,
                  iconColor: Colors.amber,
                  value: equipment.rating.toString(),
                  label: L.tr(context, 'rating'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 32, color: AppColors.divider);
  }

  Future<void> _showContactDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Contact Owner',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                equipment.ownerName,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Equipment: ${equipment.name}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryGreen.withAlpha(30),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.phone_rounded,
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        equipment.contactNumber.isNotEmpty
                            ? equipment.contactNumber
                            : '+91 98765 43210', // Default number
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final phoneNumber = equipment.contactNumber.isNotEmpty
                            ? equipment.contactNumber
                            : '+91 98765 43210';
                        Clipboard.setData(ClipboardData(text: phoneNumber));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Phone number $phoneNumber copied!'),
                            backgroundColor: AppColors.primaryGreen,
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.copy_rounded,
                        color: AppColors.primaryGreen,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Call the owner to discuss rental details, availability, and pricing.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final phoneNumber = equipment.contactNumber.isNotEmpty
                    ? equipment.contactNumber
                    : '+91 98765 43210';
                // TODO: Implement phone call functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Calling $phoneNumber...'),
                    backgroundColor: AppColors.primaryGreen,
                  ),
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              child: Text(
                'Call Now',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
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
          SectionTitle(
            title: L.tr(context, 'description'),
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
              children: _schedule.map((slot) => _buildDayRow(slot)).toList(),
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
                  available ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 16,
                  color: available ? AppColors.primaryGreen : Colors.grey,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  available ? 'Available' : 'Booked',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: available ? AppColors.primaryGreen : Colors.grey,
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
  const _BookingBar({required this.equipment});

  final Equipment equipment;

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
      child: equipment.isRent
          ? AgButton(
              label: L.tr(context, 'book_for_borrow'),
              icon: Icons.calendar_today_rounded,
              isExpanded: true,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingScreen(equipment: equipment),
                  ),
                );
              },
            )
          : AgButton(
              label: L.tr(context, 'buy_equipment'),
              icon: Icons.shopping_cart_rounded,
              isExpanded: true,
              onPressed: () {
                _showBuyConfirmation(context);
              },
            ),
    );
  }

  void _showBuyConfirmation(BuildContext context) {
    final priceStr = _formatPrice(equipment.purchasePrice);
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
              'Pay via UPI to record purchase transaction or message owner to negotiate.',
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
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    chatId: '',
                    equipmentId: equipment.id,
                    equipmentName: equipment.name,
                    equipmentImage: equipment.imageUrl,
                    ownerId: equipment.ownerId.isEmpty
                        ? 'unknown'
                        : equipment.ownerId,
                    ownerName: equipment.ownerName,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat_rounded, size: 16),
            label: Text(
              'Message',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              side: const BorderSide(color: AppColors.primaryGreen),
            ),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UpiPaymentScreen(
                    equipment: equipment,
                    amount: equipment.purchasePrice > 0
                        ? equipment.purchasePrice
                        : 250000.0,
                    paymentType: 'equipment_purchase',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.payment_rounded, size: 16),
            label: Text(
              'Pay via UPI',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
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
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted),
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

  String _formatPrice(double price) {
    final buf = StringBuffer();
    final priceStr = price.toInt().toString();
    for (int i = 0; i < priceStr.length; i++) {
      if ((priceStr.length - i) % 3 == 0 && i != 0) buf.write(',');
      buf.write(priceStr[i]);
    }
    return buf.toString().split('').reversed.join('');
  }
}
