import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'main_shell.dart';
import '../widgets/ag_card.dart';
import '../widgets/section_title.dart';

/// Agriculture Knowledge Hub — Explore screen.
///
/// Contains three sections:
/// 1. Equipment Knowledge
/// 2. New Agricultural Technologies
/// 3. Daily Agriculture News
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Explore',
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),

            // ── SECTION 1 — Equipment Knowledge ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SectionTitle(
                title: 'Equipment Knowledge',
                trailing: Text(
                  'Learn',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              ),
            ),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: _knowledgeItems.length,
                itemBuilder: (context, index) {
                  final item = _knowledgeItems[index];
                  return _KnowledgeCard(
                    item: item,
                    onTap: () => _showKnowledgeModal(context, item),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── SECTION 2 — New Agricultural Technologies ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SectionTitle(
                title: 'New Agri Technologies',
                trailing: Text(
                  'Innovation',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: _techItems.length,
              itemBuilder: (context, index) {
                final item = _techItems[index];
                return _TechCard(item: item);
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── SECTION 3 — Daily Agriculture News ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SectionTitle(
                title: 'Daily Agriculture News',
                trailing: Text(
                  'Today',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: _newsItems.length,
              itemBuilder: (context, index) {
                final news = _newsItems[index];
                return _NewsCard(news: news);
              },
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  void _showKnowledgeModal(BuildContext context, _KnowledgeItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
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
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryGreen.withAlpha(30),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(item.emoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  item.title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  item.detail,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DATA MODELS & DUMMY DATA
// ─────────────────────────────────────────────

class _KnowledgeItem {
  const _KnowledgeItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.detail,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final String detail;
}

const _knowledgeItems = [
  _KnowledgeItem(
    emoji: '🚜',
    title: 'Tractor Usage Guide',
    subtitle: 'Ploughing, tilling & hauling',
    detail:
        'Tractors are the backbone of modern farming. They are used for '
        'ploughing fields, tilling soil, hauling heavy loads, and powering '
        'implements like rotavators and seed drills.\n\n'
        'Key tips:\n'
        '• Always check oil and coolant levels before use.\n'
        '• Use the right HP tractor for your farm size.\n'
        '• Maintain tyre pressure for optimal traction.',
  ),
  _KnowledgeItem(
    emoji: '🌾',
    title: 'Harvester Efficiency Tips',
    subtitle: 'Maximize crop yield',
    detail:
        'Combine harvesters can reduce harvesting time by up to 90% compared '
        'to manual methods.\n\n'
        'Efficiency tips:\n'
        '• Harvest at optimal moisture content (14-18%).\n'
        '• Clean sieves regularly to reduce grain loss.\n'
        '• Adjust reel speed based on crop height.',
  ),
  _KnowledgeItem(
    emoji: '🌱',
    title: 'Seed Drill Benefits',
    subtitle: 'Precision seed placement',
    detail:
        'Seed drills ensure uniform seed spacing and depth, leading to '
        'better germination rates and higher yields.\n\n'
        'Benefits:\n'
        '• 20-30% seed savings compared to broadcast sowing.\n'
        '• Uniform plant growth and easier weeding.\n'
        '• Compatible with fertilizer placement for dual benefit.',
  ),
  _KnowledgeItem(
    emoji: '💧',
    title: 'Smart Irrigation',
    subtitle: 'Water management',
    detail:
        'Smart irrigation systems use soil moisture sensors and weather '
        'data to optimize water usage.\n\n'
        'Advantages:\n'
        '• Save up to 40% water compared to flood irrigation.\n'
        '• Reduce energy costs for pumping.\n'
        '• Prevent over-watering and root rot.',
  ),
];

class _TechItem {
  const _TechItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
}

const _techItems = [
  _TechItem(
    icon: Icons.smart_toy_rounded,
    title: 'AI Crop Monitoring',
    description:
        'Machine learning algorithms analyze satellite imagery to detect '
        'crop diseases, pest infestations, and nutrient deficiencies early.',
    color: Colors.blue,
  ),
  _TechItem(
    icon: Icons.water_drop_rounded,
    title: 'Smart Irrigation Systems',
    description:
        'IoT-based sensors monitor soil moisture in real-time and '
        'automatically trigger irrigation only when needed.',
    color: Colors.cyan,
  ),
  _TechItem(
    icon: Icons.flight_rounded,
    title: 'Drone-based Spraying',
    description:
        'Agricultural drones deliver precise fertilizer and pesticide '
        'application, reducing chemical usage by up to 40%.',
    color: Colors.deepPurple,
  ),
];

class _NewsItem {
  const _NewsItem({
    required this.icon,
    required this.headline,
    required this.source,
    required this.timeAgo,
  });

  final IconData icon;
  final String headline;
  final String source;
  final String timeAgo;
}

const _newsItems = [
  _NewsItem(
    icon: Icons.account_balance_rounded,
    headline: 'Government subsidy announced for tractors — up to ₹50,000 benefit for small farmers.',
    source: 'Krishi News',
    timeAgo: '2h ago',
  ),
  _NewsItem(
    icon: Icons.eco_rounded,
    headline: 'New drought-resistant rice variety released by ICAR for semi-arid regions.',
    source: 'AgriToday',
    timeAgo: '5h ago',
  ),
  _NewsItem(
    icon: Icons.water_drop_rounded,
    headline: 'AI-based irrigation systems help reduce water consumption by 35% in Karnataka farms.',
    source: 'FarmTech India',
    timeAgo: '8h ago',
  ),
  _NewsItem(
    icon: Icons.trending_up_rounded,
    headline: 'Wheat prices surge 12% — MSP increase expected in upcoming kharif season.',
    source: 'Agri Market',
    timeAgo: '1d ago',
  ),
];

// ─────────────────────────────────────────────
// CARD WIDGETS
// ─────────────────────────────────────────────

class _KnowledgeCard extends StatelessWidget {
  const _KnowledgeCard({required this.item, required this.onTap});

  final _KnowledgeItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        child: AgCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(item.emoji, style: const TextStyle(fontSize: 24)),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textMuted.withAlpha(120),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechCard extends StatelessWidget {
  const _TechCard({required this.item});

  final _TechItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AgCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.news});

  final _NewsItem news;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AgCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(news.icon, color: AppColors.primaryGreen, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        news.source,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '· ${news.timeAgo}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
