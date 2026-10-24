import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';
import 'package:pregnancy_appp/screens/home/fetal_details_page.dart';
import 'package:pregnancy_appp/services/content_service.dart';

class AmIPregnantCard extends StatefulWidget {
  final int week;
  final int daysRemaining;

  const AmIPregnantCard({
    super.key,
    required this.week,
    required this.daysRemaining,
  });

  @override
  State<AmIPregnantCard> createState() => _AmIPregnantCardState();
}

class _AmIPregnantCardState extends State<AmIPregnantCard> {
  int _week = 12;
  int _daysRemaining = 196;
  String _sizeComparison = "Plum";
  int _heartRate = 160;
  bool _loading = true;
  String? _lastLocale;

  @override
  void initState() {
    super.initState();
    _week = widget.week;
    _daysRemaining = widget.daysRemaining;
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = Localizations.localeOf(context).languageCode;
    if (_lastLocale != null && _lastLocale != currentLocale) {
      _load();
    }
    _lastLocale = currentLocale;
  }

  @override
  void didUpdateWidget(covariant AmIPregnantCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.week != widget.week) {
      _week = widget.week;
      _daysRemaining = widget.daysRemaining;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final lang = mounted ? Localizations.localeOf(context).languageCode : null;
      final data = await ContentService.getFetalByWeek(widget.week, lang: lang);
      if (!mounted) return;

      final heartRate = (data['heartRate'] as num?)?.toInt();
      final sizeRaw = (lang != null && data['size_comparison_$lang'] != null && data['size_comparison_$lang'].toString().isNotEmpty)
          ? data['size_comparison_$lang']
          : (data['size_comparison'] ?? data['size_comparison_en']);

      setState(() {
        if (heartRate != null) _heartRate = heartRate;
        if (sizeRaw != null && sizeRaw.toString().isNotEmpty) {
          _sizeComparison = sizeRaw.toString();
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Image overlay
          Positioned(
            right: 0,
            bottom: 0,
            top: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
              child: Image.asset(
                'assets/images/girl-pregnanacy.png',
                width: 140,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Week badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${AppStrings.of(context, 'week')} $_week",
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                
                Text(
                  AppStrings.of(context, 'your_pregnancy_this_week'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                
                _buildListItem(
                  Icons.child_care_rounded,
                  AppStrings.of(context, 'size_comparison_text', [_sizeComparison]),
                ),
                const SizedBox(height: 10),
                _buildListItem(
                  Icons.favorite_rounded,
                  AppStrings.of(context, 'heart_rate_text', [_heartRate]),
                ),
                const SizedBox(height: 10),
                _buildListItem(
                  Icons.calendar_month_rounded,
                  AppStrings.of(context, 'days_remaining_text', [_daysRemaining]),
                ),
                
                const SizedBox(height: 20),
                
                // View Details Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FetalDetailsPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    elevation: 0,
                  ),
                  child: Text(
                    AppStrings.of(context, 'view_details'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
