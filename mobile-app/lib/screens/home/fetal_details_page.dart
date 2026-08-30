import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/content_service.dart';
import 'package:pregnancy_appp/services/mother_service.dart';

class FetalDetailsPage extends StatefulWidget {
  const FetalDetailsPage({super.key});

  @override
  State<FetalDetailsPage> createState() => _FetalDetailsPageState();
}

class _FetalDetailsPageState extends State<FetalDetailsPage> {
  Map<String, dynamic>? _data;
  int? _week;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    int week = 12;
    try {
      final progress = await MotherService.getGestationalWeek();
      week = (progress['currentWeek'] as num?)?.toInt() ?? 12;
      final data = await ContentService.getFetalByWeek(week);
      if (!mounted) return;
      setState(() {
        _week = week;
        _data = data;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 404) {
        // No content for this week yet: show the friendly empty state.
        setState(() {
          _week = week;
          _data = {};
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          _week != null ? 'Week $_week Development' : 'Fetal Details',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final data = _data!;
    final sizeComparison = (data['size_comparison'] as String?)?.trim() ?? '';
    final milestone = (data['milestone'] as String?)?.trim() ?? '';
    final tips = (data['tips'] as String?)?.trim() ?? '';
    final imageUrl = (data['image_url'] as String?) ?? '';

    if (sizeComparison.isEmpty && milestone.isEmpty && tips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.child_care_rounded, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No details available for this week yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.network(
                imageUrl,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _imageFallback(),
              ),
            )
          else
            _imageFallback(),
          if (sizeComparison.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.compare_rounded, color: AppColors.primary, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Baby\'s size',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sizeComparison,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (milestone.isNotEmpty) ...[
            const SizedBox(height: 20),
            _detailCard(
              title: 'Week $_week Development',
              icon: Icons.child_care_rounded,
              body: milestone,
            ),
          ],
          if (tips.isNotEmpty) ...[
            const SizedBox(height: 20),
            _detailCard(
              title: 'Parent Tip',
              icon: Icons.lightbulb_outline_rounded,
              body: tips,
            ),
          ],
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Center(
        child: Icon(Icons.child_care_rounded, size: 80, color: AppColors.primary),
      ),
    );
  }

  Widget _detailCard({
    required String title,
    required IconData icon,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
          ),
        ],
      ),
    );
  }
}