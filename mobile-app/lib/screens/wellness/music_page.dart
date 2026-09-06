import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/content_service.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ── Tabs: regular music categories + Story tab at the end ────────────────
  static const List<String> _musicCategories = ['Relaxation', 'Classical', 'Lullaby'];

  @override
  void initState() {
    super.initState();
    // 3 music tabs + 1 Story tab = 4 total
    _tabController = TabController(length: _musicCategories.length + 1, vsync: this);
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
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            ..._musicCategories.map((c) => Tab(text: c)),
            const Tab(
              icon: Icon(Icons.auto_stories_rounded, size: 16),
              text: 'Story',
              iconMargin: EdgeInsets.only(bottom: 2),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ..._musicCategories.map((c) => _MusicListTab(category: c)),
          const _StoryTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Music List Tab (Relaxation / Classical / Lullaby)
// ─────────────────────────────────────────────────────────────────────────────

class _MusicListTab extends StatefulWidget {
  final String category;
  const _MusicListTab({required this.category});

  @override
  State<_MusicListTab> createState() => _MusicListTabState();
}

class _MusicListTabState extends State<_MusicListTab> {
  List<dynamic> _tracks = [];
  bool _loading = true;
  String? _error;

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
      final tracks = await ContentService.getMusic(category: widget.category);
      if (!mounted) return;
      setState(() => _tracks = tracks);
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

  String _formatDuration(dynamic duration) {
    if (duration == null) return '';
    if (duration is num) {
      final seconds = duration.toInt();
      if (seconds <= 0) return '';
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return '$m:${s.toString().padLeft(2, '0')}';
    }
    return duration.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_note_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No ${widget.category.toLowerCase()} music available yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _tracks.length,
      itemBuilder: (context, index) => _buildTrackCard(_tracks[index]),
    );
  }

  Widget _buildTrackCard(dynamic track) {
    final title = (track['title'] as String?) ?? '';
    final duration = _formatDuration(track['duration']);
    final thumbnailUrl = (track['thumbnail_url'] as String?) ?? '';
    final mediaUrl = (track['media_url'] as String?) ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: thumbnailUrl.isNotEmpty
                ? Image.network(
                    thumbnailUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _thumbFallback(),
                  )
                : _thumbFallback(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                if (duration.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(duration,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              mediaUrl.isNotEmpty
                  ? Icons.play_arrow_rounded
                  : Icons.lock_outline_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbFallback() {
    return Container(
      width: 52,
      height: 52,
      color: AppColors.primary.withValues(alpha: 0.1),
      child: const Icon(Icons.music_note_rounded, color: AppColors.primary),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Story Tab  (under Relaxation)
// ─────────────────────────────────────────────────────────────────────────────

class _StoryTab extends StatelessWidget {
  const _StoryTab();

  // Curated story cards — can be wired to backend later
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
                AppColors.primary.withValues(alpha: 0.75),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Text('📖', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              const Expanded(
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Story cards
        ..._stories.map((story) => _StoryCard(story: story)),
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
          onTap: () {
            // TODO: open story player
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Emoji icon in colored circle
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      story['emoji'] as String,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if ((story['titleAm'] as String).isNotEmpty)
                        Text(
                          story['titleAm'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        story['description'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 3),
                          Text(
                            story['duration'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                            ),
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
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: color,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}