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
    for (final key in [
      'label',
      'value',
      'text',
      'title',
      'name',
      'tip',
      'desc',
      'description',
      'en',
      'am',
      'om',
      'or',
      'so',
      'url'
    ]) {
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

  final l = (lang == 'om' || lang == 'or') ? 'or' : lang;
  if (source[l] != null) {
    final v = source[l];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    if (v is Map) {
      final inner = _safeStr(v);
      if (inner.isNotEmpty) return inner;
    }
  }
  if (lang == 'or' || lang == 'om') {
    final alt = source['om'] ?? source['or'];
    if (alt is String && alt.trim().isNotEmpty) return alt.trim();
  }

  String? check(List<String> keys) {
    for (final k in keys) {
      final v = source[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v is Map) {
        final inner = _extractLocalized(
          v,
          lang,
          amKeys: ['am'],
          orKeys: ['or', 'om'],
          soKeys: ['so'],
          enKeys: ['en'],
          fallback: _safeStr(v),
        );
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

  final def = check(defaultKeys);
  if (def != null && def.isNotEmpty) return def;
  final strL = _safeStr(source[l]);
  if (strL.isNotEmpty) return strL;
  final strEn = _safeStr(source['en']);
  if (strEn.isNotEmpty) return strEn;
  final strAm = _safeStr(source['am']);
  if (strAm.isNotEmpty) return strAm;
  return fallback;
}

// ─────────────────────────────────────────────────────────────────────────────
// Sleep Detail Page (Details Tab + In-UI Video Tab)
// ─────────────────────────────────────────────────────────────────────────────

class SleepDetailPage extends StatefulWidget {
  final Map<String, dynamic> tip;
  final bool isAvoid;

  const SleepDetailPage({
    super.key,
    required this.tip,
    this.isAvoid = false,
  });

  @override
  State<SleepDetailPage> createState() => _SleepDetailPageState();
}

class _SleepDetailPageState extends State<SleepDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static String get _defaultSleepVideo =>
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
    if (widget.isAvoid) return true;
    final t = (widget.tip['type'] ?? widget.tip['category_type'] ?? '').toString().toLowerCase();
    return t == 'avoid' || widget.tip['isAvoid'] == true || widget.tip['is_avoid'] == true;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _getTitle(String userLang) => _extractLocalized(
        widget.tip,
        userLang,
        amKeys: ['titleAm', 'title_am', 'nameAm', 'name_am'],
        orKeys: ['titleOr', 'title_or', 'titleOm', 'title_om', 'nameOr', 'name_or'],
        soKeys: ['titleSo', 'title_so', 'nameSo', 'name_so'],
        enKeys: ['titleEn', 'title_en', 'nameEn', 'name_en'],
        defaultKeys: ['title', 'name'],
        fallback: _isItemAvoid ? 'Sleep Position to Avoid' : 'Sleep & Rest Guide',
      );

  String _getBody(String userLang) => _extractLocalized(
        widget.tip,
        userLang,
        amKeys: ['descriptionAm', 'description_am', 'descAm', 'desc_am', 'bodyAm', 'body_am'],
        orKeys: ['descriptionOr', 'description_or', 'descOr', 'desc_or', 'bodyOr', 'body_or'],
        soKeys: ['descriptionSo', 'description_so', 'descSo', 'desc_so', 'bodySo', 'body_so'],
        enKeys: ['descriptionEn', 'description_en', 'descEn', 'desc_en', 'bodyEn', 'body_en'],
        defaultKeys: ['description', 'desc', 'body', 'tips', 'instructions'],
        fallback: '',
      );

  String _getImageUrl() {
    final raw = _safeExtractMedia(
      widget.tip['illustration_url'] ??
          widget.tip['imageUrl'] ??
          widget.tip['image_url'] ??
          widget.tip['image'],
    );
    return resolveVideoUrl(raw);
  }

  String _getVideoUrl() {
    String raw = _safeExtractMedia(
      widget.tip['videoUrl'] ??
          widget.tip['video_url'] ??
          widget.tip['video'],
    );
    if (raw.isEmpty) {
      final img = _safeExtractMedia(
        widget.tip['illustrationUrl'] ??
            widget.tip['illustration_url'] ??
            widget.tip['imageUrl'] ??
            widget.tip['image_url'],
      );
      if (img.endsWith('.mp4') || img.contains('youtube.com') || img.contains('youtu.be')) {
        raw = img;
      }
    }
    if (raw.isEmpty && widget.tip['list_of_sleep'] is List) {
      for (final it in (widget.tip['list_of_sleep'] as List)) {
        if (it is Map) {
          final v = _safeExtractMedia(it['videoUrl'] ?? it['video_url'] ?? it['video']);
          if (v.isNotEmpty) {
            raw = v;
            break;
          }
        }
      }
    }
    return resolveVideoUrl(raw.isNotEmpty ? raw : _defaultSleepVideo);
  }

  String _getCategory() {
    final cat = _safeStr(widget.tip['category'] ?? widget.tip['type']);
    if (cat.isNotEmpty) return cat;
    return _isItemAvoid ? 'AVOID' : 'HEALTHY SLEEP POSTURE';
  }

  String _getEmoji() {
    final emoji = _safeStr(widget.tip['emoji']);
    if (emoji.isNotEmpty) return emoji;
    return _isItemAvoid ? '🚫' : '🌙';
  }

  String _getReason(String userLang) => _extractLocalized(
        widget.tip,
        userLang,
        amKeys: ['whyImportantAm', 'why_important_am', 'reasonAm', 'reason_am'],
        orKeys: ['whyImportantOr', 'why_important_or', 'whyImportantOm', 'why_important_om'],
        soKeys: ['whyImportantSo', 'why_important_so', 'reasonSo', 'reason_so'],
        enKeys: ['whyImportantEn', 'why_important_en', 'reasonEn', 'reason_en'],
        defaultKeys: ['why_important', 'whyImportant', 'reason', 'description'],
        fallback: _getBody(userLang),
      );

  String _getPostureLabel(String userLang) {
    final labelFromBackend = _extractLocalized(
      widget.tip,
      userLang,
      amKeys: ['descriptionLabelAm', 'description_label_am', 'benefitLabelAm', 'benefit_label_am'],
      orKeys: ['descriptionLabelOr', 'description_label_or', 'benefitLabelOr', 'benefit_label_or'],
      soKeys: ['descriptionLabelSo', 'description_label_so', 'benefitLabelSo', 'benefit_label_so'],
      enKeys: ['descriptionLabelEn', 'description_label_en', 'benefitLabelEn', 'benefit_label_en'],
      defaultKeys: ['description_label', 'benefit_label', 'benefitLabel', 'label'],
      fallback: '',
    );
    final valFromBackend = _extractLocalized(
      widget.tip,
      userLang,
      amKeys: ['descriptionValueAm', 'description_value_am', 'benefitValueAm', 'benefit_value_am'],
      orKeys: ['descriptionValueOr', 'description_value_or', 'benefitValueOr', 'benefit_value_or'],
      soKeys: ['descriptionValueSo', 'description_value_so', 'benefitValueSo', 'benefit_value_so'],
      enKeys: ['descriptionValueEn', 'description_value_en', 'benefitValueEn', 'benefit_value_en'],
      defaultKeys: ['description_value', 'benefit_value', 'benefitValue', 'alignment', 'position'],
      fallback: '',
    );
    if (valFromBackend.isNotEmpty) {
      return labelFromBackend.isNotEmpty ? '$labelFromBackend: $valFromBackend' : valFromBackend;
    }
    if (_isItemAvoid) return 'Risk: Severe Vena Cava Compression';
    return 'Recommended: Left-Side Lateral (SOS)';
  }

  String _getHealthTips(String userLang) {
    final rawTips = widget.tip['health_tips'] ?? widget.tip['healthTips'] ?? widget.tip['tips'];
    if (rawTips is List && rawTips.isNotEmpty) {
      final formatted = rawTips.map((e) => _safeStr(e)).where((s) => s.isNotEmpty).join(' • ');
      if (formatted.isNotEmpty) return formatted;
    }
    return _extractLocalized(
      widget.tip,
      userLang,
      amKeys: ['sleepingTipsAm', 'sleeping_tips_am', 'tipsAm', 'tips_am', 'healthTipsAm', 'health_tips_am'],
      orKeys: ['sleepingTipsOr', 'sleeping_tips_or', 'tipsOr', 'tips_or', 'healthTipsOr', 'health_tips_or'],
      soKeys: ['sleepingTipsSo', 'sleeping_tips_so', 'tipsSo', 'tips_so', 'healthTipsSo', 'health_tips_so'],
      enKeys: ['sleepingTipsEn', 'sleeping_tips_en', 'tipsEn', 'tips_en', 'healthTipsEn', 'health_tips_en'],
      defaultKeys: ['sleeping_tips', 'sleepingTips', 'health_tips', 'healthTips', 'tips', 'additional_tips'],
      fallback: _isItemAvoid
          ? 'Use a wedge pillow behind your back to prevent rolling onto your spine during deep sleep.'
          : 'Tuck a pillow between your knees and under your belly to keep your hips and lower spine comfortably aligned.',
    );
  }

  List<Map<String, dynamic>> _getTechniques(String userLang) {
    dynamic raw = widget.tip['list_of_sleep'] ??
        widget.tip['listSleep'] ??
        widget.tip['techniques'] ??
        widget.tip['sections_json'] ??
        widget.tip['sections'] ??
        widget.tip['tips_list'] ??
        widget.tip['items'];

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
        'name_en': _extractLocalized(widget.tip, 'en', enKeys: ['titleEn', 'title_en', 'nameEn', 'name_en'], defaultKeys: ['name', 'title']),
        'name_am': _extractLocalized(widget.tip, 'am', amKeys: ['titleAm', 'title_am', 'nameAm', 'name_am'], defaultKeys: ['name', 'title']),
        'name_om': _extractLocalized(widget.tip, 'om', orKeys: ['titleOr', 'title_or', 'nameOr', 'name_or', 'titleOm', 'title_om'], defaultKeys: ['name', 'title']),
        'name_so': _extractLocalized(widget.tip, 'so', soKeys: ['titleSo', 'title_so', 'nameSo', 'name_so'], defaultKeys: ['name', 'title']),
        'label': _getPostureLabel(userLang),
        'description': _getBody(userLang),
        'description_en': _extractLocalized(widget.tip, 'en', enKeys: ['descriptionEn', 'description_en', 'bodyEn', 'body_en'], defaultKeys: ['description']),
        'description_am': _extractLocalized(widget.tip, 'am', amKeys: ['descriptionAm', 'description_am', 'bodyAm', 'body_am'], defaultKeys: ['description']),
        'image_url': _getImageUrl(),
        'video_url': _getVideoUrl(),
        'tip': _getHealthTips(userLang),
      }
    ];
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        final userLang = localeProvider.locale?.languageCode ?? 'en';
        final techniques = _getTechniques(userLang);
        final title = _getTitle(userLang);
        final category = _getCategory();
        final emoji = _getEmoji();
        final videoUrl = _getVideoUrl();

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          body: Column(
            children: [
              // ── Header Banner ──────────────────────────────────────────────
              _buildHeader(context, userLang),

              // ── Tab Bar ────────────────────────────────────────────────────
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF5C6BC0),
                  unselectedLabelColor: Colors.grey[500],
                  indicatorColor: const Color(0xFF5C6BC0),
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.menu_book_rounded, size: 18),
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
                    _SleepDetailsTab(
                      title: title,
                      category: category,
                      emoji: emoji,
                      isAvoid: _isItemAvoid,
                      reason: _getReason(userLang),
                      postureLabel: _getPostureLabel(userLang),
                      healthTips: _getHealthTips(userLang),
                      techniques: techniques,
                      userLang: userLang,
                      videoUrl: videoUrl,
                    ),
                    _SleepVideoTab(
                      title: title,
                      category: category,
                      emoji: emoji,
                      isAvoid: _isItemAvoid,
                      reason: _getReason(userLang),
                      postureLabel: _getPostureLabel(userLang),
                      healthTips: _getHealthTips(userLang),
                      techniques: techniques,
                      userLang: userLang,
                      rawAdminVideoUrl: _safeExtractMedia(widget.tip['videoUrl'] ?? widget.tip['video_url'] ?? widget.tip['video']),
                      defaultVideoUrl: videoUrl,
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
          height: imageUrl.isNotEmpty && !imageUrl.endsWith('.mp4') ? 210 : 130,
          child: imageUrl.isNotEmpty && !imageUrl.endsWith('.mp4')
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
        // Video button top right
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: GestureDetector(
            onTap: () {
              _tabController.animateTo(1);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Watch Video',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Bottom header info
        Positioned(
          left: 16,
          right: 16,
          bottom: 14,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (category.isNotEmpty)
                      Text(
                        category.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              // How to Sleep vs Avoid badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isItemAvoid
                      ? Colors.red.withValues(alpha: 0.9)
                      : const Color(0xFF5C6BC0).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isItemAvoid ? '🚫 What to Avoid' : '🛌 How to Sleep',
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5C6BC0), Color(0xFF7986CB)],
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

class _SleepDetailsTab extends StatelessWidget {
  final String title;
  final String category;
  final String emoji;
  final bool isAvoid;
  final String reason;
  final String postureLabel;
  final String healthTips;
  final List<Map<String, dynamic>> techniques;
  final String userLang;
  final String videoUrl;

  const _SleepDetailsTab({
    required this.title,
    required this.category,
    required this.emoji,
    required this.isAvoid,
    required this.reason,
    required this.postureLabel,
    required this.healthTips,
    required this.techniques,
    required this.userLang,
    required this.videoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (reason.isNotEmpty)
          _ReasonBanner(reason: reason, isAvoid: isAvoid),
        _SleepSectionCard(
          title: title,
          category: category,
          emoji: emoji,
          isAvoid: isAvoid,
          reason: reason,
          postureLabel: postureLabel,
          healthTips: healthTips,
          techniques: techniques,
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
        color: isAvoid ? Colors.red.shade50 : const Color(0xFF5C6BC0).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAvoid ? Colors.red.shade100 : const Color(0xFF5C6BC0).withValues(alpha: 0.2),
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
                    color: isAvoid ? Colors.red : const Color(0xFF5C6BC0),
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

class _SleepSectionCard extends StatelessWidget {
  final String title;
  final String category;
  final String emoji;
  final bool isAvoid;
  final String reason;
  final String postureLabel;
  final String healthTips;
  final List<Map<String, dynamic>> techniques;
  final String userLang;
  final String videoUrl;

  const _SleepSectionCard({
    required this.title,
    required this.category,
    required this.emoji,
    required this.isAvoid,
    required this.reason,
    required this.postureLabel,
    required this.healthTips,
    required this.techniques,
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
                  : const Color(0xFF5C6BC0).withValues(alpha: 0.08),
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
                          color: isAvoid ? Colors.red : const Color(0xFF5C6BC0),
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

          // Posture & Support Requirement badge
          if (postureLabel.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isAvoid
                    ? Colors.red.shade50
                    : const Color(0xFF5C6BC0).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(isAvoid ? '⚠️' : '🛌', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      postureLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isAvoid ? Colors.red.shade900 : const Color(0xFF5C6BC0),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Health / Sleep Tips container
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
                    child: Text(
                      healthTips,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 6),
          Divider(height: 1, color: Colors.grey.shade100),

          // Techniques list
          if (techniques.isNotEmpty) ...[
            ...techniques.map(
              (tech) => _SleepTechniqueRow(
                technique: tech,
                isAvoid: isAvoid,
                userLang: userLang,
                defaultVideoUrl: videoUrl,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: GestureDetector(
                onTap: () => _showAllTechniques(context, techniques, title, emoji),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${AppStrings.of(context, 'view_all_items')} (${techniques.length})',
                      style: const TextStyle(
                        color: Color(0xFF5C6BC0),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 16, color: Color(0xFF5C6BC0)),
                  ],
                ),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No sleep techniques listed for this card.',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  void _showAllTechniques(
    BuildContext context,
    List<Map<String, dynamic>> techniques,
    String typeLabel,
    String emoji,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SleepListSheet(
        techniques: techniques,
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
// Sleep Technique Row
// ─────────────────────────────────────────────────────────────────────────────

class _SleepTechniqueRow extends StatelessWidget {
  final Map<String, dynamic> technique;
  final bool isAvoid;
  final String userLang;
  final String defaultVideoUrl;

  const _SleepTechniqueRow({
    required this.technique,
    required this.isAvoid,
    required this.userLang,
    required this.defaultVideoUrl,
  });

  String _name() => _extractLocalized(
        technique,
        userLang,
        amKeys: ['nameAm', 'name_am', 'titleAm', 'title_am'],
        orKeys: ['nameOr', 'name_or', 'nameOm', 'name_om', 'titleOr', 'title_or'],
        soKeys: ['nameSo', 'name_so', 'titleSo', 'title_so'],
        enKeys: ['nameEn', 'name_en', 'titleEn', 'title_en'],
        defaultKeys: ['name', 'title'],
        fallback: 'Sleep Technique',
      );

  @override
  Widget build(BuildContext context) {
    final name = _name();
    final thumb = resolveVideoUrl(_safeExtractMedia(technique['imageUrl'] ?? technique['image_url'] ?? technique['image']));

    return InkWell(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _SleepDetailsSheet(
          technique: technique,
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
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isAvoid ? Colors.red.shade50 : const Color(0xFF5C6BC0).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(isAvoid ? '⚠️' : '🛌', style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sleep List Sheet (View all techniques)
// ─────────────────────────────────────────────────────────────────────────────

class _SleepListSheet extends StatelessWidget {
  final List<Map<String, dynamic>> techniques;
  final String typeLabel;
  final String emoji;
  final bool isAvoid;
  final String userLang;
  final String defaultVideoUrl;

  const _SleepListSheet({
    required this.techniques,
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
      maxChildSize: 0.9,
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      typeLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey.shade100),
            Expanded(
              child: ListView.separated(
                controller: controller,
                itemCount: techniques.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (_, i) {
                  final t = techniques[i];
                  final name = _extractLocalized(
                    t,
                    userLang,
                    amKeys: ['nameAm', 'name_am'],
                    orKeys: ['nameOr', 'name_or', 'nameOm', 'name_om'],
                    soKeys: ['nameSo', 'name_so'],
                    enKeys: ['nameEn', 'name_en'],
                    defaultKeys: ['name', 'title'],
                    fallback: 'Sleep Technique',
                  );
                  final thumb = resolveVideoUrl(_safeExtractMedia(t['imageUrl'] ?? t['image_url'] ?? t['image']));

                  return ListTile(
                    leading: thumb.isNotEmpty && !thumb.endsWith('.mp4')
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
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
                        builder: (_) => _SleepDetailsSheet(
                          technique: t,
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
        color: isAvoid ? Colors.red.shade50 : const Color(0xFF5C6BC0).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(isAvoid ? '⚠️' : '🛌', style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sleep Details Bottom Sheet (With In-UI Video Playback & Safe Parsing)
// ─────────────────────────────────────────────────────────────────────────────

class _SleepDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> technique;
  final bool isAvoid;
  final String userLang;
  final String defaultVideoUrl;

  const _SleepDetailsSheet({
    required this.technique,
    required this.isAvoid,
    required this.userLang,
    required this.defaultVideoUrl,
  });

  @override
  State<_SleepDetailsSheet> createState() => _SleepDetailsSheetState();
}

class _SleepDetailsSheetState extends State<_SleepDetailsSheet> {
  bool _showVideoInUi = false;

  String get _name => _extractLocalized(
        widget.technique,
        widget.userLang,
        amKeys: ['nameAm', 'name_am', 'titleAm', 'title_am'],
        orKeys: ['nameOr', 'name_or', 'nameOm', 'name_om', 'titleOr', 'title_or'],
        soKeys: ['nameSo', 'name_so', 'titleSo', 'title_so'],
        enKeys: ['nameEn', 'name_en', 'titleEn', 'title_en'],
        defaultKeys: ['name', 'title'],
        fallback: 'Sleep Technique',
      );

  String get _description => _extractLocalized(
        widget.technique,
        widget.userLang,
        amKeys: ['descriptionAm', 'description_am', 'descAm', 'desc_am'],
        orKeys: ['descriptionOr', 'description_or', 'descOr', 'desc_or'],
        soKeys: ['descriptionSo', 'description_so', 'descSo', 'desc_so'],
        enKeys: ['descriptionEn', 'description_en', 'descEn', 'desc_en'],
        defaultKeys: ['description', 'desc', 'tips', 'instructions'],
        fallback: '',
      );

  String get _imageUrl =>
      resolveVideoUrl(_safeExtractMedia(widget.technique['imageUrl'] ?? widget.technique['image_url'] ?? widget.technique['image']));

  String get _videoUrl {
    final raw = _safeExtractMedia(widget.technique['videoUrl'] ?? widget.technique['video_url'] ?? widget.technique['video']);
    return resolveVideoUrl(raw.isNotEmpty ? raw : widget.defaultVideoUrl);
  }

  String get _label => _extractLocalized(
        widget.technique,
        widget.userLang,
        amKeys: ['labelAm', 'label_am', 'positionAm'],
        orKeys: ['labelOr', 'label_or', 'labelOm', 'positionOr'],
        soKeys: ['labelSo', 'label_so', 'positionSo'],
        enKeys: ['labelEn', 'label_en', 'positionEn'],
        defaultKeys: ['label', 'position', 'alignment'],
        fallback: '',
      );

  String get _tip => _extractLocalized(
        widget.technique,
        widget.userLang,
        amKeys: ['tipAm', 'tip_am', 'tipsAm', 'safetyAm'],
        orKeys: ['tipOr', 'tip_or', 'tipsOr', 'safetyOr'],
        soKeys: ['tipSo', 'tip_so', 'tipsSo', 'safetySo'],
        enKeys: ['tipEn', 'tip_en', 'tipsEn', 'safetyEn'],
        defaultKeys: ['tip', 'helpful_tips', 'safety', 'tips'],
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
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Technique Details',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.isAvoid ? Colors.red.shade50 : const Color(0xFF5C6BC0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.isAvoid ? '🚫 What to Avoid' : '🛌 How to Sleep',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: widget.isAvoid ? Colors.red : const Color(0xFF5C6BC0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey.shade100),

            // In-UI Embedded Video Player or Thumbnail
            if (_showVideoInUi) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AppVideoPlayer(
                    key: ValueKey(_videoUrl),
                    videoUrl: _videoUrl,
                    title: _name,
                    autoPlay: true,
                    aspectRatio: 16 / 9,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showVideoInUi = false),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Hide Video Player'),
                  ),
                ),
              ),
            ] else if (_imageUrl.isNotEmpty && !_imageUrl.endsWith('.mp4')) ...[
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
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _imagePlaceholder(),
              ),
            ],

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
            ),

            // Embedded Video Toggle Button
            if (!_showVideoInUi)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _showVideoInUi = true),
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                  label: const Text('Watch Sleep Position Video (In App)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C6BC0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            // Posture / Alignment label badge
            if (_label.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: widget.isAvoid ? Colors.red.shade50 : const Color(0xFF5C6BC0).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(widget.isAvoid ? '⚠️' : '🛌', style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _label,
                          style: TextStyle(
                            color: widget.isAvoid ? Colors.red.shade900 : const Color(0xFF5C6BC0),
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
                  widget.isAvoid ? 'Why avoid this sleep position?' : 'Recommended sleep posture guidance:',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],

            // Health / Safety tips block
            if (_tip.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                child: const Text(
                  '💡 Helpful Posture & Bedding Tips',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Text(
                    _tip,
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],

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
        color: const Color(0xFF5C6BC0).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(Icons.bedtime_rounded, size: 48, color: Color(0xFF7986CB)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Video Tab (In-UI Video Player at Top + Interactive Technique Selection)
// ─────────────────────────────────────────────────────────────────────────────

class _SleepVideoTab extends StatefulWidget {
  final String title;
  final String category;
  final String emoji;
  final bool isAvoid;
  final String reason;
  final String postureLabel;
  final String healthTips;
  final List<Map<String, dynamic>> techniques;
  final String userLang;
  final String rawAdminVideoUrl;
  final String defaultVideoUrl;
  final String? thumbnailUrl;

  const _SleepVideoTab({
    required this.title,
    required this.category,
    required this.emoji,
    this.isAvoid = false,
    this.reason = '',
    this.postureLabel = '',
    this.healthTips = '',
    required this.techniques,
    required this.userLang,
    this.rawAdminVideoUrl = '',
    required this.defaultVideoUrl,
    this.thumbnailUrl,
  });

  @override
  State<_SleepVideoTab> createState() => _SleepVideoTabState();
}

class _SleepVideoTabState extends State<_SleepVideoTab> {
  late List<_SleepVideoEntry> _entries;
  _SleepVideoEntry? _activeEntry;

  @override
  void initState() {
    super.initState();
    _entries = _buildEntries();
    if (_entries.isNotEmpty) {
      _activeEntry = _entries.first;
    }
  }

  @override
  void didUpdateWidget(covariant _SleepVideoTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.techniques != widget.techniques ||
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

  List<_SleepVideoEntry> _buildEntries() {
    final entries = <_SleepVideoEntry>[];
    final Set<String> seenUrls = {};

    // 1. Main Sleep Video (only if admin explicitly provided a dedicated video)
    if (widget.rawAdminVideoUrl.trim().isNotEmpty) {
      final mainUrl = resolveVideoUrl(widget.rawAdminVideoUrl);
      if (!seenUrls.contains(mainUrl)) {
        seenUrls.add(mainUrl);
        entries.add(_SleepVideoEntry(
          emoji: widget.emoji,
          typeLabel: widget.category.isNotEmpty ? widget.category : (widget.isAvoid ? 'AVOID' : 'HEALTHY SLEEP POSTURE'),
          title: '${widget.title} — Full Posture Guide',
          subtitle: widget.reason.isNotEmpty ? widget.reason : 'Doctor-recommended pregnancy sleeping posture & pillow setup',
          videoUrl: mainUrl,
          techniqueName: widget.title,
          imageUrl: widget.thumbnailUrl ?? '',
          isAvoid: widget.isAvoid,
          postureLabel: widget.postureLabel,
          alignmentBenefit: widget.isAvoid ? 'Spinal strain / Vena Cava compression' : 'Optimal maternal cardiac output & uterine blood flow',
          description: widget.reason,
          beddingTips: widget.healthTips,
          reason: widget.reason,
        ));
      }
    }

    // 2. Specific Sleep Technique Videos (ONLY add if admin explicitly provided a video for this technique)
    for (final t in widget.techniques) {
      final rawTVid = _safeExtractMedia(t['videoUrl'] ?? t['video_url'] ?? t['video']);
      // Never double-list items that do not have their own admin video
      if (rawTVid.trim().isEmpty) continue;

      final tUrl = resolveVideoUrl(rawTVid);
      if (seenUrls.contains(tUrl)) continue;
      seenUrls.add(tUrl);

      final tName = _extractLocalized(
        t,
        widget.userLang,
        amKeys: ['nameAm', 'name_am'],
        orKeys: ['nameOr', 'name_or', 'nameOm', 'name_om'],
        soKeys: ['nameSo', 'name_so'],
        enKeys: ['nameEn', 'name_en'],
        defaultKeys: ['name', 'title'],
        fallback: 'Sleep Technique',
      );

      final desc = _extractLocalized(
        t,
        widget.userLang,
        amKeys: ['descriptionAm', 'descAm'],
        orKeys: ['descriptionOr', 'descOr'],
        soKeys: ['descriptionSo', 'descSo'],
        enKeys: ['descriptionEn', 'descEn'],
        defaultKeys: ['description', 'desc', 'body', 'instructions'],
        fallback: 'Sleeping alignment walkthrough and positioning tips',
      );

      final posLabel = _extractLocalized(
        t,
        widget.userLang,
        amKeys: ['labelAm', 'label_am', 'positionAm'],
        orKeys: ['labelOr', 'label_or', 'positionOr'],
        soKeys: ['labelSo', 'label_so', 'positionSo'],
        enKeys: ['labelEn', 'label_en', 'positionEn'],
        defaultKeys: ['label', 'position', 'alignment', 'posture'],
        fallback: widget.postureLabel,
      );

      final tip = _extractLocalized(
        t,
        widget.userLang,
        amKeys: ['tipAm', 'tip_am', 'sleepingTipsAm'],
        orKeys: ['tipOr', 'tip_or', 'sleepingTipsOr'],
        soKeys: ['tipSo', 'tip_so', 'sleepingTipsSo'],
        enKeys: ['tipEn', 'tip_en', 'sleepingTipsEn'],
        defaultKeys: ['tip', 'tips', 'sleeping_tips', 'helpful_tips', 'bedding_tips'],
        fallback: widget.healthTips,
      );

      final rawThumb = _safeExtractMedia(t['imageUrl'] ?? t['image_url'] ?? t['image'] ?? t['illustration_url']);
      final thumbUrl = resolveVideoUrl(rawThumb);

      entries.add(_SleepVideoEntry(
        emoji: widget.emoji,
        typeLabel: widget.category.isNotEmpty ? widget.category : 'SLEEP POSTURE',
        title: '$tName — ${widget.title}',
        subtitle: desc,
        videoUrl: tUrl,
        techniqueName: tName,
        imageUrl: thumbUrl,
        isAvoid: widget.isAvoid,
        postureLabel: posLabel,
        alignmentBenefit: desc,
        description: desc,
        beddingTips: tip,
        reason: widget.reason,
      ));
    }

    // 3. Fallback: If no admin-added videos found across techniques or main, provide defaultVideoUrl as single entry
    if (entries.isEmpty && widget.defaultVideoUrl.trim().isNotEmpty) {
      final fallbackUrl = resolveVideoUrl(widget.defaultVideoUrl);
      entries.add(_SleepVideoEntry(
        emoji: widget.emoji,
        typeLabel: widget.category.isNotEmpty ? widget.category : (widget.isAvoid ? 'AVOID' : 'HEALTHY SLEEP POSTURE'),
        title: '${widget.title} — Guided Position Video',
        subtitle: 'Doctor-recommended pregnancy sleeping posture & pillow setup',
        videoUrl: fallbackUrl,
        techniqueName: widget.title,
        imageUrl: widget.thumbnailUrl ?? '',
        isAvoid: widget.isAvoid,
        postureLabel: widget.postureLabel.isNotEmpty ? widget.postureLabel : 'Recommended: Left-Side Lateral (SOS)',
        alignmentBenefit: 'Relieves inferior vena cava pressure and optimizes placental blood flow.',
        description: widget.reason.isNotEmpty ? widget.reason : 'Doctor-recommended sleeping posture for prenatal comfort and safety.',
        beddingTips: widget.healthTips.isNotEmpty ? widget.healthTips : 'Place a contour pillow between your knees and tuck a wedge pillow under your abdomen.',
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
                  color: const Color(0xFF5C6BC0).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.video_library_rounded, color: Color(0xFF5C6BC0), size: 32),
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
                const Icon(Icons.playlist_play_rounded, color: Color(0xFF5C6BC0), size: 20),
                const SizedBox(width: 6),
                Text(
                  'Available Sleep Guides (${_entries.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          ..._entries.map(
            (entry) => _SleepVideoItemCard(
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
  Widget _buildActivePropertiesCard(_SleepVideoEntry entry) {
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
                                : const Color(0xFF5C6BC0).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            entry.typeLabel.toUpperCase(),
                            style: TextStyle(
                              color: entry.isAvoid ? Colors.red : const Color(0xFF5C6BC0),
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
                                : Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            entry.isAvoid ? '🚫 Avoid' : '🛌 Recommended',
                            style: TextStyle(
                              color: entry.isAvoid ? Colors.red.shade800 : Colors.indigo.shade800,
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

          // Posture / Alignment Badge
          if (entry.postureLabel.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: entry.isAvoid ? Colors.red.shade50 : const Color(0xFF5C6BC0).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: entry.isAvoid ? Colors.red.shade100 : const Color(0xFF5C6BC0).withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Text(entry.isAvoid ? '⚠️' : '🛌', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.postureLabel,
                      style: TextStyle(
                        color: entry.isAvoid ? Colors.red.shade900 : const Color(0xFF5C6BC0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Posture Guidance / Anatomical Explanation
          if (entry.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              entry.isAvoid ? 'Why Avoid This Sleep Position:' : 'Posture Guidance & Benefits:',
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

          // Pillow & Bedding Setup Tips
          if (entry.beddingTips.isNotEmpty) ...[
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
                      entry.beddingTips,
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
// Sleep Video Data Model & Card
// ─────────────────────────────────────────────────────────────────────────────

class _SleepVideoEntry {
  final String emoji;
  final String typeLabel;
  final String title;
  final String subtitle;
  final String videoUrl;
  final String techniqueName;
  final String imageUrl;
  final bool isAvoid;
  final String postureLabel;
  final String alignmentBenefit;
  final String description;
  final String beddingTips;
  final String reason;

  _SleepVideoEntry({
    required this.emoji,
    required this.typeLabel,
    required this.title,
    required this.subtitle,
    required this.videoUrl,
    required this.techniqueName,
    required this.imageUrl,
    required this.isAvoid,
    required this.postureLabel,
    required this.alignmentBenefit,
    required this.description,
    required this.beddingTips,
    required this.reason,
  });
}

class _SleepVideoItemCard extends StatelessWidget {
  final _SleepVideoEntry entry;
  final bool isSelected;
  final VoidCallback onSelect;

  const _SleepVideoItemCard({
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
          color: isSelected ? const Color(0xFF5C6BC0) : Colors.grey.shade200,
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
                              color: isSelected ? const Color(0xFF5C6BC0) : Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: isSelected ? Colors.white : const Color(0xFF5C6BC0),
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
                                color: entry.isAvoid ? Colors.red : const Color(0xFF5C6BC0),
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
                          color: isSelected ? const Color(0xFF5C6BC0) : Colors.black87,
                        ),
                      ),
                      if (entry.postureLabel.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          entry.postureLabel,
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
                    color: isSelected ? const Color(0xFF5C6BC0).withValues(alpha: 0.1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isSelected ? 'PLAYING' : 'WATCH',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF5C6BC0) : Colors.grey[700],
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
      color: const Color(0xFF5C6BC0).withValues(alpha: 0.15),
      child: const Center(
        child: Icon(
          Icons.bedtime_rounded,
          size: 28,
          color: Color(0xFF5C6BC0),
        ),
      ),
    );
  }
}

