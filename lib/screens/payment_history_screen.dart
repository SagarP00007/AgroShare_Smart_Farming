import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/payment.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_card.dart';

/// Screen listing payment transaction history for the user.
class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final Key _streamKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser?.uid ?? 'demo_farmer';

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Payment History',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.textLight,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        key: _streamKey,
        stream: FirestoreService.instance.userPaymentsStream(uid),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          var payments = docs
              .map(
                (doc) =>
                    Payment.fromMap(doc.id, doc.data() as Map<String, dynamic>),
              )
              .toList();

          if (payments.isEmpty || snapshot.hasError) {
            payments = FirestoreService.instance.getFallbackPayments(uid);
          }

          if (payments.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 400));
            },
            color: AppColors.primaryGreen,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                return _PaymentCard(payment: payments[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 40,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No Payment History Yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Completed booking deposits and payments will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});

  final Payment payment;

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
        '${payment.date.day} ${months[payment.date.month - 1]} ${payment.date.year}, ${payment.date.hour.toString().padLeft(2, '0')}:${payment.date.minute.toString().padLeft(2, '0')}';

    return AgCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Equipment & Status badge
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondaryGreen.withAlpha(35),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  Icons.agriculture_rounded,
                  color: AppColors.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.equipmentName,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          payment.formattedType,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildStatusBadge(payment),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '₹${payment.amount.toInt()}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppSpacing.sm),

          // Details row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    payment.paymentMethod.toLowerCase().contains('cash')
                        ? Icons.payments_outlined
                        : Icons.payment_rounded,
                    size: 14,
                    color: payment.paymentMethod.toLowerCase().contains('cash')
                        ? Colors.amber.shade900
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    payment.paymentMethod,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight:
                          payment.paymentMethod.toLowerCase().contains('cash')
                              ? FontWeight.w600
                              : FontWeight.w400,
                      color:
                          payment.paymentMethod.toLowerCase().contains('cash')
                              ? Colors.amber.shade900
                              : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Text(
                dateStr,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xs),

          // Transaction ID row with copy button
          Row(
            children: [
              Expanded(
                child: Text(
                  'ID: ${payment.transactionId}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: payment.transactionId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Transaction ID copied!',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: AppColors.primaryGreen,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Payment payment) {
    final isPending = payment.status == 'pending' ||
        (payment.paymentMethod.toLowerCase().contains('cash') &&
            payment.status != 'paid' &&
            payment.status != 'successful');

    final color = isPending
        ? Colors.amber.shade900
        : (payment.status == 'failed'
            ? Colors.redAccent
            : Colors.green.shade700);

    final bg = isPending
        ? Colors.amber.withAlpha(25)
        : (payment.status == 'failed'
            ? Colors.redAccent.withAlpha(20)
            : Colors.green.withAlpha(20));

    final label = isPending
        ? 'PAY AT PICKUP'
        : (payment.status == 'failed' ? 'FAILED' : 'PAID');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
