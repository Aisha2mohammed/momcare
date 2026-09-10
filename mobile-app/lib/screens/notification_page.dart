import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final List<Map<String, dynamic>> _notifications = [];
  final Set<String> _readingIds = {};

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
      setState(() {
        _notifications
          ..clear()
          ..addAll(notifications.map((n) => n as Map<String, dynamic>));
      });
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
    final id = notification['id'] as String? ?? '';
    if (id.isEmpty || notification['is_read'] == true) return;
    if (_readingIds.contains(id)) return;

    // Optimistic: reflect read state, then confirm server-side.
    setState(() {
      notification['is_read'] = true;
      _readingIds.add(id);
    });
    try {
      await NotificationService.markRead(id);
    } catch (_) {
      if (!mounted) return;
      // Non-critical; leave local state as-is but notify user.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update read state.')),
      );
    } finally {
      if (mounted) setState(() => _readingIds.remove(id));
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
    return '${dt.day}/${dt.month}/${dt.year}';
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
      child: ListView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          for (final notification in _notifications) _buildNotificationItem(notification),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isRead = notification['is_read'] == true;
    final title = (notification['title'] as String?)?.trim() ?? '';
    final body = (notification['body'] as String?)?.trim() ?? '';
    final time = _timeAgo(
      (notification['sent_at'] as String?) ?? notification['created_at'] as String?,
    );

    return GestureDetector(
      onTap: () => _markRead(notification),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.grey[50] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isRead
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
          border: isRead
              ? null
              : Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                  if (title.isNotEmpty) const SizedBox(height: 6),
                  if (body.isNotEmpty)
                    Text(
                      body,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.3),
                    ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                margin: const EdgeInsets.only(left: 10, top: 4),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}