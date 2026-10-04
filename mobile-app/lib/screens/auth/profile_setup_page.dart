import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/screens/home/mainscreen.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/mother_service.dart';

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
  String _selectedLanguage = 'en';
  bool _isLoading = false;

  /// Display name -> the code the backend stores in `users.language`.
  /// Must match the set accepted by `ContentService._language()`.
  /// Note: Afan Oromo is 'or' here, not the 'om' locale used by L10n.
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

  /// Pre-fills anything already on the profile. A missing mother_profiles row
  /// is normal here, so failures are ignored rather than surfaced.
  Future<void> _prefill() async {
    try {
      final data = await MotherService.getProfile();
      if (!mounted) return;
      final user = data['user'];
      if (user is Map<String, dynamic>) {
        _nameController.text = (user['name'] as String?) ?? '';
        final code = user['language'] as String?;
        if (code != null && _languageCodes.containsValue(code)) {
          _selectedLanguage = code;
        }
      }
      final profile = data['profile'];
      if (profile is Map<String, dynamic>) {
        _cityController.text = (profile['city'] as String?) ?? '';
      }
    } catch (_) {
      // Nothing saved yet - start from a blank form.
    }
  }

  void _calculateDueDate(DateTime lmp) {
    setState(() {
      _lmpDate = lmp;
      _dueDate = lmp.add(const Duration(days: 280)); // 40 weeks typically
    });
  }

  Future<void> _saveProfile() async {
    if (_lmpDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your last menstrual period date.')),
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please try again.')),
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
        title: const Text('Profile Setup', style: TextStyle(color: Colors.black)),
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
              const Text('Personal Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Age',
                  // There is no age column on users or mother_profiles, so this
                  // value is intentionally not submitted. See FRONTEND_ISSUES.md.
                  helperText: 'Not saved yet',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
              const SizedBox(height: 24),

              const Text('Pregnancy Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectLMP(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _lmpDate == null
                            ? 'Select Last Menstrual Period (LMP)'
                            : 'LMP: ${DateFormat('MMM dd, yyyy').format(_lmpDate!)}',
                        style: TextStyle(color: _lmpDate == null ? Colors.black54 : Colors.black, fontSize: 16),
                      ),
                      const Icon(Icons.calendar_today, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dueDate == null
                          ? 'Estimated Due Date (Auto)'
                          : 'Due: ${DateFormat('MMM dd, yyyy').format(_dueDate!)}',
                      style: TextStyle(color: _dueDate == null ? Colors.black45 : Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const Icon(Icons.child_care, color: Colors.black45),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text('Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedLanguage,
                decoration: InputDecoration(
                  labelText: 'Preferred Language',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
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
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Complete Setup', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}