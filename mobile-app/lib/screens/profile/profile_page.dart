import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/screens/auth/login_page.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/mother_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  String? _error;

  String _name = '';
  String _phone = '';
  int _gestationalWeek = 0;
  String? _dueDate;
  String? _assignedHospital;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await MotherService.getProfile();
      if (!mounted) return;
      final user = data['user'] as Map<String, dynamic>? ?? {};
      final profile = data['profile'] as Map<String, dynamic>?;

      final assignedHospital = (profile?['assigned_hospital_name'] as String?) ?? '';
      setState(() {
        _name = (user['name'] as String?) ?? _name;
        _phone = (user['phone'] as String?) ?? '';
        _gestationalWeek = profile?['gestational_week'] as int? ?? 0;
        _dueDate = profile?['due_date'] as String?;
        _assignedHospital = assignedHospital.isEmpty ? null : assignedHospital;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDueDate(String? iso) {
    if (iso == null || iso.isEmpty) return '--';
    final d = DateTime.tryParse(iso);
    if (d == null) return '--';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }

  Future<void> _editText(String title, String initial, String label, void Function(String) onSave) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      onSave(result);
    }
  }

  Future<void> _updateProfile(Map<String, dynamic> body, String successMessage) async {
    setState(() => _isLoading = true);
    try {
      await MotherService.updateProfile(
        name: body['name'] as String?,
        language: body['language'] as String?,
        lmpDate: body['lmpDate'] as String?,
        city: body['city'] as String?,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      await _loadProfile();
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

  Future<void> _selectLMP() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 7 * 12)),
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final iso = picked.toIso8601String().split('T').first;
      await _updateProfile(
        {'lmpDate': iso},
        'Pregnancy details updated',
      );
    }
  }

  Future<void> _logout() async {
    await ApiService.clearSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(Icons.person_rounded, size: 80, color: AppColors.primary),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isLoading ? 'Loading...' : _name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isLoading
                        ? '...'
                        : (_gestationalWeek > 0 ? '$_gestationalWeek Weeks Pregnant' : 'Pregnancy details not set'),
                    style: const TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    OutlinedButton(onPressed: _loadProfile, child: const Text('Retry')),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 35),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem("Week", _gestationalWeek > 0 ? '$_gestationalWeek' : '--'),
                  _buildStatItem("Phone", _phone),
                  _buildStatItem("Due Date", _formatDueDate(_dueDate)),
                ],
              ),
            ],

            const SizedBox(height: 35),

            if (_assignedHospital != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_hospital_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Assigned hospital: $_assignedHospital',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
            ],

            _buildSettingsSection("Account Settings", [
              _buildSettingsTile(
                Icons.person_outline_rounded,
                "Personal Information",
                onTap: () => _editText(
                  'Edit Name',
                  _name,
                  'Full Name',
                  (value) => _updateProfile({'name': value}, 'Name updated'),
                ),
              ),
              _buildSettingsTile(
                Icons.calendar_month_rounded,
                "Pregnancy Details (LMP)",
                onTap: _selectLMP,
              ),
            ]),

            const SizedBox(height: 25),

            _buildSettingsSection("App Settings", [
              _buildSettingsTile(Icons.notifications_none_rounded, "Notifications", onTap: () {}),
              _buildSettingsTile(Icons.language_rounded, "Language Settings", onTap: () {}),
              _buildSettingsTile(Icons.security_rounded, "Privacy & Security", onTap: () {}),
            ]),

            const SizedBox(height: 30),

            TextButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, color: Colors.red),
              label: const Text("Log Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.red[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 12),
          child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }
}