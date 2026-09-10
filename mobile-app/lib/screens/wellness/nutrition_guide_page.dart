import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/content_service.dart';
import 'package:pregnancy_appp/services/mother_service.dart';
import 'nutrient_detail_page.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// URL resolver
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
  const host = 'http://192.168.0.199:5000';
  return resolved.startsWith('/') ? '$host$resolved' : '$host/$resolved';
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Localized-text extractor
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  return check(enKeys) ??
      check(amKeys) ??
      check(orKeys) ??
      check(soKeys) ??
      check(defaultKeys) ??
      fallback;
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Main Page
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class NutritionGuidePage extends StatefulWidget {
  const NutritionGuidePage({super.key});

  @override
  State<NutritionGuidePage> createState() => _NutritionGuidePageState();
}

class _NutritionGuidePageState extends State<NutritionGuidePage> {
  // Period filter
  String _periodMode = 'trimester'; // 'trimester' | 'month' | 'week'
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
        _selectedValue = trimester;
        _periodMode = 'trimester';
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
              _PeriodChipRow(
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Period Mode Row
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PeriodModeRow extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;

  const _PeriodModeRow({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const modes = [
      ('month', 'Month'),
      ('trimester', 'Trimester'),
      ('week', 'Week'),
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Period Chip Row
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PeriodChipRow extends StatelessWidget {
  final String mode;
  final int selected;
  final int currentWeek;
  final int currentTrimester;
  final int currentMonth;
  final ValueChanged<int> onSelected;

  const _PeriodChipRow({
    required this.mode,
    required this.selected,
    required this.currentWeek,
    required this.currentTrimester,
    required this.currentMonth,
    required this.onSelected,
  });

  List<int> get _values {
    switch (mode) {
      case 'month':
        return List.generate(9, (i) => i + 1);
      case 'week':
        return List.generate(40, (i) => i + 1);
      default:
        return [1, 2, 3];
    }
  }

  String _label(int v) {
    switch (mode) {
      case 'month':
        return 'M$v';
      case 'week':
        return 'W$v';
      default:
        return v == 1
            ? '1st'
            : v == 2
                ? '2nd'
                : '3rd';
    }
  }

  bool _isCurrent(int v) {
    switch (mode) {
      case 'month':
        return v == currentMonth;
      case 'week':
        return v == currentWeek;
      default:
        return v == currentTrimester;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _values.map((v) {
          final isSelected = v == selected;
          final isCurrent = _isCurrent(v);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : isCurrent
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : isCurrent
                            ? AppColors.primary.withValues(alpha: 0.4)
                            : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _label(v),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isCurrent
                                ? AppColors.primary
                                : Colors.grey[600],
                        fontWeight: isSelected || isCurrent
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isSelected ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Nutrition Content (week guides list)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
        old.periodValue != widget.periodValue) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ContentService.getNutrition(widget.trimester);
      if (!mounted) return;

      List<dynamic> displayItems = items;

      if (widget.periodMode == 'week') {
        final weekMatches = items.where((it) {
          final w = it['week'];
          return w != null &&
              (w == widget.periodValue ||
                  w.toString() == widget.periodValue.toString());
        }).toList();
        if (weekMatches.isNotEmpty) displayItems = weekMatches;
      } else if (widget.periodMode == 'month') {
        final startWeek = ((widget.periodValue - 1) * 4.33).round() + 1;
        final endWeek = (widget.periodValue * 4.33).round();
        final monthMatches = items.where((it) {
          final w = int.tryParse(it['week']?.toString() ?? '') ?? 0;
          return w >= startWeek && w <= endWeek;
        }).toList();
        if (monthMatches.isNotEmpty) displayItems = monthMatches;
      }

      setState(() => _guides = displayItems);
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
    if (_guides.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu_rounded,
                size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No nutrition guides available for this period.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _guides.length,
      itemBuilder: (_, i) =>
          _WeekGuideCard(guide: _guides[i], userLang: widget.userLang),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Week Guide Card
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _WeekGuideCard extends StatelessWidget {
  final dynamic guide;
  final String userLang;

  const _WeekGuideCard({required this.guide, required this.userLang});

  Map? get _map => guide is Map ? guide as Map : null;

  int get _week => int.tryParse(_map?['week']?.toString() ?? '') ?? 0;
  int get _trimester =>
      int.tryParse(_map?['trimester']?.toString() ?? '') ?? 0;
  int get _month => _week > 0 ? ((_week / 4.33).ceil()).clamp(1, 9) : 0;

  String _trimesterLabel(int t) {
    if (t == 1) return '1st Trimester';
    if (t == 2) return '2nd Trimester';
    return '3rd Trimester';
  }

  String get _hydration => _loc(
        _map,
        userLang,
        amKeys: ['hydrationAm', 'hydration_am'],
        orKeys: ['hydrationOr', 'hydration_or'],
        soKeys: ['hydrationSo', 'hydration_so'],
        enKeys: ['hydrationEn', 'hydration_en'],
        defaultKeys: ['hydration'],
        fallback: '',
      );

  String get _whyImportant => _loc(
        _map,
        userLang,
        amKeys: ['whyImportantAm', 'why_important_am'],
        orKeys: ['whyImportantOr', 'why_important_or'],
        soKeys: ['whyImportantSo', 'why_important_so'],
        enKeys: ['whyImportantEn', 'why_important_en'],
        defaultKeys: ['why_important', 'whyImportant'],
        fallback: '',
      );

  List<Map<String, dynamic>> get _sections {
    final raw = _map?['nutrientSectionsJson'] ??
        _map?['nutrient_sections_json'] ??
        _map?['sections'];
    if (raw is List && raw.isNotEmpty) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _WeekHeader(
            week: _week,
            trimester: _trimester,
            month: _month,
            trimesterLabel: _trimesterLabel(_trimester),
          ),

          // â”€â”€ Nutrient section rows â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (sections.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No nutrient information for this week yet.',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              itemCount: sections.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (ctx, i) => _NutrientSectionRow(
                section: sections[i],
                userLang: userLang,
                onTap: () {
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => NutrientDetailPage(
                        nutrient: sections[i],
                        weekGuide: _map != null
                            ? Map<String, dynamic>.from(_map!)
                            : {},
                        initialLang: userLang,
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 12),

          // â”€â”€ Hydration strip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (_hydration.isNotEmpty)
            _InfoStrip(icon: 'ðŸ’§', text: _hydration, color: const Color(0xFFE3F2FD), textColor: const Color(0xFF1565C0)),

          // â”€â”€ Why important strip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (_whyImportant.isNotEmpty)
            _InfoStrip(icon: 'ðŸ’¡', text: _whyImportant, color: AppColors.primary.withValues(alpha: 0.07), textColor: Colors.grey.shade800),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Week Header
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _WeekHeader extends StatelessWidget {
  final int week;
  final int trimester;
  final int month;
  final String trimesterLabel;

  const _WeekHeader({
    required this.week,
    required this.trimester,
    required this.month,
    required this.trimesterLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  week > 0 ? '$week' : 'â€”',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    height: 1,
                  ),
                ),
                const Text(
                  'WK',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  week > 0 ? 'Week $week Nutrition Guide' : 'Nutrition Guide',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    if (trimester > 0)
                      _HeaderChip(
                          icon: Icons.timeline_rounded,
                          label: trimesterLabel),
                    if (month > 0)
                      _HeaderChip(
                          icon: Icons.calendar_month_rounded,
                          label: 'Month $month'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Nutrient Section Row
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
    final emoji = (section['emoji'] as String?) ?? 'ðŸŒ¿';
    final title = _loc(
      section,
      userLang,
      amKeys: ['titleAm', 'title_am'],
      orKeys: ['titleOr', 'title_or'],
      soKeys: ['titleSo', 'title_so'],
      enKeys: ['titleEn', 'title_en'],
      defaultKeys: ['title', 'name', 'nutrientType'],
      fallback: 'Nutrient',
    );
    final body = _loc(
      section,
      userLang,
      amKeys: ['bodyAm', 'body_am'],
      orKeys: ['bodyOr', 'body_or'],
      soKeys: ['bodySo', 'body_so'],
      enKeys: ['bodyEn', 'body_en'],
      defaultKeys: ['body', 'description'],
      fallback: '',
    );
    final imageUrl =
        _resolveUrl((section['imageUrl'] ?? section['image_url']) as String?);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Nutrient icon / image badge
            Container(
              width: 46,
              height: 46,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
                    )
                  : Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (body.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            height: 1.4),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Info Strip (Hydration / Why Important)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _InfoStrip extends StatelessWidget {
  final String icon;
  final String text;
  final Color color;
  final Color textColor;

  const _InfoStrip({
    required this.icon,
    required this.text,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.5, color: textColor, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

