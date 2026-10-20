import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/screens/auth/login_page.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/mother_service.dart';
import 'package:pregnancy_appp/widget/status_modal.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';
import 'package:provider/provider.dart';

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
  String? _profilePhotoUrl;
  bool _isUploadingPhoto = false;

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

      // Week + due date must come from a LIVE calculation based on the LMP date.
      var week = profile?['gestational_week'] as int? ?? 0;
      var dueDate = profile?['due_date'] as String?;
      try {
        final progress = await MotherService.getGestationalWeek();
        week = (progress['currentWeek'] as num?)?.toInt() ?? week;
        final liveDueDate = progress['dueDate'] as String?;
        if (liveDueDate != null && liveDueDate.isNotEmpty) dueDate = liveDueDate;
      } catch (_) {
        // Fall back to the stored profile values.
      }

      if (!mounted) return;

      final photo = (profile?['profile_photo'] as String?) ?? (user['profile_photo'] as String?);

      setState(() {
        _name = (user['name'] as String?) ?? _name;
        _phone = (user['phone'] as String?) ?? '';
        _gestationalWeek = week;
        _dueDate = dueDate;
        _assignedHospital = assignedHospital.isEmpty ? null : assignedHospital;
        if (photo != null && photo.isNotEmpty) {
          _profilePhotoUrl = photo;
        }
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

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);

      final newUrl = await MotherService.uploadProfilePhoto(File(picked.path));

      if (!mounted) return;
      setState(() {
        _profilePhotoUrl = newUrl;
      });

      await _loadProfile();

      if (!mounted) return;
      AppStatusModal.showSuccess(
        context: context,
        title: 'Photo Uploaded!',
        message: 'Your profile picture has been updated successfully.',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppStatusModal.showError(
        context: context,
        title: 'Upload Failed',
        message: e.message,
      );
    } catch (e) {
      if (!mounted) return;
      AppStatusModal.showError(
        context: context,
        title: 'Upload Failed',
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showPhotoPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Change Profile Photo',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose where to select your profile picture from:',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                  ),
                  title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Capture using device camera'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAndUploadPhoto(ImageSource.camera);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB)),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Select an existing photo from gallery'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAndUploadPhoto(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
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
      AppStatusModal.showSuccess(
        context: context,
        title: 'Profile Updated',
        message: successMessage,
      );
      await _loadProfile();
    } on ApiException catch (e) {
      if (!mounted) return;
      AppStatusModal.showError(
        context: context,
        title: 'Update Failed',
        message: e.message,
      );
    } catch (e) {
      if (!mounted) return;
      AppStatusModal.showError(
        context: context,
        title: 'Update Failed',
        message: 'Network error. Please try again.',
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
                  GestureDetector(
                    onTap: _isUploadingPhoto ? null : _showPhotoPickerSheet,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          backgroundImage: (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty)
                              ? NetworkImage(ApiService.resolveUrl(_profilePhotoUrl!))
                              : null,
                          child: _isUploadingPhoto
                              ? Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                )
                              : (_profilePhotoUrl == null || _profilePhotoUrl!.isEmpty)
                                  ? const Icon(Icons.person_rounded, size: 80, color: AppColors.primary)
                                  : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
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
              _buildSettingsTile(
                Icons.notifications_none_rounded,
                "Notifications",
                onTap: _showNotificationsScreen,
              ),
              Consumer<LocaleProvider>(
                builder: (context, localeProvider, _) {
                  final code = localeProvider.locale?.languageCode ?? 'en';
                  final langName = L10n.getLanguageName(code);
                  return _buildSettingsTile(
                    Icons.language_rounded,
                    AppStrings.of(context, 'language'),
                    subtitle: langName,
                    onTap: _showLanguagePicker,
                  );
                },
              ),
              _buildSettingsTile(
                Icons.security_rounded,
                "Privacy & Security",
                onTap: _showPrivacyScreen,
              ),
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

  Widget _buildSettingsTile(IconData icon, String title, {String? subtitle, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600))
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }

  // ── Language picker ──────────────────────────────────────────────────
  void _showLanguagePicker() {
    final provider = Provider.of<LocaleProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.of(context, 'language'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              for (final locale in L10n.all)
                ListTile(
                  leading: Icon(
                    provider.locale?.languageCode == locale.languageCode
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    L10n.getLanguageName(locale.languageCode),
                    style: TextStyle(
                      fontWeight: provider.locale?.languageCode == locale.languageCode
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    provider.setLocale(locale);
                    MotherService.updateProfile(language: locale.languageCode).catchError((_) {});
                    Navigator.pop(context);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ── Notifications screen ─────────────────────────────────────────────
  void _showNotificationsScreen() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Notifications",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const ListTile(
                leading: Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                title: Text("Push notifications"),
                subtitle: Text("Managed by your phone settings"),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: AppColors.primary),
                title: const Text("Open system settings"),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Open your phone Settings → Apps → Pregnancy App → Notifications")),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ── Privacy & Security screen ────────────────────────────────────────
  void _showPrivacyScreen() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Privacy & Security",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.lock_reset_outlined, color: AppColors.primary),
                title: const Text("Change password"),
                subtitle: const Text("We will email you a reset link"),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password reset link will be sent to your email")),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                title: const Text("Privacy policy"),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Privacy policy screen coming soon")),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: const Text("Log out", style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}