import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/content_service.dart';
import 'package:pregnancy_appp/services/mother_service.dart';
import 'package:provider/provider.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';

class FetalDetailsPage extends StatefulWidget {
  const FetalDetailsPage({super.key});

  @override
  State<FetalDetailsPage> createState() => _FetalDetailsPageState();
}

class _FetalDetailsPageState extends State<FetalDetailsPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _data;
  int? _week;
  bool _loading = true;
  String? _error;
  late TabController _sectionTab;

  static const _sections = ['Overview', 'Development', 'Mom', 'Checklist'];

  @override
  void initState() {
    super.initState();
    _sectionTab = TabController(length: _sections.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _sectionTab.dispose();
    super.dispose();
  }

  // ── Data Loading ────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    int week = 12;
    try {
      final progress = await MotherService.getGestationalWeek();
      week = (progress['currentWeek'] as num?)?.toInt() ?? 12;
      final data = await ContentService.getFetalByWeek(week);
      if (!mounted) return;
      setState(() { _week = week; _data = data; });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 404) {
        setState(() { _week = week; _data = {}; });
      } else {
        setState(() => _error = e.message);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _lang() {
    try {
      final code = Localizations.localeOf(context).languageCode;
      // backend uses 'om' for Oromo (not 'or')
      if (['en', 'am', 'om', 'so'].contains(code)) return code;
    } catch (_) {}
    return 'en';
  }

  String _pick(Map<String, dynamic> d, String key, {String fallbackKey = ''}) {
    final v = d[key];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    if (fallbackKey.isNotEmpty) {
      final v2 = d[fallbackKey];
      if (v2 is String && v2.trim().isNotEmpty) return v2.trim();
    }
    return '';
  }

  String _loc(Map<String, dynamic> d, String field) {
    final lang = _lang();
    
    // First, check if the backend already localized it into the base field
    if (d[field] is String && (d[field] as String).trim().isNotEmpty) {
      return (d[field] as String).trim();
    }
    
    // Otherwise, try to extract from raw fields
    for (final l in [lang, 'en', 'am', 'om', 'so']) {
      for (final k in ['${field}_$l', '$field${l[0].toUpperCase()}${l.substring(1)}']) {
        final v = d[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    }
    return '';
  }

  String _formatWeight(dynamic g) {
    if (g == null) return '';
    final grams = double.tryParse(g.toString()) ?? 0;
    if (grams <= 0) return '';
    if (grams < 1000) return '${grams.toStringAsFixed(0)}g';
    return '${(grams / 1000).toStringAsFixed(2)}kg';
  }

  String _formatLength(dynamic cm) {
    if (cm == null) return '';
    final val = double.tryParse(cm.toString()) ?? 0;
    if (val <= 0) return '';
    return '${val.toStringAsFixed(1)}cm';
  }

  List<dynamic> _senses() {
    final s = _data?['senses'];
    if (s is List) return s;
    return [];
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F0FC),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _errorView()
              : _buildContent(),
    );
  }

  Widget _errorView() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      );

  Widget _buildContent() {
    final d = _data ?? {};
    final lang = _lang();
    final imageUrl = _pick(d, 'image_url', fallbackKey: 'imageUrl');
    final title = _loc(d, 'title');
    final summary = _loc(d, 'summary');
    final lengthCm = _formatLength(d['baby_length_cm'] ?? d['babyLengthCm']);
    final weightG = _formatWeight(d['baby_weight_g'] ?? d['babyWeightG']);
    final sizeComp = _loc(d, 'size_comparison');
    final milestone = _loc(d, 'milestone');

    if (d.isEmpty) return _emptyState();

    return CustomScrollView(
      slivers: [
        // ── App Bar ─────────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: const Color(0xFF61183e),
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl.isNotEmpty)
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _heroBg(),
                  )
                else
                  _heroBg(),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF61183e).withOpacity(0.92),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 20, right: 20, bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.4)),
                        ),
                        child: Text(
                          'Week $_week',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title.isNotEmpty ? title : 'Week $_week Development',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      if (summary.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: const Color(0xFF61183e), // Primary color
              width: double.infinity,
              child: TabBar(
                controller: _sectionTab,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                indicatorWeight: 3,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: _sections.map((s) => Tab(text: s)).toList(),
              ),
            ),
          ),
        ),

        // ── Stats strip ──────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _StatsStrip(
            lengthCm: lengthCm,
            weightG: weightG,
            sizeComp: sizeComp,
            week: _week ?? 0,
          ),
        ),

        // ── Tabbed body ──────────────────────────────────────────────────────
        SliverFillRemaining(
          child: TabBarView(
            controller: _sectionTab,
            children: [
              _OverviewTab(data: d, lang: lang, milestone: milestone),
              _DevelopmentTab(data: d, lang: lang, senses: _senses()),
              _MomTab(data: d, lang: lang),
              _ChecklistTab(data: d, lang: lang),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroBg() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF61183e), Color(0xFF2D1B69)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Text('👶', style: TextStyle(fontSize: 90)),
        ),
      );

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.child_care_rounded, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No details available for week $_week yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 15),
              ),
            ],
          ),
        ),
      );
}

// ── Stats Strip ──────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final String lengthCm;
  final String weightG;
  final String sizeComp;
  final int week;
  const _StatsStrip({required this.lengthCm, required this.weightG, required this.sizeComp, required this.week});

  @override
  Widget build(BuildContext context) {
    final items = <Map<String, String>>[];
    if (lengthCm.isNotEmpty) items.add({'icon': '📏', 'label': 'Length', 'value': lengthCm});
    if (weightG.isNotEmpty) items.add({'icon': '⚖️', 'label': 'Weight', 'value': weightG});
    if (sizeComp.isNotEmpty) items.add({'icon': '🍐', 'label': 'Size of', 'value': sizeComp});
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      color: const Color(0xFF61183e),
      child: Container(
        margin: const EdgeInsets.only(top: 1),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) => _StatItem(
            icon: item['icon']!,
            label: item['label']!,
            value: item['value']!,
          )).toList(),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String icon, label, value;
  const _StatItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A2E))),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      );
}

// ── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> data;
  final String lang;
  final String milestone;
  const _OverviewTab({required this.data, required this.lang, required this.milestone});

  String _loc(String field) {
    for (final l in [lang, 'en', 'am']) {
      final v = data['${field}_$l'];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final healthTip = _loc('health_tip');
    final emotional = _loc('emotional_message');
    final diary = _loc('diary_prompt');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (milestone.isNotEmpty)
            _InfoCard(
              icon: Icons.stars_rounded,
              color: const Color(0xFF7C3AED),
              title: 'This Week\'s Milestone',
              body: milestone,
            ),
          if (healthTip.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.lightbulb_rounded,
              color: const Color(0xFFF59E0B),
              title: 'Health Tip',
              body: healthTip,
            ),
          ],
          if (emotional.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.favorite_rounded,
              color: const Color(0xFFEC4899),
              title: 'A Message for You 💕',
              body: emotional,
              bgColor: const Color(0xFFFFF0F7),
            ),
          ],
          if (diary.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.edit_note_rounded,
              color: const Color(0xFF0891B2),
              title: 'Diary Prompt',
              body: diary,
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Development Tab ───────────────────────────────────────────────────────────

class _DevelopmentTab extends StatelessWidget {
  final Map<String, dynamic> data;
  final String lang;
  final List<dynamic> senses;
  const _DevelopmentTab({required this.data, required this.lang, required this.senses});

  String _loc(String field) {
    for (final l in [lang, 'en', 'am']) {
      final v = data['${field}_$l'];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final devSections = [
      {'icon': '🧠', 'title': 'Brain Development', 'field': 'brain_dev'},
      {'icon': '❤️', 'title': 'Heart Development', 'field': 'heart_dev'},
      {'icon': '🫀', 'title': 'Organ Development', 'field': 'organ_dev'},
      {'icon': '🦴', 'title': 'Bone & Muscle', 'field': 'bone_muscle_dev'},
      {'icon': '🏃', 'title': 'Movements', 'field': 'movement'},
      {'icon': '🌱', 'title': 'Physical Development', 'field': 'physical_development'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...devSections.where((s) => _loc(s['field']!).isNotEmpty).map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DevCard(
                  emoji: s['icon']!,
                  title: s['title']!,
                  body: _loc(s['field']!),
                ),
              )),
          // Senses
          if (senses.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('👁️', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text('Developing Senses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: senses.map((s) {
                      final label = (s is Map) ? (s['label${lang[0].toUpperCase()}${lang.substring(1)}'] ?? s['labelEn'] ?? s['key'] ?? '') : s.toString();
                      return Chip(
                        label: Text(label.toString(), style: const TextStyle(fontSize: 12)),
                        backgroundColor: const Color(0xFFF3E8FF),
                        labelStyle: const TextStyle(color: Color(0xFF7C3AED)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Mom Tab ────────────────────────────────────────────────────────────────────

class _MomTab extends StatelessWidget {
  final Map<String, dynamic> data;
  final String lang;
  const _MomTab({required this.data, required this.lang});

  String _loc(String field) {
    for (final l in [lang, 'en', 'am']) {
      final v = data['${field}_$l'];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final sections = [
      {'icon': Icons.pregnant_woman_rounded, 'title': 'Maternal Changes', 'field': 'maternal_changes', 'color': 0xFF7C3AED},
      {'icon': Icons.sick_rounded, 'title': 'Common Symptoms', 'field': 'common_symptoms', 'color': 0xFFDB2777},
      {'icon': Icons.local_hospital_rounded, 'title': 'Antenatal Care', 'field': 'antenatal_care', 'color': 0xFF059669},
      {'icon': Icons.biotech_rounded, 'title': 'Screening Info', 'field': 'screening_information', 'color': 0xFF0891B2},
      {'icon': Icons.warning_rounded, 'title': 'Warning Signs', 'field': 'warning_signs', 'color': 0xFFDC2626},
      {'icon': Icons.phone_in_talk_rounded, 'title': 'When to Contact Provider', 'field': 'when_to_contact_provider', 'color': 0xFFF59E0B},
    ];

    final bondTitle = _loc('bonding_activity_title');
    final bondDesc = _loc('bonding_activity_description');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...sections.where((s) => _loc(s['field'] as String).isNotEmpty).map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _InfoCard(
                  icon: s['icon'] as IconData,
                  color: Color(s['color'] as int),
                  title: s['title'] as String,
                  body: _loc(s['field'] as String),
                ),
              )),
          if (bondTitle.isNotEmpty || bondDesc.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFECF5), Color(0xFFF3E8FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDB2777).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🤱', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text(
                        bondTitle.isNotEmpty ? bondTitle : 'Bonding Activity',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  if (bondDesc.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(bondDesc, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5)),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Checklist Tab ──────────────────────────────────────────────────────────────

class _ChecklistTab extends StatefulWidget {
  final Map<String, dynamic> data;
  final String lang;
  const _ChecklistTab({required this.data, required this.lang});

  @override
  State<_ChecklistTab> createState() => _ChecklistTabState();
}

class _ChecklistTabState extends State<_ChecklistTab> {
  final Set<int> _checked = {};

  String _loc(String field) {
    for (final l in [widget.lang, 'en', 'am']) {
      final v = widget.data['${field}_$l'];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  List<String> _checkItems() {
    final antenatal = _loc('antenatal_care');
    final warning = _loc('warning_signs');
    final screening = _loc('screening_information');
    final health = _loc('health_tip');
    return [
      if (antenatal.isNotEmpty) antenatal,
      if (warning.isNotEmpty) warning,
      if (screening.isNotEmpty) screening,
      if (health.isNotEmpty) health,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _checkItems();
    if (items.isEmpty) {
      return const Center(child: Text('No checklist available for this week yet.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF61183e).withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.checklist_rounded, color: Color(0xFF61183e)),
                SizedBox(width: 8),
                Text(
                  'Your Week\'s Checklist',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF61183e)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(items.length, (i) => GestureDetector(
                onTap: () => setState(() {
                  if (_checked.contains(i)) _checked.remove(i); else _checked.add(i);
                }),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _checked.contains(i) ? const Color(0xFFF0FDF4) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _checked.contains(i)
                          ? const Color(0xFF059669).withOpacity(0.5)
                          : Colors.grey.withOpacity(0.15),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: _checked.contains(i) ? const Color(0xFF059669) : Colors.transparent,
                          border: Border.all(
                            color: _checked.contains(i) ? const Color(0xFF059669) : Colors.grey.shade400,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _checked.contains(i)
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          items[i],
                          style: TextStyle(
                            fontSize: 13,
                            color: _checked.contains(i) ? Colors.grey[600] : Colors.grey[800],
                            decoration: _checked.contains(i) ? TextDecoration.lineThrough : null,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Shared Card Widgets ────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final Color? bgColor;
  const _InfoCard({required this.icon, required this.color, required this.title, required this.body, this.bgColor});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor ?? Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
          ],
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(body, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.55)),
          ],
        ),
      );
}

class _DevCard extends StatelessWidget {
  final String emoji, title, body;
  const _DevCard({required this.emoji, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(body, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      );
}