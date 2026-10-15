import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/content_service.dart';
import 'package:pregnancy_appp/services/mother_service.dart';
import 'package:pregnancy_appp/widget/app_video_player.dart';
import 'package:pregnancy_appp/widget/week_selector.dart';
import 'package:pregnancy_appp/widget/wellness_info_card.dart';
import 'package:pregnancy_appp/widget/wellness_type_filter_row.dart';
import 'sleep_detail_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// URL resolver
// ─────────────────────────────────────────────────────────────────────────────

String _safeExtractMedia(dynamic source) {
  if (source == null) return '';
  if (source is String) return source.trim();
  if (source is Map) {
    if (source['url'] != null) return _safeExtractMedia(source['url']);
    if (source['uri'] != null) return _safeExtractMedia(source['uri']);
    if (source['path'] != null) return _safeExtractMedia(source['path']);
    if (source['en'] != null) return _safeExtractMedia(source['en']);
  }
  return source.toString();
}

String _safeStr(dynamic val, [String fallback = '']) {
  if (val == null) return fallback;
  if (val is String) {
    final trimmed = val.trim();
    return trimmed.isNotEmpty ? trimmed : fallback;
  }
  if (val is Map) {
    for (final key in ['label', 'value', 'text', 'title', 'name', 'tip', 'desc', 'description', 'en', 'am', 'om', 'or', 'so']) {
      final v = val[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v is Map) {
        final inner = _safeStr(v);
        if (inner.isNotEmpty) return inner;
      }
    }
  }
  return val.toString();
}

String _resolveUrl(String? url) {
  if (url == null || url.trim().isEmpty) return '';
  return resolveVideoUrl(url);
}

class SleepTipsPage extends StatefulWidget {
  const SleepTipsPage({super.key});

  @override
  State<SleepTipsPage> createState() => _SleepTipsPageState();
}

class _SleepTipsPageState extends State<SleepTipsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // 0 = not loaded yet → no week filter is applied.
  int _currentWeek = 0;
  int _selectedWeek = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectCurrentTrimester();
    _loadWeek();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWeek() async {
    try {
      final data = await MotherService.getGestationalWeek();
      final week = (data['currentWeek'] as int?) ?? 0;
      if (!mounted || week <= 0) return;
      setState(() {
        _currentWeek = week;
        _selectedWeek = week;
      });
    } catch (_) {
      // Keep 0 → the week selector still renders, the current-week chip is
      // simply not highlighted and no week filter is applied.
    }
  }

  Future<void> _selectCurrentTrimester() async {
    final trimester = await ContentService.currentTrimester();
    if (!mounted || _tabController.index == trimester - 1) return;
    setState(() => _tabController.index = trimester - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(AppStrings.of(context, 'sleeping')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: AppStrings.of(context, 'trimester_1')),
            Tab(text: AppStrings.of(context, 'trimester_2')),
            Tab(text: AppStrings.of(context, 'trimester_3')),
          ],
        ),
      ),
      body: Column(
        children: [
          WeekSelector(
            mode: 'week',
            selected: _selectedWeek,
            currentWeek: _currentWeek,
            onSelected: (v) => setState(() => _selectedWeek = v),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SleepTipsList(trimester: 1, selectedWeek: _selectedWeek),
                _SleepTipsList(trimester: 2, selectedWeek: _selectedWeek),
                _SleepTipsList(trimester: 3, selectedWeek: _selectedWeek),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepTipsList extends StatefulWidget {
  final int trimester;
  final int selectedWeek;

  const _SleepTipsList({required this.trimester, required this.selectedWeek});

  @override
  State<_SleepTipsList> createState() => _SleepTipsListState();
}

class _SleepTipsListState extends State<_SleepTipsList> {
  List<dynamic> _items = [];
  Map<String, dynamic>? _weekInfo;
  bool _loading = true;
  String? _error;
  String? _lastLang;
  String _currentType = 'do';

  static String _defaultSleepWhy(String lang) {
    if (lang == 'am') return 'በግራ ጎን መተኛት ወደ ልጅዎ የሚሄደውን የደም ዝውውር ያሻሽላል።';
    if (lang == 'om' || lang == 'or') return 'Cinaacha bitaatiin ciisuun dhangala’aa dhiigaa daa’imaaf ni dabala.';
    if (lang == 'so') return 'Seexashada dhinaca bidix waxa ay hagaajisaa socodka dhiigga ee ilmaha.';
    return 'Sleeping on your left side improves blood flow to your baby and reduces swelling.';
  }

  static String _defaultSleepTips(String lang) {
    if (lang == 'am') return 'በግራ ጎን ትራስ በጉልበቶች መሀል አድርገው ይተኙ እና ከመተኛትዎ በፊት ከባድ ምግብ አይመገቡ።';
    if (lang == 'om' || lang == 'or') return 'Cinaacha bitaatiin boraatii jilba gidduu kaa’uun ciisaa, hirriba dura nyaata ulfaataa irraa fagaadhaa.';
    if (lang == 'so') return 'Sii dhinaca bidix oo barkimo lugaha dhexdeeda saar, iskana ilaali cunto culus hurdada ka hor.';
    return 'Sleep on your left side with a pillow between your knees and avoid heavy meals before bedtime.';
  }

  

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLang = Localizations.localeOf(context).languageCode;
    if (_lastLang != null && _lastLang != newLang) {
      _load();
    }
    _lastLang = newLang;
  }

  @override
  void didUpdateWidget(covariant _SleepTipsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedWeek != widget.selectedWeek) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final week = widget.selectedWeek > 0 ? widget.selectedWeek : null;
      final month = week != null ? ((week / 4.33).ceil()).clamp(1, 9) : null;
      final currentLang = Localizations.localeOf(context).languageCode;
      final tipsFuture = ContentService.getSleepTips(
        widget.trimester,
        week: week,
        type: _currentType,
        lang: currentLang,
      );
      final weekFuture = ContentService.getSleepWeek(
        widget.trimester,
        month: month,
        week: week,
        lang: currentLang,
      );

      final results = await Future.wait([tipsFuture, weekFuture]);
      if (!mounted) return;

      final fetched = results[0] as List<dynamic>;
      final weekData = results[1] as Map<String, dynamic>?;

      // Client-side week filter.
      List<dynamic> items = fetched;
      if (week != null) {
        final matches = fetched.where((it) {
          final w = it['week'];
          return w != null &&
              (w == week || w.toString() == week.toString());
        }).toList();
        if (matches.isNotEmpty) items = matches;
      }

      // Filter by type (do vs avoid)
      final typeMatches = items.where((it) {
        if (it is! Map) return _currentType == 'do';
        final t = (it['type'] ?? it['category_type'] ?? it['category'] ?? '').toString().toLowerCase();
        final isAvoid = t == 'avoid' || it['isAvoid'] == true || it['is_avoid'] == true;
        return _currentType == 'avoid' ? isAvoid : !isAvoid;
      }).toList();

      items = typeMatches;

      setState(() {
        _items = items;
        _weekInfo = weekData;
      });
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: Text(AppStrings.of(context, 'retry'))),
          ],
        ),
      );
    }

    final currentLang = Localizations.localeOf(context).languageCode;
    final lKey = currentLang == 'or' ? 'om' : currentLang;

    String resolveStr(Map? map, List<String> keys) {
      if (map == null) return '';
      for (final k in keys) {
        final v = map[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return '';
    }

    String whyImportant = resolveStr(_weekInfo, [
      'why_important_$lKey', 'why_important_$currentLang',
      'whyImportant$lKey', 'whyImportant$currentLang',
      'why_important', 'whyImportant',
    ]);
    if (whyImportant.isEmpty) {
      for (final it in _items) {
        if (it is Map) {
          final candidate = resolveStr(it, [
            'why_important_$lKey', 'why_important_$currentLang',
            'why_important', 'whyImportant',
          ]);
          if (candidate.isNotEmpty) {
            whyImportant = candidate;
            break;
          }
        }
      }
    }
    if (whyImportant.isEmpty) {
      whyImportant = _defaultSleepWhy(currentLang);
    }

    String sleepingTips = resolveStr(_weekInfo, [
      'sleeping_tips_$lKey', 'sleeping_tips_$currentLang',
      'sleepingTips$lKey', 'sleepingTips$currentLang',
      'sleeping_tips', 'sleepingTips',
      'tips_$lKey', 'tips_$currentLang',
      'tips',
    ]);
    if (sleepingTips.isEmpty) {
      for (final it in _items) {
        if (it is Map) {
          final candidate = resolveStr(it, [
            'sleeping_tips_$lKey', 'sleeping_tips_$currentLang',
            'sleeping_tips', 'sleepingTips',
            'tips_$lKey', 'tips_$currentLang',
            'tips',
          ]);
          if (candidate.isNotEmpty) {
            sleepingTips = candidate;
            break;
          }
        }
      }
    }
    if (sleepingTips.isEmpty) {
      sleepingTips = _defaultSleepTips(currentLang);
    }

    final listView = _items.isEmpty
        ? ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bedtime_rounded, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.of(context, 'no_data'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              WellnessInfoCard.whyImportant(context: context, content: whyImportant),
              WellnessInfoCard.sleepingTips(context: context, content: sleepingTips),
            ],
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _items.length + 1,
            itemBuilder: (context, index) {
              if (index == _items.length) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    WellnessInfoCard.whyImportant(context: context, content: whyImportant),
                    WellnessInfoCard.sleepingTips(context: context, content: sleepingTips),
                  ],
                );
              }
              return _buildTipCard(context, _items[index]);
            },
          );

    return Column(
      children: [
        WellnessTypeFilterRow(
          currentType: _currentType,
          firstKey: 'do',
          firstLabel: AppStrings.of(context, 'what_to_do'),
          firstIcon: '🌙',
          secondKey: 'avoid',
          secondLabel: AppStrings.of(context, 'what_not_to_do'),
          secondIcon: '🚫',
          onChanged: (newType) {
            setState(() {
              _currentType = newType;
            });
            _load();
          },
        ),
        Expanded(child: listView),
      ],
    );
  }

  Widget _buildTipCard(BuildContext context, dynamic item) {
    final lang = Localizations.localeOf(context).languageCode;
    final lKey = lang == 'or' ? 'om' : lang;

    String resolve(List<String> keys) {
      if (item is! Map) return '';
      for (final k in keys) {
        final v = item[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
        if (v is Map) {
          final s = _safeStr(v);
          if (s.isNotEmpty) return s;
        }
      }
      return '';
    }

    final title = resolve([
      'title_$lKey', 'title_$lang', 'name_$lKey', 'name_$lang',
      'title', 'name', 'title_en', 'title_am',
    ]);
    final description = resolve([
      'description_$lKey', 'description_$lang', 'desc_$lKey', 'desc_$lang',
      'description', 'desc', 'why_important', 'description_en', 'description_am',
    ]);
    final imageUrl =
        _resolveUrl(_safeExtractMedia(item['illustration_url'] ?? item['image_url'] ?? item['imageUrl'] ?? item['image']));
    final videoUrl =
        _resolveUrl(_safeExtractMedia(item['video_url'] ?? item['videoUrl'] ?? item['video']));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SleepDetailPage(
              tip: Map<String, dynamic>.from(item as Map),
              isAvoid: _currentType == 'avoid',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero In-UI Video player or image ─────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: videoUrl.isNotEmpty
                  ? AppVideoPlayer(
                      videoUrl: videoUrl,
                      title: title,
                      aspectRatio: 16 / 9,
                      thumbnailUrl: imageUrl.isNotEmpty ? imageUrl : null,
                    )
                  : (imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _SleepPlaceholder(),
                        )
                      : _SleepPlaceholder()),
            ),

            // ── Text content ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5C6BC0).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFF5C6BC0), size: 20),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.grey[600], height: 1.4, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5C6BC0), Color(0xFF7986CB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.bedtime_rounded,
          color: Colors.white.withValues(alpha: 0.5),
          size: 56,
        ),
      ),
    );
  }
}
