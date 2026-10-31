import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String? _lmpDate;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadCachedProfile();
    _loadProfile();
  }

  Future<void> _loadCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final directLmp = prefs.getString(MotherService.userLmpKey);
      final cachedProgress = await MotherService.getCachedGestationalWeek();
      final cachedProfile = await MotherService.getCachedProfile();
      if (!mounted) return;
      if (cachedProfile != null || cachedProgress != null || directLmp != null) {
        final cUser = cachedProfile?['user'] as Map<String, dynamic>? ?? {};
        final cProfile = cachedProfile?['profile'] as Map<String, dynamic>?;
        final cLmp = directLmp ??
            cachedProgress?['lmpDate']?.toString() ??
            cProfile?['lmp_date']?.toString() ??
            cProfile?['lmpDate']?.toString() ??
            cUser['lmpDate']?.toString() ??
            cUser['lmp_date']?.toString();
        setState(() {
          if (cUser['name'] != null && cUser['name'].toString().isNotEmpty) {
            _name = cUser['name'].toString();
          }
          if (cUser['phone'] != null && cUser['phone'].toString().isNotEmpty) {
            _phone = cUser['phone'].toString();
          }
          final w = (cachedProgress?['currentWeek'] as int?) ??
              (cProfile?['gestational_week'] as int?) ?? 0;
          if (w > 0) _gestationalWeek = w;
          final d = (cachedProgress?['dueDate'] as String?) ??
              (cProfile?['due_date'] as String?);
          if (d != null && d.isNotEmpty) _dueDate = d;
          if (cLmp != null && cLmp.isNotEmpty) _lmpDate = cLmp;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadProfile() async {
    if (_name.isEmpty && _gestationalWeek == 0) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final data = await MotherService.getProfile();
      if (!mounted) return;
      final user = data['user'] as Map<String, dynamic>? ?? {};
      final profile = data['profile'] as Map<String, dynamic>?;

      final assignedHospital = (profile?['assigned_hospital_name'] as String?) ?? '';

      // Week + due date must come from a LIVE calculation based on the LMP date.
      var week = profile?['gestational_week'] as int? ?? 0;
      var dueDate = profile?['due_date'] as String?;
      String? lmpDate = profile?['lmp_date']?.toString() ??
          profile?['lmpDate']?.toString() ??
          user['lmpDate']?.toString() ??
          user['lmp_date']?.toString();

      try {
        final progress = await MotherService.getGestationalWeek();
        final liveWeek = (progress['currentWeek'] as num?)?.toInt() ?? 0;
        if (liveWeek > 0) week = liveWeek;
        final liveDueDate = progress['dueDate'] as String?;
        if (liveDueDate != null && liveDueDate.isNotEmpty) dueDate = liveDueDate;
        final liveLmp = progress['lmpDate'] as String?;
        if (liveLmp != null && liveLmp.isNotEmpty) lmpDate = liveLmp;
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
        _lmpDate = lmpDate ?? _lmpDate;
        _assignedHospital = assignedHospital.isEmpty ? null : assignedHospital;
        if (photo != null && photo.isNotEmpty) {
          _profilePhotoUrl = photo;
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_name.isEmpty) setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      if (_name.isEmpty) setState(() => _error = 'Network error. Please try again.');
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
        title: AppStrings.of(context, 'photo_uploaded'),
        message: AppStrings.of(context, 'photo_uploaded_msg'),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppStatusModal.showError(
        context: context,
        title: AppStrings.of(context, 'upload_failed'),
        message: e.message,
      );
    } catch (e) {
      if (!mounted) return;
      AppStatusModal.showError(
        context: context,
        title: AppStrings.of(context, 'upload_failed'),
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _confirmAndDeletePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.of(context, 'remove_photo')),
        content: Text(AppStrings.of(context, 'remove_photo_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.of(context, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppStrings.of(context, 'remove_photo')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _deletePhoto();
    }
  }

  Future<void> _deletePhoto() async {
    setState(() => _isUploadingPhoto = true);
    try {
      await MotherService.deleteProfilePhoto();
      if (!mounted) return;
      setState(() {
        _profilePhotoUrl = null;
      });
      AppStatusModal.showSuccess(
        context: context,
        title: AppStrings.of(context, 'remove_photo'),
        message: AppStrings.of(context, 'remove_photo_success'),
      );
      await _loadProfile();
    } catch (e) {
      if (!mounted) return;
      AppStatusModal.showError(
        context: context,
        title: AppStrings.of(context, 'upload_failed'),
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showPhotoPickerSheet() {
    final hasPhoto = _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty;
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
                Text(
                  AppStrings.of(context, 'change_photo'),
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.of(context, 'choose_photo_source'),
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
                  title: Text(AppStrings.of(context, 'take_photo'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(AppStrings.of(context, 'capture_camera')),
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
                  title: Text(AppStrings.of(context, 'choose_gallery'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(AppStrings.of(context, 'select_gallery')),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAndUploadPhoto(ImageSource.gallery);
                  },
                ),
                if (hasPhoto) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    ),
                    title: Text(
                      AppStrings.of(context, 'remove_photo'),
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
                    ),
                    subtitle: Text(AppStrings.of(context, 'remove_photo_confirm')),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _confirmAndDeletePhoto();
                    },
                  ),
                ],
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

  String _formatLmpDate(String? iso) {
    if (iso == null || iso.trim().isEmpty) {
      return AppStrings.of(context, 'pregnancy_details_not_set');
    }
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return iso;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${months[d.month - 1]} ${d.day}, ${d.year}';
    if (_gestationalWeek > 0) {
      return '$dateStr (${AppStrings.of(context, 'weeks_pregnant', [_gestationalWeek])})';
    }
    return dateStr;
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.of(context, 'cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(AppStrings.of(context, 'save')),
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
        title: AppStrings.of(context, 'account_settings'),
        message: successMessage,
      );
      await _loadProfile();
    } on ApiException catch (e) {
      if (!mounted) return;
      AppStatusModal.showError(
        context: context,
        title: AppStrings.of(context, 'upload_failed'),
        message: e.message,
      );
    } catch (e) {
      if (!mounted) return;
      AppStatusModal.showError(
        context: context,
        title: AppStrings.of(context, 'upload_failed'),
        message: 'Network error. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectLMP() async {
    final now = DateTime.now();
    DateTime initial = now;
    if (_lmpDate != null && _lmpDate!.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(_lmpDate!);
      if (parsed != null) {
        initial = parsed.toLocal();
      }
    } else if (_gestationalWeek > 0) {
      final estimatedDays = ((_gestationalWeek - 1) * 7).clamp(0, 280);
      initial = now.subtract(Duration(days: estimatedDays));
    }

    final firstDate = DateTime(now.year - 1, now.month, now.day);
    final lastDate = now;
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: AppStrings.of(context, 'pregnancy_details'),
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
      final live = MotherService.calculateProgressFromLmp(iso);
      setState(() {
        _lmpDate = iso;
        if (live.isNotEmpty) {
          _gestationalWeek = (live['currentWeek'] as int?) ?? _gestationalWeek;
          _dueDate = (live['dueDate'] as String?) ?? _dueDate;
        }
      });

      // Instantly persist locally so the mobile app has the calendar date saved
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(MotherService.userLmpKey, iso);
        if (live.isNotEmpty) {
          await prefs.setString('cached_gestational_week', jsonEncode(live));
          MotherService.pregnancyProgress.value = live;
        }
      } catch (_) {}

      await _updateProfile(
        {'lmpDate': iso},
        AppStrings.of(context, 'pregnancy_details_updated'),
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
                    _isLoading ? AppStrings.of(context, 'loading') : _name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isLoading
                        ? '...'
                        : (_gestationalWeek > 0
                            ? AppStrings.of(context, 'weeks_pregnant', [_gestationalWeek])
                            : AppStrings.of(context, 'pregnancy_details_not_set')),
                    style: const TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    OutlinedButton(onPressed: _loadProfile, child: Text(AppStrings.of(context, 'retry'))),
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
                  _buildStatItem(AppStrings.of(context, 'week'), _gestationalWeek > 0 ? '$_gestationalWeek' : '--'),
                  _buildStatItem(AppStrings.of(context, 'stat_phone'), _phone.isNotEmpty ? _phone : '--'),
                  _buildStatItem(AppStrings.of(context, 'stat_due_date'), _formatDueDate(_dueDate)),
                ],
              ),
            ],

            const SizedBox(height: 35),

            if (_assignedHospital != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_hospital_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.of(context, 'assigned_hospital', [_assignedHospital!]),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
            ],

            _buildSettingsSection(AppStrings.of(context, 'account_settings'), [
              _buildSettingsTile(
                Icons.person_outline_rounded,
                AppStrings.of(context, 'personal_info'),
                onTap: () => _editText(
                  AppStrings.of(context, 'edit_name'),
                  _name,
                  AppStrings.of(context, 'full_name'),
                  (value) => _updateProfile({'name': value}, 'Name updated'),
                ),
              ),
              _buildSettingsTile(
                Icons.calendar_month_rounded,
                AppStrings.of(context, 'pregnancy_details'),
                subtitle: _formatLmpDate(_lmpDate),
                onTap: _selectLMP,
              ),
            ]),

            const SizedBox(height: 25),

            _buildSettingsSection(AppStrings.of(context, 'app_settings'), [
              _buildSettingsTile(
                Icons.notifications_none_rounded,
                AppStrings.of(context, 'notifications'),
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
                AppStrings.of(context, 'privacy_security'),
                onTap: _showPrivacyScreen,
              ),
            ]),

            const SizedBox(height: 30),
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
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
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
              Text(
                AppStrings.of(context, 'notifications'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                title: Text(AppStrings.of(context, 'push_notifications')),
                subtitle: Text(AppStrings.of(context, 'managed_by_phone')),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: AppColors.primary),
                title: Text(AppStrings.of(context, 'open_system_settings')),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Open your phone Settings → Apps → MomCare → Notifications')),
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
              Text(
                AppStrings.of(context, 'privacy_security'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.lock_reset_outlined, color: AppColors.primary),
                title: Text(AppStrings.of(context, 'change_password')),
                subtitle: Text(AppStrings.of(context, 'reset_link_sent')),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppStrings.of(context, 'reset_link_sent'))),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                title: Text(AppStrings.of(context, 'privacy_policy')),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppStrings.of(context, 'policy_coming_soon'))),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: Text(AppStrings.of(context, 'log_out'), style: const TextStyle(color: Colors.red)),
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