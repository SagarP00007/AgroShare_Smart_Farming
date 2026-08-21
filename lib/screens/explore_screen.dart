import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'main_shell.dart';
import '../widgets/ag_card.dart';
import '../widgets/section_title.dart';
import '../services/news_service.dart';
import '../widgets/reactive_helpers.dart';

/// Agriculture Knowledge Hub — Explore screen.
///
/// Contains three sections:
/// 1. Equipment Knowledge
/// 2. New Agricultural Technologies
/// 3. Daily Agriculture News
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late Future<List<NewsArticle>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _refreshNews();
  }

  void _refreshNews() {
    setState(() {
      _newsFuture = NewsService.instance.getFarmingNews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.textLight.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.explore_rounded,
                size: 18,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              L.tr(context, 'explore'),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshNews,
            tooltip: L.tr(context, 'refresh_news'),
          ),
          const SizedBox(width: 8),
        ],
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
      body: RefreshIndicator(
        onRefresh: () async => _refreshNews(),
        color: AppColors.primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),

              // Welcome Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryGreen.withAlpha(20),
                        AppColors.secondaryGreen.withAlpha(10),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryGreen.withAlpha(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.wb_sunny_rounded,
                            color: AppColors.primaryGreen,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            L.tr(context, 'good_day_farmer'),
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        L.tr(context, 'stay_updated_news'),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── SECTION 1 — Equipment Knowledge ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: SectionTitle(
                  title: L.tr(context, 'equipment_knowledge'),
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                ),
              ),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
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
                  title: L.tr(context, 'new_agri_technologies'),
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
                  title: L.tr(context, 'daily_farming_news'),
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                ),
              ),
              FutureBuilder<List<NewsArticle>>(
                future: _newsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return ReactiveHelpers.errorState(
                      L.tr(context, 'failed_to_load_news'),
                      onRetry: _refreshNews,
                    );
                  }

                  final newsArticles = snapshot.data ?? [];
                  if (newsArticles.isEmpty) {
                    return ReactiveHelpers.emptyState(
                      L.tr(context, 'no_news_available'),
                      L.tr(context, 'check_back_later'),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    itemCount: newsArticles.length,
                    itemBuilder: (context, index) {
                      final news = newsArticles[index];
                      return _EnhancedNewsCard(news: news);
                    },
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
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
                    child: Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
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
                  fontSize: 14,
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
                  fontSize: 12,
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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [item.color.withAlpha(30), item.color.withAlpha(15)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 26),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: item.color.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'NEW',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: item.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnhancedNewsCard extends StatelessWidget {
  const _EnhancedNewsCard({required this.news});

  final NewsArticle news;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AgCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: InkWell(
          onTap: () {
            // Can add navigation to full article here
          },
          borderRadius: AppSpacing.cardRadius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.article_rounded,
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
                          news.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                            height: 1.3,
                          ),
                        ),
                        if (news.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            news.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryGreen.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      news.source,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryGreen,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    news.timeAgo,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
