import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';
import 'package:url_launcher/url_launcher.dart';
// Multilingual & URL Utility Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _resolveUrl(String? url) {
  if (url == null || url.trim().isEmpty) return '';
  final trimmed = url.trim();
  
  String resolved = trimmed;
  if (resolved.contains('localhost')) {
    resolved = resolved.replaceAll('localhost', '192.168.0.199');
  }

  if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
    return resolved;
  }
  // If backend stored relative /uploads path
  const host = 'http://192.168.0.199:5000';
  if (resolved.startsWith('/')) {
    return '$host$resolved';
  }
  return '$host/$resolved';
}

Future<void> _launchMediaUrl(BuildContext context, String url) async {
  if (url.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Media link is not available.')),
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
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open media: $e')),
      );
    }
  }
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

  // Fallbacks: current language keys -> en -> am -> or -> so -> defaults -> first available
  return check(enKeys) ??
      check(amKeys) ??
      check(orKeys) ??
      check(soKeys) ??
      check(defaultKeys) ??
      fallback;
}

// ─────────────────────────────────────────────────────────────────────────────
// Nutrient Detail Page  (Details tab + Video tab)
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

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _getTitle(String _userLang) => _extractLocalized(
        widget.nutrient,
        _userLang,
        amKeys: ['titleAm', 'title_am', 'nameAm', 'name_am'],
        orKeys: ['titleOr', 'title_or', 'nameOr', 'name_or'],
        soKeys: ['titleSo', 'title_so', 'nameSo', 'name_so'],
        enKeys: ['titleEn', 'title_en', 'nameEn', 'name_en'],
        defaultKeys: ['title', 'name'],
        fallback: widget.isAvoid ? 'Foods to Avoid' : 'Nutrient Guide',
      );

  String _getBody(String _userLang) => _extractLocalized(
        widget.nutrient,
        _userLang,
        amKeys: ['bodyAm', 'body_am', 'descAm', 'desc_am', 'descriptionAm'],
        orKeys: ['bodyOr', 'body_or', 'descOr', 'desc_or', 'descriptionOr'],
        soKeys: ['bodySo', 'body_so', 'descSo', 'desc_so', 'descriptionSo'],
        enKeys: ['bodyEn', 'body_en', 'descEn', 'desc_en', 'descriptionEn'],
        defaultKeys: ['body', 'description', 'desc'],
        fallback: '',
      );

  String _getImageUrl() => _resolveUrl(
        (widget.nutrient['imageUrl'] ?? widget.nutrient['image_url']) as String?,
      );

  String _getPdfUrl() => _resolveUrl(
        (widget.nutrient['pdfUrl'] ?? widget.nutrient['pdf_url']) as String?,
      );

  String _getNutrientType() =>
      ((widget.nutrient['nutrientType'] ?? widget.nutrient['nutrient_type'])
          as String?) ??
      '';

  String _getEmoji() =>
      (widget.nutrient['emoji'] as String?) ?? (widget.isAvoid ? '🚫' : '🥗');

  String _getReason(String _userLang) => _extractLocalized(
        widget.nutrient,
        _userLang,
        amKeys: ['whyImportantAm', 'why_important_am', 'reasonAm', 'reason_am'],
        orKeys: ['whyImportantOr', 'why_important_or', 'reasonOr', 'reason_or'],
        soKeys: ['whyImportantSo', 'why_important_so', 'reasonSo', 'reason_so'],
        enKeys: ['whyImportantEn', 'why_important_en', 'reasonEn', 'reason_en'],
        defaultKeys: ['why_important', 'whyImportant', 'reason', 'body'],
        fallback: _getBody(_userLang),
      );

  List<Map<String, dynamic>> _getNutrientSections(String _userLang) {
    final raw = widget.nutrient['nutrientSectionsJson'] ??
        widget.nutrient['nutrient_sections_json'] ??
        widget.nutrient['nutrient_sections'] ??
        widget.nutrient['sections'];

    if (raw is List && raw.isNotEmpty) {
      return raw.map((item) {
        if (item is Map) return Map<String, dynamic>.from(item);
        return <String, dynamic>{'title': item.toString()};
      }).toList();
    }

    final foods = widget.nutrient['foods'] ?? widget.nutrient['foods_json'];
    final foodList = foods is List ? foods.cast<dynamic>() : <dynamic>[];

    return [
      {
        'id': 'sec-0',
        'nutrientType': _getNutrientType().isNotEmpty ? _getNutrientType() : _getTitle(_userLang),
        'emoji': _getEmoji(),
        'titleEn': _extractLocalized(widget.nutrient, 'en', enKeys: ['titleEn', 'title_en'], defaultKeys: ['title']),
        'titleAm': _extractLocalized(widget.nutrient, 'am', amKeys: ['titleAm', 'title_am'], defaultKeys: ['title']),
        'titleOr': _extractLocalized(widget.nutrient, 'or', orKeys: ['titleOr', 'title_or'], defaultKeys: ['title']),
        'titleSo': _extractLocalized(widget.nutrient, 'so', soKeys: ['titleSo', 'title_so'], defaultKeys: ['title']),
        'bodyEn': _extractLocalized(widget.nutrient, 'en', enKeys: ['bodyEn', 'body_en'], defaultKeys: ['body']),
        'bodyAm': _extractLocalized(widget.nutrient, 'am', amKeys: ['bodyAm', 'body_am'], defaultKeys: ['body']),
        'bodyOr': _extractLocalized(widget.nutrient, 'or', orKeys: ['bodyOr', 'body_or'], defaultKeys: ['body']),
        'bodySo': _extractLocalized(widget.nutrient, 'so', soKeys: ['bodySo', 'body_so'], defaultKeys: ['body']),
        'description': _getBody(_userLang),
        'foods': foodList,
        'video_url': widget.nutrient['video_url'] ?? widget.nutrient['videoUrl'],
        'video_title': widget.nutrient['video_title'] ?? widget.nutrient['videoTitle'],
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        String _userLang = localeProvider.locale?.languageCode ?? 'am';
        if (_userLang == 'om') _userLang = 'or'; // 'om' is used for Oromo, but code uses 'or'
        
        return Scaffold(
          backgroundColor: const Color(0xFFF5F0F3),
          body: Column(
            children: [
              // ── Header image / gradient banner ──────────────────────────────
              _buildHeader(context, _userLang),

              // ── TabBar directly below header ─────────────────────────────────
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
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.list_alt_rounded, size: 18),
                      text: 'Details',
                      iconMargin: EdgeInsets.only(bottom: 2),
                    ),
                    Tab(
                      icon: Icon(Icons.play_circle_outline_rounded, size: 18),
                      text: 'Video',
                      iconMargin: EdgeInsets.only(bottom: 2),
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
                      nutrientSections: _getNutrientSections(_userLang),
                      isAvoid: widget.isAvoid,
                      reason: _getReason(_userLang),
                      userLang: _userLang,
                      pdfUrl: _getPdfUrl(),
                      whyImportantText: _extractLocalized(
                        widget.weekGuide,
                        _userLang,
                        amKeys: ['whyImportantAm', 'why_important_am'],
                        orKeys: ['whyImportantOr', 'why_important_or'],
                        soKeys: ['whyImportantSo', 'why_important_so'],
                        enKeys: ['whyImportantEn', 'why_important_en'],
                        defaultKeys: ['why_important'],
                        fallback: '',
                      ),
                      hydrationText: _extractLocalized(
                        widget.weekGuide,
                        _userLang,
                        amKeys: ['hydrationAm', 'hydration_am'],
                        orKeys: ['hydrationOr', 'hydration_or'],
                        soKeys: ['hydrationSo', 'hydration_so'],
                        enKeys: ['hydrationEn', 'hydration_en'],
                        defaultKeys: ['hydration'],
                        fallback: '',
                      ),
                    ),
                    _VideoTab(
                      nutrientSections: _getNutrientSections(_userLang),
                      userLang: _userLang,
                      defaultVideoUrl: (widget.nutrient['videoUrl'] ?? widget.nutrient['video_url']) as String?,
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

  Widget _buildHeader(BuildContext context, String _userLang) {
    final title = _getTitle(_userLang);
    final imageUrl = _getImageUrl();
    final emoji = _getEmoji();
    final nutrientType = _getNutrientType();
    final pdfUrl = _getPdfUrl();

    return Stack(
      children: [
        // Background: image or gradient
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
        // PDF action button if PDF URL present
        if (pdfUrl.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: GestureDetector(
              onTap: () => _launchMediaUrl(context, pdfUrl),
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
                    Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'PDF Guide',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Title + emoji
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
                    if (nutrientType.isNotEmpty)
                      Text(
                        nutrientType.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              // Eat / Avoid badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isAvoid
                      ? Colors.red.withValues(alpha: 0.85)
                      : Colors.green.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.isAvoid ? '🚫 Avoid' : '✅ Eat',
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

class _DetailsTab extends StatelessWidget {
  final List<Map<String, dynamic>> nutrientSections;
  final bool isAvoid;
  final String reason;
  final String userLang;
  final String pdfUrl;
  final String whyImportantText;
  final String hydrationText;

  const _DetailsTab({
    required this.nutrientSections,
    required this.isAvoid,
    required this.reason,
    required this.userLang,
    required this.pdfUrl,
    this.whyImportantText = '',
    this.hydrationText = '',
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (reason.isNotEmpty)
          _ReasonBanner(reason: reason, isAvoid: isAvoid),
        ...nutrientSections.map(
          (section) => _NutrientSection(
            section: section,
            isAvoid: isAvoid,
            userLang: userLang,
          ),
        ),
        // ── Hydration from weekly guide ───────────────────────────
        if (hydrationText.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💧', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hydration',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF1565C0))),
                      const SizedBox(height: 3),
                      Text(hydrationText,
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1565C0),
                              height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        // ── Why Important from weekly guide ───────────────────────
        if (whyImportantText.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
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
                      Text('Why This Is Important',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.primary)),
                      const SizedBox(height: 3),
                      Text(whyImportantText,
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (pdfUrl.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.picture_as_pdf_rounded, color: Colors.red.shade700, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Full PDF Nutrition Guide',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Download or view full official dietary booklet',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _launchMediaUrl(context, pdfUrl),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: const Text('Open', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
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
                  isAvoid ? 'Why to Avoid' : 'Why This Is Important',
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
// Nutrient Section card (e.g. 🥩 IRON / 🥛 CALCIUM)
// ─────────────────────────────────────────────────────────────────────────────

class _NutrientSection extends StatelessWidget {
  final Map<String, dynamic> section;
  final bool isAvoid;
  final String userLang;

  const _NutrientSection({
    required this.section,
    required this.isAvoid,
    required this.userLang,
  });

  @override
  Widget build(BuildContext context) {
    final rawType = (section['nutrientType'] ?? section['nutrient_type'] ?? section['type'] ?? '') as String;
    final emoji = (section['emoji'] as String?) ?? (isAvoid ? '🚫' : '🌿');

    final title = _extractLocalized(
      section,
      userLang,
      amKeys: ['titleAm', 'title_am', 'nameAm', 'name_am'],
      orKeys: ['titleOr', 'title_or', 'nameOr', 'name_or'],
      soKeys: ['titleSo', 'title_so', 'nameSo', 'name_so'],
      enKeys: ['titleEn', 'title_en', 'nameEn', 'name_en'],
      defaultKeys: ['title', 'name', 'type', 'nutrientType'],
      fallback: rawType.isNotEmpty ? rawType : (isAvoid ? 'AVOID' : 'NUTRIENT'),
    );

    final description = _extractLocalized(
      section,
      userLang,
      amKeys: ['bodyAm', 'body_am', 'descAm', 'descriptionAm'],
      orKeys: ['bodyOr', 'body_or', 'descOr', 'descriptionOr'],
      soKeys: ['bodySo', 'body_so', 'descSo', 'descriptionSo'],
      enKeys: ['bodyEn', 'body_en', 'descEn', 'descriptionEn'],
      defaultKeys: ['body', 'description', 'desc'],
      fallback: '',
    );

    final benefitVal = (section['benefitValue'] ?? section['benefit_value'] ?? '') as String;
    final benefitLabel = _extractLocalized(
      section,
      userLang,
      amKeys: ['benefitLabelAm', 'benefit_label_am'],
      orKeys: ['benefitLabelOr', 'benefit_label_or'],
      soKeys: ['benefitLabelSo', 'benefit_label_so'],
      enKeys: ['benefitLabelEn', 'benefit_label_en'],
      defaultKeys: ['benefitLabel', 'benefit_label'],
      fallback: 'Daily requirement',
    );

    final tips = (section['helpfulTips'] ?? section['helpful_tips'] ?? section['tip'] ?? '') as String;
    final foods = (section['foods'] as List<dynamic>?) ?? [];

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
          // ── Header ───────────────────────────────────────────
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
                        title.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: isAvoid ? Colors.red : AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      if (description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            description,
                            style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.35),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Benefit Badge / Requirement ───────────────────────
          if (benefitVal.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isAvoid ? Colors.red.shade50 : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(isAvoid ? '⚠️' : '🩸', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$benefitLabel: $benefitVal',
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

          // ── Helpful Tips ──────────────────────────────────────
          if (tips.isNotEmpty)
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
                      tips,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 6),
          Divider(height: 1, color: Colors.grey.shade100),

          // ── Food items ────────────────────────────────────────
          if (foods.isNotEmpty) ...[
            ...foods.map(
              (food) => _FoodRow(
                food: food,
                isAvoid: isAvoid,
                userLang: userLang,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: GestureDetector(
                onTap: () => _showAllFoods(context, foods, title, emoji),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All Foods (${foods.length})',
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
                'No food items listed for this section.',
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

  const _FoodRow({
    required this.food,
    required this.isAvoid,
    required this.userLang,
  });

  String _foodName(dynamic food) {
    if (food is String) return food;
    if (food is Map) {
      return _extractLocalized(
        food,
        userLang,
        amKeys: ['nameAm', 'name_am', 'titleAm', 'title_am'],
        orKeys: ['nameOr', 'name_or', 'titleOr', 'title_or'],
        soKeys: ['nameSo', 'name_so', 'titleSo', 'title_so'],
        enKeys: ['nameEn', 'name_en', 'titleEn', 'title_en'],
        defaultKeys: ['name', 'title'],
        fallback: 'Food Item',
      );
    }
    return food.toString();
  }

  @override
  Widget build(BuildContext context) {
    final name = _foodName(food);
    final foodMap = food is Map ? food : null;
    final thumb = _resolveUrl(foodMap?['imageUrl'] ?? foodMap?['image_url']);

    return InkWell(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _FoodDetailsSheet(
          food: food,
          isAvoid: isAvoid,
          userLang: userLang,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            if (thumb.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  thumb,
                  width: 34,
                  height: 34,
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
// Food List Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _FoodListSheet extends StatelessWidget {
  final List<dynamic> foods;
  final String typeLabel;
  final String emoji;
  final bool isAvoid;
  final String userLang;

  const _FoodListSheet({
    required this.foods,
    required this.typeLabel,
    required this.emoji,
    required this.isAvoid,
    required this.userLang,
  });

  String _nameOf(dynamic food) {
    if (food is String) return food;
    if (food is Map) {
      return _extractLocalized(
        food,
        userLang,
        amKeys: ['nameAm', 'name_am', 'titleAm', 'title_am'],
        orKeys: ['nameOr', 'name_or', 'titleOr', 'title_or'],
        soKeys: ['nameSo', 'name_so', 'titleSo', 'title_so'],
        enKeys: ['nameEn', 'name_en', 'titleEn', 'title_en'],
        defaultKeys: ['name', 'title'],
        fallback: 'Food Item',
      );
    }
    return food.toString();
  }

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
                itemCount: foods.length,
                separatorBuilder: (_, __) =>
                    Divider(color: Colors.grey.shade100, height: 1),
                itemBuilder: (ctx, i) {
                  final food = foods[i];
                  final name = _nameOf(food);
                  final foodMap = food is Map ? food : null;
                  final thumb = _resolveUrl(foodMap?['imageUrl'] ?? foodMap?['image_url']);

                  return ListTile(
                    leading: thumb.isNotEmpty
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
                        builder: (_) => _FoodDetailsSheet(
                          food: food,
                          isAvoid: isAvoid,
                          userLang: userLang,
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
        color: isAvoid
            ? Colors.red.shade50
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          isAvoid ? '🚫' : '🥗',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Food Details Bottom Sheet Modal
// ─────────────────────────────────────────────────────────────────────────────

class _FoodDetailsSheet extends StatelessWidget {
  final dynamic food;
  final bool isAvoid;
  final String userLang;

  const _FoodDetailsSheet({
    required this.food,
    required this.isAvoid,
    required this.userLang,
  });

  Map? get _map => food is Map ? food as Map : null;

  String get _name => _extractLocalized(
        _map,
        userLang,
        amKeys: ['nameAm', 'name_am', 'titleAm', 'title_am'],
        orKeys: ['nameOr', 'name_or', 'titleOr', 'title_or'],
        soKeys: ['nameSo', 'name_so', 'titleSo', 'title_so'],
        enKeys: ['nameEn', 'name_en', 'titleEn', 'title_en'],
        defaultKeys: ['name', 'title'],
        fallback: food is String ? food : 'Food Item',
      );

  String get _nameAmharic => (_map?['nameAm'] ?? _map?['name_am'] ?? '') as String;
  String get _nameOromo => (_map?['nameOr'] ?? _map?['name_or'] ?? '') as String;
  String get _nameSomali => (_map?['nameSo'] ?? _map?['name_so'] ?? '') as String;
  String get _nameEnglish => (_map?['nameEn'] ?? _map?['name_en'] ?? '') as String;

  String get _description => _extractLocalized(
        _map,
        userLang,
        amKeys: ['descriptionAm', 'description_am', 'descAm', 'bodyAm'],
        orKeys: ['descriptionOr', 'description_or', 'descOr', 'bodyOr'],
        soKeys: ['descriptionSo', 'description_so', 'descSo', 'bodySo'],
        enKeys: ['descriptionEn', 'description_en', 'descEn', 'bodyEn'],
        defaultKeys: ['description', 'desc', 'why_include', 'whyInclude', 'body'],
        fallback: '',
      );

  String get _imageUrl => _resolveUrl(
        (_map?['imageUrl'] ?? _map?['image_url']) as String?,
      );

  String get _videoUrl => _resolveUrl(
        (_map?['videoUrl'] ?? _map?['video_url']) as String?,
      );

  String get _benefit => (_map?['benefit'] ?? _map?['benefitValue'] ?? _map?['benefit_value'] ?? '') as String;
  String get _benefitLabel => _extractLocalized(
        _map,
        userLang,
        amKeys: ['benefitLabelAm', 'benefit_label_am'],
        orKeys: ['benefitLabelOr', 'benefit_label_or'],
        soKeys: ['benefitLabelSo', 'benefit_label_so'],
        enKeys: ['benefitLabelEn', 'benefit_label_en'],
        defaultKeys: ['benefitLabel', 'benefit_label'],
        fallback: 'Nutritional Value',
      );

  String get _tip => (_map?['tip'] ?? _map?['helpfulTips'] ?? _map?['helpful_tips'] ?? '') as String;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
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
                    Text('Food Details',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ),
            Divider(color: Colors.grey.shade100),
            if (_imageUrl.isNotEmpty)
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_name.isNotEmpty)
                    Text(
                      _name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  // Multilingual subtitling pills
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (_nameEnglish.isNotEmpty && userLang != 'en')
                        _langPill('EN', _nameEnglish),
                      if (_nameAmharic.isNotEmpty && userLang != 'am')
                        _langPill('AM', _nameAmharic),
                      if (_nameOromo.isNotEmpty && userLang != 'or')
                        _langPill('OR', _nameOromo),
                      if (_nameSomali.isNotEmpty && userLang != 'so')
                        _langPill('SO', _nameSomali),
                    ],
                  ),
                ],
              ),
            ),

            // Video button if available
            if (_videoUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: ElevatedButton.icon(
                  onPressed: () => _launchMediaUrl(context, _videoUrl),
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                  label: const Text('Watch Food Video Guide'),
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

            // Benefit block
            if (_benefit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isAvoid
                        ? Colors.red.shade50
                        : AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isAvoid ? '⚠️' : '🩸',
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_benefitLabel.isNotEmpty)
                              Text(_benefitLabel,
                                  style: TextStyle(
                                      color: isAvoid
                                          ? Colors.red
                                          : AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            Text(_benefit,
                                style: TextStyle(
                                    color: Colors.grey[700], fontSize: 13)),
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
                  isAvoid ? 'Why avoid it?' : 'Why include it?',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
            ],

            // Tip block
            if (_tip.isNotEmpty) ...[
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
                                    color: Colors.grey[800],
                                    fontSize: 13,
                                    height: 1.5)),
                          ],
                        ),
                      ),
                    ],
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

  Widget _langPill(String code, String val) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$code: $val',
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
        child: Icon(Icons.restaurant_rounded,
            size: 48,
            color: AppColors.primary.withValues(alpha: 0.4)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Video Tab — Dynamic functional playback list
// ─────────────────────────────────────────────────────────────────────────────

class _VideoTab extends StatelessWidget {
  final List<Map<String, dynamic>> nutrientSections;
  final String userLang;
  final String? defaultVideoUrl;

  const _VideoTab({
    required this.nutrientSections,
    required this.userLang,
    this.defaultVideoUrl,
  });

  List<_VideoEntry> _buildEntries() {
    final entries = <_VideoEntry>[];

    for (final section in nutrientSections) {
      final sectionType =
          ((section['nutrientType'] ?? section['type'] ?? '') as String).toUpperCase();
      final sectionEmoji = (section['emoji'] as String?) ?? '🎬';
      final foods = (section['foods'] as List<dynamic>?) ?? [];
      final sectionVideoUrl = _resolveUrl(
        (section['video_url'] ?? section['videoUrl'] ?? defaultVideoUrl) as String?,
      );

      final sectionTitle = _extractLocalized(
        section,
        userLang,
        amKeys: ['titleAm', 'title_am', 'videoTitleAm'],
        orKeys: ['titleOr', 'title_or', 'videoTitleOr'],
        soKeys: ['titleSo', 'title_so', 'videoTitleSo'],
        enKeys: ['titleEn', 'title_en', 'videoTitleEn'],
        defaultKeys: ['video_title', 'videoTitle', 'title', 'type'],
        fallback: sectionType.isNotEmpty ? '$sectionType Video Guide' : 'Nutrition Video',
      );

      final sectionDesc = _extractLocalized(
        section,
        userLang,
        amKeys: ['bodyAm', 'body_am'],
        orKeys: ['bodyOr', 'body_or'],
        soKeys: ['bodySo', 'body_so'],
        enKeys: ['bodyEn', 'body_en'],
        defaultKeys: ['body', 'description'],
        fallback: 'Overview of $sectionType foods in pregnancy',
      );

      final sectionThumb = _resolveUrl((section['imageUrl'] ?? section['image_url']) as String?);

      // Section video card
      entries.add(_VideoEntry(
        emoji: sectionEmoji,
        typeLabel: sectionType,
        title: sectionTitle,
        subtitle: sectionDesc,
        videoUrl: sectionVideoUrl,
        foodName: '',
        foodImageUrl: sectionThumb,
      ));

      // Food items videos
      for (final food in foods) {
        if (food is! Map) continue;
        final foodMap = food as Map<String, dynamic>;
        final foodName = _extractLocalized(
          foodMap,
          userLang,
          amKeys: ['nameAm', 'name_am'],
          orKeys: ['nameOr', 'name_or'],
          soKeys: ['nameSo', 'name_so'],
          enKeys: ['nameEn', 'name_en'],
          defaultKeys: ['name', 'title'],
          fallback: '',
        );

        if (foodName.isEmpty) continue;

        final foodVideoUrl = _resolveUrl(
          (foodMap['video_url'] ?? foodMap['videoUrl'] ?? sectionVideoUrl) as String?,
        );
        final foodImageUrl = _resolveUrl(
          (foodMap['image_url'] ?? foodMap['imageUrl']) as String?,
        );
        final benefit = _extractLocalized(
          foodMap,
          userLang,
          amKeys: ['descriptionAm', 'descAm'],
          orKeys: ['descriptionOr', 'descOr'],
          soKeys: ['descriptionSo', 'descSo'],
          enKeys: ['descriptionEn', 'descEn'],
          defaultKeys: ['description', 'benefit', 'why_include'],
          fallback: '$foodName in pregnancy',
        );

        entries.add(_VideoEntry(
          emoji: sectionEmoji,
          typeLabel: sectionType,
          title: '$foodName — $sectionType',
          subtitle: benefit,
          videoUrl: foodVideoUrl,
          foodName: foodName,
          foodImageUrl: foodImageUrl.isNotEmpty ? foodImageUrl : sectionThumb,
        ));
      }
    }

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _buildEntries();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Intro hint banner
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.play_circle_outline_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tap any card to watch video guides on your device.',
                  style: TextStyle(
                      color: AppColors.primary, fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),

        // One white card per entry
        ...entries.map((entry) => _VideoItemCard(entry: entry)),
      ],
    );
  }
}

// ─── Video Data Class ─────────────────────────────────────────────────────────

class _VideoEntry {
  final String emoji;
  final String typeLabel;
  final String title;
  final String subtitle;
  final String videoUrl;
  final String foodName;
  final String foodImageUrl;

  const _VideoEntry({
    required this.emoji,
    required this.typeLabel,
    required this.title,
    required this.subtitle,
    required this.videoUrl,
    required this.foodName,
    required this.foodImageUrl,
  });
}

// ─── Single Video Card ────────────────────────────────────────────────────────

class _VideoItemCard extends StatelessWidget {
  final _VideoEntry entry;
  const _VideoItemCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final hasImage = entry.foodImageUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          onTap: () {
            if (entry.videoUrl.isNotEmpty) {
              _launchMediaUrl(context, entry.videoUrl);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Video guide link is being prepared for this item.'),
                ),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail / play area ─────────────────────────────────
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
                      child: hasImage
                          ? Image.network(
                              entry.foodImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _thumbnailPlaceholder(),
                            )
                          : _thumbnailPlaceholder(),
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

                    // Nutrient-type badge (top-left)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(entry.emoji,
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              entry.typeLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Centred play button
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Card body ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(entry.emoji,
                            style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (entry.subtitle.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                entry.subtitle,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
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

  Widget _thumbnailPlaceholder() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.07),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(entry.emoji, style: const TextStyle(fontSize: 38)),
            const SizedBox(height: 6),
            Text(
              entry.typeLabel,
              style: TextStyle(
                color: AppColors.primary.withValues(alpha: 0.7),
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
