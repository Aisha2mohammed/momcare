import 'package:flutter/material.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/home/home_tab.dart';
import 'package:doctor_app/chat/chat_list_tab.dart';
import 'package:doctor_app/appointment/appointment_tab.dart';
import 'package:doctor_app/profile/profile_tab.dart';
import 'package:doctor_app/model/mock_data.dart';
import 'package:doctor_app/model/doctor_profile_model.dart';
import 'package:doctor_app/auth/auth_service.dart';
import 'package:doctor_app/notification/notification_screen.dart';
import 'package:doctor_app/notification/notification_model.dart';
import 'package:doctor_app/l10n/l10n.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    DoctorProfileModel.shared.addListener(_onProfileUpdated);
    LocaleNotifier.shared.addListener(_onProfileUpdated);
    _loadDoctorProfile();
  }

  @override
  void dispose() {
    DoctorProfileModel.shared.removeListener(_onProfileUpdated);
    LocaleNotifier.shared.removeListener(_onProfileUpdated);
    super.dispose();
  }

  void _onProfileUpdated() {
    if (mounted) setState(() {});
  }

  Future<void> _loadDoctorProfile() async {
    try {
      final user = await AuthService.instance.getCurrentUser();
      final userId = user['id'] ?? user['userId'];
      if (userId != null && userId.isNotEmpty) {
        await AuthService.instance.getDoctorProfile(userId);
      }
      if (user['status'] != null) {
        final status = user['status']!.toLowerCase();
        DoctorProfileModel.shared.isVerified = status == 'approved' || status == 'active';
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  int get _unreadChatCount {
    return MockData.acceptedPatients.where((p) => !p.isRead || p.unreadCount > 0).length;
  }

  int get _incomingQueueCount {
    return MockData.incomingPatients.length;
  }

  @override
  Widget build(BuildContext context) {
    final unreadChats = _unreadChatCount;
    final incomingQueue = _incomingQueueCount;
    final unreadNotifs = NotificationRepository.unreadCount;
    final doc = DoctorProfileModel.shared;

    final List<Widget> tabs = [
      const HomeTab(),
      const ChatListTab(),
      const AppointmentTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 16,
        title: InkWell(
          onTap: () => setState(() => _currentIndex = 3),
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                backgroundImage: doc.avatarUrl.isNotEmpty ? NetworkImage(doc.avatarUrl) : null,
                onBackgroundImageError: (_, __) {},
                backgroundColor: AppColors.primaryLight,
                radius: 20,
                child: doc.avatarUrl.isEmpty
                    ? const Icon(Icons.person, color: AppColors.primary, size: 22)
                    : null,
              ),
              Positioned(
                bottom: -1,
                right: -1,
                child: Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    doc.isVerified ? Icons.check_circle_rounded : Icons.schedule_rounded,
                    size: 11,
                    color: doc.isVerified ? AppColors.success : Colors.amber.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Alerts & Notifications',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 26),
                if (unreadNotifs > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.riskHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unreadNotifs',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
              setState(() {});
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: [
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.home_outlined),
                if (incomingQueue > 0)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.riskHigh,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: const Icon(Icons.home),
            label: LocaleNotifier.shared.t('home'),
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_outlined),
                if (unreadChats > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$unreadChats',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: const Icon(Icons.chat),
            label: LocaleNotifier.shared.t('consultations'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today_outlined),
            activeIcon: const Icon(Icons.calendar_today),
            label: LocaleNotifier.shared.t('appointments'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: LocaleNotifier.shared.t('profile'),
          ),
        ],
      ),
    );
  }
}
