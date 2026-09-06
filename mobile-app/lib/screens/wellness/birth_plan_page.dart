// import 'package:flutter/material.dart';
// import 'package:pregnancy_appp/constants/color.dart';

// class BirthPlanPage extends StatefulWidget {
//   const BirthPlanPage({super.key});

//   @override
//   State<BirthPlanPage> createState() => _BirthPlanPageState();
// }

// class _BirthPlanPageState extends State<BirthPlanPage> {
//   final Map<String, bool> _hospitalBagItems = {
//     "Mother's ID and Medical Records": true,
//     "Birth Plan printed copies": false,
//     "Comfortable clothing / Robe": false,
//     "Slippers and socks": true,
//     "Maternity pads & Underwear": false,
//     "Toiletries (Toothbrush, Deodorant)": false,
//     "Baby Clothes (Newborn size)": true,
//     "Baby Diapers & Wipes": false,
//     "Baby blanket": false,
//     "Car seat installed": false,
//   };

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FA),
//       appBar: AppBar(
//         title: const Text("Birth Material List"),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         foregroundColor: AppColors.textPrimary,
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(20),
//         children: [
//           const Text(
//             "Hospital Bag Checklist",
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 10),
//           Text(
//             "Pack your hospital bag a few weeks before your due date.",
//             style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//           ),
//           const SizedBox(height: 20),
//           Container(
//             padding: const EdgeInsets.symmetric(vertical: 10),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(20),
//               boxShadow: [
//                 BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))
//               ],
//             ),
//             child: Column(
//               children: _hospitalBagItems.keys.map((String key) {
//                 return CheckboxListTile(
//                   title: Text(
//                     key,
//                     style: TextStyle(
//                       decoration: _hospitalBagItems[key]! ? TextDecoration.lineThrough : null,
//                       color: _hospitalBagItems[key]! ? Colors.grey : Colors.black87,
//                     ),
//                   ),
//                   value: _hospitalBagItems[key],
//                   activeColor: AppColors.primary,
//                   onChanged: (bool? value) {
//                     setState(() {
//                       _hospitalBagItems[key] = value ?? false;
//                     });
//                   },
//                 );
//               }).toList(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
