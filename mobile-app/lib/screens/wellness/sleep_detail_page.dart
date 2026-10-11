import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';
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

  static const String _defaultSleepVideo =
      'http://192.168.1.4:5000/uploads/file-1789254638769-685033131.mp4';

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
    final raw = _safeExtractMedia(
      widget.tip['videoUrl'] ??
          widget.tip['video_url'] ??
          widget.tip['video'],
    );
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

    if (_isItemAvoid) {
      return [
        {
          'name': 'Supine Flat Back Sleeping',
          'name_en': 'Supine Flat Back Sleeping',
          'name_am': 'በጀርባ ጠፍጣፋ አድርጎ መተኛት',
          'name_om': 'Dugdaan Qajeelaa Ciisuu',
          'name_so': 'Dhabarka oo Toos Loogu Jiifo',
          'label': 'Risk: Blood Pressure Drop',
          'description': 'Compresses inferior vena cava and aorta, reducing blood and oxygen flow to placenta.',
          'description_en': 'Compresses inferior vena cava and aorta, reducing blood and oxygen flow to placenta.',
          'description_am': 'ትልቁን የደም ስር በመጫን ወደ ልጅዎ የሚሄደውን ደም እና ኦክስጅን ይቀንሳል።',
          'description_om': 'Dhiigni fi oksijiiniin gara daa\'imaatti deemu ni hir\'ata.',
          'description_so': 'Waxay yareysaa dhiigga iyo oksijiinta u socota mandheerta.',
          'image_url': 'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=400',
          'video_url': _getVideoUrl(),
          'tip': 'If you wake up on your back, gently roll back onto your left side without panic.',
        },
        {
          'name': 'Prone Stomach Compression',
          'name_en': 'Prone Stomach Compression',
          'name_am': 'በሆድ ተደፍቶ መተኛት',
          'name_om': 'Garaan Ciisuu',
          'name_so': 'Caloosha oo Toos Loogu Seexdo',
          'label': 'Risk: Uterine Pressure',
          'description': 'Direct mechanical pressure on the expanding abdomen and restricts free maternal breathing.',
          'description_en': 'Direct mechanical pressure on the expanding abdomen and restricts free maternal breathing.',
          'description_am': 'በማደግ ላይ ባለው ማህፀን ላይ ቀጥተኛ ጫና በማሳደር ምቾት ያሳጣል።',
          'description_om': 'Garaan ciisuun garaa fi mormaa irratti dhiibbaa fida.',
          'description_so': 'Cadaadis toos ah ayay ku haysaa caloosha iyo neefsashada.',
          'image_url': 'https://images.unsplash.com/photo-1520206183501-b80df61043c2?w=400',
          'video_url': _getVideoUrl(),
          'tip': 'Practice side-sleeping early in pregnancy before belly expands.',
        },
      ];
    }

    return [
      {
        'name': 'Left-Side Alignment (SOS Position)',
        'name_en': 'Left-Side Alignment (SOS Position)',
        'name_am': 'በግራ ጎን ማረፍ (የSOS አተኛኘት)',
        'name_om': 'Cinaacha Bitaatiin Ciisuu (SOS)',
        'name_so': 'Dhinaca Bidix oo Loo Seexdo (SOS)',
        'label': 'Position: Optimal Circulation',
        'description': 'Maximizes blood flow and essential nutrient transport to placenta and fetal vital organs.',
        'description_en': 'Maximizes blood flow and essential nutrient transport to placenta and fetal vital organs.',
        'description_am': 'ወደ ልጅዎ እና የእንግዴ ልጅ የሚሄደውን የደም ዝውውር እና የተመጣጠነ ምግብ መጠን ያሳድጋል።',
        'description_om': 'Dhangala\'aa dhiigaa gara daa\'imaatti ni dabala.',
        'description_so': 'Waxay si weyn u kordhisaa socodka dhiigga ee mandheerta.',
        'image_url': 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=400',
        'video_url': _getVideoUrl(),
        'tip': 'Bend your knees slightly towards your chest to keep pelvic joints tension-free.',
      },
      {
        'name': 'Knee Pillow Pelvic Support',
        'name_en': 'Knee Pillow Pelvic Support',
        'name_am': 'የጉልበት መሀል ትራስ ድጋፍ',
        'name_om': 'Boraatii Jilba Gidduu Kaa\'uu',
        'name_so': 'Barkimada Lugaha Dhexdooda',
        'label': 'Support: Spine & Hip Relief',
        'description': 'Prevents upper leg from pulling spine out of alignment and eliminates sacroiliac joint pressure.',
        'description_en': 'Prevents upper leg from pulling spine out of alignment and eliminates sacroiliac joint pressure.',
        'description_am': 'የላይኛው እግር የጀርባ አጥንትን እንዳይጎትት በማድረግ የመገጣጠሚያ ህመምን ያስታግሳል።',
        'description_om': 'Cinaacha dugdaa fi mudhii boqochiisa.',
        'description_so': 'Waxay toosisaa laf-dhabarta waxayna baabi\'isaa xanuunka misigta.',
        'image_url': 'https://images.unsplash.com/photo-1511295742362-92c96b124e52?w=400',
        'video_url': _getVideoUrl(),
        'tip': 'Use a firm, full-length body pillow or pregnancy C-shaped cushion.',
      },
      {
        'name': 'Elevated Head & Torso for Acid Reflux',
        'name_en': 'Elevated Head & Torso for Acid Reflux',
        'name_am': 'ራስን እና ደረትን ከፍ አድርጎ ማረፍ',
        'name_om': 'Mataafi Qoma Ol Kaasuun Ciisuu',
        'name_so': 'Madaxa iyo Laabta oo Kor Loo Qaado',
        'label': 'Technique: Anti-Heartburn',
        'description': 'Uses gravity to keep gastric juices from rising into esophagus during late-trimester nights.',
        'description_en': 'Uses gravity to keep gastric juices from rising into esophagus during late-trimester nights.',
        'description_am': 'የጨጓራ አሲድ ወደ ጉሮሮ እንዳይወጣ በማድረግ የምሽት የጨጓራ ቃጠሎን ይከላከላል።',
        'description_om': 'Gubaa laphee fi qomaa hir\'isa.',
        'description_so': 'Waxay ka hortagtaa laab-jeexa habeennimo ee uurka.',
        'image_url': 'https://images.unsplash.com/photo-1507652313519-d4e9174996dd?w=400',
        'video_url': _getVideoUrl(),
        'tip': 'Elevate the head of your bed 15–20 cm or sleep on an angled wedge pillow.',
      },
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
                      techniques: techniques,
                      userLang: userLang,
                      defaultVideoUrl: videoUrl,
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
  final List<Map<String, dynamic>> techniques;
  final String userLang;
  final String defaultVideoUrl;

  const _SleepVideoTab({
    required this.title,
    required this.category,
    required this.emoji,
    required this.techniques,
    required this.userLang,
    required this.defaultVideoUrl,
  });

  @override
  State<_SleepVideoTab> createState() => _SleepVideoTabState();
}

class _SleepVideoTabState extends State<_SleepVideoTab> {
  late String _activeVideoUrl;
  late String _activeTitle;

  @override
  void initState() {
    super.initState();
    _activeVideoUrl = widget.defaultVideoUrl;
    _activeTitle = widget.title;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── In-UI Embedded Video Player ─────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AppVideoPlayer(
            videoUrl: _activeVideoUrl,
            title: _activeTitle,
            aspectRatio: 16 / 9,
          ),
        ),
        const SizedBox(height: 14),

        // Hint banner
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF5C6BC0).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.play_circle_outline_rounded, color: Color(0xFF5C6BC0), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Select any sleep posture below to stream directly in the video player above.',
                  style: TextStyle(color: Color(0xFF5C6BC0), fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),

        // Main sleep video card
        _VideoItemCard(
          title: '${widget.title} — Complete Position Guide',
          subtitle: 'Doctor-recommended pregnancy sleeping positions and pillow setups',
          videoUrl: widget.defaultVideoUrl,
          category: widget.category,
          emoji: widget.emoji,
          isSelected: _activeVideoUrl == widget.defaultVideoUrl,
          onSelect: () {
            setState(() {
              _activeVideoUrl = widget.defaultVideoUrl;
              _activeTitle = widget.title;
            });
          },
        ),

        // Technique sub-videos
        ...widget.techniques.map((t) {
          final tName = _extractLocalized(
            t,
            widget.userLang,
            amKeys: ['nameAm', 'name_am'],
            orKeys: ['nameOr', 'name_or', 'nameOm', 'name_om'],
            soKeys: ['nameSo', 'name_so'],
            enKeys: ['nameEn', 'name_en'],
            defaultKeys: ['name', 'title'],
            fallback: 'Sleep Guide',
          );
          final desc = _extractLocalized(
            t,
            widget.userLang,
            amKeys: ['descriptionAm', 'descAm'],
            orKeys: ['descriptionOr', 'descOr'],
            soKeys: ['descriptionSo', 'descSo'],
            enKeys: ['descriptionEn', 'descEn'],
            defaultKeys: ['description', 'desc', 'label'],
            fallback: 'Posture and alignment demonstration',
          );
          final rawV = _safeExtractMedia(t['videoUrl'] ?? t['video_url'] ?? t['video']);
          final vUrl = resolveVideoUrl(rawV.isNotEmpty ? rawV : widget.defaultVideoUrl);
          final rawThumb = _safeExtractMedia(t['imageUrl'] ?? t['image_url'] ?? t['image']);

          return _VideoItemCard(
            title: tName,
            subtitle: desc,
            videoUrl: vUrl,
            category: widget.category,
            emoji: '🌙',
            imageUrl: resolveVideoUrl(rawThumb),
            isSelected: _activeVideoUrl == vUrl,
            onSelect: () {
              setState(() {
                _activeVideoUrl = vUrl;
                _activeTitle = tName;
              });
            },
          );
        }),
      ],
    );
  }
}

class _VideoItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String videoUrl;
  final String category;
  final String emoji;
  final String? imageUrl;
  final bool isSelected;
  final VoidCallback onSelect;

  const _VideoItemCard({
    required this.title,
    required this.subtitle,
    required this.videoUrl,
    required this.category,
    required this.emoji,
    this.imageUrl,
    this.isSelected = false,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty && !imageUrl!.endsWith('.mp4');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF5C6BC0) : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
          onTap: onSelect,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with play button overlay
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
                child: SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasImage)
                        Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _videoPlaceholder(),
                        )
                      else
                        _videoPlaceholder(),
                      Container(
                        color: Colors.black.withValues(alpha: 0.28),
                      ),
                      Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF5C6BC0) : Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: isSelected ? Colors.white : const Color(0xFF5C6BC0),
                            size: 30,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.videocam_rounded, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                isSelected ? 'Now Playing' : 'Tap to Play',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Title and category
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5C6BC0),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _videoPlaceholder() {
    return Container(
      color: const Color(0xFF5C6BC0).withValues(alpha: 0.15),
      child: const Center(
        child: Icon(Icons.play_circle_fill_rounded, size: 48, color: Color(0xFF5C6BC0)),
      ),
    );
  }
}
