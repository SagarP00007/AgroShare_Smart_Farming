import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_button.dart';
import '../widgets/ag_card.dart';
import 'main_shell.dart';
import 'payment_history_screen.dart';

/// Professional Payment Success screen displayed after a successful simulated UPI payment.
class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({
    super.key,
    required this.transactionId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentType,
    required this.equipmentName,
    this.equipmentImage = '',
    this.bookingId = '',
  });

  final String transactionId;
  final double amount;
  final String paymentMethod;
  final String paymentType;
  final String equipmentName;
  final String equipmentImage;
  final String bookingId;

  String get _paymentTypeLabel {
    switch (paymentType) {
      case 'rental_deposit':
        return 'Booking Security Deposit';
      case 'rental_remaining':
        return 'Remaining Balance Payment';
      case 'equipment_purchase':
        return 'Full Equipment Purchase';
      default:
        return 'Equipment Payment';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCash = paymentMethod.toLowerCase().contains('cash');
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
    final now = DateTime.now();
    final dateStr =
        '${now.day} ${months[now.month - 1]} ${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Payment Receipt',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.md),

              // Animated Success / Confirmed Hero Badge
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: (isCash ? Colors.amber : AppColors.primaryGreen)
                      .withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: isCash ? Colors.amber.shade800 : AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCash ? Icons.handshake_rounded : Icons.check_rounded,
                      size: 40,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Text(
                isCash ? 'Booking Confirmed!' : 'Payment Successful!',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isCash
                    ? '₹${amount.toInt()} to be paid in cash at pickup'
                    : '₹${amount.toInt()} paid via $paymentMethod',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isCash ? Colors.amber.shade900 : AppColors.primaryGreen,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Receipt Card
              AgCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transaction Details',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (isCash ? Colors.amber : Colors.green)
                                .withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: (isCash
                                      ? Colors.amber.shade600
                                      : Colors.green.shade600)
                                  .withAlpha(50),
                            ),
                          ),
                          child: Text(
                            isCash ? 'PAY AT PICKUP (PENDING)' : 'SUCCESSFUL',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isCash
                                  ? Colors.amber.shade900
                                  : Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: AppSpacing.md),

                    _receiptRow('Equipment', equipmentName, isBold: true),
                    const SizedBox(height: AppSpacing.sm),
                    _receiptRow('Payment Type', _paymentTypeLabel),
                    const SizedBox(height: AppSpacing.sm),
                    _receiptRow(
                      isCash ? 'Deposit Amount Due' : 'Amount Paid',
                      '₹${amount.toInt()}',
                      valueColor: isCash
                          ? Colors.amber.shade900
                          : AppColors.primaryGreen,
                      isBold: true,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _receiptRow('Date & Time', dateStr),
                    const SizedBox(height: AppSpacing.sm),
                    _receiptRow('Payment Method', paymentMethod),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: AppSpacing.md),

                    // Transaction ID with copy button
                    Text(
                      'Transaction / Booking Ref ID',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            transactionId,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: transactionId),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Reference ID copied!',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: AppColors.primaryGreen,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.copy_rounded,
                            size: 18,
                            color: AppColors.primaryGreen,
                          ),
                          tooltip: 'Copy ID',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Prototype notice
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: (isCash ? Colors.amber : AppColors.secondaryGreen)
                      .withAlpha(20),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCash
                          ? Icons.info_outline_rounded
                          : Icons.verified_user_rounded,
                      color: isCash
                          ? Colors.amber.shade900
                          : AppColors.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        isCash
                            ? 'Please pay ₹${amount.toInt()} in cash directly to the equipment owner upon pickup. The owner will confirm payment receipt in the app.'
                            : 'Simulated Prototype Transaction saved to Firestore. Your equipment booking has been recorded.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isCash
                              ? Colors.amber.shade900
                              : AppColors.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Action buttons
              AgButton(
                label: 'View My Bookings',
                icon: Icons.calendar_month_rounded,
                isExpanded: true,
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainShell()),
                    (route) => false,
                  );
                },
              ),

              const SizedBox(height: AppSpacing.md),

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaymentHistoryScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.history_rounded,
                  size: 18,
                  color: AppColors.primaryGreen,
                ),
                label: Text(
                  'Payment History',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: AppColors.primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainShell()),
                    (route) => false,
                  );
                },
                child: Text(
                  'Return to Home',
                  style: GoogleFonts.poppins(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isBold ? AppColors.textDark : AppColors.textMuted,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
