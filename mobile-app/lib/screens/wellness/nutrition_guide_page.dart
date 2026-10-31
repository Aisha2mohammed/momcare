import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/content_service.dart';
import 'package:pregnancy_appp/services/mother_service.dart';
import 'package:pregnancy_appp/widget/app_video_player.dart';
import 'package:pregnancy_appp/widget/week_selector.dart';
import 'package:pregnancy_appp/widget/wellness_info_card.dart';
import 'package:pregnancy_appp/widget/wellness_type_filter_row.dart';
import 'nutrient_detail_page.dart';


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


String _loc(
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

  final l = (lang == 'om' || lang == 'or') ? 'om' : lang;

  if (source[l] != null && source[l].toString().trim().isNotEmpty) {
    final v = source[l];
    if (v is String) return v.trim();
    if (v is Map) return _loc(v, lang, fallback: fallback);
  }
  if ((lang == 'om' || lang == 'or') && source['or'] != null && source['or'].toString().trim().isNotEmpty) {
    final v = source['or'];
    if (v is String) return v.trim();
  }

  String? check(List<String> keys) {
    for (final k in keys) {
      final v = source[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v is Map) {
        final inner = _loc(v, lang, fallback: '');
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
      check(['en', 'am', 'om', 'or', 'so']) ??
      fallback;
}



class NutritionGuidePage extends StatefulWidget {
  const NutritionGuidePage({super.key});

  @override
  State<NutritionGuidePage> createState() => _NutritionGuidePageState();
}

class _NutritionGuidePageState extends State<NutritionGuidePage> {
  // Period filter
  String _periodMode = 'week'; // Default to week based on profile LMP
  int _currentWeek = 1;
  int _currentTrimester = 1;
  int _currentMonth = 1;
  int _selectedValue = 1;
  bool _loadingPeriod = true;

  @override
  void initState() {
    super.initState();
    _fetchUserPeriod();
  }

  Future<void> _fetchUserPeriod() async {
    setState(() => _loadingPeriod = true);
    try {
      final data = await MotherService.getGestationalWeek();
      final week = (data['currentWeek'] as int?) ?? 1;
      final trimester = (data['currentTrimester'] as int?) ?? 1;
      final month = ((week / 4.33).ceil()).clamp(1, 9);
      if (!mounted) return;
      setState(() {
        _currentWeek = week;
        _currentTrimester = trimester;
        _currentMonth = month;
        _selectedValue = week;
        _periodMode = 'week';
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingPeriod = false);
    }
  }

  void _setPeriodMode(String mode) {
    setState(() {
      _periodMode = mode;
      switch (mode) {
        case 'month':
          _selectedValue = _currentMonth;
          break;
        case 'week':
          _selectedValue = _currentWeek;
          break;
        default:
          _selectedValue = _currentTrimester;
      }
    });
  }

  int get _trimesterForContent {
    if (_periodMode == 'trimester') return _selectedValue.clamp(1, 3);
    if (_periodMode == 'week') {
      final w = _selectedValue;
      if (w <= 13) return 1;
      if (w <= 27) return 2;
      return 3;
    }
    final w = (_selectedValue * 4.33).round();
    if (w <= 13) return 1;
    if (w <= 27) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0F3),
      appBar: AppBar(
        title: Text(
          AppStrings.of(context, 'nutrition'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              const Divider(height: 1, color: Color(0xFFEDE8EB)),
              _PeriodModeRow(
                current: _periodMode,
                onChanged: _setPeriodMode,
              ),
              WeekSelector(
                mode: _periodMode,
                selected: _selectedValue,
                currentWeek: _currentWeek,
                currentTrimester: _currentTrimester,
                currentMonth: _currentMonth,
                onSelected: (v) => setState(() => _selectedValue = v),
              ),
            ],
          ),
        ),
      ),
      body: _loadingPeriod
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Consumer<LocaleProvider>(
              builder: (context, localeProvider, child) {
                // If language isn't matched directly with 'om' to 'or', we do basic fallback.
                String userLang = localeProvider.locale?.languageCode ?? 'am';
                if (userLang == 'om') userLang = 'or'; // 'om' is used for Oromo, but code uses 'or'
                return _NutritionContent(
                  trimester: _trimesterForContent,
                  periodMode: _periodMode,
                  periodValue: _selectedValue,
                  userLang: userLang,
                );
              },
            ),
    );
  }
}


class _PeriodModeRow extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;

  const _PeriodModeRow({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final modes = [
      ('month', AppStrings.of(context, 'period_month')),
      ('trimester', AppStrings.of(context, 'period_trimester')),
      ('week', AppStrings.of(context, 'period_week')),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: modes.map((m) {
          final selected = m.$1 == current;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(m.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  m.$2,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.grey[600],
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}


class _NutritionContent extends StatefulWidget {
  final int trimester;
  final String periodMode;
  final int periodValue;
  final String userLang;

  const _NutritionContent({
    required this.trimester,
    required this.periodMode,
    required this.periodValue,
    required this.userLang,
  });

  @override
  State<_NutritionContent> createState() => _NutritionContentState();
}

class _NutritionContentState extends State<_NutritionContent> {
  List<dynamic> _guides = [];
  Map<String, dynamic>? _weekInfo;
  String _currentType = 'eat'; // 'eat' | 'avoid'
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_NutritionContent old) {
    super.didUpdateWidget(old);
    if (old.trimester != widget.trimester ||
        old.periodMode != widget.periodMode ||
        old.periodValue != widget.periodValue ||
        old.userLang != widget.userLang) {
      _load();
    }
  }



  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final weekNum = widget.periodMode == 'week' ? widget.periodValue : null;
      final monthNum = widget.periodMode == 'month'
          ? widget.periodValue
          : (widget.periodMode == 'week' ? ((widget.periodValue / 4.33).ceil()).clamp(1, 9) : null);

      final itemsFuture = ContentService.getNutrition(
        widget.trimester,
        month: widget.periodMode == 'month' ? widget.periodValue : null,
        week: weekNum,
        type: _currentType,
        lang: widget.userLang,
      );
      final weekFuture = ContentService.getNutritionWeek(
        widget.trimester,
        month: monthNum,
        week: weekNum,
        lang: widget.userLang,
      );

      final results = await Future.wait([itemsFuture, weekFuture]);
      if (!mounted) return;

      final items = results[0] as List<dynamic>;
      final weekData = results[1] as Map<String, dynamic>?;

      List<dynamic> displayItems = items;

      if (widget.periodMode == 'week') {
        final weekMatches = items.where((it) {
          final w = it['week'] ??
              (weekData != null && it['nutrition_week_id'] != null && it['nutrition_week_id'] == weekData['id']
                  ? weekData['week']
                  : null);
          return w != null &&
              (w == widget.periodValue ||
                  w.toString() == widget.periodValue.toString());
        }).toList();
        if (weekMatches.isNotEmpty) {
          displayItems = weekMatches;
        } else if (items.isNotEmpty) {
          displayItems = items;
        }
      } else if (widget.periodMode == 'month') {
        final monthMatches = items.where((it) {
          final m = it['month'] ??
              (weekData != null && it['nutrition_week_id'] != null && it['nutrition_week_id'] == weekData['id']
                  ? weekData['month']
                  : null);
          if (m != null && (m == widget.periodValue || m.toString() == widget.periodValue.toString())) {
            return true;
          }
          final w = int.tryParse(it['week']?.toString() ?? '') ??
              (weekData != null && it['nutrition_week_id'] != null && it['nutrition_week_id'] == weekData['id']
                  ? int.tryParse(weekData['week']?.toString() ?? '') ?? 0
                  : 0);
          final startWeek = ((widget.periodValue - 1) * 4.33).round() + 1;
          final endWeek = (widget.periodValue * 4.33).round();
          return w >= startWeek && w <= endWeek;
        }).toList();
        if (monthMatches.isNotEmpty) {
          displayItems = monthMatches;
        } else if (items.isNotEmpty) {
          displayItems = items;
        }
      }

      setState(() {
        _guides = displayItems;
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

    // Resolve whyImportant & hydration from weekInfo, items, or fallback
    String whyImportant = '';
    String hydration = '';

    if (_weekInfo != null) {
      whyImportant = _loc(
        _weekInfo,
        widget.userLang,
        amKeys: ['whyImportantAm', 'why_important_am'],
        orKeys: ['whyImportantOr', 'why_important_or', 'whyImportantOm', 'why_important_om'],
        soKeys: ['whyImportantSo', 'why_important_so'],
        enKeys: ['whyImportantEn', 'why_important_en'],
        defaultKeys: ['why_important', 'whyImportant'],
        fallback: '',
      );
      hydration = _loc(
        _weekInfo,
        widget.userLang,
        amKeys: ['hydrationAm', 'hydration_am'],
        orKeys: ['hydrationOr', 'hydration_or', 'hydrationOm', 'hydration_om'],
        soKeys: ['hydrationSo', 'hydration_so'],
        enKeys: ['hydrationEn', 'hydration_en'],
        defaultKeys: ['hydration'],
        fallback: '',
      );
    }

    if (whyImportant.isEmpty && _guides.isNotEmpty) {
      for (final g in _guides) {
        if (g is Map) {
          final candidate = _loc(
            g,
            widget.userLang,
            amKeys: ['whyImportantAm', 'why_important_am'],
            orKeys: ['whyImportantOr', 'why_important_or', 'whyImportantOm', 'why_important_om'],
            soKeys: ['whyImportantSo', 'why_important_so'],
            enKeys: ['whyImportantEn', 'why_important_en'],
            defaultKeys: ['why_important', 'whyImportant'],
            fallback: '',
          );
          if (candidate.isNotEmpty) {
            whyImportant = candidate;
            break;
          }
        }
      }
    }

    if (hydration.isEmpty && _guides.isNotEmpty) {
      for (final g in _guides) {
        if (g is Map) {
          final candidate = _loc(
            g,
            widget.userLang,
            amKeys: ['hydrationAm', 'hydration_am'],
            orKeys: ['hydrationOr', 'hydration_or', 'hydrationOm', 'hydration_om'],
            soKeys: ['hydrationSo', 'hydration_so'],
            enKeys: ['hydrationEn', 'hydration_en'],
            defaultKeys: ['hydration'],
            fallback: '',
          );
          if (candidate.isNotEmpty) {
            hydration = candidate;
            break;
          }
        }
      }
    }

    // Collect and filter nutrient items for active tab (eat vs avoid)
    final List<Map<String, dynamic>> allItems = [];
    for (final g in _guides) {
      if (g is! Map) continue;
      final gMap = Map<String, dynamic>.from(g);
      final gType = (gMap['type'] ?? 'eat').toString().toLowerCase();
      final isAvoid = gType == 'avoid' || gMap['isAvoid'] == true || gMap['is_avoid'] == true;
      if (_currentType == 'avoid' ? isAvoid : !isAvoid) {
        allItems.add(gMap);
      }
    }

    return Column(
      children: [
        // ── Tab Switcher: What to Eat / What to Avoid ────────────────
        WellnessTypeFilterRow(
          currentType: _currentType,
          firstKey: 'eat',
          firstLabel: AppStrings.of(context, 'what_to_eat'),
          firstIcon: '🥗',
          secondKey: 'avoid',
          secondLabel: AppStrings.of(context, 'what_not_to_eat'),
          secondIcon: '🚫',
          onChanged: (newType) {
            if (_currentType != newType) {
              setState(() => _currentType = newType);
              _load();
            }
          },
        ),

        // ── Main List & Bottom Cards ─────────────────────────────────
        Expanded(
          child: allItems.isEmpty
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _currentType == 'avoid'
                                  ? Icons.do_not_disturb_alt_rounded
                                  : Icons.restaurant_menu_rounded,
                              size: 72,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _currentType == 'avoid'
                                  ? 'No foods to avoid listed for this period.'
                                  : 'No nutrition guides available for this period.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500], fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (whyImportant.trim().isNotEmpty)
                      WellnessInfoCard.whyImportant(context: context, content: whyImportant),
                    if (hydration.trim().isNotEmpty)
                      WellnessInfoCard.hydration(context: context, content: hydration),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  itemCount: allItems.length + 1,
                  itemBuilder: (context, i) {
                    // At the bottom of the list of nutrition items
                    if (i == allItems.length) {
                      if (whyImportant.trim().isEmpty && hydration.trim().isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          if (whyImportant.trim().isNotEmpty)
                            WellnessInfoCard.whyImportant(context: context, content: whyImportant),
                          if (hydration.trim().isNotEmpty)
                            WellnessInfoCard.hydration(context: context, content: hydration),
                        ],
                      );
                    }

                    final section = allItems[i];
                    return _NutrientSectionRow(
                      section: section,
                      userLang: widget.userLang,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NutrientDetailPage(
                              nutrient: section,
                              weekGuide: _weekInfo ?? section,
                              isAvoid: _currentType == 'avoid',
                              initialLang: widget.userLang,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}



// ignore: unused_element
class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: Colors.white70),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Nutrient Section Row
// ─────────────────────────────────────────────────────────────────────────────

class _NutrientSectionRow extends StatelessWidget {
  final Map<String, dynamic> section;
  final String userLang;
  final VoidCallback onTap;

  const _NutrientSectionRow({
    required this.section,
    required this.userLang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = _safeStr(section['emoji'], '🥗');
    final title = _loc(
      section,
      userLang,
      amKeys: ['titleAm', 'title_am', 'nameAm', 'name_am'],
      orKeys: ['titleOr', 'title_or', 'nameOr', 'name_or', 'titleOm', 'title_om'],
      soKeys: ['titleSo', 'title_so', 'nameSo', 'name_so'],
      enKeys: ['titleEn', 'title_en', 'nameEn', 'name_en'],
      defaultKeys: ['title', 'name', 'nutrientType'],
      fallback: 'Nutrition Guide',
    );
    final body = _loc(
      section,
      userLang,
      amKeys: ['descriptionAm', 'description_am', 'bodyAm', 'body_am', 'descAm', 'desc_am'],
      orKeys: ['descriptionOr', 'description_or', 'descriptionOm', 'description_om', 'bodyOr', 'body_or'],
      soKeys: ['descriptionSo', 'description_so', 'bodySo', 'body_so'],
      enKeys: ['descriptionEn', 'description_en', 'bodyEn', 'body_en'],
      defaultKeys: ['body', 'description', 'desc'],
      fallback: '',
    );
    final imageUrl =
        _resolveUrl(_safeExtractMedia(section['imageUrl'] ?? section['image_url'] ?? section['image']));
    final videoUrl =
        _resolveUrl(_safeExtractMedia(section['videoUrl'] ?? section['video_url'] ?? section['video']));

    final descLabel = _loc(
      section,
      userLang,
      amKeys: ['descriptionLabelAm', 'description_label_am', 'benefitLabelAm', 'benefit_label_am'],
      orKeys: ['descriptionLabelOr', 'description_label_or', 'descriptionLabelOm', 'description_label_om'],
      soKeys: ['descriptionLabelSo', 'description_label_so', 'benefitLabelSo', 'benefit_label_so'],
      enKeys: ['descriptionLabelEn', 'description_label_en', 'benefitLabelEn', 'benefit_label_en'],
      defaultKeys: ['description_label', 'benefit_label', 'label'],
      fallback: '',
    );
    final descValue = _loc(
      section,
      userLang,
      amKeys: ['descriptionValueAm', 'description_value_am', 'benefitValueAm', 'benefit_value_am'],
      orKeys: ['descriptionValueOr', 'description_value_or', 'descriptionValueOm', 'description_value_om'],
      soKeys: ['descriptionValueSo', 'description_value_so', 'benefitValueSo', 'benefit_value_so'],
      enKeys: ['descriptionValueEn', 'description_value_en', 'benefitValueEn', 'benefit_value_en'],
      defaultKeys: ['description_value', 'benefit_value', 'value'],
      fallback: '',
    );

    final isAvoid = (section['type'] ?? '').toString().toLowerCase() == 'avoid' ||
        section['isAvoid'] == true ||
        section['is_avoid'] == true;

    dynamic foodsRaw = section['list_food'] ?? section['listFood'] ?? section['foods'];
    if (foodsRaw is String && foodsRaw.trim().startsWith('[')) {
      try {
        foodsRaw = jsonDecode(foodsRaw);
      } catch (_) {}
    }
    final List<dynamic> foods = foodsRaw is List ? foodsRaw : [];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero In-UI Video or Image ──────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
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
                          height: 175,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _NutrientPlaceholder(emoji: emoji),
                        )
                      : _NutrientPlaceholder(emoji: emoji)),
            ),

            // ── Text & Metadata Content ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAvoid ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isAvoid ? '🚫 WHAT TO AVOID' : '🥗 WHAT TO EAT',
                          style: TextStyle(
                            color: isAvoid ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      if (descValue.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAvoid ? const Color(0xFFFFF3E0) : const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            descLabel.isNotEmpty ? '$descLabel: $descValue' : descValue,
                            style: TextStyle(
                              color: isAvoid ? const Color(0xFFE65100) : const Color(0xFF1565C0),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      if (foods.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${foods.length} items',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title & chevron
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey.shade600,
                          size: 18,
                        ),
                      ),
                    ],
                  ),

                  // Description
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],

                  // Food items preview tags
                  if (foods.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: foods.take(4).map((f) {
                        final fName = _loc(
                          f,
                          userLang,
                          amKeys: ['nameAm', 'name_am'],
                          orKeys: ['nameOr', 'name_or', 'nameOm', 'name_om'],
                          soKeys: ['nameSo', 'name_so'],
                          enKeys: ['nameEn', 'name_en'],
                          defaultKeys: ['name', 'title'],
                          fallback: 'Item',
                        );
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAvoid ? const Color(0xFFFFF5F5) : const Color(0xFFF1F8E9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isAvoid ? const Color(0xFFFFCDD2) : const Color(0xFFDCEDC8),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            fName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isAvoid ? const Color(0xFFB71C1C) : const Color(0xFF1B5E20),
                            ),
                          ),
                        );
                      }).toList(),
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

class _NutrientPlaceholder extends StatelessWidget {
  final String emoji;
  const _NutrientPlaceholder({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
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
        child: Text(emoji, style: const TextStyle(fontSize: 48)),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Info Strip (Hydration / Why Important)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€



