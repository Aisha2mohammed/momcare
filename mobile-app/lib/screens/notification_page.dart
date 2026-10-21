import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/screens/emergency/emergency_page.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/notification_service.dart';

class _TypeConfig {
  final String label;
  final Color color;
  final Color bgLight;
  final IconData icon;

  const _TypeConfig({
    required this.label,
    required this.color,
    required this.bgLight,
    required this.icon,
  });
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final List<Map<String, dynamic>> _notifications = [];
  final Set<String> _readingIds = {};
  final Set<String> _unreadIds = {};

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
    try {
      final notifications = await NotificationService.getMyNotifications();
      if (!mounted) return;

      final notifList = notifications.map((n) => n as Map<String, dynamic>).toList();
      final unread = <String>{};
      for (final n in notifList) {
        final id = (n['id'] ?? '').toString();
        final isRead = n['is_read'] == true || n['is_read'] == 'true' || n['is_read'] == 1;
        if (!isRead && id.isNotEmpty) {
          unread.add(id);
        }
      }

      setState(() {
        _notifications
          ..clear()
          ..addAll(notifList);
        _unreadIds
          ..clear()
          ..addAll(unread);
      });

      // Synchronize and mark read on backend so the red count number in top navbar disappears
      try {
        await NotificationService.markAllRead();
      } catch (_) {
        NotificationService.unreadCount.value = 0;
      }
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

  Future<void> _markRead(Map<String, dynamic> notification) async {
    final id = (notification['id'] ?? '').toString();
    if (id.isEmpty) return;
    if (_readingIds.contains(id)) return;

    // Immediately remove the red dot indicator when viewed inside it
    setState(() {
      notification['is_read'] = true;
      _unreadIds.remove(id);
      _readingIds.add(id);
    });

    try {
      await NotificationService.markRead(id);
    } catch (_) {
      // Non-critical; local state is preserved
    } finally {
      if (mounted) setState(() => _readingIds.remove(id));
    }
  }

  Future<void> _markAllAsRead() async {
    if (_unreadIds.isEmpty && !_notifications.any((n) => n['is_read'] != true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications are already marked as read.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _unreadIds.clear();
      for (final n in _notifications) {
        n['is_read'] = true;
      }
    });

    try {
      await NotificationService.markAllRead();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      // Non-critical
    }
  }

  String _timeAgo(String? iso) {
    final dt = DateTime.tryParse(iso ?? '');
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(dt);
  }

  String _formattedDateTime(String? iso) {
    final dt = DateTime.tryParse(iso ?? '');
    if (dt == null) return '';
    return DateFormat('EEEE, MMM d, yyyy • h:mm a').format(dt);
  }

  _TypeConfig _getTypeConfig(String? rawType) {
    final type = (rawType ?? '').toLowerCase().trim();
    if (type.contains('alert') || type.contains('warning') || type.contains('emergency')) {
      return _TypeConfig(
        label: 'Alert',
        color: const Color(0xFFDC2626),
        bgLight: const Color(0xFFFEE2E2),
        icon: Icons.warning_amber_rounded,
      );
    }
    if (type.contains('tip') || type.contains('wellness') || type.contains('nutrition')) {
      return _TypeConfig(
        label: 'Tip',
        color: const Color(0xFF2563EB),
        bgLight: const Color(0xFFDBEAFE),
        icon: Icons.lightbulb_outline_rounded,
      );
    }
    return _TypeConfig(
      label: 'Reminder',
      color: AppColors.primary,
      bgLight: AppColors.primary.withValues(alpha: 0.12),
      icon: Icons.event_note_rounded,
    );
  }

  void _showNotificationModal(BuildContext context, Map<String, dynamic> notification) {
    // Automatically mark notification as read when opened
    _markRead(notification);

    final title = (notification['title'] ?? notification['title_en'] ?? notification['title_am'] ?? 'Notification').toString().trim();
    final body = (notification['body'] ?? notification['body_en'] ?? notification['body_am'] ?? '').toString().trim();
    final rawDate = (notification['sent_at'] ?? notification['created_at']) as String?;
    final dateFormatted = _formattedDateTime(rawDate);
    final relativeTime = _timeAgo(rawDate);

    final rawType = (notification['type'] ?? notification['data']?['type'])?.toString();
    final typeConfig = _getTypeConfig(rawType);

    final trimester = notification['trimester'] ?? notification['data']?['trimester'];
    final week = notification['week'] ?? notification['data']?['week'];
    final month = notification['month'] ?? notification['data']?['month'];

    final isEmergency = typeConfig.label == 'Alert' || notification['data']?['screen'] == 'emergency';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),

                // Modal Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: typeConfig.bgLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(typeConfig.icon, size: 16, color: typeConfig.color),
                            const SizedBox(width: 6),
                            Text(
                              typeConfig.label.toUpperCase(),
                              style: TextStyle(
                                color: typeConfig.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (relativeTime.isNotEmpty)
                        Text(
                          relativeTime,
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      const SizedBox(width: 6),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded, color: Colors.grey),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Modal Content Body (Scrollable)
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Targeting Tags (Trimester, Week, Month)
                        if (trimester != null || week != null || month != null) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (trimester != null && trimester.toString().isNotEmpty)
                                _buildMetadataChip(
                                  icon: Icons.calendar_today_rounded,
                                  label: 'Trimester $trimester',
                                  color: AppColors.primary,
                                ),
                              if (week != null && week.toString().isNotEmpty)
                                _buildMetadataChip(
                                  icon: Icons.child_care_rounded,
                                  label: 'Week $week',
                                  color: const Color(0xFF0D9488),
                                ),
                              if (month != null && month.toString().isNotEmpty)
                                _buildMetadataChip(
                                  icon: Icons.access_time_rounded,
                                  label: 'Month $month',
                                  color: const Color(0xFFD97706),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Title
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                            height: 1.3,
                          ),
                        ),

                        if (dateFormatted.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded, size: 14, color: Colors.grey[400]),
                              const SizedBox(width: 6),
                              Text(
                                dateFormatted,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Message Body Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            body.isNotEmpty ? body : 'No additional details provided.',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF334155),
                              height: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Action button if Emergency / Alert
                        if (isEmergency)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.pop(modalContext);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EmergencyPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.emergency_rounded),
                              label: const Text('Open Emergency Assistance'),
                            ),
                          ),

                        // Dismiss button
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => Navigator.pop(modalContext),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetadataChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              tooltip: 'Mark all as read',
              icon: const Icon(Icons.done_all_rounded, color: AppColors.primary),
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("Retry"),
            ),
          ],
        ),
      );
    }
    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text("No notifications yet.", style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 4),
            Text(
              "Updates from your care team will appear here.",
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationItem(_notifications[index]);
        },
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final id = (notification['id'] ?? '').toString();
    final isRead = !_unreadIds.contains(id) &&
        (notification['is_read'] == true || notification['is_read'] == 'true' || notification['is_read'] == 1);
    final title = (notification['title'] ?? notification['title_en'] ?? notification['title_am'] ?? '').toString().trim();
    final body = (notification['body'] ?? notification['body_en'] ?? notification['body_am'] ?? '').toString().trim();
    final time = _timeAgo(
      (notification['sent_at'] as String?) ?? notification['created_at'] as String?,
    );

    final rawType = (notification['type'] ?? notification['data']?['type'])?.toString();
    final typeConfig = _getTypeConfig(rawType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isRead
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
        border: Border.all(
          color: isRead ? Colors.grey[200]! : AppColors.primary.withValues(alpha: 0.15),
          width: isRead ? 1 : 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showNotificationModal(context, notification),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Icon with subtle tint
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isRead
                        ? Colors.grey[200]
                        : typeConfig.bgLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    typeConfig.icon,
                    color: isRead ? Colors.grey[600] : typeConfig.color,
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
                              title.isNotEmpty ? title : 'Notification',
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                fontSize: 15,
                                color: isRead ? Colors.grey[800] : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: TextStyle(
                              color: isRead ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      if (body.isNotEmpty)
                        Text(
                          body,
                          style: TextStyle(
                            color: isRead ? Colors.grey[600] : Colors.grey[700],
                            fontSize: 13.5,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                // Unread indicator dot
                if (!isRead)
                  Container(
                    margin: const EdgeInsets.only(left: 10, top: 4),
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x66EF4444),
                          blurRadius: 4,
                          offset: Offset(0, 1),
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
}