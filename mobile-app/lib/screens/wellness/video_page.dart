// import 'package:flutter/material.dart';
// import 'package:pregnancy_appp/constants/color.dart';
// import 'package:pregnancy_appp/l10n/l10n.dart';

// class VideoPage extends StatelessWidget {
//   const VideoPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 3,
//       child: Scaffold(
//         backgroundColor: const Color(0xFFF8F9FA),
//         appBar: AppBar(
//           title: Text(AppStrings.of(context, 'video')),
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           foregroundColor: AppColors.textPrimary,
//           bottom: const TabBar(
//             labelColor: AppColors.primary,
//             unselectedLabelColor: Colors.grey,
//             indicatorColor: AppColors.primary,
//             tabs: [
//               Tab(text: "1st Trimester"),
//               Tab(text: "2nd Trimester"),
//               Tab(text: "3rd Trimester"),
//             ],
//           ),
//         ),
//         body: TabBarView(
//           children: [
//             _buildVideoList(1),
//             _buildVideoList(2),
//             _buildVideoList(3),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildVideoList(int trimester) {
//     List<Widget> items;
//     if (trimester == 1) {
//       items = [
//         _buildVideoItem("Early Pregnancy Tips", "What to expect in the first 12 weeks."),
//         _buildVideoItem("Managing Morning Sickness", "Dietary changes that can help reduce nausea."),
//       ];
//     } else if (trimester == 2) {
//       items = [
//         _buildVideoItem("Anatomy Scan Preparation", "Details about your mid-pregnancy ultrasound."),
//         _buildVideoItem("Baby Movement", "When to expect those first flutters or kicks."),
//       ];
//     } else {
//       items = [
//         _buildVideoItem("Signs of Labor", "How to know when it is time to go to the hospital."),
//         _buildVideoItem("Postpartum Care Basics", "Preparing yourself for the first few weeks after birth."),
//       ];
//     }

//     return ListView(
//       padding: const EdgeInsets.all(20),
//       children: items,
//     );
//   }

//   Widget _buildVideoItem(String title, String description) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 20),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(25),
//         boxShadow: [
//           BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5)),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             height: 150,
//             width: double.infinity,
//             decoration: BoxDecoration(
//               color: AppColors.primary.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(15),
//             ),
//             child: const Center(
//               child: Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 60),
//             ),
//           ),
//           const SizedBox(height: 15),
//           Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//           const SizedBox(height: 5),
//           Text(description, style: TextStyle(color: Colors.grey[700], height: 1.5)),
//         ],
//       ),
//     );
//   }
// }
