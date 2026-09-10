import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';
import 'package:pregnancy_appp/services/content_service.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _resolveUrl(String? url) {
  if (url == null || url.trim().isEmpty) return '';
  final trimmed = url.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  const host = 'http://192.168.0.199:5000';
  if (trimmed.startsWith('/')) {
    return '$host$trimmed';
  }
  return '$host/$trimmed';
}

String _extractLocalized(
  dynamic source,
  String lang, {
  List<String> amKeys = const [],
  List<String> orKeys = const [],
  List<String> soKeys = const [],
  List<String> enKeys = const [],
  List<String> defaultKeys = const [],
  String fallback = '',
}) {
  if (source is! Map) {
    if (source is String && source.trim().isNotEmpty) return source.trim();
    return fallback;
  }

  String? check(List<String> keys) {
    for (final k in keys) {
      final v = source[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  String? match;
  if (lang == 'am') match = check(amKeys);
  if (lang == 'or') match = check(orKeys);
  if (lang == 'so') match = check(soKeys);
  if (lang == 'en') match = check(enKeys);

  if (match != null && match.isNotEmpty) return match;

  return check(enKeys) ??
      check(amKeys) ??
      check(orKeys) ??
      check(soKeys) ??
      check(defaultKeys) ??
      fallback;
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Video Page
// ─────────────────────────────────────────────────────────────────────────────

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          AppStrings.of(context, 'video'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: "1st Trimester"),
                Tab(text: "2nd Trimester"),
                Tab(text: "3rd Trimester"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _TrimesterVideoList(trimester: 1),
          _TrimesterVideoList(trimester: 2),
          _TrimesterVideoList(trimester: 3),
        ],
      ),
    );
  }
}

class _TrimesterVideoList extends StatefulWidget {
  final int trimester;
  const _TrimesterVideoList({required this.trimester});

  @override
  State<_TrimesterVideoList> createState() => _TrimesterVideoListState();
}

class _TrimesterVideoListState extends State<_TrimesterVideoList>
    with AutomaticKeepAliveClientMixin {
  List<_VideoItem> _videos = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    setState(() => _loading = true);
    final list = <_VideoItem>[];

    try {
      final userLang = await ContentService.getLanguage();
      final items = await ContentService.getNutrition(widget.trimester);

      for (final item in items) {
        if (item is! Map) continue;
        final rawSections = item['nutrientSectionsJson'] ??
            item['nutrient_sections_json'] ??
            item['nutrient_sections'] ??
            item['sections'];

        final itemVideo = _resolveUrl((item['videoUrl'] ?? item['video_url']) as String?);
        final itemTitle = _extractLocalized(
          item,
          userLang,
          amKeys: ['titleAm', 'title_am'],
          orKeys: ['titleOr', 'title_or'],
          soKeys: ['titleSo', 'title_so'],
          enKeys: ['titleEn', 'title_en'],
          defaultKeys: ['title', 'name'],
          fallback: 'Nutrition Guide',
        );

        final itemBody = _extractLocalized(
          item,
          userLang,
          amKeys: ['bodyAm', 'body_am'],
          orKeys: ['bodyOr', 'body_or'],
          soKeys: ['bodySo', 'body_so'],
          enKeys: ['bodyEn', 'body_en'],
          defaultKeys: ['body', 'description'],
          fallback: 'Essential pregnancy nutrition guide',
        );

        final itemThumb = _resolveUrl((item['imageUrl'] ?? item['image_url']) as String?);
        final emoji = (item['emoji'] as String?) ?? '🥗';

        if (itemVideo.isNotEmpty) {
          list.add(_VideoItem(
            title: itemTitle,
            description: itemBody,
            videoUrl: itemVideo,
            thumbnailUrl: itemThumb,
            emoji: emoji,
            category: 'Nutrition',
          ));
        }

        if (rawSections is List) {
          for (final sec in rawSections) {
            if (sec is! Map) continue;
            final secVideo = _resolveUrl((sec['videoUrl'] ?? sec['video_url']) as String?);
            final secEmoji = (sec['emoji'] as String?) ?? emoji;

            final secTitle = _extractLocalized(
              sec,
              userLang,
              amKeys: ['videoTitleAm', 'titleAm', 'title_am'],
              orKeys: ['videoTitleOr', 'titleOr', 'title_or'],
              soKeys: ['videoTitleSo', 'titleSo', 'title_so'],
              enKeys: ['videoTitleEn', 'titleEn', 'title_en'],
              defaultKeys: ['videoTitle', 'video_title', 'title', 'nutrientType', 'type'],
              fallback: '$secEmoji Nutrient Video',
            );

            final secDesc = _extractLocalized(
              sec,
              userLang,
              amKeys: ['bodyAm', 'body_am'],
              orKeys: ['bodyOr', 'body_or'],
              soKeys: ['bodySo', 'body_so'],
              enKeys: ['bodyEn', 'body_en'],
              defaultKeys: ['body', 'description'],
              fallback: 'Nutritional benefits and food preparation',
            );

            final secThumb = _resolveUrl((sec['imageUrl'] ?? sec['image_url']) as String?);

            if (secVideo.isNotEmpty) {
              list.add(_VideoItem(
                title: secTitle,
                description: secDesc,
                videoUrl: secVideo,
                thumbnailUrl: secThumb.isNotEmpty ? secThumb : itemThumb,
                emoji: secEmoji,
                category: 'Nutrients',
              ));
            }

            final foods = sec['foods'];
            if (foods is List) {
              for (final food in foods) {
                if (food is! Map) continue;
                final fVideo = _resolveUrl((food['videoUrl'] ?? food['video_url']) as String?);
                if (fVideo.isNotEmpty) {
                  final fName = _extractLocalized(
                    food,
                    userLang,
                    amKeys: ['nameAm', 'name_am'],
                    orKeys: ['nameOr', 'name_or'],
                    soKeys: ['nameSo', 'name_so'],
                    enKeys: ['nameEn', 'name_en'],
                    defaultKeys: ['name', 'title'],
                    fallback: 'Food Video Guide',
                  );

                  final fDesc = _extractLocalized(
                    food,
                    userLang,
                    amKeys: ['descriptionAm', 'descAm'],
                    orKeys: ['descriptionOr', 'descOr'],
                    soKeys: ['descriptionSo', 'descSo'],
                    enKeys: ['descriptionEn', 'descEn'],
                    defaultKeys: ['description', 'why_include', 'benefit'],
                    fallback: 'Healthy pregnancy preparation',
                  );

                  final fThumb = _resolveUrl((food['imageUrl'] ?? food['image_url']) as String?);

                  list.add(_VideoItem(
                    title: fName,
                    description: fDesc,
                    videoUrl: fVideo,
                    thumbnailUrl: fThumb.isNotEmpty ? fThumb : (secThumb.isNotEmpty ? secThumb : itemThumb),
                    emoji: secEmoji,
                    category: 'Foods',
                  ));
                }
              }
            }
          }
        }
      }
    } catch (_) {
      // Fall back to curated videos below
    }

    // Curated educational pregnancy videos fallback per trimester
    if (list.isEmpty) {
      if (widget.trimester == 1) {
        list.addAll([
          const _VideoItem(
            title: "First Trimester Nutrition & Morning Sickness",
            description: "Essential foods, folic acid, hydration and managing nausea in weeks 1 to 13.",
            videoUrl: "https://www.youtube.com/watch?v=F_31wG7p73U",
            thumbnailUrl: "",
            emoji: "🥗",
            category: "Nutrition",
          ),
          const _VideoItem(
            title: "First Trimester Gentle Prenatal Exercises",
            description: "Safe stretching, core stability, and gentle movement for early pregnancy.",
            videoUrl: "https://www.youtube.com/watch?v=VpC1o5bQy-g",
            thumbnailUrl: "",
            emoji: "🧘‍♀️",
            category: "Wellness",
          ),
        ]);
      } else if (widget.trimester == 2) {
        list.addAll([
          const _VideoItem(
            title: "Second Trimester Iron & Calcium Guide",
            description: "How to boost iron absorption and support baby's rapid bone and blood development.",
            videoUrl: "https://www.youtube.com/watch?v=ZfF6T92fDqA",
            thumbnailUrl: "",
            emoji: "🥩",
            category: "Nutrition",
          ),
          const _VideoItem(
            title: "Fetal Development & Anatomy Scan Tips",
            description: "What to expect during your mid-pregnancy ultrasound and monitoring kicks.",
            videoUrl: "https://www.youtube.com/watch?v=8lXgW5LhE-g",
            thumbnailUrl: "",
            emoji: "👶",
            category: "Fetal Growth",
          ),
        ]);
      } else {
        list.addAll([
          const _VideoItem(
            title: "Third Trimester Nutrition & Energy Needs",
            description: "Healthy calorie intake, hydration, and preparing your body for labor and delivery.",
            videoUrl: "https://www.youtube.com/watch?v=B_g6F3m8V5w",
            thumbnailUrl: "",
            emoji: "🥑",
            category: "Nutrition",
          ),
          const _VideoItem(
            title: "Labor Preparation & Breathing Exercises",
            description: "Breathing techniques, pelvic floor relaxation, and signs of active labor.",
            videoUrl: "https://www.youtube.com/watch?v=k_K8R1x5f5A",
            thumbnailUrl: "",
            emoji: "🏥",
            category: "Birth Prep",
          ),
        ]);
      }
    }

    if (mounted) {
      setState(() {
        _videos = list;
        _loading = false;
      });
    }
  }

  Future<void> _playVideo(String url) async {
    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video link is not available yet.')),
      );
      return;
    }
    try {
      final uri = Uri.parse(_resolveUrl(url));
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open video: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _videos.length,
      itemBuilder: (ctx, i) => _buildVideoCard(_videos[i]),
    );
  }

  Widget _buildVideoCard(_VideoItem item) {
    final hasThumb = item.thumbnailUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _playVideo(item.videoUrl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video Thumbnail Area with Centered Play Button
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: hasThumb
                          ? Image.network(
                              item.thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder(item),
                            )
                          : _placeholder(item),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Category Badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(item.emoji, style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              item.category.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Centered Play Button
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.primary,
                            size: 34,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Title and Description
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(_VideoItem item) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 4),
            Text(
              item.category,
              style: TextStyle(
                color: AppColors.primary.withValues(alpha: 0.7),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoItem {
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final String emoji;
  final String category;

  const _VideoItem({
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.emoji,
    required this.category,
  });
}
