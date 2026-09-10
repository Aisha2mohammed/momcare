import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';
import 'package:pregnancy_appp/screens/wellness/music_detail.dart';
import 'package:pregnancy_appp/services/api_service.dart';
//import 'package:pregnancy_appp/services/content_service.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Music category tabs + Story tab
  static const List<String> _musicCategories = ['relaxation', 'classical', 'lullaby', 'stories'];
  static const List<String> _tabLabels = ['Relaxation', 'Classical', 'Lullaby', 'Stories'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _musicCategories.length, vsync: this);
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
        title: Text(AppStrings.of(context, 'music')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _tabLabels.map((c) {
            if (c == 'Stories') {
              return const Tab(
                icon: Icon(Icons.auto_stories_rounded, size: 16),
                text: 'Stories',
                iconMargin: EdgeInsets.only(bottom: 2),
              );
            }
            return Tab(text: c);
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _musicCategories.map((c) => _MusicListTab(category: c)).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Music List Tab — shows title + image cards, taps open detail page
// ─────────────────────────────────────────────────────────────────────────────

class _MusicListTab extends StatefulWidget {
  final String category;
  const _MusicListTab({required this.category});

  @override
  State<_MusicListTab> createState() => _MusicListTabState();
}

class _MusicListTabState extends State<_MusicListTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _tracks = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true; // keep state when switching tabs

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Fetch with lang=null so we get full multi-lingual payload from backend
      final localeCode = _safeLocale();
      final response = await ApiService.get(
        '/music?category=${Uri.encodeComponent(widget.category)}&lang=$localeCode&limit=100',
      );
      final data = response['data'];
      if (!mounted) return;
      if (data is List) {
        setState(() => _tracks = data.cast<Map<String, dynamic>>());
      } else {
        setState(() => _tracks = []);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _safeLocale() {
    try {
      final ctx = context;
      final code = Localizations.localeOf(ctx).languageCode;
      // backend uses 'om' for Oromo, 'so' for Somali
      if (['en', 'am', 'om', 'so'].contains(code)) return code;
    } catch (_) {}
    return 'en';
  }

  String _resolveTitle(Map<String, dynamic> t, String lang) {
    String pick(String k) {
      final v = t[k];
      return (v is String && v.trim().isNotEmpty) ? v.trim() : '';
    }

    // Try current lang, then en, then am, then any
    for (final k in ['title_$lang', 'title${lang[0].toUpperCase()}${lang.substring(1)}',
        'titleEn', 'title_en', 'titleAm', 'title_am']) {
      final v = pick(k);
      if (v.isNotEmpty) return v;
    }
    return pick('title') != '' ? pick('title') : 'Untitled';
  }

  String _resolveImage(Map<String, dynamic> t) {
    for (final k in ['imageUrl', 'image_url', 'thumbnailUrl', 'thumbnail_url']) {
      final v = t[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  String _formatDuration(dynamic d) {
    if (d == null) return '';
    final s = (d is num) ? d.toInt() : int.tryParse(d.toString()) ?? 0;
    if (s <= 0) return '';
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_off_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No ${widget.category} music available yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
          ],
        ),
      );
    }

    final lang = _safeLocale();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _tracks.length,
      itemBuilder: (context, index) {
        final t = _tracks[index];
        final title = _resolveTitle(t, lang);
        final imageUrl = _resolveImage(t);
        final dur = _formatDuration(t['durationSeconds'] ?? t['duration_seconds']);

        return _TrackCard(
          title: title,
          imageUrl: imageUrl,
          duration: dur,
          category: (t['category'] as String?) ?? widget.category,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MusicDetailPage(track: t),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single track card — image + title only
// ─────────────────────────────────────────────────────────────────────────────

class _TrackCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String duration;
  final String category;
  final VoidCallback onTap;

  const _TrackCard({
    required this.title,
    required this.imageUrl,
    required this.duration,
    required this.category,
    required this.onTap,
  });

  static const _categoryColors = {
    'relaxation': Color(0xFF7C3AED),
    'classical': Color(0xFF2563EB),
    'lullaby': Color(0xFFDB2777),
  };

  @override
  Widget build(BuildContext context) {
    final accentColor = _categoryColors[category.toLowerCase()] ?? AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // ── Thumbnail ──────────────────────────────────────────────
                Hero(
                  tag: 'music_img_$title',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _fallback(accentColor),
                          )
                        : _fallback(accentColor),
                  ),
                ),
                const SizedBox(width: 14),
                // ── Title + meta ───────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1A1A2E),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              category[0].toUpperCase() + category.substring(1),
                              style: TextStyle(
                                fontSize: 10,
                                color: accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (duration.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.timer_outlined, size: 12, color: Colors.grey[400]),
                            const SizedBox(width: 3),
                            Text(
                              duration,
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // ── Play icon ──────────────────────────────────────────────
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, accentColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallback(Color color) => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.2), color.withOpacity(0.08)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(Icons.music_note_rounded, color: color, size: 30),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Story Tab
// ─────────────────────────────────────────────────────────────────────────────

class _StoryTab extends StatelessWidget {
  const _StoryTab();

  static const List<Map<String, dynamic>> _stories = [
    {
      'emoji': '🌙',
      'title': 'Bedtime Calming Stories',
      'titleAm': 'የሌሊት ተረቶች',
      'description': 'Gentle stories to help you unwind and sleep peacefully.',
      'duration': '10–15 min',
      'color': 0xFF7C3AED,
    },
    {
      'emoji': '🌸',
      'title': 'Nature & Relaxation Tales',
      'titleAm': 'ተፈጥሮ ተረቶች',
      'description': 'Soothing stories set in forests, meadows, and peaceful places.',
      'duration': '8–12 min',
      'color': 0xFF059669,
    },
    {
      'emoji': '👶',
      'title': 'Baby Bond Stories',
      'titleAm': 'ለፅንሱ ተረቶች',
      'description': 'Loving stories to connect with your growing baby.',
      'duration': '5–10 min',
      'color': 0xFFDB2777,
    },
    {
      'emoji': '✨',
      'title': 'Affirmations & Guided Thoughts',
      'titleAm': 'አዎንታዊ ሀሳቦች',
      'description': 'Positive affirmations and guided relaxation for expectant mothers.',
      'duration': '10 min',
      'color': 0xFFD97706,
    },
    {
      'emoji': '🫶',
      'title': 'Mindfulness for Pregnancy',
      'titleAm': 'ለእርግዝና ሚንድፉልነስ',
      'description': 'Breathing, body-scan, and mindfulness sessions for every trimester.',
      'duration': '12–20 min',
      'color': 0xFF0891B2,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Header banner
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.75),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Text('📖', style: TextStyle(fontSize: 36)),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Relaxation Stories',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Calm your mind with gentle stories curated for pregnancy.',
                      style: TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ..._stories.map((s) => _StoryCard(story: s)),
      ],
    );
  }
}

class _StoryCard extends StatelessWidget {
  final Map<String, dynamic> story;
  const _StoryCard({required this.story});

  @override
  Widget build(BuildContext context) {
    final color = Color(story['color'] as int);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(story['emoji'] as String, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if ((story['titleAm'] as String).isNotEmpty)
                        Text(
                          story['titleAm'] as String,
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        story['description'] as String,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 3),
                          Text(
                            story['duration'] as String,
                            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.play_arrow_rounded, color: color, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}