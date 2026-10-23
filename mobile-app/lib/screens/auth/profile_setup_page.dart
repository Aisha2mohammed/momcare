import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/screens/home/mainscreen.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/mother_service.dart';
import 'package:pregnancy_appp/widget/status_modal.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  DateTime? _lmpDate;
  DateTime? _dueDate;
  int? _calculatedWeek;
  int? _calculatedTrimester;
  int? _daysRemaining;

  String _selectedLanguage = 'en';
  bool _isLoading = false;

  /// Display name -> code backend stores in `users.language`.
  static const Map<String, String> _languageCodes = {
    'English': 'en',
    'Amharic': 'am',
    'Afan Oromo': 'or',
    'Somali': 'so',
  };
  final List<String> _languages = ['English', 'Amharic', 'Afan Oromo', 'Somali'];

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  /// Pre-fills anything already on the profile.
  Future<void> _prefill() async {
    try {
      final data = await MotherService.getProfile();
      if (!mounted) return;
      final user = data['user'];
      if (user is Map<String, dynamic>) {
        _nameController.text = (user['name'] as String?) ?? '';
        final code = user['language'] as String?;
        if (code != null && _languageCodes.containsValue(code)) {
          setState(() {
            _selectedLanguage = code;
          });
        }
      }
      final profile = data['profile'];
      if (profile is Map<String, dynamic>) {
        _cityController.text = (profile['city'] as String?) ?? '';
        final lmpStr = profile['lmp_date']?.toString();
        if (lmpStr != null && lmpStr.isNotEmpty) {
          try {
            final parsedLmp = DateTime.parse(lmpStr);
            _calculateDueDate(parsedLmp);
          } catch (_) {}
        }
      }
    } catch (_) {
      // Start from a blank form if not yet created
    }
  }

  void _calculateDueDate(DateTime lmp) {
    final now = DateTime.now();
    final daysSinceLmp = now.difference(lmp).inDays;
    final rawWeek = (daysSinceLmp / 7).floor() + 1;
    final clampedWeek = rawWeek.clamp(1, 42);
    final trimester = clampedWeek <= 13 ? 1 : (clampedWeek <= 26 ? 2 : 3);
    final dueDate = lmp.add(const Duration(days: 280));
    final daysLeft = dueDate.difference(now).inDays.clamp(0, 280);

    setState(() {
      _lmpDate = lmp;
      _dueDate = dueDate;
      _calculatedWeek = clampedWeek;
      _calculatedTrimester = trimester;
      _daysRemaining = daysLeft;
    });
  }

  Future<void> _saveProfile() async {
    if (_lmpDate == null) {
      AppStatusModal.showError(
        context: context,
        title: 'LMP Date Required',
        message: 'Please select your Last Menstrual Period (LMP) date so MomCare can calculate and display your pregnancy week accurately.',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await MotherService.updateProfile(
        name: _nameController.text.trim(),
        language: _selectedLanguage,
        lmpDate: _lmpDate!.toIso8601String().split('T').first,
        city: _cityController.text.trim(),
      );
      if (!mounted) return;

      AppStatusModal.showSuccess(
        context: context,
        title: 'Profile Ready! 🌸',
        message: 'You are currently in Week $_calculatedWeek! Your personalized pregnancy timeline, weekly tips, and fetal development tracker are ready.',
        buttonText: 'Enter MomCare',
        onDismiss: () {
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const MainScreen(showWelcomeNotification: true),
            ),
            (route) => false,
          );
        },
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppStatusModal.showError(
        context: context,
        title: 'Setup Failed',
        message: e.message,
      );
    } catch (e) {
      if (!mounted) return;
      AppStatusModal.showError(
        context: context,
        title: 'Connection Error',
        message: 'Network error. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectLMP(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _lmpDate ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _calculateDueDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Personalize Your Care', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D1625))),
              const SizedBox(height: 14),

              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Age (optional)',
                  prefixIcon: const Icon(Icons.cake_outlined, color: AppColors.primary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City / Region',
                  prefixIcon: const Icon(Icons.location_city_outlined, color: AppColors.primary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
              const SizedBox(height: 24),

              const Text('Pregnancy Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D1625))),
              const SizedBox(height: 6),
              const Text(
                'Enter your Last Menstrual Period (LMP) to calculate your current pregnancy week and due date.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 14),

              // LMP Selector Button
              GestureDetector(
                onTap: () => _selectLMP(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _lmpDate != null ? AppColors.primary : Colors.grey.shade300,
                      width: _lmpDate != null ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, color: _lmpDate != null ? AppColors.primary : Colors.grey.shade600),
                          const SizedBox(width: 12),
                          Text(
                            _lmpDate == null
                                ? 'Select LMP Date'
                                : 'LMP: ${DateFormat('MMMM dd, yyyy').format(_lmpDate!)}',
                            style: TextStyle(
                              color: _lmpDate == null ? Colors.black54 : Colors.black87,
                              fontSize: 15,
                              fontWeight: _lmpDate != null ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    ],
                  ),
                ),
              ),

              // Real-time Pregnancy Week Calculation Card
              if (_calculatedWeek != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF61183E), Color(0xFF8B2659)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.child_care_rounded, color: Colors.white, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Week $_calculatedWeek of 40',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _calculatedTrimester == 1
                                  ? '1st Trimester'
                                  : _calculatedTrimester == 2
                                      ? '2nd Trimester'
                                      : '3rd Trimester',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Estimated Due Date: ${DateFormat('MMMM dd, yyyy').format(_dueDate!)}',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '~$_daysRemaining days remaining until delivery',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              const Text('App Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D1625))),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                decoration: InputDecoration(
                  labelText: 'Preferred Language',
                  prefixIcon: const Icon(Icons.language_rounded, color: AppColors.primary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
                items: _languages.map((String lang) {
                  return DropdownMenuItem<String>(
                    value: _languageCodes[lang],
                    child: Text(lang),
                  );
                }).toList(),
                onChanged: _isLoading
                    ? null
                    : (newValue) {
                        setState(() {
                          _selectedLanguage = newValue!;
                        });
                      },
              ),
              const SizedBox(height: 36),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Complete Setup & View Week',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}