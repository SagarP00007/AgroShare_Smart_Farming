import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipment.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_button.dart';
import '../widgets/ag_card.dart';
import '../widgets/section_title.dart';
import 'main_shell.dart';
import 'upi_payment_screen.dart';

/// Booking form screen for a selected piece of equipment.
///
/// Allows user to pick date, time, and duration.
/// Shows a two-step payment process:
/// 1. Deposit (to secure booking)
/// 2. Remaining Amount (paid after return)
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.equipment});

  final Equipment equipment;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  int _durationHours = 2;

  double get _totalCost => widget.equipment.pricePerHour * _durationHours;
  double get _deposit => 200.0;
  double get _remaining => (_totalCost - _deposit).clamp(0.0, double.infinity);

  // ── Date picker ──
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppColors.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── Time picker ──
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppColors.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // ── Confirm booking ──
  void _confirmBooking() {
    final bookingDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final bookingData = <String, dynamic>{
      'userId': AuthService.instance.currentUser?.uid ?? 'guest_user',
      'equipmentId': widget.equipment.id,
      'equipmentName': widget.equipment.name,
      'ownerId': widget.equipment.ownerId,
      'ownerName': widget.equipment.ownerName,
      'date': Timestamp.fromDate(bookingDateTime),
      'bookingDate': Timestamp.fromDate(bookingDateTime),
      'durationHours': _durationHours,
      'totalCost': _totalCost,
      'depositAmount': _deposit,
      'status': 'upcoming',
      'createdAt': FieldValue.serverTimestamp(),
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpiPaymentScreen(
          equipment: widget.equipment,
          amount: _deposit,
          paymentType: 'rental_deposit',
          bookingData: bookingData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Book Equipment',
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Equipment summary
                    _EquipmentSummary(equipment: widget.equipment),
                    const SizedBox(height: AppSpacing.lg),

                    // Date & time pickers
                    const SectionTitle(
                      title: 'Schedule',
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    ),
                    _ScheduleCard(
                      selectedDate: _selectedDate,
                      selectedTime: _selectedTime,
                      onPickDate: _pickDate,
                      onPickTime: _pickTime,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Duration selector
                    const SectionTitle(
                      title: 'Duration',
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    ),
                    _DurationSelector(
                      selected: _durationHours,
                      onChanged: (v) => setState(() => _durationHours = v),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Payment summary
                    const SectionTitle(
                      title: 'Payment Summary',
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    ),
                    _PaymentSummary(
                      pricePerHour: widget.equipment.pricePerHour,
                      durationHours: _durationHours,
                      total: _totalCost,
                      deposit: _deposit,
                      remaining: _remaining,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),

            // Fixed bottom button
            Container(
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
                label: 'Pay Deposit (₹${_deposit.toInt()})',
                icon: Icons.check_circle_outline_rounded,
                isExpanded: true,
                onPressed: _confirmBooking,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EQUIPMENT SUMMARY
// ─────────────────────────────────────────────

class _EquipmentSummary extends StatelessWidget {
  const _EquipmentSummary({required this.equipment});
  final Equipment equipment;

  @override
  Widget build(BuildContext context) {
    return AgCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: SizedBox(
              width: 64,
              height: 64,
              child: Image.asset(
                equipment.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.secondaryGreen.withAlpha(30),
                  child: const Icon(
                    Icons.agriculture_rounded,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipment.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '₹${equipment.pricePerHour.toInt()} / hour  •  ${equipment.distance} km away',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
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

// ─────────────────────────────────────────────
// SCHEDULE CARD (date & time)
// ─────────────────────────────────────────────

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.selectedDate,
    required this.selectedTime,
    required this.onPickDate,
    required this.onPickTime,
  });

  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dateStr =
        '${selectedDate.day} ${months[selectedDate.month - 1]} ${selectedDate.year}';
    final timeStr = selectedTime.format(context);

    return AgCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _PickerTile(
              icon: Icons.calendar_today_rounded,
              label: 'Date',
              value: dateStr,
              onTap: onPickDate,
            ),
          ),
          Container(width: 1, height: 48, color: AppColors.divider),
          Expanded(
            child: _PickerTile(
              icon: Icons.access_time_rounded,
              label: 'Time',
              value: timeStr,
              onTap: onPickTime,
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.primaryGreen),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DURATION SELECTOR
// ─────────────────────────────────────────────

class _DurationSelector extends StatelessWidget {
  const _DurationSelector({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  static const _options = [1, 2, 3, 4, 6, 8];

  @override
  Widget build(BuildContext context) {
    return AgCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _options.map((hours) {
                final isSelected = hours == selected;
                return ChoiceChip(
                  label: Text(
                    '$hours ${hours == 1 ? 'hr' : 'hrs'}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppColors.textLight
                          : AppColors.textDark,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primaryGreen,
                  backgroundColor: AppColors.lightBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primaryGreen
                          : AppColors.divider,
                    ),
                  ),
                  onSelected: (_) => onChanged(hours),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 1,
            child: TextFormField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'Custom hr',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.md,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  borderSide: const BorderSide(color: AppColors.primaryGreen),
                ),
              ),
              onChanged: (val) {
                final hrs = int.tryParse(val) ?? 0;
                if (hrs > 0) onChanged(hrs);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PAYMENT SUMMARY
// ─────────────────────────────────────────────

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({
    required this.pricePerHour,
    required this.durationHours,
    required this.total,
    required this.deposit,
    required this.remaining,
  });

  final double pricePerHour;
  final int durationHours;
  final double total;
  final double deposit;
  final double remaining;

  @override
  Widget build(BuildContext context) {
    return AgCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Base calc
          _CostRow(label: 'Rental Price', value: '₹${pricePerHour.toInt()}/hr'),
          const SizedBox(height: AppSpacing.sm),
          _CostRow(
            label: 'Duration',
            value: '$durationHours ${durationHours == 1 ? 'hour' : 'hours'}',
          ),
          const SizedBox(height: AppSpacing.sm),
          _CostRow(
            label: 'Total Cost',
            value: '₹${total.toInt()}',
            isBold: true,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(height: 1, color: AppColors.divider),
          ),

          // Deposit
          _CostRow(
            label: 'Deposit (Pay Now)',
            value: '₹${deposit.toInt()}',
            valueColor: AppColors.primaryGreen,
            isBold: true,
          ),
          const SizedBox(height: 4),
          Text(
            'Deposit secures the booking.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Remaining
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.secondaryGreen.withAlpha(20),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CostRow(
                  label: 'Remaining Balance',
                  value: '₹${remaining.toInt()}',
                  valueColor: AppColors.textDark,
                  isBold: true,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Remaining amount will be paid after equipment return.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w500,
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

class _CostRow extends StatelessWidget {
  const _CostRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: isBold ? AppColors.textDark : AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
