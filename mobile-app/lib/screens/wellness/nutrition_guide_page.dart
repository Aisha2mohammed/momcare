import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/content_service.dart';
import 'package:pregnancy_appp/services/mother_service.dart';
import 'nutrient_detail_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main Page
// ─────────────────────────────────────────────────────────────────────────────

class NutritionGuidePage extends StatefulWidget {
  const NutritionGuidePage({super.key});

  @override
  State<NutritionGuidePage> createState() => _NutritionGuidePageState();
}

class _NutritionGuidePageState extends State<NutritionGuidePage>
    with SingleTickerProviderStateMixin {
  late final TabController _innerTabController;

  // Period mode: 'month' | 'trimester' | 'week'
  String _periodMode = 'trimester';

  // Values fetched from backend
  int _currentWeek = 1;
  int _currentTrimester = 1;
  int _currentMonth = 1;

  // Selected period value
  int _selectedValue = 1;

  bool _loadingPeriod = true;

  @override
  void initState() {
    super.initState();
    _innerTabController = TabController(length: 2, vsync: this);
    _fetchUserPeriod();
  }

  @override
  void dispose() {
    _innerTabController.dispose();
    super.dispose();
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
      // keep defaults
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

  // Map any period mode → trimester for backend calls
  int get _trimesterForContent {
    if (_periodMode == 'trimester') return _selectedValue.clamp(1, 3);
    if (_periodMode == 'week') {
      final w = _selectedValue;
      if (w <= 13) return 1;
      if (w <= 27) return 2;
      return 3;
    }
    // month
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
      body: Column(
        children: [
          // ── Inner Eat / Avoid tab bar ──────────────────────────────────
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _innerTabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: '✅  What to Eat'),
                Tab(text: '🚫  What NOT to Eat'),
              ],
            ),
          ),
          // ── Content ───────────────────────────────────────────────────
          Expanded(
            child: _loadingPeriod
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : TabBarView(
                    controller: _innerTabController,
                    children: [
                      _NutritionContent(
                        trimester: _trimesterForContent,
                        type: 'eat',
                      ),
                      _NutritionContent(
                        trimester: _trimesterForContent,
                        type: 'avoid',
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
// Period Mode Row  (Month | Trimester | Week)
// ─────────────────────────────────────────────────────────────────────────────

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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.primary : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  m.$2,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.grey[600],
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
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

// ─────────────────────────────────────────────────────────────────────────────
// Period Chip Row  (individual numbers)
// ─────────────────────────────────────────────────────────────────────────────

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
        return 'Month $v';
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                          color: isSelected ? Colors.white : AppColors.primary,
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

// ─────────────────────────────────────────────────────────────────────────────
// Nutrition Content (list + banners)
// ─────────────────────────────────────────────────────────────────────────────

class _NutritionContent extends StatefulWidget {
  final int trimester;
  final String type; // 'eat' | 'avoid'

  const _NutritionContent({required this.trimester, required this.type});

  @override
  State<_NutritionContent> createState() => _NutritionContentState();
}

class _NutritionContentState extends State<_NutritionContent>
    with AutomaticKeepAliveClientMixin {
  List<dynamic> _allItems = [];
  bool _loading = true;
  String? _error;
  bool _guideExpanded = false;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_NutritionContent old) {
    super.didUpdateWidget(old);
    if (old.trimester != widget.trimester || old.type != widget.type) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Fetch all nutrition items for this trimester
      final items = await ContentService.getNutrition(widget.trimester);
      if (!mounted) return;
      // Filter client-side by type field; fallback: show all for 'eat'
      final filtered = items.where((item) {
        final t = (item['type'] as String?)?.toLowerCase();
        if (t == null || t.isEmpty) return widget.type == 'eat';
        return t == widget.type || t == widget.type.replaceAll('eat', 'food');
      }).toList();
      setState(() => _allItems = filtered.isEmpty ? items : filtered);
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
    super.build(context);
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (_allItems.isEmpty)
          _buildEmpty()
        else
          ..._allItems.map((item) => _buildNutrientCard(item)),

        const SizedBox(height: 16),

        // ── Hydration Banner ─────────────────────────────────────────
        _HydrationBanner(),

        const SizedBox(height: 16),

        // ── Why Important Banner ─────────────────────────────────────
        _WhyImportantBanner(
          expanded: _guideExpanded,
          onToggle: () => setState(() => _guideExpanded = !_guideExpanded),
          isAvoid: widget.type == 'avoid',
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant_menu_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            widget.type == 'eat'
                ? 'No nutrition guidance available yet.'
                : 'No foods to avoid listed yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientCard(dynamic item) {
    final name = (item['title'] as String?) ?? '';
    final body = (item['body'] as String?) ?? '';
    final imageUrl = (item['image_url'] as String?) ?? '';
    final nutrientType = (item['nutrient_type'] as String?) ?? '';
    final emoji = (item['emoji'] as String?) ?? (widget.type == 'avoid' ? '🚫' : '🥗');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NutrientDetailPage(
              nutrient: item,
              isAvoid: widget.type == 'avoid',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            // Top row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon badge
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.type == 'avoid'
                          ? Colors.red.shade50
                          : AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (nutrientType.isNotEmpty)
                          Text(
                            nutrientType.toUpperCase(),
                            style: TextStyle(
                              color: AppColors.primary.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        if (name.isNotEmpty)
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        if (body.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.grey, size: 22),
                ],
              ),
            ),
            // Optional image thumbnail
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Image.network(
                  imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            // Tap hint footer
            if (imageUrl.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Container(
                      height: 1,
                      width: 24,
                      color: Colors.grey.shade200,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.type == 'avoid'
                          ? 'Tap to see why to avoid'
                          : 'Tap to see nutrients & foods',
                      style: TextStyle(
                        color: AppColors.primary.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hydration Banner
// ─────────────────────────────────────────────────────────────────────────────

class _HydrationBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('💧', style: TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hydration',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Remember to drink fluids regularly throughout the day.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
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
// Why Important Banner
// ─────────────────────────────────────────────────────────────────────────────

class _WhyImportantBanner extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final bool isAvoid;

  const _WhyImportantBanner({
    required this.expanded,
    required this.onToggle,
    required this.isAvoid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('💡', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Why are these important?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Colors.grey.shade100),
                  const SizedBox(height: 10),
                  Text(
                    isAvoid
                        ? 'Pregnancy increases your body\'s sensitivity to certain foods. '
                            'Some foods can carry bacteria, viruses, or chemicals that '
                            'are especially harmful to you and your baby during pregnancy.'
                        : 'Pregnancy increases the need for several nutrients. A varied '
                            'diet can help provide nutrients needed to support your health '
                            'and your baby\'s growth.',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.menu_book_rounded, size: 18),
                      label: const Text('Read Full Guide'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
          ),
        ],
      ),
    );
  }
}