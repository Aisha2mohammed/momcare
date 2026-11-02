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
    _showNotificationDetailModal(notif);
  }

  void _showNotificationDetailModal(DoctorNotification notif) {
    setState(() {
      notif.isRead = true;
    });

    final patient = _findPatient(notif.patientId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: notif.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(notif.icon, color: notif.color, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: notif.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              notif.type == NotificationType.criticalAlert ? 'CRITICAL RISK ALERT' : 'TRIAGE UPDATE',
                              style: TextStyle(color: notif.color, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notif.title,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMMM dd, yyyy · hh:mm a').format(notif.timestamp),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'Alert Details',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  notif.message,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.45),
                ),
                const SizedBox(height: 18),

                // Patient Information Card
                if (patient != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage: patient.imageUrl.isNotEmpty ? NetworkImage(patient.imageUrl) : null,
                          onBackgroundImageError: (_, __) {},
                          child: patient.imageUrl.isEmpty ? Text(patient.name.isNotEmpty ? patient.name[0] : 'P') : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(patient.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(
                                '${patient.gestationalAge} • Risk: ${patient.riskLabel}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Action Buttons
                Row(
                  children: [
                    if (patient != null) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ChatDetailScreen(patient: patient)),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.primary),
                          label: const Text('Chat Now', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            PatientChartDialog.show(context, patient);
                          },
                          icon: const Icon(Icons.insert_chart_outlined_rounded, size: 16, color: Colors.white),
                          label: const Text('View Chart', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(18),
        boxShadow: isUnread
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
        border: Border.all(
          color: isUnread
              ? (isCritical ? AppColors.riskHigh.withValues(alpha: 0.35) : AppColors.primary.withValues(alpha: 0.2))
              : Colors.grey.shade200,
          width: isUnread ? 1.4 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _onNotificationTap(notif),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clean circular icon badge matching mobile-app
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isUnread
                        ? notif.color.withValues(alpha: 0.12)
                        : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notif.icon,
                    color: isUnread ? notif.color : Colors.grey[600],
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                fontSize: 15,
                                color: isUnread ? const Color(0xFF0F172A) : Colors.grey[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: isCritical ? AppColors.riskHigh : AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: isUnread ? Colors.grey[700] : Colors.grey[500],
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
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
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
