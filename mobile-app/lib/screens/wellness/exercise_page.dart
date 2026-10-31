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
import 'exercise_detail_page.dart';

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

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage>
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
        title: Text(AppStrings.of(context, 'exercise')),
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
                _ExerciseList(trimester: 1, selectedWeek: _selectedWeek),
                _ExerciseList(trimester: 2, selectedWeek: _selectedWeek),
                _ExerciseList(trimester: 3, selectedWeek: _selectedWeek),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseList extends StatefulWidget {
  final int trimester;
  final int selectedWeek;

  const _ExerciseList({required this.trimester, required this.selectedWeek});

  @override
  State<_ExerciseList> createState() => _ExerciseListState();
}

class _ExerciseListState extends State<_ExerciseList> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  String? _lastLang;
  String _currentType = 'do';

  Map<String, dynamic>? _weekInfo;



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
  void didUpdateWidget(covariant _ExerciseList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedWeek != widget.selectedWeek ||
        oldWidget.trimester != widget.trimester) {
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
      final exFuture = ContentService.getExercises(
        widget.trimester,
        week: week,
        type: _currentType,
        lang: currentLang,
      );
      final weekFuture = ContentService.getExerciseWeek(
        widget.trimester,
        month: month,
        week: week,
        lang: currentLang,
      );

      final results = await Future.wait([exFuture, weekFuture]);
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

    String exerciseTips = resolveStr(_weekInfo, [
      'exercise_tips_$lKey', 'exercise_tips_$currentLang',
      'exerciseTips$lKey', 'exerciseTips$currentLang',
      'exercise_tips', 'exerciseTips',
      'tips_$lKey', 'tips_$currentLang',
      'tips',
    ]);
    if (exerciseTips.isEmpty) {
      for (final it in _items) {
        if (it is Map) {
          final candidate = resolveStr(it, [
            'exercise_tips_$lKey', 'exercise_tips_$currentLang',
            'exercise_tips', 'exerciseTips',
            'tips_$lKey', 'tips_$currentLang',
            'tips',
          ]);
          if (candidate.isNotEmpty) {
            exerciseTips = candidate;
            break;
          }
        }
      }
    }

    final listView = _items.isEmpty
        ? ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fitness_center_rounded, size: 64, color: Colors.grey[400]),
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
              if (whyImportant.trim().isNotEmpty)
                WellnessInfoCard.whyImportant(context: context, content: whyImportant),
              if (exerciseTips.trim().isNotEmpty)
                WellnessInfoCard.exerciseTips(context: context, content: exerciseTips),
            ],
          )
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _items.length + 1,
            itemBuilder: (context, index) {
              if (index == _items.length) {
                if (whyImportant.trim().isEmpty && exerciseTips.trim().isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    if (whyImportant.trim().isNotEmpty)
                      WellnessInfoCard.whyImportant(context: context, content: whyImportant),
                    if (exerciseTips.trim().isNotEmpty)
                      WellnessInfoCard.exerciseTips(context: context, content: exerciseTips),
                  ],
                );
              }
              return _buildExerciseItem(context, _items[index]);
            },
          );

    return Column(
      children: [
        WellnessTypeFilterRow(
          currentType: _currentType,
          firstKey: 'do',
          firstLabel: AppStrings.of(context, 'what_to_do'),
          firstIcon: '💪',
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

  Widget _buildExerciseItem(BuildContext context, dynamic item) {
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

    final name = resolve([
      'title_$lKey', 'title_$lang', 'name_$lKey', 'name_$lang',
      'title', 'name', 'title_en', 'title_am',
    ]);
    final safetyNotes = resolve([
      'why_important_$lKey', 'why_important_$lang', 'safety_notes_$lKey', 'safety_notes_$lang',
      'why_important', 'safetyNotes', 'safety_notes', 'description_$lKey', 'description',
    ]);
    final durationMin = (item['duration_minutes'] as num?)?.toInt() ??
        (item['duration_min'] as num?)?.toInt() ??
        0;
    final imageUrl =
        _resolveUrl(_safeExtractMedia(item['image_url'] ?? item['imageUrl'] ?? item['image']));
    final videoUrl =
        _resolveUrl(_safeExtractMedia(item['video_url'] ?? item['videoUrl'] ?? item['video']));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExerciseDetailPage(
              exercise: Map<String, dynamic>.from(item as Map),
              isAvoid: _currentType == 'avoid',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image or In-UI Video player ─────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              child: videoUrl.isNotEmpty
                  ? AppVideoPlayer(
                      videoUrl: videoUrl,
                      title: name,
                      aspectRatio: 16 / 9,
                      thumbnailUrl: imageUrl.isNotEmpty ? imageUrl : null,
                    )
                  : (imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _ExercisePlaceholder(),
                        )
                      : _ExercisePlaceholder()),
            ),

            // ── Text content ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (name.isNotEmpty)
                              Text(
                                name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 17),
                              ),
                            if (durationMin > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.timer_rounded,
                                      size: 13, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppStrings.of(context, 'about_min').replaceAll('%d', '$durationMin'),
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.chevron_right_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                    ],
                  ),
                  if (safetyNotes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      safetyNotes,
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

class _ExercisePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.primary.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.fitness_center_rounded,
          color: Colors.white.withValues(alpha: 0.5),
          size: 56,
        ),
      ),
    );
  }
}
