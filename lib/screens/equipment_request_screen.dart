import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipment_request.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/ag_button.dart';
import '../widgets/ag_card.dart';
import 'create_request_screen.dart';
import 'request_detail_screen.dart';
import 'main_shell.dart';

/// Equipment Requests hub screen allowing farmers to post equipment needs
/// and equipment owners to browse and respond with machinery offers.
class EquipmentRequestScreen extends StatefulWidget {
  const EquipmentRequestScreen({super.key});

  @override
  State<EquipmentRequestScreen> createState() => _EquipmentRequestScreenState();
}

class _EquipmentRequestScreenState extends State<EquipmentRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Equipment Requests',
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Open Requests'),
            Tab(text: 'My Requests'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top CTA Banner
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AgCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_comment_rounded,
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
                            'Need Machinery for Your Farm?',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            'Post a request and receive offers from owners nearby.',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateRequestScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                      ),
                      child: Text(
                        'Post Request',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OpenRequestsTab(),
                  _MyRequestsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenRequestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.instance.openRequestsStream(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        var requests = docs
            .map((d) => EquipmentRequest.fromMap(
                d.id, d.data() as Map<String, dynamic>))
            .where((r) => r.isOpen)
            .toList();

        if (requests.isEmpty || snapshot.hasError) {
          requests = FirestoreService.instance.getFallbackEquipmentRequests();
        }

        if (requests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_rounded,
                    size: 56,
                    color: AppColors.textMuted.withAlpha(120),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No open requests nearby',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Check back later or post your own equipment request above.',
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

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          physics: const BouncingScrollPhysics(),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            return _RequestCardItem(request: req);
          },
        );
      },
    );
  }
}

class _MyRequestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser?.uid ?? 'farmer_demo';

    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.instance.myEquipmentRequestsStream(uid),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        var myRequests = docs
            .map((d) => EquipmentRequest.fromMap(
                d.id, d.data() as Map<String, dynamic>))
            .toList();

        if (myRequests.isEmpty || snapshot.hasError) {
          myRequests = FirestoreService.instance.getFallbackEquipmentRequests();
        }

        if (myRequests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.playlist_add_check_rounded,
                    size: 56,
                    color: AppColors.textMuted.withAlpha(120),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'You have no active requests',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AgButton(
                    label: 'Post New Request',
                    icon: Icons.add_rounded,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateRequestScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          physics: const BouncingScrollPhysics(),
          itemCount: myRequests.length,
          itemBuilder: (context, index) {
            final req = myRequests[index];
            return _RequestCardItem(request: req);
          },
        );
      },
    );
  }
}

class _RequestCardItem extends StatelessWidget {
  const _RequestCardItem({required this.request});

  final EquipmentRequest request;

  @override
  Widget build(BuildContext context) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final dateStr =
        '${request.requiredDate.day} ${months[request.requiredDate.month - 1]} ${request.requiredDate.year}';

    return AgCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestDetailScreen(
              requestId: request.id,
              fallbackRequest: request,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.agriculture_rounded,
                  color: AppColors.primaryGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.equipmentType,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${request.taskCrop} • ${request.locationName}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${request.maxBudgetPerHour.toInt()}/hr',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppSpacing.sm),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '$dateStr (${request.durationHours} hrs)',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w500),
                  ),
                ],
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.reply_all_rounded, size: 14, color: AppColors.primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      '${request.responseCount} Offers',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
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
