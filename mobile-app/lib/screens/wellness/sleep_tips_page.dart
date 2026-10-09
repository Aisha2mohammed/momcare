import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/content_service.dart';
import 'package:pregnancy_appp/services/mother_service.dart';
import 'package:pregnancy_appp/widget/week_selector.dart';

class SleepTipsPage extends StatefulWidget {
  const SleepTipsPage({super.key});

  @override
  State<SleepTipsPage> createState() => _SleepTipsPageState();
}

class _SleepTipsPageState extends State<SleepTipsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // 0 = not loaded yet → no week filter is applied.
  int _currentWeek = 0;
  int _selectedWeek = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectCurrentTrimester();
    _loadWeek();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWeek() async {
    try {
      final data = await MotherService.getGestationalWeek();
      final week = (data['currentWeek'] as int?) ?? 0;
      if (!mounted || week <= 0) return;
      setState(() {
        _currentWeek = week;
        _selectedWeek = week;
      });
    } catch (_) {
      // Keep 0 → the week selector still renders, the current-week chip is
      // simply not highlighted and no week filter is applied.
    }
  }

  Future<void> _selectCurrentTrimester() async {
    final trimester = await ContentService.currentTrimester();
    if (!mounted || _tabController.index == trimester - 1) return;
    setState(() => _tabController.index = trimester - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(AppStrings.of(context, 'sleeping')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: "1st Trimester"),
            Tab(text: "2nd Trimester"),
            Tab(text: "3rd Trimester"),
          ],
        ),
      ),
      body: Column(
        children: [
          WeekSelector(
            mode: 'week',
            selected: _selectedWeek,
            currentWeek: _currentWeek,
            onSelected: (v) => setState(() => _selectedWeek = v),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SleepTipsList(trimester: 1, selectedWeek: _selectedWeek),
                _SleepTipsList(trimester: 2, selectedWeek: _selectedWeek),
                _SleepTipsList(trimester: 3, selectedWeek: _selectedWeek),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepTipsList extends StatefulWidget {
  final int trimester;
  final int selectedWeek;

  const _SleepTipsList({required this.trimester, required this.selectedWeek});

  @override
  State<_SleepTipsList> createState() => _SleepTipsListState();
}

class _SleepTipsListState extends State<_SleepTipsList> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _SleepTipsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedWeek != widget.selectedWeek) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final week = widget.selectedWeek > 0 ? widget.selectedWeek : null;
      final fetched = await ContentService.getSleepTips(widget.trimester, week: week);
      if (!mounted) return;

      // Client-side week filter. `sleep_tips.week` is currently NULL for every
      // row, so this usually finds nothing — in that case keep the whole
      // trimester list rather than showing an empty screen.
      List<dynamic> items = fetched;
      if (week != null) {
        final matches = fetched.where((it) {
          final w = it['week'];
          return w != null &&
              (w == week || w.toString() == week.toString());
        }).toList();
        if (matches.isNotEmpty) items = matches;
      }

      setState(() => _items = items);
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
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
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
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bedtime_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No sleep tips available yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _items.length,
      itemBuilder: (context, index) => _buildTipCard(_items[index]),
    );
  }

  Widget _buildTipCard(dynamic item) {
    final title = (item['title'] as String?) ?? '';
    final description = (item['description'] as String?) ?? '';
    final illustrationUrl = (item['illustration_url'] as String?) ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bedtime_rounded, color: AppColors.primary, size: 30),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(description, style: TextStyle(color: Colors.grey[700], height: 1.4)),
          ],
          if (illustrationUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                illustrationUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}