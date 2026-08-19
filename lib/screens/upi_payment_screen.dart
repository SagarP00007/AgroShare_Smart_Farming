import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipment.dart';
import '../models/payment.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_button.dart';
import '../widgets/ag_card.dart';
import 'payment_success_screen.dart';

/// Prototype UPI-Style Payment screen.
///
/// Features realistic simulated payment flow with options for Google Pay, PhonePe, Paytm,
/// UPI ID entry, simulated MPIN authorization, processing states, failure testing,
/// duplicate payment protection, and Firestore persistence.
class UpiPaymentScreen extends StatefulWidget {
  const UpiPaymentScreen({
    super.key,
    required this.equipment,
    required this.amount,
    required this.paymentType, // 'rental_deposit', 'rental_remaining', 'equipment_purchase'
    this.bookingData,
    this.bookingId,
  });

  final Equipment equipment;
  final double amount;
  final String paymentType;
  final Map<String, dynamic>? bookingData;
  final String? bookingId;

  @override
  State<UpiPaymentScreen> createState() => _UpiPaymentScreenState();
}

class _UpiPaymentScreenState extends State<UpiPaymentScreen> {
  String _selectedMethod = 'Google Pay';
  final _upiIdCtrl = TextEditingController(text: 'farmer@okicici');
  bool _isProcessing = false;
  bool _simulateFailure = false;

  @override
  void dispose() {
    _upiIdCtrl.dispose();
    super.dispose();
  }

  String get _paymentCategoryLabel {
    switch (widget.paymentType) {
      case 'rental_deposit':
        return 'Booking Security Deposit';
      case 'rental_remaining':
        return 'Rental Remaining Balance';
      case 'equipment_purchase':
        return 'Full Equipment Purchase Price';
      default:
        return 'Equipment Payment';
    }
  }

  void _initiatePayment() {
    if (_isProcessing) return;

    if (_selectedMethod == 'UPI ID' && _upiIdCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid UPI ID', style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _showMpinDialog();
  }

  void _showMpinDialog() {
    final mpinCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'UPI Security PIN',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'NPCI 256-BIT ENCRYPTED',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Paying ₹${widget.amount.toInt()} via $_selectedMethod',
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: mpinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                autofocus: true,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 12,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '••••••',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 24,
                    letterSpacing: 12,
                    color: AppColors.textMuted,
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.lightBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: AgButton(
                      label: 'Authorize Payment',
                      icon: Icons.lock_outline_rounded,
                      onPressed: () {
                        if (mpinCtrl.text.length < 4) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Please enter 4-6 digit UPI PIN')),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        _processSimulatedPayment();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processSimulatedPayment() async {
    setState(() => _isProcessing = true);

    // Show processing modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 54,
                  height: 54,
                  child: CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Processing UPI Payment...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Communicating securely with bank server',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading dialog

    if (_simulateFailure) {
      setState(() => _isProcessing = false);
      _showFailureDialog();
      return;
    }

    try {
      final uid = AuthService.instance.currentUser?.uid ?? 'demo_farmer';
      final now = DateTime.now();
      final txnId = 'TXN${now.millisecondsSinceEpoch}';

      // 1. Record payment in Firestore
      final paymentData = Payment(
        id: '',
        transactionId: txnId,
        userId: uid,
        equipmentId: widget.equipment.id,
        equipmentName: widget.equipment.name,
        equipmentImage: widget.equipment.imageUrl,
        amount: widget.amount,
        paymentType: widget.paymentType,
        paymentMethod: _selectedMethod,
        upiId: _selectedMethod == 'UPI ID' ? _upiIdCtrl.text.trim() : 'farmer@$_selectedMethod',
        status: 'successful',
        date: now,
        bookingId: widget.bookingId ?? '',
      ).toMap();

      await FirestoreService.instance.recordPayment(paymentData);

      String createdBookingId = widget.bookingId ?? '';

      // 2. If creating booking on deposit payment:
      if (widget.paymentType == 'rental_deposit' && widget.bookingData != null) {
        final bData = Map<String, dynamic>.from(widget.bookingData!);
        bData['depositAmount'] = widget.amount;
        bData['depositTxnId'] = txnId;
        bData['paymentStatus'] = 'deposit_paid';
        final docRef = await FirestoreService.instance.createBooking(bData);
        createdBookingId = docRef.id;
      } else if (widget.bookingId != null && widget.bookingId!.isNotEmpty) {
        // If paying remaining balance:
        await FirestoreService.instance.updateBookingStatus(widget.bookingId!, 'completed');
      }

      if (!mounted) return;
      setState(() => _isProcessing = false);

      // 3. Navigate to Payment Success screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            transactionId: txnId,
            amount: widget.amount,
            paymentMethod: _selectedMethod,
            paymentType: widget.paymentType,
            equipmentName: widget.equipment.name,
            equipmentImage: widget.equipment.imageUrl,
            bookingId: createdBookingId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment process error: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showFailureDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 28),
            const SizedBox(width: 8),
            Text(
              'Payment Failed',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
          ],
        ),
        content: Text(
          'Simulated payment failure (Bank server timeout or insufficient balance). No money was deducted.',
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Retry Payment', style: GoogleFonts.poppins(color: AppColors.primaryGreen)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'UPI Prototype Payment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.textLight,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Prototype disclaimer banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.amber.withAlpha(40),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Prototype Simulation Mode • No real money will be charged.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Header Card
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
                                _paymentCategoryLabel,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'INSTANT UPI',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '₹${widget.amount.toInt()}',
                            style: GoogleFonts.poppins(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const Divider(height: 1, color: AppColors.divider),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              const Icon(Icons.agriculture_rounded,
                                  size: 18, color: AppColors.textMuted),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.equipment.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // UPI Payment Options
                    Text(
                      'Select Payment Method',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    AgCard(
                      margin: EdgeInsets.zero,
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildOptionTile(
                            title: 'Google Pay',
                            subtitle: 'Fast UPI payment via GPay',
                            iconWidget: _brandBadge('GPay', Colors.blue),
                            value: 'Google Pay',
                          ),
                          const Divider(height: 1, color: AppColors.divider),
                          _buildOptionTile(
                            title: 'PhonePe',
                            subtitle: 'Direct bank transfer via PhonePe',
                            iconWidget: _brandBadge('Pe', Colors.purple),
                            value: 'PhonePe',
                          ),
                          const Divider(height: 1, color: AppColors.divider),
                          _buildOptionTile(
                            title: 'Paytm / BHIM UPI',
                            subtitle: 'Paytm UPI ID or BHIM App',
                            iconWidget: _brandBadge('UPI', const Color(0xFF002E6D)),
                            value: 'Paytm / BHIM',
                          ),
                          const Divider(height: 1, color: AppColors.divider),
                          _buildOptionTile(
                            title: 'Custom UPI ID',
                            subtitle: 'Enter VPA e.g. name@upi',
                            iconWidget: const Icon(Icons.alternate_email_rounded,
                                color: AppColors.primaryGreen),
                            value: 'UPI ID',
                          ),
                        ],
                      ),
                    ),

                    if (_selectedMethod == 'UPI ID') ...[
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _upiIdCtrl,
                        decoration: InputDecoration(
                          labelText: 'Enter VPA / UPI ID',
                          hintText: 'username@bank',
                          prefixIcon: const Icon(Icons.payment_rounded, color: AppColors.primaryGreen),
                          filled: true,
                          fillColor: AppColors.cardBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.lg),

                    // Failure simulation check box for testing cancel/failure flows
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(15),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: CheckboxListTile(
                        dense: true,
                        title: Text(
                          'Test Failure State (Simulate Failed Transaction)',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          'Enable to test handling when payment fails or drops',
                          style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textMuted),
                        ),
                        value: _simulateFailure,
                        activeColor: Colors.redAccent,
                        onChanged: (val) => setState(() => _simulateFailure = val ?? false),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Pay Button
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
                label: _isProcessing ? 'Processing...' : 'Pay ₹${widget.amount.toInt()} Now',
                icon: Icons.shield_rounded,
                isExpanded: true,
                onPressed: _isProcessing ? null : _initiatePayment,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required Widget iconWidget,
    required String value,
  }) {
    final isSelected = _selectedMethod == value;
    return Container(
      color: isSelected ? AppColors.primaryGreen.withAlpha(12) : Colors.transparent,
      child: ListTile(
        leading: iconWidget,
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primaryGreen : AppColors.textDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
        ),
        trailing: Radio<String>(
          value: value,
          groupValue: _selectedMethod,
          activeColor: AppColors.primaryGreen,
          onChanged: (val) {
            if (val != null) setState(() => _selectedMethod = val);
          },
        ),
        onTap: () => setState(() => _selectedMethod = value),
      ),
    );
  }

  Widget _brandBadge(String label, Color bg) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: bg,
          ),
        ),
      ),
    );
  }
}
