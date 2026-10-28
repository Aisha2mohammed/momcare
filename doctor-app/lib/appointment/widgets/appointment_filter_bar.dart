import 'package:flutter/material.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:intl/intl.dart';

class AppointmentFilterBar extends StatelessWidget {
  final int selectedTab; // 0: Pending, 1: Upcoming, 2: Completed, 3: Cancelled
  final ValueChanged<int> onTabSelected;
  final Map<int, int> tabCounts;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateSelected;
  final VoidCallback onPickCustomDate;
  final Set<String> appointmentDates; // Format: 'yyyy-MM-dd'

  const AppointmentFilterBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    required this.tabCounts,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onPickCustomDate,
    required this.appointmentDates,
  });

  static const List<String> tabTitles = [
    'Pending Requests',
    'Upcoming',
    'Completed',
    'Cancelled / Rejected',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Status Tabs Bar (Horizontal scrollable)
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: tabTitles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isSelected = selectedTab == index;
              final count = tabCounts[index] ?? 0;

              return InkWell(
                onTap: () => onTabSelected(index),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey.shade300,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Text(
                        tabTitles[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // 2. Interactive Calendar Date Strip
        Container(
          height: 74,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // "All Dates" Pill
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 6),
                child: InkWell(
                  onTap: () => onDateSelected(null),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 58,
                    height: 64,
                    decoration: BoxDecoration(
                      color: selectedDate == null ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selectedDate == null ? AppColors.primary : Colors.grey.shade300,
                      ),
                      boxShadow: selectedDate == null
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.date_range_rounded,
                          size: 18,
                          color: selectedDate == null ? Colors.white : AppColors.primary,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'All',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: selectedDate == null ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Horizontal Calendar Days (from -3 days to +10 days)
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: 14,
                  itemBuilder: (context, index) {
                    final day = DateTime.now().subtract(const Duration(days: 3)).add(Duration(days: index));
                    final isSelected = selectedDate != null && DateUtils.isSameDay(selectedDate!, day);
                    final isToday = DateUtils.isSameDay(DateTime.now(), day);
                    final dateKey = DateFormat('yyyy-MM-dd').format(day);
                    final hasAppointments = appointmentDates.contains(dateKey);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => onDateSelected(day),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 52,
                          height: 64,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : (isToday ? AppColors.primaryLight.withValues(alpha: 0.3) : Colors.white),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isToday ? AppColors.primary : Colors.grey.shade300),
                              width: isToday ? 1.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('E').format(day).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : (isToday ? AppColors.primary : AppColors.textSecondary),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${day.day}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : (isToday ? AppColors.primary : AppColors.textPrimary),
                                ),
                              ),
                              const SizedBox(height: 3),
                              // Dot indicator for scheduled appointments
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: hasAppointments
                                      ? (isSelected ? Colors.white : AppColors.riskHigh)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Calendar Picker Button
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 16),
                child: InkWell(
                  onTap: onPickCustomDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 44,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
