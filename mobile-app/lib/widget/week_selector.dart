import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';

/// Horizontally scrollable period/week chip row.
///
/// Extracted from `nutrition_guide_page.dart` so the same selector can be
/// reused by the Nutrition, Sleep and Exercise screens.
///
/// `mode` selects which range is offered:
///  - `'week'`    → W1…W40
///  - `'month'`   → M1…M9
///  - otherwise   → 1st / 2nd / 3rd trimester
///
/// `selected` is the chip the user has tapped, `currentWeek` is the
/// woman's real gestational week — they are styled independently so the
/// "you are here" marker stays visible while she browses other periods.
class WeekSelector extends StatelessWidget {
  final String mode;
  final int selected;
  final int currentWeek;
  final int currentTrimester;
  final int currentMonth;
  final ValueChanged<int> onSelected;

  const WeekSelector({
    super.key,
    required this.mode,
    required this.selected,
    required this.currentWeek,
    this.currentTrimester = 0,
    this.currentMonth = 0,
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
