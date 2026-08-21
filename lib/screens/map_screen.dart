import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/equipment_data.dart';
import '../models/equipment.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_card.dart';
import 'equipment_detail_screen.dart';

/// A simulated map view showing nearby equipment as floating markers
/// positioned over an aerial farmland background.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  // Marker positions (fractional x, y on the map area)
  static const _markerPositions = [
    Offset(0.20, 0.25),
    Offset(0.65, 0.18),
    Offset(0.40, 0.50),
    Offset(0.75, 0.55),
    Offset(0.15, 0.70),
    Offset(0.55, 0.78),
  ];

  static const _markerIcons = [
    Icons.agriculture_rounded,
    Icons.grass_rounded,
    Icons.water_drop_rounded,
    Icons.settings_rounded,
    Icons.eco_rounded,
    Icons.pest_control_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Map background ──
            Positioned.fill(child: _MapBackground()),

            // ── Header overlay ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildMapHeader(context),
            ),

            // ── Equipment markers ──
            ...List.generate(dummyEquipment.length, (i) {
              final pos = _markerPositions[i];
              return Positioned(
                left: pos.dx * (MediaQuery.of(context).size.width - 130),
                top: 140 + pos.dy * (MediaQuery.of(context).size.height - 300),
                child: _EquipmentMarker(
                  equipment: dummyEquipment[i],
                  icon: _markerIcons[i],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EquipmentDetailScreen(equipment: dummyEquipment[i]),
                      ),
                    );
                  },
                ),
              );
            }),

            // ── Locate Me FAB ──
            Positioned(
              bottom: AppSpacing.lg,
              right: AppSpacing.lg,
              child: _LocateMeFab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.lightBackground,
            AppColors.lightBackground.withAlpha(240),
            AppColors.lightBackground.withAlpha(0),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + title row
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textDark,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nearby Equipment',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Discover farm machines around your location.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MAP BACKGROUND
// ─────────────────────────────────────────────

class _MapBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFE8F0E4)),
      child: CustomPaint(
        painter: _MapPatternPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Draws a subtle grid + farmland pattern to simulate a map.
class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFD0DFC8)
      ..strokeWidth = 0.5;

    // Grid lines
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // "Road" lines
    final roadPaint = Paint()
      ..color = const Color(0xFFC5D4BC)
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.35, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width, size.height * 0.45),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.65, size.height),
      roadPaint,
    );

    // Farmland patches
    final patchPaint = Paint()..style = PaintingStyle.fill;
    final patches = [
      (Rect.fromLTWH(20, 60, 100, 80), const Color(0xFFD5E8C8)),
      (Rect.fromLTWH(size.width * 0.5, 100, 120, 70), const Color(0xFFCDE4BE)),
      (Rect.fromLTWH(40, size.height * 0.55, 90, 60), const Color(0xFFDBEDD0)),
      (
        Rect.fromLTWH(size.width * 0.6, size.height * 0.6, 110, 90),
        const Color(0xFFD0E6C0),
      ),
    ];
    for (final (rect, color) in patches) {
      patchPaint.color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        patchPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
// EQUIPMENT MARKER
// ─────────────────────────────────────────────

class _EquipmentMarker extends StatelessWidget {
  const _EquipmentMarker({
    required this.equipment,
    required this.icon,
    required this.onTap,
  });

  final Equipment equipment;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Card bubble
          AgCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryGreen.withAlpha(35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.primaryGreen),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      equipment.name.split(' ').take(2).join(' '),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '${equipment.distance} km',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Pin
          CustomPaint(size: const Size(14, 8), painter: _PinPainter()),
          // Dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withAlpha(80),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws a small triangle pointing down (pin connector).
class _PinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cardBackground
      ..style = PaintingStyle.fill;
    final shadow = Paint()
      ..color = Colors.black.withAlpha(12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, shadow);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
// LOCATE ME FAB
// ─────────────────────────────────────────────

class _LocateMeFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Showing nearby equipment.',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
        );
      },
      backgroundColor: AppColors.primaryGreen,
      icon: const Icon(Icons.my_location_rounded, color: AppColors.textLight),
      label: Text(
        'Locate Me',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
        ),
      ),
    );
  }
}
