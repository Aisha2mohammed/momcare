import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/model/mock_data.dart';
import 'package:doctor_app/notification/notification_model.dart';
import 'package:doctor_app/chat/chat_detail_screen.dart';
import 'package:doctor_app/widget/patient_chart_dialog.dart';

enum NotificationTabFilter { all, critical, appointments, unread }

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  NotificationTabFilter _selectedTab = NotificationTabFilter.all;

  List<DoctorNotification> get _filteredNotifications {
    final list = NotificationRepository.notifications;
    switch (_selectedTab) {
      case NotificationTabFilter.all:
        return list;
      case NotificationTabFilter.critical:
        return list.where((n) => n.type == NotificationType.criticalAlert).toList();
      case NotificationTabFilter.appointments:
        return list.where((n) => n.type == NotificationType.appointment).toList();
      case NotificationTabFilter.unread:
        return list.where((n) => !n.isRead).toList();
    }
  }

  int _countFor(NotificationTabFilter tab) {
    final list = NotificationRepository.notifications;
    switch (tab) {
      case NotificationTabFilter.all:
        return list.length;
      case NotificationTabFilter.critical:
        return list.where((n) => n.type == NotificationType.criticalAlert).length;
      case NotificationTabFilter.appointments:
        return list.where((n) => n.type == NotificationType.appointment).length;
      case NotificationTabFilter.unread:
        return list.where((n) => !n.isRead).length;
    }
  }

  void _markAllAsRead() {
    setState(() {
      NotificationRepository.markAllAsRead();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Notifications?'),
        content: const Text('Are you sure you want to clear all notifications from your alert feed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                NotificationRepository.clearAll();
              });
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes.clamp(1, 60)}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return DateFormat('MMM dd, hh:mm a').format(time);
    }
  }

  PatientModel? _findPatient(String patientId) {
    try {
      return MockData.incomingPatients.firstWhere((p) => p.id == patientId);
    } catch (_) {
      try {
        return MockData.acceptedPatients.firstWhere((p) => p.id == patientId);
      } catch (_) {
        return null;
      }
    }
  }

  void _onNotificationTap(DoctorNotification notif) {
    setState(() {
      notif.isRead = true;
    });

    final patient = _findPatient(notif.patientId);
    if (patient != null) {
      if (notif.type == NotificationType.criticalAlert) {
        PatientChartDialog.show(context, patient);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatDetailScreen(patient: patient)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _filteredNotifications;
    final unreadCount = _countFor(NotificationTabFilter.unread);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            const Text(
              'Alerts & Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.riskHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Mark All as Read',
            icon: const Icon(Icons.done_all_rounded, color: AppColors.primary, size: 22),
            onPressed: _markAllAsRead,
          ),
          IconButton(
            tooltip: 'Clear All',
            icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.textSecondary, size: 22),
            onPressed: _clearAllNotifications,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterTab(
                    tab: NotificationTabFilter.all,
                    label: 'All Alerts',
                    count: _countFor(NotificationTabFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterTab(
                    tab: NotificationTabFilter.critical,
                    label: 'Critical Risk',
                    count: _countFor(NotificationTabFilter.critical),
                    activeColor: AppColors.riskHigh,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterTab(
                    tab: NotificationTabFilter.appointments,
                    label: 'Appointments',
                    count: _countFor(NotificationTabFilter.appointments),
                    activeColor: const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterTab(
                    tab: NotificationTabFilter.unread,
                    label: 'Unread',
                    count: _countFor(NotificationTabFilter.unread),
                  ),
                ],
              ),
            ),
          ),

          // Notifications List
          Expanded(
            child: notifications.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return _buildNotificationCard(notif);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    required NotificationTabFilter tab,
    required String label,
    required int count,
    Color? activeColor,
  }) {
    final isSelected = _selectedTab == tab;
    final effectiveColor = activeColor ?? AppColors.primary;

    return InkWell(
      onTap: () => setState(() => _selectedTab = tab),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? effectiveColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? effectiveColor : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(DoctorNotification notif) {
    final isUnread = !notif.isRead;
    final isCritical = notif.type == NotificationType.criticalAlert;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onNotificationTap(notif),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnread
                ? (isCritical ? AppColors.riskHighBg.withValues(alpha: 0.5) : Colors.white)
                : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? (isCritical ? AppColors.riskHigh.withValues(alpha: 0.4) : AppColors.primary.withValues(alpha: 0.25))
                  : Colors.grey.shade200,
              width: isUnread ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isUnread ? 0.04 : 0.01),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge / Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: notif.color.withValues(alpha: 0.12),
                    backgroundImage: NetworkImage(notif.patientAvatar),
                    onBackgroundImageError: (_, __) {},
                    child: Text(notif.patientName.isNotEmpty ? notif.patientName[0] : 'P'),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: notif.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Icon(notif.icon, size: 10, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Notification Body
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                              color: isCritical ? AppColors.riskHigh : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isCritical ? AppColors.riskHigh : AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notif.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            notif.patientName,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatTime(notif.timestamp),
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'You have no pending alerts or consultation notifications in this filter.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
