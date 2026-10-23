import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/screens/home/home.dart';
import 'package:pregnancy_appp/screens/community/community_page.dart';
import 'package:pregnancy_appp/screens/wellness/wellness_page.dart';
import 'package:pregnancy_appp/screens/emergency/emergency_page.dart';
import 'package:pregnancy_appp/screens/profile/profile_page.dart';
import 'package:pregnancy_appp/screens/chatbot_page.dart';
import 'package:pregnancy_appp/screens/connect_doctor_page.dart';
import 'package:pregnancy_appp/widget/buttom_navbar.dart';
import 'package:pregnancy_appp/widget/top_navbar.dart';
import 'package:pregnancy_appp/services/push_service.dart';

class MainScreen extends StatefulWidget {
  final bool showWelcomeNotification;
  const MainScreen({super.key, this.showWelcomeNotification = false});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.showWelcomeNotification) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerWelcome();
      });
    }
  }

  Future<void> _triggerWelcome() async {
    // 1. Trigger OS heads-up push notification
    await PushService.showWelcomeNotification();

    // 2. Display in-app beautiful floating greeting
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF61183E),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to MomCare! 🌸',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Your trusted companion for pregnancy and motherhood.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  final List<Widget> _pages = [
    const HomePage(),
    const CommunityPage(),
    const WellnessPage(),
    const EmergencyPage(),
    const ProfilePage(),
  ];

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_hospital, color: AppColors.primary),
                ),
                title: const Text("Connect Doctor", style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Book appointments & find  doctors"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ConnectClinicPage()));
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary),
                ),
                title: const Text("AI Assistant", style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Chat with Enat AI Bot"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatBotPage()));
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: const CustomTopNavbar(),
      body: _pages[_selectedIndex], 
      
      // Floating Action Button: hidden on Community page so Community's + Post FAB can show cleanly
      floatingActionButton: _selectedIndex == 1
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton(
                onPressed: () => _showActionMenu(context),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
