import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';

class WellnessTypeFilterRow extends StatelessWidget {
  final String currentType;
  final String firstKey;
  final String firstLabel;
  final String firstIcon;
  final String secondKey;
  final String secondLabel;
  final String secondIcon;
  final ValueChanged<String> onChanged;

  const WellnessTypeFilterRow({
    super.key,
    required this.currentType,
    required this.firstKey,
    required this.firstLabel,
    required this.firstIcon,
    required this.secondKey,
    required this.secondLabel,
    required this.secondIcon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterTab(
              icon: firstIcon,
              label: firstLabel,
              isSelected: currentType == firstKey,
              activeColor: AppColors.primary,
              onTap: () => onChanged(firstKey),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _FilterTab(
              icon: secondIcon,
              label: secondLabel,
              isSelected: currentType == secondKey,
              activeColor: const Color(0xFFD32F2F),
              onTap: () => onChanged(secondKey),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String icon;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _FilterTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
