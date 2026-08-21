import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipment.dart';
import '../models/equipment_request.dart';
import '../models/equipment_request_response.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_button.dart';
import '../widgets/ag_card.dart';
import '../widgets/section_title.dart';
import 'chat_screen.dart';

/// Screen displaying equipment request details, responses from owners,
/// and allowing owners to offer machinery or farmers to accept offers.
class RequestDetailScreen extends StatefulWidget {
  const RequestDetailScreen({
    super.key,
    required this.requestId,
    this.fallbackRequest,
  });

  final String requestId;
  final EquipmentRequest? fallbackRequest;

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService.instance.currentUser?.uid ?? 'guest';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirestoreService.instance.equipmentRequestStream(
        widget.requestId,
      ),
      builder: (context, snapshot) {
        EquipmentRequest? request = widget.fallbackRequest;
        if (snapshot.hasData && snapshot.data!.exists) {
          request = EquipmentRequest.fromMap(
            snapshot.data!.id,
            snapshot.data!.data() as Map<String, dynamic>,
          );
        }

        request ??= FirestoreService.instance
            .getFallbackEquipmentRequests()
            .firstWhere(
              (r) => r.id == widget.requestId,
              orElse: () =>
                  widget.fallbackRequest ??
                  FirestoreService.instance
                      .getFallbackEquipmentRequests()
                      .first,
            );

        final isRequester = currentUid == request.requesterId;

        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            title: Text(
              'Equipment Request',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: AppColors.textLight,
            elevation: 0,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRequestCard(request),
                  const SizedBox(height: AppSpacing.lg),

                  if (!isRequester && request.isOpen) ...[
                    AgButton(
                      label: 'Offer My Equipment',
                      icon: Icons.handshake_rounded,
                      isExpanded: true,
                      onPressed: () =>
                          _showOfferEquipmentModal(context, request!),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Responses Section
                  SectionTitle(
                    title:
                        'Owner Offers & Responses (${request.responseCount})',
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  ),

                  _buildResponsesList(request, currentUid),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestCard(EquipmentRequest req) {
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
        '${req.requiredDate.day} ${months[req.requiredDate.month - 1]} ${req.requiredDate.year}';

    return AgCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.agriculture_rounded,
                  color: AppColors.primaryGreen,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.equipmentType,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Requested by ${req.requesterName}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: req.isOpen
                      ? AppColors.primaryGreen.withAlpha(20)
                      : Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  req.status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: req.isOpen ? AppColors.primaryGreen : Colors.grey,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppSpacing.md),

          // Specs grid
          Row(
            children: [
              Expanded(
                child: _infoItem(Icons.eco_rounded, 'Task/Crop', req.taskCrop),
              ),
              Expanded(
                child: _infoItem(
                  Icons.currency_rupee_rounded,
                  'Max Budget',
                  '₹${req.maxBudgetPerHour.toInt()}/hr',
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _infoItem(
                  Icons.calendar_today_rounded,
                  'Required Date',
                  dateStr,
                ),
              ),
              Expanded(
                child: _infoItem(
                  Icons.location_on_outlined,
                  'Location',
                  req.locationName,
                ),
              ),
            ],
          ),

          if (req.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Details:',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              req.description,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.textDark,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildResponsesList(EquipmentRequest req, String currentUid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.instance.requestResponsesStream(req.id),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        var responses = docs
            .map(
              (d) => EquipmentRequestResponse.fromMap(
                d.id,
                d.data() as Map<String, dynamic>,
              ),
            )
            .toList();

        if (responses.isEmpty || snapshot.hasError) {
          responses = FirestoreService.instance.getFallbackRequestResponses(
            req.id,
          );
        }

        if (responses.isEmpty) {
          return AgCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: Text(
                'No offers received yet. Machinery owners nearby will respond soon.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          );
        }

        return Column(
          children: responses.map((resp) {
            return _ResponseCard(
              response: resp,
              request: req,
              currentUid: currentUid,
              onAccept: () async {
                await FirestoreService.instance.acceptRequestResponse(
                  requestId: req.id,
                  responseId: resp.id,
                );

                if (!context.mounted) return;

                // Create chat room with owner
                final chatId = await ChatService().getOrCreateChat(
                  resp.equipmentId,
                  resp.ownerId,
                );

                if (!context.mounted) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chatId: chatId,
                      equipmentId: resp.equipmentId,
                      equipmentName: resp.equipmentName,
                      equipmentImage: resp.equipmentImage,
                      ownerId: resp.ownerId,
                      ownerName: resp.ownerName,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showOfferEquipmentModal(BuildContext context, EquipmentRequest req) {
    final currentUid = AuthService.instance.currentUser?.uid ?? 'seed';
    final priceCtrl = TextEditingController(
      text: req.maxBudgetPerHour.toInt().toString(),
    );
    final msgCtrl = TextEditingController(
      text:
          'I have an available machine ready for your farm on requested date.',
    );
    Equipment? selectedMachine;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              top: AppSpacing.lg,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      'Offer Your Equipment',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Offer equipment to ${req.requesterName} for ${req.equipmentType}.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Select Machine Dropdown from owner listings
                    StreamBuilder<QuerySnapshot>(
                      stream: FirestoreService.instance.userEquipmentStream(
                        currentUid,
                      ),
                      builder: (context, snapshot) {
                        final docs = snapshot.data?.docs ?? [];
                        var myMachines = docs
                            .map(
                              (d) => Equipment.fromMap(
                                d.id,
                                d.data() as Map<String, dynamic>,
                              ),
                            )
                            .toList();

                        if (myMachines.isEmpty) {
                          myMachines = FirestoreService.instance
                              .getFallbackEquipment();
                        }

                        selectedMachine ??= myMachines.first;

                        return DropdownButtonFormField<Equipment>(
                          initialValue: selectedMachine,
                          decoration: InputDecoration(
                            labelText: 'Select Equipment to Offer',
                            labelStyle: GoogleFonts.poppins(
                              color: AppColors.textMuted,
                            ),
                            prefixIcon: const Icon(
                              Icons.agriculture_rounded,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          items: myMachines.map((m) {
                            return DropdownMenuItem(
                              value: m,
                              child: Text(
                                '${m.name} (₹${m.pricePerHour.toInt()}/hr)',
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setModalState(() => selectedMachine = val),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Offered Price
                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Offered Price Per Hour (₹)',
                        prefixIcon: const Icon(
                          Icons.currency_rupee_rounded,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Message
                    TextField(
                      controller: msgCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Message to Farmer',
                        hintText:
                            'e.g. Includes driver and fuel. Ready on date.',
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    AgButton(
                      label: 'Send Offer to Farmer',
                      icon: Icons.send_rounded,
                      isExpanded: true,
                      onPressed: () async {
                        final user = AuthService.instance.currentUser;
                        String ownerName = 'Equipment Owner';
                        if (user != null) {
                          try {
                            final userDoc = await FirestoreService.instance
                                .getUser(user.uid);
                            ownerName =
                                (userDoc.data()
                                    as Map<String, dynamic>?)?['name'] ??
                                'Equipment Owner';
                          } catch (_) {}
                        }

                        await FirestoreService.instance.submitRequestResponse({
                          'requestId': req.id,
                          'ownerId': currentUid,
                          'ownerName': ownerName,
                          'equipmentId': selectedMachine?.id ?? 'eq_offer',
                          'equipmentName':
                              selectedMachine?.name ?? req.equipmentType,
                          'equipmentImage':
                              selectedMachine?.imageUrl ??
                              'assets/images/tractor.webp',
                          'offeredPricePerHour':
                              double.tryParse(priceCtrl.text.trim()) ??
                              req.maxBudgetPerHour,
                          'message': msgCtrl.text.trim(),
                          'status': 'pending',
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Offer sent to ${req.requesterName}!',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: AppColors.primaryGreen,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  const _ResponseCard({
    required this.response,
    required this.request,
    required this.currentUid,
    required this.onAccept,
  });

  final EquipmentRequestResponse response;
  final EquipmentRequest request;
  final String currentUid;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final isRequester = currentUid == request.requesterId;

    return AgCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryGreen.withAlpha(20),
                child: Text(
                  response.ownerName.isNotEmpty
                      ? response.ownerName[0].toUpperCase()
                      : 'O',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      response.ownerName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Offered: ${response.equipmentName}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${response.offeredPricePerHour.toInt()}/hr',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),

          if (response.message.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"${response.message}"',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textDark,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          if (isRequester && request.isOpen)
            Row(
              children: [
                Expanded(
                  child: AgButton(
                    label: 'Accept Offer & Chat / Book',
                    icon: Icons.chat_rounded,
                    onPressed: onAccept,
                  ),
                ),
              ],
            )
          else if (response.isAccepted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primaryGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Offer Accepted ✓',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
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
