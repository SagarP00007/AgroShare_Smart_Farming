import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_card.dart';
import '../widgets/section_title.dart';
import 'chat_screen.dart';

/// Displays full details for an equipment group including members and status.
/// Contact is via in-app chat only; no phone/email shared.
class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key, required this.groupName, this.groupId});

  final String groupName;
  final String? groupId;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  String get _emoji => '🚜';
  String get _name => widget.groupName;

  late Map<String, bool> _paymentStatus;
  List<String> _memberIds = [];
  String _location = 'Community';
  int _currentMembers = 0;
  int _targetMembers = 5;
  String _sharePerFarmer = '₹0';
  bool _isFull = false;
  bool get _allPaid => _isFull && _paymentStatus.values.every((paid) => paid);

  @override
  void initState() {
    super.initState();
    if (widget.groupId == null) {
      _currentMembers = 2;
      _targetMembers = 3;
      _location = 'Community';
      _sharePerFarmer = '₹2,00,000';
      _paymentStatus = {'Member 1': true, 'Member 2': false};
    } else {
      _paymentStatus = {};
    }
  }

  void _applyGroupData(Map<String, dynamic> data) {
    final members = List<String>.from(data['members'] ?? []);
    final current = (data['currentMembers'] ?? 0).toInt();
    final target = (data['targetMembers'] ?? 5).toInt();
    final price = (data['targetPrice'] ?? 0).toDouble();
    final share = target > 0 ? (price / target).toInt() : 0;
    setState(() {
      _memberIds = members;
      _currentMembers = current;
      _targetMembers = target;
      _location = (data['location'] ?? 'Community') as String;
      _sharePerFarmer = '₹${share.toStringAsFixed(0)}';
      _isFull = current >= target;
      _paymentStatus = {
        for (int i = 0; i < members.length; i++) 'Member ${i + 1}': i.isEven,
      };
    });
  }

  void _togglePayment(String member) {
    if (_paymentStatus[member] == true) return;
    setState(() => _paymentStatus[member] = true);
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: AppSpacing.lg),
            _buildStatusCard(),
            const SizedBox(height: AppSpacing.lg),
            _buildMemberList(),
            if (_isFull) ...[
              const SizedBox(height: AppSpacing.lg),
              _buildEscrowPayment(),
            ],
            const SizedBox(height: AppSpacing.lg),
            _buildContactViaChatNote(),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showReportSheet(context),
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: const Text('Report User'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm + 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.buttonRadius,
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Group Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.textLight,
        elevation: 0,
      ),
      body: widget.groupId != null
          ? StreamBuilder<DocumentSnapshot>(
              stream: FirestoreService.instance.groupStream(widget.groupId!),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data =
                      snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _applyGroupData(data);
                  });
                }
                return body;
              },
            )
          : body,
    );
  }

  /// Note: contact only via in-app chat; no phone/email shared.
  Widget _buildContactViaChatNote() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withAlpha(15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.primaryGreen.withAlpha(40)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 20,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Contact only via in-app chat. No phone or email is shared with other members.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Escrow Payment Section ─────────────────────────────────────

  Widget _buildEscrowPayment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Escrow Payment', padding: EdgeInsets.zero),
        const SizedBox(height: AppSpacing.md),
        AgCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with shield icon
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Color(0xFF1565C0),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deposit Amount',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          '₹5,000',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_allPaid)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm + 2,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: Text(
                        'PURCHASE READY',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textLight,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Escrow message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withAlpha(12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: const Color(0xFF1565C0).withAlpha(40),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: Color(0xFF1565C0),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Payment secured by AgroShare Escrow.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1565C0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              const Divider(color: AppColors.divider),
              const SizedBox(height: AppSpacing.sm),

              // Per-member payment status
              for (final entry in _paymentStatus.entries)
                _PaymentRow(
                  name: entry.key,
                  isPaid: entry.value,
                  onPay: () => _togglePayment(entry.key),
                ),

              // All-paid status
              if (_allPaid) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm + 2,
                    horizontal: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 18,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Purchase Ready',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Report Bottom Sheet ────────────────────────────────────────

  void _showReportSheet(BuildContext context) {
    const reasons = ['Fraud', 'Fake listing', 'Misbehavior'];
    const icons = [
      Icons.warning_amber_rounded,
      Icons.description_outlined,
      Icons.person_off_outlined,
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                Text(
                  'Report User',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Select a reason for reporting:',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                for (int i = 0; i < reasons.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      leading: Icon(icons[i], color: Colors.redAccent),
                      title: Text(
                        reasons[i],
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        side: const BorderSide(color: AppColors.divider),
                      ),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Report submitted successfully.',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Equipment Info ─────────────────────────────────────────────

  Widget _buildInfoCard() {
    return AgCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Text(_emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  _name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.divider),
          const SizedBox(height: AppSpacing.md),

          // Info rows
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: _location,
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
            icon: Icons.people_outline_rounded,
            label: 'Members',
            value: '$_currentMembers / $_targetMembers',
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
            icon: Icons.currency_rupee_rounded,
            label: 'Share per Farmer',
            value: _sharePerFarmer,
          ),
        ],
      ),
    );
  }

  // ── Group Status ───────────────────────────────────────────────

  Widget _buildStatusCard() {
    return AgCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _isFull
                  ? AppColors.primaryGreen.withAlpha(25)
                  : Colors.orange.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _isFull
                  ? Icons.check_circle_rounded
                  : Icons.hourglass_top_rounded,
              size: 24,
              color: _isFull ? AppColors.primaryGreen : Colors.orange,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group Status',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _isFull ? 'Ready to Purchase' : 'Waiting for Members',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: _isFull
                        ? AppColors.primaryGreen
                        : Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),
          if (_isFull)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                'READY',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                  letterSpacing: 1.0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Member List (Message via chat only; no contact details) ────

  Widget _buildMemberList() {
    final members = _memberIds.isEmpty
        ? ['Member 1', 'Member 2']
        : List.generate(_memberIds.length, (i) => 'Member ${i + 1}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Members', padding: EdgeInsets.zero),
        const SizedBox(height: AppSpacing.md),
        AgCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            children: [
              for (int i = 0; i < members.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.divider),
                _MemberTile(
                  name: members[i],
                  index: i,
                  memberId: i < _memberIds.length ? _memberIds[i] : null,
                  onMessage: i < _memberIds.length
                      ? () {
                          final uid = AuthService.instance.currentUser?.uid;
                          if (uid == null || uid == _memberIds[i]) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                chatId: '',
                                equipmentId: 'group-chat',
                                equipmentName: 'Group Chat',
                                equipmentImage: '',
                                ownerId: _memberIds[i],
                                ownerName: 'Group member',
                              ),
                            ),
                          );
                        }
                      : null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Info Row Helper ──────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryGreen),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

// ── Member Tile Helper ───────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.name,
    required this.index,
    this.memberId,
    this.onMessage,
  });

  final String name;
  final int index;
  final String? memberId;
  final VoidCallback? onMessage;

  // Cycle through avatar colors
  static const _avatarColors = [
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
    Color(0xFFEF6C00),
    Color(0xFF6A1B9A),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _avatarColors[index % _avatarColors.length];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withAlpha(30),
            child: Text(
              name[0].toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _statChip(
                      Icons.handshake_outlined,
                      'Member',
                      AppColors.primaryGreen,
                    ),
                    if (onMessage != null && memberId != null)
                      TextButton.icon(
                        onPressed: onMessage,
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                        ),
                        label: Text(
                          'Message',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm - 2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment Row Helper ──────────────────────────────────────────

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.name,
    required this.isPaid,
    required this.onPay,
  });

  final String name;
  final bool isPaid;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          if (isPaid)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Paid',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: onPay,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Pending',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
