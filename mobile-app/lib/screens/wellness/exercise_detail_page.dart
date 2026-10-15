import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/widget/app_video_player.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Multilingual & Safe String Utility Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _safeStr(dynamic val, [String fallback = '']) {
  if (val == null) return fallback;
  if (val is String) {
    final trimmed = val.trim();
    return trimmed.isNotEmpty ? trimmed : fallback;
  }
  if (val is Map) {
    for (final key in ['en', 'am', 'om', 'or', 'so', 'value', 'text', 'title', 'name', 'label', 'tip', 'desc', 'description']) {
      final v = val[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
  }
  return val.toString();
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
  if (source == null) return fallback;
  if (source is String) return source.trim().isNotEmpty ? source.trim() : fallback;
  if (source is! Map) return source.toString();

  String? check(List<String> keys) {
    for (final k in keys) {
      final v = source[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v is Map) {
        final inner = _safeStr(v);
        if (inner.isNotEmpty) return inner;
      }
    }
    return null;
  }

  String? match;
  if (lang == 'am') match = check(amKeys);
  if (lang == 'or' || lang == 'om') {
    match = check(orKeys);
    if (match == null) {
      final omKeys = orKeys.map((k) => k.replaceAll('or', 'om').replaceAll('Or', 'Om')).toList();
      match = check(omKeys);
    }
  }
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
// Exercise Detail Page (Details Tab + In-UI Video Tab)
// ─────────────────────────────────────────────────────────────────────────────

class ExerciseDetailPage extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final bool isAvoid;

  const ExerciseDetailPage({
    super.key,
    required this.exercise,
    this.isAvoid = false,
  });

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static String get _defaultExerciseVideo =>
      '${ApiEndpoints.serverHost}/uploads/file-1789254638769-685033131.mp4';

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

  bool get _isItemAvoid {
    final t = (widget.exercise['type'] ?? widget.exercise['category_type'] ?? '').toString().toLowerCase();
    return widget.isAvoid || t == 'avoid' || widget.exercise['isAvoid'] == true || widget.exercise['is_avoid'] == true;
  }

  String _getTitle(String userLang) => _extractLocalized(
        widget.exercise,
        userLang,
        amKeys: ['titleAm', 'title_am', 'nameAm', 'name_am'],
        orKeys: ['titleOr', 'title_or', 'titleOm', 'title_om', 'nameOr', 'name_or'],
        soKeys: ['titleSo', 'title_so', 'nameSo', 'name_so'],
        enKeys: ['titleEn', 'title_en', 'nameEn', 'name_en'],
        defaultKeys: ['title', 'name'],
        fallback: _isItemAvoid ? 'Exercise to Avoid' : 'Prenatal Exercise',
      );

  String _getBody(String userLang) => _extractLocalized(
        widget.exercise,
        userLang,
        amKeys: ['descriptionAm', 'description_am', 'descAm', 'desc_am', 'bodyAm', 'body_am'],
        orKeys: ['descriptionOr', 'description_or', 'descOr', 'desc_or', 'bodyOr', 'body_or'],
        soKeys: ['descriptionSo', 'description_so', 'descSo', 'desc_so', 'bodySo', 'body_so'],
        enKeys: ['descriptionEn', 'description_en', 'descEn', 'desc_en', 'bodyEn', 'body_en'],
        defaultKeys: ['description', 'desc', 'body', 'steps', 'instructions'],
        fallback: '',
      );

  String _getImageUrl() => resolveVideoUrl(
        _safeStr(widget.exercise['imageUrl'] ?? widget.exercise['image_url']),
      );

  String _getVideoUrl() {
    String raw = _safeStr(widget.exercise['videoUrl'] ?? widget.exercise['video_url'] ?? widget.exercise['video']);
    if (raw.isEmpty) {
      final img = _safeStr(widget.exercise['imageUrl'] ?? widget.exercise['image_url']);
      if (img.endsWith('.mp4') || img.contains('youtube.com') || img.contains('youtu.be')) {
        raw = img;
      }
    }
    if (raw.isEmpty && widget.exercise['list_of_exercise'] is List) {
      for (final it in (widget.exercise['list_of_exercise'] as List)) {
        if (it is Map) {
          final v = _safeStr(it['videoUrl'] ?? it['video_url'] ?? it['video']);
          if (v.isNotEmpty) {
            raw = v;
            break;
          }
        }
      }
    }
    return resolveVideoUrl(raw.isNotEmpty ? raw : _defaultExerciseVideo);
  }

  String _getCategory() =>
      _safeStr(widget.exercise['category'] ?? widget.exercise['type'], _isItemAvoid ? 'AVOID' : 'PRENATAL FITNESS');

  String _getEmoji() {
    final emoji = _safeStr(widget.exercise['emoji']);
    if (emoji.isNotEmpty) return emoji;
    return _isItemAvoid ? '🚫' : '🧘‍♀️';
  }

  String _getReason(String userLang) => _extractLocalized(
        widget.exercise,
        userLang,
        amKeys: ['whyImportantAm', 'why_important_am', 'safetyNotesAm', 'safety_notes_am'],
        orKeys: ['whyImportantOr', 'why_important_or', 'whyImportantOm', 'why_important_om'],
        soKeys: ['whyImportantSo', 'why_important_so', 'safetyNotesSo', 'safety_notes_so'],
        enKeys: ['whyImportantEn', 'why_important_en', 'safetyNotesEn', 'safety_notes_en'],
        defaultKeys: ['why_important', 'whyImportant', 'safety_notes', 'safetyNotes', 'description'],
        fallback: _getBody(userLang),
      );

  String _getDurationLabel(BuildContext context, String userLang) {
    final labelFromBackend = _extractLocalized(
      widget.exercise,
      userLang,
      amKeys: ['descriptionLabelAm', 'description_label_am', 'benefitLabelAm', 'benefit_label_am'],
      orKeys: ['descriptionLabelOr', 'description_label_or', 'benefitLabelOr', 'benefit_label_or'],
      soKeys: ['descriptionLabelSo', 'description_label_so', 'benefitLabelSo', 'benefit_label_so'],
      enKeys: ['descriptionLabelEn', 'description_label_en', 'benefitLabelEn', 'benefit_label_en'],
      defaultKeys: ['description_label', 'benefit_label', 'benefitLabel'],
      fallback: '',
    );
    final valFromBackend = _extractLocalized(
      widget.exercise,
      userLang,
      amKeys: ['descriptionValueAm', 'description_value_am', 'benefitValueAm', 'benefit_value_am'],
      orKeys: ['descriptionValueOr', 'description_value_or', 'benefitValueOr', 'benefit_value_or'],
      soKeys: ['descriptionValueSo', 'description_value_so', 'benefitValueSo', 'benefit_value_so'],
      enKeys: ['descriptionValueEn', 'description_value_en', 'benefitValueEn', 'benefit_value_en'],
      defaultKeys: ['description_value', 'benefit_value', 'benefitValue'],
      fallback: '',
    );

    if (valFromBackend.isNotEmpty) {
      return labelFromBackend.isNotEmpty ? '$labelFromBackend: $valFromBackend' : valFromBackend;
    }

    final min = (widget.exercise['duration_minutes'] as num?)?.toInt() ??
        (widget.exercise['duration_min'] as num?)?.toInt() ??
        0;
    if (min > 0) {
      return AppStrings.of(context, 'about_min').replaceAll('%d', '$min');
    }
    return _isItemAvoid ? 'Risk: Avoid Entirely' : '15-20 min daily';
  }

  String _getHealthTips(String userLang) {
    final rawTips = widget.exercise['health_tips'] ?? widget.exercise['healthTips'] ?? widget.exercise['tips'];
    if (rawTips is List && rawTips.isNotEmpty) {
      return rawTips.map((e) => _safeStr(e)).where((s) => s.isNotEmpty).join(' • ');
    }
    return _extractLocalized(
      widget.exercise,
      userLang,
      amKeys: ['healthTipsAm', 'health_tips_am', 'tipsAm', 'tips_am'],
      orKeys: ['healthTipsOr', 'health_tips_or', 'tipsOr', 'tips_or'],
      soKeys: ['healthTipsSo', 'health_tips_so', 'tipsSo', 'tips_so'],
      enKeys: ['healthTipsEn', 'health_tips_en', 'tipsEn', 'tips_en'],
      defaultKeys: ['health_tips', 'healthTips', 'tips', 'safety_notes'],
      fallback: _isItemAvoid
          ? 'Stop immediately if you experience sharp abdominal pain, bleeding, or dizziness.'
          : 'Stay hydrated, breathe evenly throughout each movement, and rest whenever your body asks.',
    );
  }

  List<Map<String, dynamic>> _getMovements(String userLang) {
    dynamic raw = widget.exercise['list_of_exercise'] ??
        widget.exercise['movements'] ??
        widget.exercise['exercises'] ??
        widget.exercise['items'];

    if (raw is String && raw.trim().startsWith('[')) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {}
    }

    if (raw is List && raw.isNotEmpty) {
      return raw.map((item) {
        if (item is Map) return Map<String, dynamic>.from(item);
        return <String, dynamic>{'name': item.toString()};
      }).toList();
    }

    return [
      {
        'name': _getTitle(userLang),
        'nameEn': _extractLocalized(widget.exercise, 'en', enKeys: ['titleEn', 'title_en', 'nameEn', 'name_en'], defaultKeys: ['name', 'title']),
        'nameAm': _extractLocalized(widget.exercise, 'am', amKeys: ['titleAm', 'title_am', 'nameAm', 'name_am'], defaultKeys: ['name', 'title']),
        'nameOr': _extractLocalized(widget.exercise, 'or', orKeys: ['titleOr', 'title_or', 'nameOr', 'name_or', 'titleOm', 'title_om'], defaultKeys: ['name', 'title']),
        'nameSo': _extractLocalized(widget.exercise, 'so', soKeys: ['titleSo', 'title_so', 'nameSo', 'name_so'], defaultKeys: ['name', 'title']),
        'label': _getDurationLabel(context, userLang),
        'description': _getBody(userLang),
        'descEn': _extractLocalized(widget.exercise, 'en', enKeys: ['descriptionEn', 'description_en', 'bodyEn', 'body_en'], defaultKeys: ['description']),
        'descAm': _extractLocalized(widget.exercise, 'am', amKeys: ['descriptionAm', 'description_am', 'bodyAm', 'body_am'], defaultKeys: ['description']),
        'imageUrl': _getImageUrl(),
        'videoUrl': _getVideoUrl(),
        'tip': _getHealthTips(userLang),
      }
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        String userLang = localeProvider.locale?.languageCode ?? 'am';
        if (userLang == 'om') userLang = 'or';

        return Scaffold(
          backgroundColor: const Color(0xFFF5F0F3),
          body: Column(
            children: [
              // ── Header image / gradient banner ────────────────────────────
              _buildHeader(context, userLang),

              // ── TabBar directly below header ───────────────────────────────
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.list_alt_rounded, size: 18),
                      text: AppStrings.of(context, 'details_tab'),
                      iconMargin: const EdgeInsets.only(bottom: 2),
                    ),
                    Tab(
                      icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                      text: AppStrings.of(context, 'video_tab'),
                      iconMargin: const EdgeInsets.only(bottom: 2),
                    ),
                  ],
                ),
              ),

              // ── Tab Content ────────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ExerciseDetailsTab(
                      title: _getTitle(userLang),
                      category: _getCategory(),
                      emoji: _getEmoji(),
                      isAvoid: _isItemAvoid,
                      reason: _getReason(userLang),
                      durationLabel: _getDurationLabel(context, userLang),
                      healthTips: _getHealthTips(userLang),
                      movements: _getMovements(userLang),
                      userLang: userLang,
                      videoUrl: _getVideoUrl(),
                      onSwitchToVideo: () => _tabController.animateTo(1),
                    ),
                    _ExerciseVideoTab(
                      title: _getTitle(userLang),
                      category: _getCategory(),
                      emoji: _getEmoji(),
                      isAvoid: _isItemAvoid,
                      reason: _getReason(userLang),
                      durationLabel: _getDurationLabel(context, userLang),
                      healthTips: _getHealthTips(userLang),
                      movements: _getMovements(userLang),
                      userLang: userLang,
                      rawAdminVideoUrl: _safeStr(widget.exercise['videoUrl'] ?? widget.exercise['video_url'] ?? widget.exercise['video']),
                      defaultVideoUrl: _getVideoUrl(),
                      thumbnailUrl: _getImageUrl(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, String userLang) {
    final title = _getTitle(userLang);
    final imageUrl = _getImageUrl();
    final emoji = _getEmoji();
    final category = _getCategory();

    return Stack(
      children: [
        // Background
        SizedBox(
          width: double.infinity,
          height: imageUrl.isNotEmpty ? 210 : 130,
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _headerGradient(emoji),
                )
              : _headerGradient(emoji),
        ),
        // Dark gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),
        ),
        // Back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        // Video button top right switches to Video Tab
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: GestureDetector(
            onTap: () => _tabController.animateTo(1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Watch Video',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Title + emoji + badge
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        shadows: [
                          Shadow(blurRadius: 4, color: Colors.black54),
                        ],
                      ),
                    ),
                    if (category.isNotEmpty)
                      Text(
                        category.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              // What to do / avoid badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isItemAvoid
                      ? Colors.red.withValues(alpha: 0.85)
                      : Colors.green.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isItemAvoid ? '🚫 What to Avoid' : '💪 What to Do',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerGradient(String emoji) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 60)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Details Tab
// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseDetailsTab extends StatelessWidget {
  final String title;
  final String category;
  final String emoji;
  final bool isAvoid;
  final String reason;
  final String durationLabel;
  final String healthTips;
  final List<Map<String, dynamic>> movements;
  final String userLang;
  final String videoUrl;
  final VoidCallback onSwitchToVideo;

  const _ExerciseDetailsTab({
    required this.title,
    required this.category,
    required this.emoji,
    required this.isAvoid,
    required this.reason,
    required this.durationLabel,
    required this.healthTips,
    required this.movements,
    required this.userLang,
    required this.videoUrl,
    required this.onSwitchToVideo,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (reason.isNotEmpty)
          _ReasonBanner(reason: reason, isAvoid: isAvoid),
        _ExerciseSectionCard(
          title: title,
          category: category,
          emoji: emoji,
          isAvoid: isAvoid,
          reason: reason,
          durationLabel: durationLabel,
          healthTips: healthTips,
          movements: movements,
          userLang: userLang,
          videoUrl: videoUrl,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reason Banner
// ─────────────────────────────────────────────────────────────────────────────

class _ReasonBanner extends StatelessWidget {
  final String reason;
  final bool isAvoid;

  const _ReasonBanner({required this.reason, this.isAvoid = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAvoid ? Colors.red.shade50 : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAvoid ? Colors.red.shade100 : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isAvoid ? '⚠️' : '💡', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAvoid
                      ? AppStrings.of(context, 'why_to_avoid')
                      : AppStrings.of(context, 'why_this_is_important'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isAvoid ? Colors.red : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  reason,
                  style: TextStyle(
                    color: isAvoid ? Colors.red.shade900 : AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.5,
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

// ─────────────────────────────────────────────────────────────────────────────
// Section Card
// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseSectionCard extends StatelessWidget {
  final String title;
  final String category;
  final String emoji;
  final bool isAvoid;
  final String reason;
  final String durationLabel;
  final String healthTips;
  final List<Map<String, dynamic>> movements;
  final String userLang;
  final String videoUrl;

  const _ExerciseSectionCard({
    required this.title,
    required this.category,
    required this.emoji,
    required this.isAvoid,
    required this.reason,
    required this.durationLabel,
    required this.healthTips,
    required this.movements,
    required this.userLang,
    required this.videoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isAvoid
                  ? Colors.red.shade50
                  : AppColors.primary.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: isAvoid ? Colors.red : AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Duration / Description value badge
          if (durationLabel.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isAvoid
                    ? Colors.red.shade50
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(isAvoid ? '⚠️' : '⏱️', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      durationLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isAvoid ? Colors.red.shade900 : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Health / Safety Tips container
          if (healthTips.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.of(context, 'health_tips_title'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.amber.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          healthTips,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade900,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 6),
          Divider(height: 1, color: Colors.grey.shade100),

          // Movements list
          if (movements.isNotEmpty) ...[
            ...movements.map(
              (movement) => _MovementRow(
                movement: movement,
                isAvoid: isAvoid,
                userLang: userLang,
                defaultVideoUrl: videoUrl,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: GestureDetector(
                onTap: () => _showAllMovements(context, movements, title, emoji),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${AppStrings.of(context, 'view_all_items')} (${movements.length})',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No exercise items listed for this section.',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  void _showAllMovements(
    BuildContext context,
    List<Map<String, dynamic>> movements,
    String typeLabel,
    String emoji,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MovementListSheet(
        movements: movements,
        typeLabel: typeLabel,
        emoji: emoji,
        isAvoid: isAvoid,
        userLang: userLang,
        defaultVideoUrl: videoUrl,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Movement Row
// ─────────────────────────────────────────────────────────────────────────────

class _MovementRow extends StatelessWidget {
  final Map<String, dynamic> movement;
  final bool isAvoid;
  final String userLang;
  final String defaultVideoUrl;

  const _MovementRow({
    required this.movement,
    required this.isAvoid,
    required this.userLang,
    required this.defaultVideoUrl,
  });

  String _name() => _extractLocalized(
        movement,
        userLang,
        amKeys: ['nameAm', 'name_am', 'titleAm', 'title_am'],
        orKeys: ['nameOr', 'name_or', 'nameOm', 'name_om', 'titleOr', 'title_or'],
        soKeys: ['nameSo', 'name_so', 'titleSo', 'title_so'],
        enKeys: ['nameEn', 'name_en', 'titleEn', 'title_en'],
        defaultKeys: ['name', 'title'],
        fallback: 'Exercise Movement',
      );

  @override
  Widget build(BuildContext context) {
    final name = _name();
    final thumb = resolveVideoUrl(_safeStr(movement['imageUrl'] ?? movement['image_url']));

    return InkWell(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _MovementDetailsSheet(
          movement: movement,
          isAvoid: isAvoid,
          userLang: userLang,
          defaultVideoUrl: defaultVideoUrl,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            if (thumb.isNotEmpty && !thumb.endsWith('.mp4'))
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  thumb,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _dotIndicator(),
                ),
              )
            else
              _dotIndicator(),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.info_outline_rounded, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _dotIndicator() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isAvoid ? Colors.red.shade300 : AppColors.primary,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Movement List Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _MovementListSheet extends StatelessWidget {
  final List<Map<String, dynamic>> movements;
  final String typeLabel;
  final String emoji;
  final bool isAvoid;
  final String userLang;
  final String defaultVideoUrl;

  const _MovementListSheet({
    required this.movements,
    required this.typeLabel,
    required this.emoji,
    required this.isAvoid,
    required this.userLang,
    required this.defaultVideoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      typeLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey.shade100),
            Expanded(
              child: ListView.separated(
                controller: controller,
                itemCount: movements.length,
                separatorBuilder: (_, __) =>
                    Divider(color: Colors.grey.shade100, height: 1),
                itemBuilder: (ctx, i) {
                  final m = movements[i];
                  final name = _extractLocalized(
                    m,
                    userLang,
                    amKeys: ['nameAm', 'name_am'],
                    orKeys: ['nameOr', 'name_or', 'nameOm', 'name_om'],
                    soKeys: ['nameSo', 'name_so'],
                    enKeys: ['nameEn', 'name_en'],
                    defaultKeys: ['name', 'title'],
                    fallback: 'Movement Item',
                  );
                  final thumb = resolveVideoUrl(_safeStr(m['imageUrl'] ?? m['image_url']));

                  return ListTile(
                    leading: thumb.isNotEmpty && !thumb.endsWith('.mp4')
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              thumb,
                              width: 38,
                              height: 38,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _leadPlaceholder(),
                            ),
                          )
                        : _leadPlaceholder(),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _MovementDetailsSheet(
                          movement: m,
                          isAvoid: isAvoid,
                          userLang: userLang,
                          defaultVideoUrl: defaultVideoUrl,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leadPlaceholder() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isAvoid ? Colors.red.shade50 : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          isAvoid ? '🚫' : '🧘‍♀️',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Movement Details Bottom Sheet (With In-UI Video Playback & Safe Parsing)
// ─────────────────────────────────────────────────────────────────────────────

class _MovementDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> movement;
  final bool isAvoid;
  final String userLang;
  final String defaultVideoUrl;

  const _MovementDetailsSheet({
    required this.movement,
    required this.isAvoid,
    required this.userLang,
    required this.defaultVideoUrl,
  });

  @override
  State<_MovementDetailsSheet> createState() => _MovementDetailsSheetState();
}

class _MovementDetailsSheetState extends State<_MovementDetailsSheet> {
  bool _showVideoInUi = false;

  String get _name => _extractLocalized(
        widget.movement,
        widget.userLang,
        amKeys: ['nameAm', 'name_am', 'titleAm', 'title_am'],
        orKeys: ['nameOr', 'name_or', 'nameOm', 'name_om', 'titleOr', 'title_or'],
        soKeys: ['nameSo', 'name_so', 'titleSo', 'title_so'],
        enKeys: ['nameEn', 'name_en', 'titleEn', 'title_en'],
        defaultKeys: ['name', 'title'],
        fallback: 'Exercise Movement',
      );

  String get _description => _extractLocalized(
        widget.movement,
        widget.userLang,
        amKeys: ['descriptionAm', 'description_am', 'descAm', 'desc_am'],
        orKeys: ['descriptionOr', 'description_or', 'descOr', 'desc_or'],
        soKeys: ['descriptionSo', 'description_so', 'descSo', 'desc_so'],
        enKeys: ['descriptionEn', 'description_en', 'descEn', 'desc_en'],
        defaultKeys: ['description', 'desc', 'steps', 'instructions'],
        fallback: '',
      );

  String get _imageUrl =>
      resolveVideoUrl(_safeStr(widget.movement['imageUrl'] ?? widget.movement['image_url']));

  String get _videoUrl {
    final raw = _safeStr(widget.movement['videoUrl'] ?? widget.movement['video_url']);
    return resolveVideoUrl(raw.isNotEmpty ? raw : widget.defaultVideoUrl);
  }

  String get _label => _extractLocalized(
        widget.movement,
        widget.userLang,
        amKeys: ['labelAm', 'label_am', 'benefitLabelAm'],
        orKeys: ['labelOr', 'label_or', 'benefitLabelOr'],
        soKeys: ['labelSo', 'label_so', 'benefitLabelSo'],
        enKeys: ['labelEn', 'label_en', 'benefitLabelEn'],
        defaultKeys: ['label', 'benefit_label', 'benefit', 'duration'],
        fallback: '',
      );

  String get _tip => _extractLocalized(
        widget.movement,
        widget.userLang,
        amKeys: ['tipAm', 'tip_am', 'tipsAm', 'safetyAm'],
        orKeys: ['tipOr', 'tip_or', 'tipsOr', 'safetyOr'],
        soKeys: ['tipSo', 'tip_so', 'tipsSo', 'safetySo'],
        enKeys: ['tipEn', 'tip_en', 'tipsEn', 'safetyEn'],
        defaultKeys: ['tip', 'helpful_tips', 'safety', 'safety_notes'],
        fallback: '',
      );

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: ListView(
          controller: controller,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                    SizedBox(width: 4),
                    Text('Movement Details',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ),
            Divider(color: Colors.grey.shade100),

            // In-UI Video Player OR Cover image
            if (_showVideoInUi)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: AppVideoPlayer(
                  key: ValueKey(_videoUrl),
                  videoUrl: _videoUrl,
                  title: _name,
                  thumbnailUrl: _imageUrl,
                  autoPlay: true,
                ),
              )
            else if (_imageUrl.isNotEmpty && !_imageUrl.endsWith('.mp4'))
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    _imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _imagePlaceholder(),
              ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
            ),

            // Toggle In-UI Video Playback Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() => _showVideoInUi = !_showVideoInUi);
                },
                icon: Icon(
                  _showVideoInUi ? Icons.visibility_rounded : Icons.play_circle_fill_rounded,
                  size: 20,
                ),
                label: Text(
                  _showVideoInUi ? 'Hide Video Player' : 'Watch Video in App (With Sound)',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Label block
            if (_label.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: widget.isAvoid ? Colors.red.shade50 : AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(widget.isAvoid ? '⚠️' : '⏱️', style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _label,
                          style: TextStyle(
                            color: widget.isAvoid ? Colors.red.shade900 : AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Description block
            if (_description.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                child: Text(
                  widget.isAvoid ? 'Why avoid this movement?' : 'How to perform safely:',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _description,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.6),
                ),
              ),
            ],

            // Tip block
            if (_tip.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.shade100),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Helpful tip',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.amber)),
                            const SizedBox(height: 4),
                            Text(_tip,
                                style: TextStyle(
                                    color: Colors.grey[800], fontSize: 13, height: 1.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(Icons.fitness_center_rounded,
            size: 48, color: AppColors.primary.withValues(alpha: 0.4)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Video Tab — In-UI Player with Sound, Controls & Sub-items
// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseVideoTab extends StatefulWidget {
  final String title;
  final String category;
  final String emoji;
  final bool isAvoid;
  final String reason;
  final String durationLabel;
  final String healthTips;
  final List<Map<String, dynamic>> movements;
  final String userLang;
  final String rawAdminVideoUrl;
  final String defaultVideoUrl;
  final String? thumbnailUrl;

  const _ExerciseVideoTab({
    required this.title,
    required this.category,
    required this.emoji,
    this.isAvoid = false,
    this.reason = '',
    this.durationLabel = '',
    this.healthTips = '',
    required this.movements,
    required this.userLang,
    this.rawAdminVideoUrl = '',
    required this.defaultVideoUrl,
    this.thumbnailUrl,
  });

  @override
  State<_ExerciseVideoTab> createState() => _ExerciseVideoTabState();
}

class _ExerciseVideoTabState extends State<_ExerciseVideoTab> {
  late List<_ExerciseVideoEntry> _entries;
  _ExerciseVideoEntry? _activeEntry;

  @override
  void initState() {
    super.initState();
    _entries = _buildEntries();
    if (_entries.isNotEmpty) {
      _activeEntry = _entries.first;
    }
  }

  @override
  void didUpdateWidget(covariant _ExerciseVideoTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movements != widget.movements ||
        oldWidget.userLang != widget.userLang ||
        oldWidget.rawAdminVideoUrl != widget.rawAdminVideoUrl ||
        oldWidget.defaultVideoUrl != widget.defaultVideoUrl) {
      setState(() {
        _entries = _buildEntries();
        if (_entries.isNotEmpty &&
            (_activeEntry == null || !_entries.any((e) => e.videoUrl == _activeEntry!.videoUrl))) {
          _activeEntry = _entries.first;
        }
      });
    }
  }

  List<_ExerciseVideoEntry> _buildEntries() {
    final entries = <_ExerciseVideoEntry>[];
    final Set<String> seenUrls = {};

    // 1. Main Exercise Video (only if admin provided a dedicated video)
    if (widget.rawAdminVideoUrl.trim().isNotEmpty) {
      final mainUrl = resolveVideoUrl(widget.rawAdminVideoUrl);
      if (!seenUrls.contains(mainUrl)) {
        seenUrls.add(mainUrl);
        entries.add(_ExerciseVideoEntry(
          emoji: widget.emoji,
          typeLabel: widget.category.isNotEmpty ? widget.category : (widget.isAvoid ? 'AVOID' : 'PRENATAL FITNESS'),
          title: '${widget.title} — Full Session',
          subtitle: widget.reason.isNotEmpty ? widget.reason : 'Doctor-approved prenatal routine walkthrough',
          videoUrl: mainUrl,
          movementName: widget.title,
          imageUrl: widget.thumbnailUrl ?? '',
          isAvoid: widget.isAvoid,
          reps: widget.durationLabel,
          muscles: widget.isAvoid ? 'High Strain / Core Pressure' : 'Full Body & Core Stability',
          description: widget.reason,
          tips: widget.healthTips,
          reason: widget.reason,
        ));
      }
    }

    // 2. Specific Movement Videos (ONLY add if admin explicitly provided a video for this movement)
    for (final m in widget.movements) {
      final rawMVid = _safeStr(m['videoUrl'] ?? m['video_url'] ?? m['video']);
      // Never double-list items that do not have their own admin video
      if (rawMVid.trim().isEmpty) continue;

      final mUrl = resolveVideoUrl(rawMVid);
      if (seenUrls.contains(mUrl)) continue;
      seenUrls.add(mUrl);

      final mName = _extractLocalized(
        m,
        widget.userLang,
        amKeys: ['nameAm', 'name_am'],
        orKeys: ['nameOr', 'name_or', 'nameOm', 'name_om'],
        soKeys: ['nameSo', 'name_so'],
        enKeys: ['nameEn', 'name_en'],
        defaultKeys: ['name', 'title'],
        fallback: 'Exercise Movement',
      );

      final desc = _extractLocalized(
        m,
        widget.userLang,
        amKeys: ['descriptionAm', 'descAm'],
        orKeys: ['descriptionOr', 'descOr'],
        soKeys: ['descriptionSo', 'descSo'],
        enKeys: ['descriptionEn', 'descEn'],
        defaultKeys: ['description', 'desc', 'steps', 'instructions'],
        fallback: 'Movement form and safe execution guide',
      );

      final reps = _extractLocalized(
        m,
        widget.userLang,
        amKeys: ['labelAm', 'label_am', 'repsAm'],
        orKeys: ['labelOr', 'label_or', 'repsOr'],
        soKeys: ['labelSo', 'label_so', 'repsSo'],
        enKeys: ['labelEn', 'label_en', 'repsEn'],
        defaultKeys: ['label', 'reps', 'sets', 'duration'],
        fallback: widget.durationLabel,
      );

      final muscles = _extractLocalized(
        m,
        widget.userLang,
        defaultKeys: ['target_muscles', 'muscles', 'focus_area', 'targetMuscles'],
        fallback: widget.isAvoid ? 'High Strain Zones' : 'Pelvic floor, hips & spinal stabilizers',
      );

      final tip = _extractLocalized(
        m,
        widget.userLang,
        amKeys: ['tipAm', 'tip_am', 'safetyAm'],
        orKeys: ['tipOr', 'tip_or', 'safetyOr'],
        soKeys: ['tipSo', 'tip_so', 'safetySo'],
        enKeys: ['tipEn', 'tip_en', 'safetyEn'],
        defaultKeys: ['tip', 'safety', 'safety_notes', 'helpful_tips'],
        fallback: widget.healthTips,
      );

      final rawThumb = _safeStr(m['imageUrl'] ?? m['image_url']);
      final thumbUrl = resolveVideoUrl(rawThumb);

      entries.add(_ExerciseVideoEntry(
        emoji: widget.emoji,
        typeLabel: widget.category.isNotEmpty ? widget.category : 'EXERCISE ROUTINE',
        title: '$mName — ${widget.title}',
        subtitle: desc,
        videoUrl: mUrl,
        movementName: mName,
        imageUrl: thumbUrl,
        isAvoid: widget.isAvoid,
        reps: reps,
        muscles: muscles,
        description: desc,
        tips: tip,
        reason: widget.reason,
      ));
    }

    // 3. Fallback: If no admin-added videos found across movements or main, provide defaultVideoUrl as single entry
    if (entries.isEmpty && widget.defaultVideoUrl.trim().isNotEmpty) {
      final fallbackUrl = resolveVideoUrl(widget.defaultVideoUrl);
      entries.add(_ExerciseVideoEntry(
        emoji: widget.emoji,
        typeLabel: widget.category.isNotEmpty ? widget.category : (widget.isAvoid ? 'AVOID' : 'PRENATAL FITNESS'),
        title: '${widget.title} — Guided Session',
        subtitle: 'Doctor-approved prenatal routine walkthrough',
        videoUrl: fallbackUrl,
        movementName: widget.title,
        imageUrl: widget.thumbnailUrl ?? '',
        isAvoid: widget.isAvoid,
        reps: widget.durationLabel.isNotEmpty ? widget.durationLabel : '15-20 min daily',
        muscles: widget.isAvoid ? 'High Strain Zones' : 'Pelvic floor, core stability & hip mobility',
        description: widget.reason.isNotEmpty ? widget.reason : 'Safe and doctor-approved pregnancy movement technique.',
        tips: widget.healthTips.isNotEmpty ? widget.healthTips : 'Stay hydrated, breathe evenly throughout each movement, and rest whenever needed.',
        reason: widget.reason,
      ));
    }

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.video_library_rounded, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Videos Available Yet',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Educational video guides added by the specialist will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final active = _activeEntry ?? _entries.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── 1. In-UI Embedded Video Player with Controls ─────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AppVideoPlayer(
            key: ValueKey(active.videoUrl),
            videoUrl: active.videoUrl,
            title: active.title,
            thumbnailUrl: active.imageUrl.isNotEmpty ? active.imageUrl : widget.thumbnailUrl,
            autoPlay: true,
            aspectRatio: 16 / 9,
          ),
        ),
        const SizedBox(height: 14),

        // ── 2. Active Video Properties & Details Card ───────────────────────
        _buildActivePropertiesCard(active),
        const SizedBox(height: 20),

        // ── 3. Available Videos List (No Double Listing) ─────────────────────
        if (_entries.length > 1) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.playlist_play_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Available Exercise Videos (${_entries.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          ..._entries.map(
            (entry) => _ExerciseVideoItemCard(
              entry: entry,
              isSelected: active.videoUrl == entry.videoUrl,
              onSelect: () {
                setState(() {
                  _activeEntry = entry;
                });
              },
            ),
          ),
        ],
      ],
    );
  }

  // Active Video Properties Display
  Widget _buildActivePropertiesCard(_ExerciseVideoEntry entry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Emoji, Title, Category Badge, Avoid/Do Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: entry.isAvoid
                                ? Colors.red.withValues(alpha: 0.1)
                                : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            entry.typeLabel.toUpperCase(),
                            style: TextStyle(
                              color: entry.isAvoid ? Colors.red : AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: entry.isAvoid
                                ? Colors.red.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            entry.isAvoid ? '🚫 Avoid' : '💪 Recommended',
                            style: TextStyle(
                              color: entry.isAvoid ? Colors.red.shade800 : Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Duration / Reps / Sets Badge
          if (entry.reps.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: entry.isAvoid ? Colors.red.shade50 : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: entry.isAvoid ? Colors.red.shade100 : AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Text(entry.isAvoid ? '⚠️' : '⏱️', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.reps,
                      style: TextStyle(
                        color: entry.isAvoid ? Colors.red.shade900 : AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Target Muscles / Focus Area
          if (entry.muscles.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.accessibility_new_rounded,
                    size: 15,
                    color: entry.isAvoid ? Colors.red.shade400 : AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Target Focus: ${entry.muscles}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Safe Execution Guidance / Description
          if (entry.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              entry.isAvoid ? 'Why Avoid This Routine:' : 'Execution Guidance:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              entry.description,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],

          // Safety & Breathing Tips
          if (entry.tips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.tips,
                      style: TextStyle(color: Colors.amber.shade900, fontSize: 12, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exercise Video Data Model & Card
// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseVideoEntry {
  final String emoji;
  final String typeLabel;
  final String title;
  final String subtitle;
  final String videoUrl;
  final String movementName;
  final String imageUrl;
  final bool isAvoid;
  final String reps;
  final String muscles;
  final String description;
  final String tips;
  final String reason;

  _ExerciseVideoEntry({
    required this.emoji,
    required this.typeLabel,
    required this.title,
    required this.subtitle,
    required this.videoUrl,
    required this.movementName,
    required this.imageUrl,
    required this.isAvoid,
    required this.reps,
    required this.muscles,
    required this.description,
    required this.tips,
    required this.reason,
  });
}

class _ExerciseVideoItemCard extends StatelessWidget {
  final _ExerciseVideoEntry entry;
  final bool isSelected;
  final VoidCallback onSelect;

  const _ExerciseVideoItemCard({
    required this.entry,
    this.isSelected = false,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = entry.imageUrl.isNotEmpty && !entry.imageUrl.endsWith('.mp4');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Thumbnail with play overlay
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 90,
                    height: 65,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hasImage)
                          Image.network(
                            entry.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _videoPlaceholder(),
                          )
                        else
                          _videoPlaceholder(),
                        Container(color: Colors.black.withValues(alpha: 0.3)),
                        Center(
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: isSelected ? Colors.white : AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(entry.emoji, style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              entry.typeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: entry.isAvoid ? Colors.red : AppColors.primary,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 13,
                          color: isSelected ? AppColors.primary : Colors.black87,
                        ),
                      ),
                      if (entry.reps.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          entry.reps,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                ),

                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isSelected ? 'PLAYING' : 'WATCH',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _videoPlaceholder() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.15),
      child: Center(
        child: Icon(
          Icons.fitness_center_rounded,
          size: 28,
          color: AppColors.primary.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

