import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Nutrient Detail Page  (Details tab + Video tab)
// ─────────────────────────────────────────────────────────────────────────────

class NutrientDetailPage extends StatefulWidget {
  final Map<String, dynamic> nutrient;
  final bool isAvoid;

  const NutrientDetailPage({
    super.key,
    required this.nutrient,
    this.isAvoid = false,
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

  String get _title => (widget.nutrient['title'] as String?) ?? 'Nutrient';
  String get _body => (widget.nutrient['body'] as String?) ?? '';
  String get _imageUrl => (widget.nutrient['image_url'] as String?) ?? '';
  String get _nutrientType =>
      (widget.nutrient['nutrient_type'] as String?) ?? '';
  String get _emoji =>
      (widget.nutrient['emoji'] as String?) ?? (widget.isAvoid ? '🚫' : '🥗');
  String get _reason =>
      (widget.nutrient['reason'] as String?) ?? _body;

  List<Map<String, dynamic>> get _nutrientSections {
    final raw = widget.nutrient['nutrient_sections'];
    if (raw is List) return raw.cast<Map<String, dynamic>>();
    final foods = widget.nutrient['foods'];
    final foodList = foods is List ? foods.cast<dynamic>() : <dynamic>[];
    return [
      {
        'type': _nutrientType.isNotEmpty ? _nutrientType : _title,
        'emoji': _emoji,
        'description': _body,
        'foods': foodList,
        'video_url': widget.nutrient['video_url'],
        'video_title': widget.nutrient['video_title'],
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0F3),
      // ── Plain AppBar (no SliverAppBar) so TabBar sits cleanly below image
      body: Column(
        children: [
          // ── Header image / gradient banner ──────────────────────────────
          _buildHeader(context),

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
                  nutrientSections: _nutrientSections,
                  isAvoid: widget.isAvoid,
                  reason: _reason,
                ),
                _VideoTab(nutrientSections: _nutrientSections),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        // Background: image or gradient
        SizedBox(
          width: double.infinity,
          height: _imageUrl.isNotEmpty ? 210 : 130,
          child: _imageUrl.isNotEmpty
              ? Image.network(
                  _imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _headerGradient(),
                )
              : _headerGradient(),
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
        // Title + emoji
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Row(
            children: [
              Text(_emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        shadows: [
                          Shadow(blurRadius: 4, color: Colors.black54),
                        ],
                      ),
                    ),
                    if (_nutrientType.isNotEmpty)
                      Text(
                        _nutrientType.toUpperCase(),
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

  Widget _headerGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(_emoji, style: const TextStyle(fontSize: 60)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Details Tab  (formerly "Image Tab")
// ─────────────────────────────────────────────────────────────────────────────

class _DetailsTab extends StatelessWidget {
  final List<Map<String, dynamic>> nutrientSections;
  final bool isAvoid;
  final String reason;

  const _DetailsTab({
    required this.nutrientSections,
    required this.isAvoid,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (isAvoid && reason.isNotEmpty)
          _ReasonBanner(reason: reason),
        ...nutrientSections.map(
          (section) => _NutrientSection(section: section, isAvoid: isAvoid),
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
  const _ReasonBanner({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Why to Avoid',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  reason,
                  style: TextStyle(
                    color: Colors.red.shade900,
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
// Nutrient Section card (e.g. 🥛 CALCIUM)
// ─────────────────────────────────────────────────────────────────────────────

class _NutrientSection extends StatelessWidget {
  final Map<String, dynamic> section;
  final bool isAvoid;

  const _NutrientSection({required this.section, required this.isAvoid});

  @override
  Widget build(BuildContext context) {
    final typeLabel = ((section['type'] as String?) ?? '').toUpperCase();
    final emoji = (section['emoji'] as String?) ?? (isAvoid ? '🚫' : '🌿');
    final description = (section['description'] as String?) ?? '';
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
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: isAvoid ? Colors.red : AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      if (description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            description,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          // Food items
          if (foods.isNotEmpty) ...[
            ...foods.map((food) => _FoodRow(food: food, isAvoid: isAvoid)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: GestureDetector(
                onTap: () => _showAllFoods(context, foods, typeLabel, emoji),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All Foods',
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
                'No food items listed.',
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

  const _FoodRow({required this.food, required this.isAvoid});

  String _foodName(dynamic food) {
    if (food is String) return food;
    if (food is Map) {
      return (food['name'] as String?) ??
          (food['title'] as String?) ??
          food.toString();
    }
    return food.toString();
  }

  @override
  Widget build(BuildContext context) {
    final name = _foodName(food);
    return InkWell(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _FoodDetailsSheet(food: food, isAvoid: isAvoid),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isAvoid ? Colors.red.shade300 : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(name, style: const TextStyle(fontSize: 15))),
            Icon(Icons.info_outline_rounded,
                size: 16, color: Colors.grey.shade400),
          ],
        ),
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

  const _FoodListSheet({
    required this.foods,
    required this.typeLabel,
    required this.emoji,
    required this.isAvoid,
  });

  String _nameOf(dynamic food) {
    if (food is String) return food;
    if (food is Map) {
      return (food['name'] as String?) ?? (food['title'] as String?) ?? '';
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
                  Text(
                    typeLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
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
                  return ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
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
                    ),
                    title: Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: Colors.grey),
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            _FoodDetailsSheet(food: food, isAvoid: isAvoid),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Food Details Bottom Sheet Modal
// ─────────────────────────────────────────────────────────────────────────────

class _FoodDetailsSheet extends StatelessWidget {
  final dynamic food;
  final bool isAvoid;

  const _FoodDetailsSheet({required this.food, required this.isAvoid});

  String get _name {
    if (food is String) return food;
    if (food is Map) return (food['name'] as String?) ?? '';
    return food.toString();
  }

  String get _nameAmharic =>
      food is Map ? ((food as Map)['name_am'] as String?) ?? '' : '';
  String get _nameLatin =>
      food is Map ? ((food as Map)['name_latin'] as String?) ?? '' : '';
  String get _imageUrl =>
      food is Map ? ((food as Map)['image_url'] as String?) ?? '' : '';
  String get _benefit =>
      food is Map ? ((food as Map)['benefit'] as String?) ?? '' : '';
  String get _benefitLabel =>
      food is Map ? ((food as Map)['benefit_label'] as String?) ?? '' : '';
  String get _whyInclude =>
      food is Map ? ((food as Map)['why_include'] as String?) ?? '' : '';
  String get _tip =>
      food is Map ? ((food as Map)['tip'] as String?) ?? '' : '';

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
                    Text(_name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 22)),
                  if (_nameAmharic.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(_nameAmharic,
                          style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500)),
                    ),
                  if (_nameLatin.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(_nameLatin,
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic)),
                    ),
                ],
              ),
            ),
            if (_benefit.isNotEmpty || _benefitLabel.isNotEmpty)
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
                            if (_benefit.isNotEmpty)
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
            if (_whyInclude.isNotEmpty) ...[
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
                child: Text(_whyInclude,
                    style: TextStyle(
                        color: Colors.grey[700], fontSize: 14, height: 1.6)),
              ),
            ],
        
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
// Video Tab — proper list of video containers
// ─────────────────────────────────────────────────────────────────────────────

class _VideoTab extends StatelessWidget {
  final List<Map<String, dynamic>> nutrientSections;

  const _VideoTab({required this.nutrientSections});

  /// Flatten every section into individual video entries:
  ///   1. One card for the section-level video (video_url on the section).
  ///   2. One card per food item that carries its own video data (named after the food).
  List<_VideoEntry> _buildEntries() {
    final entries = <_VideoEntry>[];

    for (final section in nutrientSections) {
      final sectionType =
          ((section['type'] as String?) ?? '').toUpperCase();
      final sectionEmoji = (section['emoji'] as String?) ?? '🎬';
      final foods = (section['foods'] as List<dynamic>?) ?? [];
      final sectionVideoUrl = (section['video_url'] as String?) ?? '';
      final sectionVideoTitle = (section['video_title'] as String?) ?? '';

      // ── Section-level video ───────────────────────────────────────────
      entries.add(_VideoEntry(
        emoji: sectionEmoji,
        typeLabel: sectionType,
        title: sectionVideoTitle.isNotEmpty
            ? sectionVideoTitle
            : (sectionType.isNotEmpty
                ? '$sectionType — Nutrition Guide'
                : 'Nutrition Video'),
        subtitle: 'Overview of $sectionType foods in pregnancy',
        videoUrl: sectionVideoUrl,
        foodName: '',
        foodImageUrl: '',
        foodNameAm: '',
      ));

      // ── One card per food item ────────────────────────────────────────
      for (final food in foods) {
        if (food is! Map) continue;
        final foodMap = food as Map<String, dynamic>;
        final foodName = (foodMap['name'] as String?) ?? '';
        if (foodName.isEmpty) continue;

        final foodVideoUrl =
            (foodMap['video_url'] as String?) ?? sectionVideoUrl;
        final foodImageUrl = (foodMap['image_url'] as String?) ?? '';
        final benefit = (foodMap['benefit'] as String?) ?? '';
        final nameAm = (foodMap['name_am'] as String?) ?? '';

        entries.add(_VideoEntry(
          emoji: sectionEmoji,
          typeLabel: sectionType,
          title: '$foodName${nameAm.isNotEmpty ? ' — $nameAm' : ''}',
          subtitle: benefit.isNotEmpty ? benefit : '$foodName in pregnancy',
          videoUrl: foodVideoUrl,
          foodName: foodName,
          foodImageUrl: foodImageUrl,
          foodNameAm: nameAm,
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
                  'Watch videos to learn more about each food and nutrient.',
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

// ─── Data class ───────────────────────────────────────────────────────────────

class _VideoEntry {
  final String emoji;
  final String typeLabel;
  final String title;
  final String subtitle;
  final String videoUrl;
  final String foodName;
  final String foodImageUrl;
  final String foodNameAm;

  const _VideoEntry({
    required this.emoji,
    required this.typeLabel,
    required this.title,
    required this.subtitle,
    required this.videoUrl,
    required this.foodName,
    required this.foodImageUrl,
    required this.foodNameAm,
  });
}

// ─── Single white video card ──────────────────────────────────────────────────

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Thumbnail / play area ─────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Stack(
              children: [
                // Background: food image or tinted placeholder
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
                // Dark gradient overlay
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
                      child: Icon(
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
                // Food emoji circle
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
