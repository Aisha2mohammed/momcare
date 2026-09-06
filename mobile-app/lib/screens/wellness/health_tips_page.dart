// import 'package:flutter/material.dart';
// import 'package:pregnancy_appp/constants/color.dart';
// import 'package:pregnancy_appp/services/api_service.dart';
// import 'package:pregnancy_appp/services/content_service.dart';

// class HealthTipsPage extends StatefulWidget {
//   const HealthTipsPage({super.key});

//   @override
//   State<HealthTipsPage> createState() => _HealthTipsPageState();
// }

// class _HealthTipsPageState extends State<HealthTipsPage> {
//   List<dynamic> _tips = [];
//   bool _loading = true;
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   Future<void> _load() async {
//     setState(() {
//       _loading = true;
//       _error = null;
//     });
//     try {
//       final tips = await ContentService.getHealthTips();
//       if (!mounted) return;
//       setState(() => _tips = tips);
//     } on ApiException catch (e) {
//       if (!mounted) return;
//       setState(() => _error = e.message);
//     } catch (_) {
//       if (!mounted) return;
//       setState(() => _error = 'Network error. Please try again.');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FA),
//       appBar: AppBar(
//         title: const Text('Health Tips'),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         foregroundColor: AppColors.textPrimary,
//       ),
//       body: _buildBody(),
//     );
//   }

//   Widget _buildBody() {
//     if (_loading) {
//       return const Center(child: CircularProgressIndicator(color: AppColors.primary));
//     }
//     if (_error != null) {
//       return Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(_error!, style: const TextStyle(color: Colors.red)),
//             const SizedBox(height: 12),
//             OutlinedButton(onPressed: _load, child: const Text('Retry')),
//           ],
//         ),
//       );
//     }
//     if (_tips.isEmpty) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(32),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(Icons.health_and_safety_outlined, size: 64, color: Colors.grey[400]),
//               const SizedBox(height: 16),
//               Text(
//                 'No health tips available yet.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: Colors.grey[600], fontSize: 15),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//     return RefreshIndicator(
//       onRefresh: _load,
//       child: ListView.builder(
//         physics: const AlwaysScrollableScrollPhysics(),
//         padding: const EdgeInsets.all(20),
//         itemCount: _tips.length,
//         itemBuilder: (context, index) => _buildTipCard(_tips[index]),
//       ),
//     );
//   }

//   Widget _buildTipCard(dynamic tip) {
//     final title = (tip['title'] as String?) ?? '';
//     final warningSigns = (tip['warningSigns'] as String?) ?? '';
//     final firstAid = (tip['firstAid'] as String?) ?? '';

//     return Container(
//       margin: const EdgeInsets.only(bottom: 18),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.03),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: AppColors.primary.withValues(alpha: 0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.health_and_safety_rounded, color: AppColors.primary, size: 26),
//               ),
//               const SizedBox(width: 14),
//               Expanded(
//                 child: Text(
//                   title,
//                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//               ),
//             ],
//           ),
//           if (warningSigns.isNotEmpty) ...[
//             const SizedBox(height: 14),
//             _sectionLabel(Icons.warning_amber_rounded, 'Warning signs'),
//             const SizedBox(height: 6),
//             Text(warningSigns, style: TextStyle(color: Colors.grey[700], height: 1.4)),
//           ],
//           if (firstAid.isNotEmpty) ...[
//             const SizedBox(height: 14),
//             _sectionLabel(Icons.medical_services_outlined, 'What to do'),
//             const SizedBox(height: 6),
//             Text(firstAid, style: TextStyle(color: Colors.grey[700], height: 1.4)),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _sectionLabel(IconData icon, String text) {
//     return Row(
//       children: [
//         Icon(icon, color: AppColors.primary, size: 16),
//         const SizedBox(width: 6),
//         Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
//       ],
//     );
//   }
// }