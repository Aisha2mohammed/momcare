import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/screens/home/home.dart';
import 'package:pregnancy_appp/screens/community/community_page.dart';
import 'package:pregnancy_appp/screens/wellness/wellness_page.dart';
import 'package:pregnancy_appp/screens/emergency/emergency_page.dart';
import 'package:pregnancy_appp/screens/profile/profile_page.dart';
// import 'package:pregnancy_appp/screens/chatbot_page.dart';
// import 'package:pregnancy_appp/screens/connect_doctor_page.dart';
import 'package:pregnancy_appp/widget/buttom_navbar.dart';
import 'package:pregnancy_appp/widget/top_navbar.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const CommunityPage(),
    const WellnessPage(),
    const EmergencyPage(),
    const ProfilePage(),
  ];

  // void _showActionMenu(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (context) {
  //       return SafeArea(
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             const SizedBox(height: 8),
  //             Container(
  //               width: 40,
  //               height: 4,
  //               decoration: BoxDecoration(
  //                 color: Colors.grey[300],
  //                 borderRadius: BorderRadius.circular(2),
  //               ),
  //             ),
  //             const SizedBox(height: 16),
  //             const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  //             const SizedBox(height: 16),
  //             ListTile(
  //               leading: Container(
  //                 padding: const EdgeInsets.all(8),
  //                 decoration: BoxDecoration(
  //                   color: AppColors.primary.withOpacity(0.1),
  //                   shape: BoxShape.circle,
  //                 ),
  //                 child: const Icon(Icons.local_hospital, color: AppColors.primary),
  //               ),
  //               title: const Text("Connect Doctor", style: TextStyle(fontWeight: FontWeight.w600)),
  //               subtitle: const Text("Book appointments & find  doctors"),
  //               onTap: () {
  //                 Navigator.pop(context);
  //                 Navigator.push(context, MaterialPageRoute(builder: (context) => const ConnectClinicPage()));
  //               },
  //             ),
  //             ListTile(
  //               leading: Container(
  //                 padding: const EdgeInsets.all(8),
  //                 decoration: BoxDecoration(
  //                   color: AppColors.primary.withOpacity(0.1),
  //                   shape: BoxShape.circle,
  //                 ),
  //                 child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary),
  //               ),
  //               title: const Text("AI Assistant", style: TextStyle(fontWeight: FontWeight.w600)),
  //               subtitle: const Text("Chat with Enat AI Bot"),
  //               onTap: () {
  //                 Navigator.pop(context);
  //                 Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatBotPage()));
  //               },
  //             ),
  //             const SizedBox(height: 24),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: const CustomTopNavbar(),
      body: _pages[_selectedIndex], 
      
      // Floating Action Button with generic + icon
      // floatingActionButton: Padding(
      //   padding: const EdgeInsets.only(bottom: 10),
      //   child: FloatingActionButton(
      //     onPressed: () => _showActionMenu(context),
      //     backgroundColor: AppColors.primary,
      //     child: const Icon(Icons.add, color: Colors.white, size: 28),
      //   ),
      // ),
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
