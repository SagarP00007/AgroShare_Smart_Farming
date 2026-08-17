import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/farmer.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/image_picker_util.dart';
import '../l10n/app_localizations.dart';
import '../l10n/locale_provider.dart';
import '../widgets/ag_card.dart';
import '../widgets/ag_button.dart';
import '../widgets/section_title.dart';
import 'login_screen.dart';

/// Profile screen showing farmer overview, trust score, and activity summary.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

/// Locale code -> translation key for language name.
/// Locale code -> translation key for language name.
const Map<String, String> _localeToNames = {
  'en': 'English',
  'hi': 'Hindi (हिंदी)',
  'kn': 'Kannada (ಕನ್ನಡ)',
  'bn': 'Bengali (বাংলা)',
  'te': 'Telugu (తెలుగు)',
  'ta': 'Tamil (தமிழ்)',
  'mr': 'Marathi (मराठी)',
  'gu': 'Gujarati (ગુજરાતી)',
  'ml': 'Malayalam (മലയാളം)',
  'pa': 'Punjabi (ਪੰਜਾਬੀ)',
  'or': 'Odia (ଓଡ଼ିଆ)',
  'ur': 'Urdu (اردو)',
};

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploadingProfilePhoto = false;
  Key _profileStreamKey = UniqueKey();

  void _retryProfile() {
    setState(() => _profileStreamKey = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          L.tr(context, 'profile'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        key: _profileStreamKey,
        stream: FirestoreService.instance.userStream(uid ?? 'guest'),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          var farmer = Farmer.fromMap(uid ?? 'guest', data);
          if (data.isEmpty || snapshot.hasError || farmer.name.isEmpty) {
            farmer = FirestoreService.instance.getFallbackFarmer(uid);
          }

          final activeUid = uid ?? 'guest_farmer';

          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(context, farmer, activeUid),
                  const SizedBox(height: AppSpacing.lg),
                  _buildTrustScore(farmer),
                  const SizedBox(height: AppSpacing.lg),
                  _buildActivitySummary(farmer, activeUid),
                  const SizedBox(height: AppSpacing.lg),
                  _buildMyEquipment(context, activeUid),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSettings(context, farmer, activeUid),
                  const SizedBox(height: AppSpacing.lg),
                  _buildLanguagePreferences(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildLogout(context),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl),
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.secondaryGreen.withAlpha(40),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 56,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Welcome, Farmer!',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Sign in to manage your equipment listings, view bookings, and access your profile.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AgButton(
              label: 'Log In / Register',
              icon: Icons.login_rounded,
              isExpanded: true,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildLanguagePreferences(),
          ],
        ),
      ),
    );
  }

  // ── Section 1: Profile Header ──────────────────────────────────

  Future<void> _pickAndUploadProfilePhoto(
    BuildContext context,
    String uid,
  ) async {
    if (_isUploadingProfilePhoto) return;
    final file = await pickImageFromSource(context);
    if (file == null || !context.mounted) return;
    setState(() => _isUploadingProfilePhoto = true);
    try {
      final url =
          await StorageService.instance.uploadProfileImage(file, uid);
      if (!context.mounted) return;
      await FirestoreService.instance.updateProfile(uid, {'profileImage': url});
      if (!context.mounted) return;
      setState(() => _isUploadingProfilePhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile photo updated.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _isUploadingProfilePhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildProfileHeader(
    BuildContext context,
    Farmer farmer,
    String uid,
  ) {
    final hasProfileImage = farmer.profileImage.isNotEmpty &&
        farmer.profileImage.startsWith('http');

    return AgCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          GestureDetector(
            onTap: _isUploadingProfilePhoto
                ? null
                : () => _pickAndUploadProfilePhoto(context, uid),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: AppColors.secondaryGreen.withAlpha(40),
                  backgroundImage: hasProfileImage
                      ? NetworkImage(farmer.profileImage)
                      : null,
                  child: hasProfileImage
                      ? null
                      : const Icon(
                          Icons.person_rounded,
                          size: 42,
                          color: AppColors.primaryGreen,
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.cardBackground,
                        width: 2,
                      ),
                    ),
                    child: _isUploadingProfilePhoto
                        ? const Padding(
                            padding: EdgeInsets.all(4),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textLight,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            size: 14,
                            color: AppColors.textLight,
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farmer.name.isEmpty ? 'Farmer' : farmer.name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        farmer.email,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (farmer.location.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        farmer.location,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section 2: Trust Score ─────────────────────────────────────

  Widget _buildTrustScore(Farmer farmer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Trust Score', padding: EdgeInsets.zero),
        const SizedBox(height: AppSpacing.md),
        AgCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(30),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      size: 28,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    farmer.trustScore.toStringAsFixed(1),
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '/ 5.0',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(color: AppColors.divider),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _trustStat(
                      Icons.handshake_outlined,
                      '${farmer.completedRentals}',
                      'Completed\nRentals',
                      AppColors.primaryGreen,
                    ),
                  ),
                  Container(width: 1, height: 48, color: AppColors.divider),
                  Expanded(
                    child: _trustStat(
                      Icons.groups_outlined,
                      '${farmer.groupPurchases}',
                      'Community\nPurchases',
                      const Color(0xFF1565C0),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _trustStat(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSpacing.xs),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppColors.textMuted,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  // ── Section 3: Activity Summary ────────────────────────────────

  Widget _buildActivitySummary(Farmer farmer, String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Activity Summary', padding: EdgeInsets.zero),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _activityCard(
                Icons.receipt_long_rounded,
                '${farmer.completedRentals}',
                'Total Rentals',
                AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirestoreService.instance.userEquipmentStream(uid),
                builder: (context, snap) {
                  final count = snap.data?.docs.length ?? 0;
                  return _activityCard(
                    Icons.inventory_2_rounded,
                    '$count',
                    'Equipment\nListed',
                    const Color(0xFF1565C0),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _activityCard(
    IconData icon, String value, String label, Color color,
  ) {
    return AgCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMuted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section 4: My Equipment ────────────────────────────────────

  Widget _buildMyEquipment(BuildContext context, String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'My Equipment', padding: EdgeInsets.zero),
        const SizedBox(height: AppSpacing.md),
        StreamBuilder<QuerySnapshot>(
          stream: FirestoreService.instance.userEquipmentStream(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              );
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return AgCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: Text(
                    'No equipment listed yet.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _EquipmentListingCard(
                    emoji: data['listingType'] == 'rent' ? '🚜' : '💰',
                    name: data['name'] ?? '',
                    pricePerHour: '₹${(data['pricePerHour'] ?? 0).toInt()}/hour',
                    isAvailable: data['isAvailable'] ?? true,
                    onEdit: () =>
                        _showEditEquipmentDialog(context, doc.id, data),
                    onRemove: () async {
                      await FirestoreService.instance.deleteEquipment(doc.id);
                      if (context.mounted) {
                        _showSnackbar(context, 'Equipment removed.');
                      }
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showEditEquipmentDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final priceCtrl = TextEditingController(
      text: ((data['pricePerHour'] ?? data['price']) ?? 0).toInt().toString(),
    );
    final locationCtrl = TextEditingController(text: data['locationName'] ?? data['location'] ?? '');
    bool isAvailable = data['isAvailable'] ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            'Edit Equipment',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Equipment Name',
                    labelStyle: GoogleFonts.poppins(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Price per Hour (₹)',
                    labelStyle: GoogleFonts.poppins(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: locationCtrl,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    labelStyle: GoogleFonts.poppins(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  title: Text(
                    'Available for Rent',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  value: isAvailable,
                  activeColor: AppColors.primaryGreen,
                  onChanged: (val) {
                    setDialogState(() => isAvailable = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                await FirestoreService.instance.updateEquipment(docId, {
                  'name': nameCtrl.text.trim(),
                  'pricePerHour': price,
                  'price': price,
                  'locationName': locationCtrl.text.trim(),
                  'location': locationCtrl.text.trim(),
                  'isAvailable': isAvailable,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  _showSnackbar(context, 'Equipment updated successfully!');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section 5: Settings ────────────────────────────────────────

  Widget _buildSettings(BuildContext context, Farmer farmer, String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Settings', padding: EdgeInsets.zero),
        const SizedBox(height: AppSpacing.md),
        AgCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                label: 'Edit Profile',
                onTap: () => _showEditProfileDialog(context, farmer),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _SettingsTile(
                icon: Icons.phone_outlined,
                label: 'Change Phone Number',
                onTap: () => _showEditPhoneDialog(context, farmer),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditProfileDialog(BuildContext context, Farmer farmer) {
    final nameCtrl = TextEditingController(text: farmer.name);
    final locationCtrl = TextEditingController(text: farmer.location);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: GoogleFonts.poppins(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: locationCtrl,
              decoration: InputDecoration(
                labelText: 'Location',
                labelStyle: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirestoreService.instance.updateProfile(
                AuthService.instance.uid,
                {
                  'name': nameCtrl.text.trim(),
                  'location': locationCtrl.text.trim(),
                },
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                _showSnackbar(context, 'Profile updated!');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditPhoneDialog(BuildContext context, Farmer farmer) {
    final phoneCtrl = TextEditingController(text: farmer.phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Change Phone', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            labelStyle: GoogleFonts.poppins(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirestoreService.instance.updateProfile(
                AuthService.instance.uid,
                {'phone': phoneCtrl.text.trim()},
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                _showSnackbar(context, 'Phone number updated!');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Section 6: Language Preferences (all Indian languages) ──────

  Widget _buildLanguagePreferences() {
    final currentCode = LocaleProviderInherited.of(context)?.locale.languageCode ?? 'en';
    final localeCodes = AppLocalizations.supportedLocales
        .map((l) => l.languageCode)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: L.tr(context, 'language_preferences'),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        AgCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            children: [
              for (int i = 0; i < localeCodes.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, color: AppColors.divider),
                ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🇮🇳', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _localeToNames[localeCodes[i]] ?? localeCodes[i].toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    currentCode == localeCodes[i]
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: currentCode == localeCodes[i]
                        ? AppColors.primaryGreen
                        : AppColors.textMuted,
                    size: 22,
                  ),
                  onTap: () async {
                    await LocaleProviderInherited.of(context)?.setLocale(Locale(localeCodes[i]));
                    if (mounted) setState(() {});
                  },
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Logout ─────────────────────────────────────────────────────

  Widget _buildLogout(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AgButton(
        label: L.tr(context, 'logout'),
        icon: Icons.logout_rounded,
        isExpanded: true,
        onPressed: () async {
          await AuthService.instance.signOut();
          if (!context.mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }
}

// ── Equipment Listing Card ───────────────────────────────────────

class _EquipmentListingCard extends StatelessWidget {
  const _EquipmentListingCard({
    required this.emoji,
    required this.name,
    required this.pricePerHour,
    required this.isAvailable,
    required this.onEdit,
    required this.onRemove,
  });

  final String emoji;
  final String name;
  final String pricePerHour;
  final bool isAvailable;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AgCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pricePerHour,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? AppColors.primaryGreen.withAlpha(20)
                      : Colors.orange.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isAvailable ? 'Available' : 'Rented Out',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isAvailable ? AppColors.primaryGreen : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    side: const BorderSide(color: AppColors.primaryGreen),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.buttonRadius,
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.buttonRadius,
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Settings Tile Helper ─────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tileColor = AppColors.primaryGreen;

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: tileColor.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: tileColor),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 2,
      ),
    );
  }
}
