import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BirthPlanPage extends StatefulWidget {
  const BirthPlanPage({super.key});

  @override
  State<BirthPlanPage> createState() => _BirthPlanPageState();
}

class _BirthPlanPageState extends State<BirthPlanPage> {
  final Map<String, bool> _hospitalBagItems = {
    'item_mother_id': true,
    'item_printed_plan': false,
    'item_comfortable_clothing': false,
    'item_slippers_socks': true,
    'item_maternity_pads': false,
    'item_toiletries': false,
    'item_baby_clothes': true,
    'item_diapers_wipes': false,
    'item_baby_blanket': false,
    'item_car_seat': false,
  };

  @override
  void initState() {
    super.initState();
    _loadSavedItems();
  }

  Future<void> _loadSavedItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in _hospitalBagItems.keys) {
        final val = prefs.getBool('birth_plan_$key');
        if (val != null) {
          _hospitalBagItems[key] = val;
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _setItem(String key, bool val) async {
    setState(() {
      _hospitalBagItems[key] = val;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('birth_plan_$key', val);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(AppStrings.of(context, 'birth_material_list')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            AppStrings.of(context, 'hospital_bag_checklist'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            AppStrings.of(context, 'hospital_bag_desc'),
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              children: _hospitalBagItems.keys.map((String key) {
                final isChecked = _hospitalBagItems[key] ?? false;
                return CheckboxListTile(
                  title: Text(
                    AppStrings.of(context, key),
                    style: TextStyle(
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                      color: isChecked ? Colors.grey : Colors.black87,
                    ),
                  ),
                  value: isChecked,
                  activeColor: AppColors.primary,
                  onChanged: (bool? value) {
                    _setItem(key, value ?? false);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
