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
      'benefit',
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
// Nutrient Detail Page (Details Tab + In-UI Video Tab)
// ─────────────────────────────────────────────────────────────────────────────

class NutrientDetailPage extends StatefulWidget {
  final Map<String, dynamic> nutrient;
  final Map<String, dynamic> weekGuide;
  final bool isAvoid;
  final String initialLang;

  const NutrientDetailPage({
    super.key,
    required this.nutrient,
    this.weekGuide = const {},
    this.isAvoid = false,
    this.initialLang = 'am',
  });

  @override
  State<NutrientDetailPage> createState() => _NutrientDetailPageState();
}

class _NutrientDetailPageState extends State<NutrientDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static String get _defaultNutritionVideo =>
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
    final t = (widget.nutrient['type'] ?? widget.nutrient['nutrientType'] ?? widget.nutrient['nutrient_type'] ?? '')
        .toString()
        .toLowerCase();
    return t == 'avoid' || widget.nutrient['isAvoid'] == true || widget.nutrient['is_avoid'] == true;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _getTitle(String userLang) => _extractLocalized(
        widget.nutrient,
        userLang,
        amKeys: ['titleAm', 'title_am', 'nameAm', 'name_am'],
        orKeys: ['titleOr', 'title_or', 'nameOr', 'name_or', 'titleOm', 'title_om'],
        soKeys: ['titleSo', 'title_so', 'nameSo', 'name_so'],
        enKeys: ['titleEn', 'title_en', 'nameEn', 'name_en'],
        defaultKeys: ['title', 'name'],
        fallback: _isItemAvoid ? 'Foods to Avoid' : 'Nutrient Guide',
      );

  String _getBody(String userLang) => _extractLocalized(
        widget.nutrient,
        userLang,
        amKeys: ['bodyAm', 'body_am', 'descAm', 'desc_am', 'descriptionAm', 'description_am'],
        orKeys: ['bodyOr', 'body_or', 'descOr', 'desc_or', 'descriptionOr', 'description_or'],
        soKeys: ['bodySo', 'body_so', 'descSo', 'desc_so', 'descriptionSo', 'description_so'],
        enKeys: ['bodyEn', 'body_en', 'descEn', 'desc_en', 'descriptionEn', 'description_en'],
        defaultKeys: ['body', 'description', 'desc'],
        fallback: '',
      );

  String _getImageUrl() {
    final raw = _safeExtractMedia(
      widget.nutrient['imageUrl'] ?? widget.nutrient['image_url'] ?? widget.nutrient['image'],
    );
    return resolveVideoUrl(raw);
  }

  String _getVideoUrl() {
    String raw = _safeExtractMedia(
      widget.nutrient['videoUrl'] ?? widget.nutrient['video_url'] ?? widget.nutrient['video'],
    );
    if (raw.isEmpty) {
      final img = _safeExtractMedia(widget.nutrient['imageUrl'] ?? widget.nutrient['image_url'] ?? widget.nutrient['image']);
      if (img.endsWith('.mp4') || img.contains('youtube.com') || img.contains('youtu.be')) {
        raw = img;
      }
    }
    if (raw.isEmpty && widget.nutrient['list_food'] is List) {
      for (final f in (widget.nutrient['list_food'] as List)) {
        if (f is Map) {
          final v = _safeExtractMedia(f['videoUrl'] ?? f['video_url'] ?? f['video']);
          if (v.isNotEmpty) {
            raw = v;
            break;
          }
        }
      }
    }
    return resolveVideoUrl(raw.isNotEmpty ? raw : _defaultNutritionVideo);
  }

  String _getPdfUrl() => _safeExtractMedia(
        widget.nutrient['pdfUrl'] ?? widget.nutrient['pdf_url'],
      );

  String _getNutrientType() {
    final t = _safeStr(widget.nutrient['nutrientType'] ?? widget.nutrient['nutrient_type'] ?? widget.nutrient['type']);
    return t.isNotEmpty ? t : (_isItemAvoid ? 'AVOID' : 'RECOMMENDED');
  }

  String _getEmoji() {
    final emoji = _safeStr(widget.nutrient['emoji']);
    if (emoji.isNotEmpty) return emoji;
    return _isItemAvoid ? '🚫' : '🥗';
  }

  String _getReason(String userLang) => _extractLocalized(
        widget.nutrient,
        userLang,
        amKeys: ['whyImportantAm', 'why_important_am', 'reasonAm', 'reason_am'],
        orKeys: ['whyImportantOr', 'why_important_or', 'whyImportantOm', 'why_important_om'],
        soKeys: ['whyImportantSo', 'why_important_so', 'reasonSo', 'reason_so'],
        enKeys: ['whyImportantEn', 'why_important_en', 'reasonEn', 'reason_en'],
        defaultKeys: ['why_important', 'whyImportant', 'reason', 'description'],
        fallback: _getBody(userLang),
      );

  String _getDescriptionBadge(String userLang) {
    final labelFromBackend = _extractLocalized(
      widget.nutrient,
      userLang,
      amKeys: ['descriptionLabelAm', 'description_label_am', 'benefitLabelAm', 'benefit_label_am'],
      orKeys: ['descriptionLabelOr', 'description_label_or', 'benefitLabelOr', 'benefit_label_or'],
      soKeys: ['descriptionLabelSo', 'description_label_so', 'benefitLabelSo', 'benefit_label_so'],
      enKeys: ['descriptionLabelEn', 'description_label_en', 'benefitLabelEn', 'benefit_label_en'],
      defaultKeys: ['description_label', 'benefit_label', 'benefitLabel', 'label'],
      fallback: '',
    );
    final valFromBackend = _extractLocalized(
      widget.nutrient,
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
    return _isItemAvoid ? 'Risk: Avoid Entirely' : 'Daily Essential Nutrient';
  }

  String _getHealthTips(String userLang) {
    final rawTips = widget.nutrient['health_tips'] ?? widget.nutrient['healthTips'] ?? widget.nutrient['tips'];
    if (rawTips is List && rawTips.isNotEmpty) {
      final formatted = rawTips.map((e) => _safeStr(e)).where((s) => s.isNotEmpty).join(' • ');
      if (formatted.isNotEmpty) return formatted;
    }
    return _extractLocalized(
      widget.nutrient,
      userLang,
      amKeys: ['helpfulTipsAm', 'helpful_tips_am', 'tipsAm', 'tips_am'],
      orKeys: ['helpfulTipsOr', 'helpful_tips_or', 'tipsOr', 'tips_or'],
      soKeys: ['helpfulTipsSo', 'helpful_tips_so', 'tipsSo', 'tips_so'],
      enKeys: ['helpfulTipsEn', 'helpful_tips_en', 'tipsEn', 'tips_en'],
      defaultKeys: ['helpful_tips', 'helpfulTips', 'tips'],
      fallback: _isItemAvoid
          ? 'Always wash fresh produce thoroughly and ensure meat, fish, and eggs are cooked completely.'
          : 'Eat a colorful variety of whole foods daily and drink plenty of clean water.',
    );
  }

  List<Map<String, dynamic>> _getNutrientSections(String userLang) {
    dynamic raw = widget.nutrient['nutrientSectionsJson'] ??
        widget.nutrient['nutrient_sections_json'] ??
        widget.nutrient['sections_json'];

    if (raw is String && raw.trim().startsWith('[')) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {}
    }

    if (raw is List && raw.isNotEmpty) {
      return raw.map((item) {
        if (item is Map) return Map<String, dynamic>.from(item);
        return <String, dynamic>{'nutrientType': item.toString(), 'foods': []};
      }).toList();
    }

    dynamic foods = widget.nutrient['foods'] ??
        widget.nutrient['list_food'] ??
        widget.nutrient['listFood'] ??
        widget.nutrient['food_items'] ??
        widget.nutrient['items'];

    if (foods is String && foods.trim().startsWith('[')) {
      try {
        foods = jsonDecode(foods);
      } catch (_) {}
    }

    final foodList = foods is List ? foods.cast<dynamic>() : <dynamic>[];

    return [
      {
        'id': 'sec-0',
        'nutrientType': _getNutrientType().isNotEmpty ? _getNutrientType() : _getTitle(userLang),
        'emoji': _getEmoji(),
        'titleEn': _extractLocalized(widget.nutrient, 'en', enKeys: ['titleEn', 'title_en'], defaultKeys: ['title']),
        'titleAm': _extractLocalized(widget.nutrient, 'am', amKeys: ['titleAm', 'title_am'], defaultKeys: ['title']),
        'titleOr': _extractLocalized(widget.nutrient, 'or', orKeys: ['titleOr', 'title_or'], defaultKeys: ['title']),
        'titleSo': _extractLocalized(widget.nutrient, 'so', soKeys: ['titleSo', 'title_so'], defaultKeys: ['title']),
        'bodyEn': _extractLocalized(widget.nutrient, 'en', enKeys: ['bodyEn', 'body_en'], defaultKeys: ['body']),
        'bodyAm': _extractLocalized(widget.nutrient, 'am', amKeys: ['bodyAm', 'body_am'], defaultKeys: ['body']),
        'bodyOr': _extractLocalized(widget.nutrient, 'or', orKeys: ['bodyOr', 'body_or'], defaultKeys: ['body']),
        'bodySo': _extractLocalized(widget.nutrient, 'so', soKeys: ['bodySo', 'body_so'], defaultKeys: ['body']),
        'description': _getBody(userLang),
        'description_badge': _getDescriptionBadge(userLang),
        'health_tips': _getHealthTips(userLang),
        'foods': foodList,
        'video_url': _getVideoUrl(),
        'video_title': widget.nutrient['video_title'] ?? widget.nutrient['videoTitle'],
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        String userLang = localeProvider.locale?.languageCode ?? 'am';
        if (userLang == 'om') userLang = 'or';

        final sections = _getNutrientSections(userLang);
        final defaultVid = _getVideoUrl();

        return Scaffold(
          backgroundColor: const Color(0xFFF5F0F3),
          body: Column(
            children: [
              // ── Header Banner ──────────────────────────────────────────────
              _buildHeader(context, userLang),

              // ── TabBar directly below header ─────────────────────────────────
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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

              // ── Tab content ──────────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _DetailsTab(
                      nutrientSections: sections,
                      isAvoid: _isItemAvoid,
                      reason: _getReason(userLang),
                      descriptionBadge: _getDescriptionBadge(userLang),
                      healthTips: _getHealthTips(userLang),
                      userLang: userLang,
                      pdfUrl: _getPdfUrl(),
                      whyImportantText: _extractLocalized(
                        widget.weekGuide,
                        userLang,
                        amKeys: ['whyImportantAm', 'why_important_am'],
                        orKeys: ['whyImportantOr', 'why_important_or'],
                        soKeys: ['whyImportantSo', 'why_important_so'],
                        enKeys: ['whyImportantEn', 'why_important_en'],
                        defaultKeys: ['why_important'],
                        fallback: '',
                      ),
                      hydrationText: _extractLocalized(
                        widget.weekGuide,
                        userLang,
                        amKeys: ['hydrationAm', 'hydration_am'],
                        orKeys: ['hydrationOr', 'hydration_or'],
                        soKeys: ['hydrationSo', 'hydration_so'],
                        enKeys: ['hydrationEn', 'hydration_en'],
                        defaultKeys: ['hydration'],
                        fallback: '',
                      ),
                    ),
                    _VideoTab(
                      nutrientSections: sections,
                      userLang: userLang,
                      defaultVideoUrl: defaultVid,
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
    final nutrientType = _getNutrientType();

    return Stack(
      children: [
        // Background: image or gradient
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
        // Dark overlay for legibility
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.55),
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
            onTap: () => _tabController.animateTo(1),
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
                    if (nutrientType.isNotEmpty)
                      Text(
                        nutrientType.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              // What to Eat vs What to Avoid badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isItemAvoid
                      ? Colors.red.withValues(alpha: 0.9)
                      : AppColors.primary.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isItemAvoid ? '🚫 What to Avoid' : '🥗 What to Eat',
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
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.7),
          ],
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

class _DetailsTab extends StatelessWidget {
  final List<Map<String, dynamic>> nutrientSections;
  final bool isAvoid;
  final String reason;
  final String descriptionBadge;
  final String healthTips;
  final String userLang;
  final String pdfUrl;
  final String whyImportantText;
  final String hydrationText;

  const _DetailsTab({
    required this.nutrientSections,
    required this.isAvoid,
    required this.reason,
    required this.descriptionBadge,
    required this.healthTips,
    required this.userLang,
    required this.pdfUrl,
    required this.whyImportantText,
    required this.hydrationText,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (reason.isNotEmpty)
          _ReasonBanner(reason: reason, isAvoid: isAvoid),

        // Description / Benefit badge
        if (descriptionBadge.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isAvoid ? Colors.red.shade50 : AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(isAvoid ? '⚠️' : '🥗', style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    descriptionBadge,
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

        // Health Tips
        if (healthTips.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
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

        // Nutrient sections
        ...nutrientSections.map(
          (section) => _NutrientSectionCard(
            section: section,
            isAvoid: isAvoid,
            userLang: userLang,
          ),
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
// Nutrient Section Card
// ─────────────────────────────────────────────────────────────────────────────

class _NutrientSectionCard extends StatelessWidget {
  final Map<String, dynamic> section;
  final bool isAvoid;
  final String userLang;

  const _NutrientSectionCard({
    required this.section,
    required this.isAvoid,
    required this.userLang,
  });

  @override
  Widget build(BuildContext context) {
    final rawType = _safeStr(section['nutrientType'] ?? section['nutrient_type'] ?? section['type']);
    final emoji = _safeStr(section['emoji'], isAvoid ? '🚫' : '🌿');
    final foods = (section['foods'] as List<dynamic>?) ?? [];

    String sectionTitle = _extractLocalized(
      section,
      userLang,
      amKeys: ['titleAm', 'title_am'],
      orKeys: ['titleOr', 'title_or', 'titleOm', 'title_om'],
      soKeys: ['titleSo', 'title_so'],
      enKeys: ['titleEn', 'title_en'],
      defaultKeys: ['title', 'nutrientType'],
      fallback: rawType.isNotEmpty ? rawType : (isAvoid ? 'Foods to Avoid' : 'Nutrient Guide'),
    );

    String sectionBody = _extractLocalized(
      section,
      userLang,
      amKeys: ['bodyAm', 'body_am', 'descriptionAm', 'description_am'],
      orKeys: ['bodyOr', 'body_or', 'descriptionOr', 'description_or'],
      soKeys: ['bodySo', 'body_so', 'descriptionSo', 'description_so'],
      enKeys: ['bodyEn', 'body_en', 'descriptionEn', 'description_en'],
      defaultKeys: ['body', 'description'],
      fallback: '',
    );

    final defaultVid = resolveVideoUrl(_safeExtractMedia(section['video_url'] ?? section['videoUrl']));

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
              color: isAvoid ? Colors.red.shade50 : AppColors.primary.withValues(alpha: 0.08),
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
                        rawType.isNotEmpty ? rawType.toUpperCase() : (isAvoid ? 'AVOID' : 'RECOMMENDED'),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: isAvoid ? Colors.red : AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        sectionTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      if (sectionBody.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          sectionBody,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),
          Divider(height: 1, color: Colors.grey.shade100),

          // Foods list
          if (foods.isNotEmpty) ...[
            ...foods.map(
              (f) => _FoodRow(
                food: f,
                isAvoid: isAvoid,
                userLang: userLang,
                defaultVideoUrl: defaultVid,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: GestureDetector(
                onTap: () => _showAllFoods(context, foods, sectionTitle, emoji, defaultVid),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${AppStrings.of(context, 'view_all_items')} (${foods.length})',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No specific foods listed for this section.',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  void _showAllFoods(
    BuildContext context,
    List<dynamic> foods,
    String typeLabel,
    String emoji,
    String defaultVideoUrl,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FoodListSheet(
        foods: foods,
        typeLabel: typeLabel,
        emoji: emoji,
        isAvoid: isAvoid,
        userLang: userLang,
        defaultVideoUrl: defaultVideoUrl,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Food Row
// ─────────────────────────────────────────────────────────────────────────────

class _FoodRow extends StatelessWidget {
  final dynamic food;
  final bool isAvoid;
  final String userLang;
  final String defaultVideoUrl;

  const _FoodRow({
    required this.food,
    required this.isAvoid,
    required this.userLang,
    required this.defaultVideoUrl,
  });

  Map? get _map => food is Map ? food as Map : null;

  String _name() => _extractLocalized(
        _map,
        userLang,
        amKeys: ['nameAm', 'name_am', 'titleAm', 'title_am'],
        orKeys: ['nameOr', 'name_or', 'nameOm', 'name_om', 'titleOr', 'title_or'],
        soKeys: ['nameSo', 'name_so', 'titleSo', 'title_so'],
        enKeys: ['nameEn', 'name_en', 'titleEn', 'title_en'],
        defaultKeys: ['name', 'title'],
        fallback: food is String ? food as String : 'Food Item',
      );

  @override
  Widget build(BuildContext context) {
    final name = _name();
    final thumb = resolveVideoUrl(_safeExtractMedia(_map?['imageUrl'] ?? _map?['image_url'] ?? _map?['image']));

    return InkWell(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _FoodDetailsSheet(
          food: food,
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
        color: isAvoid ? Colors.red.shade50 : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(isAvoid ? '🚫' : '🥗', style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Food List Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _FoodListSheet extends StatelessWidget {
  final List<dynamic> foods;
  final String typeLabel;
  final String emoji;
  final bool isAvoid;
  final String userLang;
  final String defaultVideoUrl;

  const _FoodListSheet({
    required this.foods,
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
                itemCount: foods.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (_, i) {
                  final f = foods[i];
                  final m = f is Map ? f : null;
                  final name = _extractLocalized(
                    m,
                    userLang,
                    amKeys: ['nameAm', 'name_am'],
                    orKeys: ['nameOr', 'name_or'],
                    soKeys: ['nameSo', 'name_so'],
                    enKeys: ['nameEn', 'name_en'],
                    defaultKeys: ['name', 'title'],
                    fallback: f is String ? f : 'Food Item',
                  );
                  final thumb = resolveVideoUrl(_safeExtractMedia(m?['imageUrl'] ?? m?['image_url'] ?? m?['image']));

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
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _FoodDetailsSheet(
                          food: f,
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(isAvoid ? '🚫' : '🥗', style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Food Details Sheet (With In-UI Video Playback & Safe Parsing)
// ─────────────────────────────────────────────────────────────────────────────

class _FoodDetailsSheet extends StatefulWidget {
  final dynamic food;
  final bool isAvoid;
  final String userLang;
  final String defaultVideoUrl;

  const _FoodDetailsSheet({
    required this.food,
    required this.isAvoid,
    required this.userLang,
    required this.defaultVideoUrl,
  });

  @override
  State<_FoodDetailsSheet> createState() => _FoodDetailsSheetState();
}

class _FoodDetailsSheetState extends State<_FoodDetailsSheet> {
  bool _showVideoInUi = false;

  Map? get _map => widget.food is Map ? widget.food as Map : null;

  String get _name => _extractLocalized(
        _map,
        widget.userLang,
        amKeys: ['nameAm', 'name_am', 'titleAm', 'title_am'],
        orKeys: ['nameOr', 'name_or', 'nameOm', 'name_om', 'titleOr', 'title_or'],
        soKeys: ['nameSo', 'name_so', 'titleSo', 'title_so'],
        enKeys: ['nameEn', 'name_en', 'titleEn', 'title_en'],
        defaultKeys: ['name', 'title'],
        fallback: widget.food is String ? widget.food as String : 'Food Item',
      );

  String get _description => _extractLocalized(
        _map,
        widget.userLang,
        amKeys: ['descriptionAm', 'description_am', 'descAm', 'bodyAm'],
        orKeys: ['descriptionOr', 'description_or', 'descOr', 'bodyOr'],
        soKeys: ['descriptionSo', 'description_so', 'descSo', 'bodySo'],
        enKeys: ['descriptionEn', 'description_en', 'descEn', 'bodyEn'],
        defaultKeys: ['description', 'desc', 'why_include', 'whyInclude', 'body'],
        fallback: '',
      );

  String get _imageUrl =>
      resolveVideoUrl(_safeExtractMedia(_map?['imageUrl'] ?? _map?['image_url'] ?? _map?['image']));

  String get _videoUrl {
    final raw = _safeExtractMedia(_map?['videoUrl'] ?? _map?['video_url'] ?? _map?['video']);
    return resolveVideoUrl(raw.isNotEmpty ? raw : widget.defaultVideoUrl);
  }

  String get _label => _extractLocalized(
        _map,
        widget.userLang,
        amKeys: ['benefitLabelAm', 'benefit_label_am', 'labelAm', 'label_am'],
        orKeys: ['benefitLabelOr', 'benefit_label_or', 'labelOr', 'label_or'],
        soKeys: ['benefitLabelSo', 'benefit_label_so', 'labelSo', 'label_so'],
        enKeys: ['benefitLabelEn', 'benefit_label_en', 'labelEn', 'label_en'],
        defaultKeys: ['benefitLabel', 'benefit_label', 'label'],
        fallback: 'Nutritional Value',
      );

  String get _benefitValue => _extractLocalized(
        _map,
        widget.userLang,
        amKeys: ['benefitValueAm', 'benefit_value_am'],
        orKeys: ['benefitValueOr', 'benefit_value_or'],
        soKeys: ['benefitValueSo', 'benefit_value_so'],
        enKeys: ['benefitValueEn', 'benefit_value_en'],
        defaultKeys: ['benefit', 'benefitValue', 'benefit_value', 'value'],
        fallback: '',
      );

  String get _tip => _extractLocalized(
        _map,
        widget.userLang,
        amKeys: ['tipAm', 'tip_am', 'helpfulTipsAm', 'helpful_tips_am'],
        orKeys: ['tipOr', 'tip_or', 'helpfulTipsOr', 'helpful_tips_or'],
        soKeys: ['tipSo', 'tip_so', 'helpfulTipsSo', 'helpful_tips_so'],
        enKeys: ['tipEn', 'tip_en', 'helpfulTipsEn', 'helpful_tips_en'],
        defaultKeys: ['tip', 'helpfulTips', 'helpful_tips'],
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
                          'Food Details',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.isAvoid ? Colors.red.shade50 : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.isAvoid ? '🚫 What to Avoid' : '🥗 What to Eat',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: widget.isAvoid ? Colors.red : AppColors.primary,
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
                  label: const Text('Watch Food Preparation / Guide Video (In App)'),
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

            // Nutritional benefit badge
            if (_benefitValue.isNotEmpty)
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
                      Text(widget.isAvoid ? '⚠️' : '🥗', style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: widget.isAvoid ? Colors.red : AppColors.primary,
                              ),
                            ),
                            Text(
                              _benefitValue,
                              style: TextStyle(
                                color: widget.isAvoid ? Colors.red.shade900 : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
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
                  widget.isAvoid ? 'Why avoid this during pregnancy?' : 'Nutritional guidance & benefits:',
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
                  '💡 Helpful Culinary & Safety Tips',
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
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(Icons.restaurant_rounded, size: 48, color: AppColors.primary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Video Tab (In-UI Video Player at Top + Interactive Food Video Selection)
// ─────────────────────────────────────────────────────────────────────────────

class _VideoTab extends StatefulWidget {
  final List<Map<String, dynamic>> nutrientSections;
  final String userLang;
  final String? defaultVideoUrl;

  const _VideoTab({
    required this.nutrientSections,
    required this.userLang,
    this.defaultVideoUrl,
  });

  @override
  State<_VideoTab> createState() => _VideoTabState();
}

class _VideoTabState extends State<_VideoTab> {
  late List<_VideoEntry> _entries;
  _VideoEntry? _activeEntry;

  @override
  void initState() {
    super.initState();
    _entries = _buildEntries();
    if (_entries.isNotEmpty) {
      _activeEntry = _entries.first;
    }
  }

  @override
  void didUpdateWidget(covariant _VideoTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nutrientSections != widget.nutrientSections ||
        oldWidget.userLang != widget.userLang) {
      setState(() {
        _entries = _buildEntries();
        if (_entries.isNotEmpty &&
            (_activeEntry == null ||
                !_entries.any((e) => e.videoUrl == _activeEntry!.videoUrl))) {
          _activeEntry = _entries.first;
        }
      });
    }
  }

  List<_VideoEntry> _buildEntries() {
    final entries = <_VideoEntry>[];
    final Set<String> seenUrls = {};

    for (final section in widget.nutrientSections) {
      final sectionType = _safeStr(section['nutrientType'] ?? section['type']).toUpperCase();
      final sectionEmoji = _safeStr(section['emoji'], '🥗');
      final foods = (section['foods'] as List<dynamic>?) ?? [];

      // 1. Primary Section / Nutrient Video (only if admin provided a video)
      final rawSecVid = _safeExtractMedia(section['video_url'] ?? section['videoUrl'] ?? section['video']);
      if (rawSecVid.trim().isNotEmpty) {
        final secUrl = resolveVideoUrl(rawSecVid);
        if (!seenUrls.contains(secUrl)) {
          seenUrls.add(secUrl);
          final sectionTitle = _extractLocalized(
            section,
            widget.userLang,
            amKeys: ['titleAm', 'title_am', 'videoTitleAm'],
            orKeys: ['titleOr', 'title_or', 'videoTitleOr', 'titleOm', 'title_om'],
            soKeys: ['titleSo', 'title_so', 'videoTitleSo'],
            enKeys: ['titleEn', 'title_en', 'videoTitleEn'],
            defaultKeys: ['video_title', 'videoTitle', 'title', 'type'],
            fallback: sectionType.isNotEmpty ? '$sectionType Video Guide' : 'Nutrition Video Guide',
          );
          final sectionDesc = _extractLocalized(
            section,
            widget.userLang,
            amKeys: ['bodyAm', 'body_am', 'descriptionAm'],
            orKeys: ['bodyOr', 'body_or', 'descriptionOr'],
            soKeys: ['bodySo', 'body_so', 'descriptionSo'],
            enKeys: ['bodyEn', 'body_en', 'descriptionEn'],
            defaultKeys: ['body', 'description'],
            fallback: 'Overview of $sectionType dietary recommendations in pregnancy',
          );
          final sectionThumb = resolveVideoUrl(_safeExtractMedia(section['imageUrl'] ?? section['image_url']));
          final benefit = _extractLocalized(
            section,
            widget.userLang,
            defaultKeys: ['benefit', 'why_important', 'description_value'],
            fallback: 'Supports healthy maternal wellness and baby development',
          );
          final tips = _extractLocalized(
            section,
            widget.userLang,
            defaultKeys: ['tips', 'health_tips', 'tip'],
            fallback: '',
          );

          entries.add(_VideoEntry(
            emoji: sectionEmoji,
            typeLabel: sectionType.isNotEmpty ? sectionType : 'NUTRITION GUIDE',
            title: sectionTitle,
            subtitle: sectionDesc,
            videoUrl: secUrl,
            foodName: '',
            foodImageUrl: sectionThumb,
            benefit: benefit,
            description: sectionDesc,
            tips: tips,
            portion: '',
          ));
        }
      }

      // 2. Specific Food Item Videos (ONLY add if admin explicitly attached a video for this item)
      for (final food in foods) {
        if (food is! Map) continue;
        final foodMap = food as Map<String, dynamic>;
        final rawFVid = _safeExtractMedia(foodMap['video_url'] ?? foodMap['videoUrl'] ?? foodMap['video']);

        // Do NOT list items that do not have their own video!
        if (rawFVid.trim().isEmpty) continue;

        final foodVideoUrl = resolveVideoUrl(rawFVid);
        if (seenUrls.contains(foodVideoUrl)) continue;
        seenUrls.add(foodVideoUrl);

        final foodName = _extractLocalized(
          foodMap,
          widget.userLang,
          amKeys: ['nameAm', 'name_am'],
          orKeys: ['nameOr', 'name_or', 'nameOm', 'name_om'],
          soKeys: ['nameSo', 'name_so'],
          enKeys: ['nameEn', 'name_en'],
          defaultKeys: ['name', 'title'],
          fallback: 'Food Item',
        );

        final rawFImg = _safeExtractMedia(foodMap['image_url'] ?? foodMap['imageUrl'] ?? foodMap['image']);
        final foodImageUrl = resolveVideoUrl(rawFImg);
        final benefit = _extractLocalized(
          foodMap,
          widget.userLang,
          amKeys: ['descriptionAm', 'descAm'],
          orKeys: ['descriptionOr', 'descOr'],
          soKeys: ['descriptionSo', 'descSo'],
          enKeys: ['descriptionEn', 'descEn'],
          defaultKeys: ['description', 'benefit', 'why_include'],
          fallback: '$foodName provides essential maternal nutrients',
        );
        final tip = _extractLocalized(
          foodMap,
          widget.userLang,
          defaultKeys: ['tip', 'tips', 'safety_tip'],
          fallback: '',
        );
        final portion = _safeStr(foodMap['portion'] ?? foodMap['serving']);

        entries.add(_VideoEntry(
          emoji: sectionEmoji,
          typeLabel: sectionType.isNotEmpty ? sectionType : 'FOOD ITEM',
          title: '$foodName — $sectionType',
          subtitle: benefit,
          videoUrl: foodVideoUrl,
          foodName: foodName,
          foodImageUrl: foodImageUrl,
          benefit: benefit,
          description: benefit,
          tips: tip,
          portion: portion,
        ));
      }
    }

    // 3. Fallback: If no admin-added videos were found across sections, check defaultVideoUrl as a single entry
    if (entries.isEmpty && widget.defaultVideoUrl != null && widget.defaultVideoUrl!.trim().isNotEmpty) {
      final fallbackUrl = resolveVideoUrl(widget.defaultVideoUrl);
      entries.add(_VideoEntry(
        emoji: '🥗',
        typeLabel: 'NUTRITION GUIDE',
        title: 'Nutritional Video Guide',
        subtitle: 'Doctor-recommended pregnancy diet & preparation techniques',
        videoUrl: fallbackUrl,
        foodName: '',
        foodImageUrl: '',
        benefit: 'Provides vital prenatal vitamins, minerals, and healthy macronutrients.',
        description: 'Comprehensive nutritional overview to ensure optimal vitamin & mineral intake during pregnancy.',
        tips: 'Wash raw produce thoroughly and consume clean water daily.',
        portion: 'Daily recommended serving',
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
        // ── 1. In-UI Embedded Video Player ──────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AppVideoPlayer(
            key: ValueKey(active.videoUrl),
            videoUrl: active.videoUrl,
            title: active.title,
            thumbnailUrl: active.foodImageUrl.isNotEmpty ? active.foodImageUrl : null,
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
                  'Available Video Guides (${_entries.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          ..._entries.map(
            (entry) => _VideoItemCard(
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
  Widget _buildActivePropertiesCard(_VideoEntry entry) {
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
          // Header Row: Emoji, Title, Category Badge
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        entry.typeLabel,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Benefit Badge / Property
          if (entry.benefit.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Row(
                children: [
                  const Text('🥗', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.benefit,
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Guidance Description
          if (entry.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              entry.description,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],

          // Portion / Serving
          if (entry.portion.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.pie_chart_outline_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Recommended Serving: ${entry.portion}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],

          // Safety / Culinary Tips
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
// Video Data Class & Card
// ─────────────────────────────────────────────────────────────────────────────

class _VideoEntry {
  final String emoji;
  final String typeLabel;
  final String title;
  final String subtitle;
  final String videoUrl;
  final String foodName;
  final String foodImageUrl;
  final String benefit;
  final String description;
  final String tips;
  final String portion;

  _VideoEntry({
    required this.emoji,
    required this.typeLabel,
    required this.title,
    required this.subtitle,
    required this.videoUrl,
    required this.foodName,
    required this.foodImageUrl,
    required this.benefit,
    required this.description,
    required this.tips,
    required this.portion,
  });
}

class _VideoItemCard extends StatelessWidget {
  final _VideoEntry entry;
  final bool isSelected;
  final VoidCallback onSelect;

  const _VideoItemCard({
    required this.entry,
    this.isSelected = false,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = entry.foodImageUrl.isNotEmpty && !entry.foodImageUrl.endsWith('.mp4');

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
                            entry.foodImageUrl,
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
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
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
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? AppColors.primary : Colors.black87,
                        ),
                      ),
                      if (entry.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          entry.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                ),

                // Active badge
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PLAYING',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
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
      color: AppColors.primary.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(Icons.play_circle_fill_rounded, size: 28, color: AppColors.primary),
      ),
    );
  }
}

