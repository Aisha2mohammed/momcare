import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/model/mock_data.dart';
import 'package:doctor_app/chat/chat_detail_screen.dart';

enum ChatFilterTab { all, accepted, rejected, unread }

class ChatListTab extends StatefulWidget {
  const ChatListTab({super.key});

  @override
  State<ChatListTab> createState() => _ChatListTabState();
}

class _ChatListTabState extends State<ChatListTab> {
  ChatFilterTab _currentTab = ChatFilterTab.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Patient> get _allPatientsList {
    final list = <Patient>[...MockData.acceptedPatients];
    for (final r in MockData.rejectedPatients) {
      if (!list.any((p) => p.id == r.id)) {
        list.add(r);
      }
    }
    return list;
  }

  int get _allCount => _allPatientsList.length;
  int get _acceptedCount => _allPatientsList.where((p) => p.isAccepted && !p.isRejected).length;
  int get _rejectedCount => _allPatientsList.where((p) => p.isRejected).length;
  int get _unreadCount => _allPatientsList.where((p) => !p.isRead || p.unreadCount > 0).length;

  List<Patient> get _filteredChats {
    return _allPatientsList.where((patient) {
      // 1. Tab filter
      bool matchesTab = true;
      switch (_currentTab) {
        case ChatFilterTab.all:
          matchesTab = true;
          break;
        case ChatFilterTab.accepted:
          matchesTab = patient.isAccepted && !patient.isRejected;
          break;
        case ChatFilterTab.rejected:
          matchesTab = patient.isRejected;
          break;
        case ChatFilterTab.unread:
          matchesTab = !patient.isRead || patient.unreadCount > 0;
          break;
      }
      if (!matchesTab) return false;

      // 2. Search filter
      if (_searchQuery.isEmpty) return true;
      final nameMatches = patient.name.toLowerCase().contains(_searchQuery);
      final msgMatches = (patient.lastMessage ?? '').toLowerCase().contains(_searchQuery);
      return nameMatches || msgMatches;
    }).toList();
  }

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return AppColors.riskHigh;
      case RiskLevel.moderate:
        return AppColors.riskModerate;
      case RiskLevel.stable:
        return AppColors.riskStable;
    }
  }

  String _formatTimestamp(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes.clamp(1, 60)}m ago';
    } else if (difference.inHours < 24) {
      return DateFormat('hh:mm a').format(time);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd').format(time);
    }
  }

  void _openChat(Patient patient) async {
    // Mark chat as read
    setState(() {
      patient.isRead = true;
      patient.unreadCount = 0;
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(patient: patient),
      ),
    );

    // Refresh state when coming back from chat screen
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final chats = _filteredChats;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header, Search & Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Patient Consultations',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Direct messages & triage follow-ups with admitted patients',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search patient or message content...',
                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 22),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Filter Tabs: All, Accepted, Rejected, Unread
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildTabButton(
                        tab: ChatFilterTab.all,
                        title: 'All Chats',
                        count: _allCount,
                      ),
                      const SizedBox(width: 8),
                      _buildTabButton(
                        tab: ChatFilterTab.accepted,
                        title: 'Accepted',
                        count: _acceptedCount,
                        activeColor: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      _buildTabButton(
                        tab: ChatFilterTab.rejected,
                        title: 'Rejected',
                        count: _rejectedCount,
                        activeColor: Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      _buildTabButton(
                        tab: ChatFilterTab.unread,
                        title: 'Unread',
                        count: _unreadCount,
                        isUnreadTab: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Chat List View
          Expanded(
            child: chats.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: chats.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      indent: 82,
                      endIndent: 16,
                      color: AppColors.divider,
                    ),
                    itemBuilder: (context, index) {
                      final patient = chats[index];
                      final isUnread = !patient.isRead && patient.unreadCount > 0;
                      final riskColor = _getRiskColor(patient.riskLevel);

                      return Material(
                        color: isUnread
                            ? AppColors.primary.withValues(alpha: 0.03)
                            : Colors.white,
                        child: InkWell(
                          onTap: () => _openChat(patient),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                // Avatar with Risk Indicator dot
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor: AppColors.primaryLight,
                                      backgroundImage: NetworkImage(patient.imageUrl),
                                      onBackgroundImageError: (_, __) {},
                                      child: Text(
                                        patient.name.isNotEmpty ? patient.name[0] : 'P',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Tooltip(
                                        message: '${patient.riskLabel} Patient',
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: riskColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),

                                // Patient Name & Last Message
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              patient.name,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: isUnread
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatTimestamp(patient.lastMessageTime),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isUnread
                                                  ? AppColors.primary
                                                  : AppColors.textMuted,
                                              fontWeight: isUnread
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          if (patient.isRejected) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: Colors.red.shade200),
                                              ),
                                              child: Text(
                                                'Declined',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red.shade700,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                          ] else if (patient.isAccepted) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.successBg,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                                              ),
                                              child: const Text(
                                                'Accepted',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.success,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryLight,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              patient.gestationalWeek,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              patient.lastMessage ?? 'No messages yet',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isUnread
                                                    ? AppColors.textPrimary
                                                    : AppColors.textSecondary,
                                                fontWeight: isUnread
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                          if (isUnread) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${patient.unreadCount}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ] else ...[
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.done_all,
                                              size: 16,
                                              color: Colors.blueAccent,
                                            ),
                                          ],
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
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required ChatFilterTab tab,
    required String title,
    required int count,
    Color? activeColor,
    bool isUnreadTab = false,
  }) {
    final isSelected = _currentTab == tab;

    return InkWell(
        onTap: () {
          setState(() {
            _currentTab = tab;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? (activeColor ?? AppColors.primary) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? (activeColor ?? AppColors.primary) : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (isUnreadTab && count > 0
                          ? AppColors.primaryLight
                          : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isUnreadTab && count > 0
                            ? AppColors.primary
                            : AppColors.textPrimary),
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

  Widget _buildEmptyState() {
    IconData icon;
    String title;
    String subtitle;

    switch (_currentTab) {
      case ChatFilterTab.unread:
        icon = Icons.mark_chat_read_outlined;
        title = 'All Caught Up!';
        subtitle = 'There are no unread patient messages at the moment.';
        break;
      case ChatFilterTab.accepted:
        icon = Icons.verified_user_outlined;
        title = 'No Accepted Patient Chats';
        subtitle = 'Patients accepted into your care team will appear here with active channels.';
        break;
      case ChatFilterTab.rejected:
        icon = Icons.cancel_outlined;
        title = 'No Declined Requests';
        subtitle = 'Referrals or consultation requests that were declined will appear here.';
        break;
      case ChatFilterTab.all:
        icon = Icons.chat_outlined;
        title = _searchQuery.isNotEmpty ? 'No Matching Chats' : 'No Active Chats';
        subtitle = _searchQuery.isNotEmpty
            ? 'No patient messages match "$_searchQuery".'
            : 'Accept incoming patients from the Home tab to start conversations.';
        break;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
