import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/screens/notification_page.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/mother_service.dart';
import 'package:pregnancy_appp/services/notification_service.dart';

class CustomTopNavbar extends StatefulWidget implements PreferredSizeWidget {
  const CustomTopNavbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<CustomTopNavbar> createState() => _CustomTopNavbarState();
}

class _CustomTopNavbarState extends State<CustomTopNavbar> with WidgetsBindingObserver {
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Fetch latest profile and unread notifications count from backend on load
    MotherService.loadInitialProfile();
    NotificationService.fetchUnreadCount();
    // Keep unread count synchronized periodically while app is active
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        NotificationService.fetchUnreadCount();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      MotherService.loadInitialProfile();
      NotificationService.fetchUnreadCount();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ValueListenableBuilder<String?>(
              valueListenable: MotherService.profilePhoto,
              builder: (context, photo, _) {
                final hasPhoto = photo != null && photo.trim().isNotEmpty;
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: hasPhoto ? NetworkImage(ApiService.resolveUrl(photo)) : null,
                    child: hasPhoto
                        ? null
                        : const Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
                  ),
                );
              },
            ),
            ValueListenableBuilder<int>(
              valueListenable: NotificationService.unreadCount,
              builder: (context, unreadCount, _) {
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Notifications',
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationPage()),
                        );
                        // Refresh count when returning from notifications screen
                        NotificationService.fetchUnreadCount();
                      },
                      icon: Icon(
                        unreadCount > 0 ? Icons.notifications_rounded : Icons.notifications_none_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: IgnorePointer(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutBack,
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444), // Vibrant red notification badge
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}