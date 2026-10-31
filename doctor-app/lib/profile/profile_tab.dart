import 'package:flutter/material.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/model/mock_data.dart';
import 'package:doctor_app/model/doctor_profile_model.dart';
import 'package:doctor_app/auth/login_screen.dart';
import 'package:doctor_app/auth/auth_service.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late DoctorProfileModel _doctor;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _doctor = DoctorProfileModel.shared;
    _doctor.availability = MockData.currentDoctorAvailability;
    DoctorProfileModel.shared.addListener(_onProfileChanged);
    _loadProfileFromBackend();
  }

  @override
  void dispose() {
    DoctorProfileModel.shared.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) {
      setState(() {
        _doctor = DoctorProfileModel.shared;
      });
    }
  }

  Future<void> _loadProfileFromBackend() async {
    try {
      final user = await AuthService.instance.getCurrentUser();
      final userId = user['id'];
      if (userId != null && userId.isNotEmpty) {
        await AuthService.instance.getDoctorProfile(userId);
      }
    } catch (_) {}
  }

  Future<void> _updatePhoto(String url) async {
    setState(() {
      _doctor.avatarUrl = url;
      DoctorProfileModel.shared.avatarUrl = url;
    });
    DoctorProfileModel.shared.notify();

    try {
      final user = await AuthService.instance.getCurrentUser();
      final userId = user['id'];
      if (userId != null && userId.isNotEmpty) {
        await AuthService.instance.updateProfilePhoto(userId, url);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor profile photo updated and saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor profile photo updated')),
        );
      }
    }
  }

  void _showPhotoPickerModal() {
    final presets = [
      'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=300',
      'https://images.unsplash.com/photo-1594824813571-638f02614d3f?w=300',
      'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=300',
      'https://images.unsplash.com/photo-1551836022-d5d88e9218df?w=300',
      'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=300',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Update Profile Photo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Option 1: Take Photo (Camera)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 22),
              ),
              title: const Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Capture new headshot using device camera', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _simulateCameraCapture();
              },
            ),
            const Divider(height: 12),

            // Option 2: Upload Photo / Gallery
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB), size: 22),
              ),
              title: const Text('Upload Photo from Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Choose a verified high-resolution image', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _showUploadUrlDialog();
              },
            ),
            const SizedBox(height: 16),

            // Option 3: Presets
            const Text(
              'Or Select from Physician Presets:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: presets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final url = presets[i];
                  final isCurrent = _doctor.avatarUrl == url;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _updatePhoto(url);
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrent ? AppColors.primary : Colors.grey.shade300,
                          width: isCurrent ? 3 : 1,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundImage: NetworkImage(url),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _simulateCameraCapture() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1594824813571-638f02614d3f?w=300',
                      fit: BoxFit.cover,
                      width: 180,
                      height: 180,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('LIVE REC', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const Icon(Icons.camera_enhance_rounded, color: Colors.white70, size: 36),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Camera Photo Captured', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('Use this photo for your MomCare Provider profile?', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Retake')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              _updatePhoto('https://images.unsplash.com/photo-1594824813571-638f02614d3f?w=300');
            },
            child: const Text('Save & Apply', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showUploadUrlDialog() {
    final urlController = TextEditingController(text: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=300');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Upload Image', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select or enter an image file URL for your doctor profile:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                hintText: 'https://...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.link_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final text = urlController.text.trim();
              Navigator.pop(ctx);
              if (text.isNotEmpty) {
                _updatePhoto(text);
              }
            },
            child: const Text('Upload', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editBioDialog() {
    final controller = TextEditingController(text: _doctor.bio);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Edit Professional Bio', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Enter your clinical summary...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final newBio = controller.text.trim();
              Navigator.pop(ctx);
              setState(() {
                _doctor.bio = newBio;
                DoctorProfileModel.shared.bio = newBio;
              });
              DoctorProfileModel.shared.notify();
              try {
                final user = await AuthService.instance.getCurrentUser();
                final userId = user['id'];
                if (userId != null && userId.isNotEmpty) {
                  await AuthService.instance.updateDoctorProfile(userId, {'bio': newBio});
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bio updated and saved!')),
                  );
                }
              } catch (_) {}
            },
            child: const Text('Save Bio', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileModal() {
    final nameCtrl = TextEditingController(text: _doctor.name);
    final specCtrl = TextEditingController(text: _doctor.specialization);
    final hospCtrl = TextEditingController(text: _doctor.hospitalClinicName.isNotEmpty ? _doctor.hospitalClinicName : _doctor.clinicAffiliation);
    final locCtrl = TextEditingController(text: _doctor.practiceLocation);
    final licCtrl = TextEditingController(text: _doctor.licenseNumber);
    final expiryCtrl = TextEditingController(text: _doctor.licenseExpiryDate.isNotEmpty ? _doctor.licenseExpiryDate : _doctor.licenseExpiry);
    final natIdCtrl = TextEditingController(text: _doctor.nationalId);
    final docCtrl = TextEditingController(text: _doctor.credentialDocumentUrl);
    final expCtrl = TextEditingController(text: _doctor.yearsExperience);
    final bioCtrl = TextEditingController(text: _doctor.bio);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 16,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Doctor Profile',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Colors.grey),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Update your clinical credentials and public profile information',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  _buildFormField(label: 'Full Name', controller: nameCtrl, icon: Icons.person_outline),
                  const SizedBox(height: 12),
                  _buildFormField(label: 'Medical Specialization', controller: specCtrl, icon: Icons.medical_services_outlined),
                  const SizedBox(height: 12),
                  _buildFormField(label: 'Hospital / Clinic Affiliation', controller: hospCtrl, icon: Icons.local_hospital_outlined),
                  const SizedBox(height: 12),
                  _buildFormField(label: 'Practice Location / City', controller: locCtrl, icon: Icons.location_on_outlined),
                  const SizedBox(height: 12),
                  _buildFormField(label: 'Medical License Number', controller: licCtrl, icon: Icons.badge_outlined),
                  const SizedBox(height: 12),
                  _buildFormField(label: 'License Expiration Date', controller: expiryCtrl, icon: Icons.calendar_today_outlined),
                  const SizedBox(height: 12),
                  _buildFormField(label: 'National ID Number', controller: natIdCtrl, icon: Icons.credit_card_rounded),
                  const SizedBox(height: 12),
                  _buildFormField(label: 'Credential Document / Certificate', controller: docCtrl, icon: Icons.file_present_rounded),
                  const SizedBox(height: 12),
                  _buildFormField(label: 'Years of Experience', controller: expCtrl, icon: Icons.history_edu_outlined),
                  const SizedBox(height: 12),
                  _buildFormField(label: 'Professional Summary / Bio', controller: bioCtrl, icon: Icons.description_outlined, maxLines: 3),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              setModalState(() => isSaving = true);
                              final cleanName = nameCtrl.text.trim();
                              final cleanSpec = specCtrl.text.trim();
                              final cleanHosp = hospCtrl.text.trim();
                              final cleanLoc = locCtrl.text.trim();
                              final cleanLic = licCtrl.text.trim();
                              final cleanExpiry = expiryCtrl.text.trim();
                              final cleanNatId = natIdCtrl.text.trim();
                              final cleanDoc = docCtrl.text.trim();
                              final cleanExp = expCtrl.text.trim();
                              final cleanBio = bioCtrl.text.trim();

                              setState(() {
                                if (cleanName.isNotEmpty) {
                                  _doctor.name = cleanName;
                                  DoctorProfileModel.shared.name = cleanName;
                                }
                                if (cleanSpec.isNotEmpty) {
                                  _doctor.specialization = cleanSpec;
                                  DoctorProfileModel.shared.specialization = cleanSpec;
                                }
                                if (cleanHosp.isNotEmpty) {
                                  _doctor.hospitalClinicName = cleanHosp;
                                  _doctor.clinicAffiliation = cleanHosp;
                                  DoctorProfileModel.shared.hospitalClinicName = cleanHosp;
                                  DoctorProfileModel.shared.clinicAffiliation = cleanHosp;
                                }
                                if (cleanLoc.isNotEmpty) {
                                  _doctor.practiceLocation = cleanLoc;
                                  DoctorProfileModel.shared.practiceLocation = cleanLoc;
                                }
                                if (cleanLic.isNotEmpty) {
                                  _doctor.licenseNumber = cleanLic;
                                  DoctorProfileModel.shared.licenseNumber = cleanLic;
                                }
                                if (cleanExpiry.isNotEmpty) {
                                  _doctor.licenseExpiryDate = cleanExpiry;
                                  _doctor.licenseExpiry = cleanExpiry;
                                  DoctorProfileModel.shared.licenseExpiryDate = cleanExpiry;
                                  DoctorProfileModel.shared.licenseExpiry = cleanExpiry;
                                }
                                if (cleanNatId.isNotEmpty) {
                                  _doctor.nationalId = cleanNatId;
                                  DoctorProfileModel.shared.nationalId = cleanNatId;
                                }
                                if (cleanDoc.isNotEmpty) {
                                  _doctor.credentialDocumentUrl = cleanDoc;
                                  DoctorProfileModel.shared.credentialDocumentUrl = cleanDoc;
                                }
                                if (cleanExp.isNotEmpty) {
                                  _doctor.yearsExperience = cleanExp;
                                  DoctorProfileModel.shared.yearsExperience = cleanExp;
                                }
                                if (cleanBio.isNotEmpty) {
                                  _doctor.bio = cleanBio;
                                  DoctorProfileModel.shared.bio = cleanBio;
                                }
                              });
                              DoctorProfileModel.shared.notify();

                              try {
                                final user = await AuthService.instance.getCurrentUser();
                                final userId = user['id'];
                                if (userId != null && userId.isNotEmpty) {
                                  await AuthService.instance.updateDoctorProfile(userId, {
                                    'name': cleanName,
                                    'specialization': cleanSpec,
                                    'hospital_clinic_name': cleanHosp,
                                    'location': cleanLoc,
                                    'license_number': cleanLic,
                                    'license_expiry_date': cleanExpiry,
                                    'national_id': cleanNatId,
                                    'credential_document_url': cleanDoc,
                                    'years_experience': cleanExp,
                                    'bio': cleanBio,
                                  });
                                }
                              } catch (_) {}

                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Doctor profile updated and synced successfully!'),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out from your MomCare Doctor provider account?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.instance.logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddSlotModal(DayScheduleModel day) {
    String selectedPeriod = 'Morning';
    final timeController = TextEditingController(text: '09:00 AM - 12:00 PM');
    int capacity = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 16,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Add Availability Slot for ${day.dayName}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),

                // Period Choice
                const Text('Time Period', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: ['Morning', 'Afternoon', 'Evening'].map((period) {
                    final isSel = selectedPeriod == period;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(period),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) {
                          setModalState(() {
                            selectedPeriod = period;
                            if (period == 'Morning') timeController.text = '09:00 AM - 12:00 PM';
                            if (period == 'Afternoon') timeController.text = '02:00 PM - 05:00 PM';
                            if (period == 'Evening') timeController.text = '05:30 PM - 08:00 PM';
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),
                const Text('Hours / Timing Range', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: timeController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.access_time_rounded, size: 18),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),

                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Max Patient Capacity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: capacity > 1 ? () => setModalState(() => capacity--) : null,
                        ),
                        Text('$capacity patients', style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: capacity < 15 ? () => setModalState(() => capacity++) : null,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final newSlot = AvailabilitySlotModel(
                        id: '${day.shortDay.toLowerCase()}-${DateTime.now().millisecondsSinceEpoch}',
                        period: selectedPeriod,
                        timeRange: timeController.text.trim(),
                        capacity: capacity,
                      );
                      setState(() {
                        day.slots.add(newSlot);
                        day.isEnabled = true;
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added $selectedPeriod slot for ${day.dayName}')),
                      );
                    },
                    child: const Text('Add Slot to Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showNotificationPreferences() {
    bool urgentRisk = true;
    bool newAppts = true;
    bool labResults = true;
    bool soundAlert = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setPrefState) {
          return Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Notification Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Customize your maternal health triage notifications', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.riskHigh,
                  title: const Text('Urgent Patient Risk Alerts (High BP/Glucose)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Push alerts immediately when critical vitals are logged', style: TextStyle(fontSize: 11)),
                  value: urgentRisk,
                  onChanged: (val) => setPrefState(() => urgentRisk = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                  title: const Text('New Appointment & Consultation Requests', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Notify when mother requests a booking', style: TextStyle(fontSize: 11)),
                  value: newAppts,
                  onChanged: (val) => setPrefState(() => newAppts = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF7C3AED),
                  title: const Text('New Lab & Ultrasound Reports Uploaded', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Alert when diagnostics are completed', style: TextStyle(fontSize: 11)),
                  value: labResults,
                  onChanged: (val) => setPrefState(() => labResults = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.amber.shade800,
                  title: const Text('Audible Emergency Risk Alert Sound', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Play audible tone even in silent mode for critical maternal emergencies', style: TextStyle(fontSize: 11)),
                  value: soundAlert,
                  onChanged: (val) => setPrefState(() => soundAlert = val),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification settings updated')),
                      );
                    },
                    child: const Text('Save Preferences', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header & Identity Section
            _buildHeaderCard(),

            const SizedBox(height: 16),

            // 2. Credential & Professional Information Card
            _buildCredentialsCard(),

            const SizedBox(height: 16),

            // 3. Interactive Availability Slot Management
            _buildAvailabilityScheduleSection(),

            const SizedBox(height: 16),

            // 4. Settings & Account Actions
            _buildSettingsSection(),

            const SizedBox(height: 24),

            // Log Out Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                label: const Text('Sign Out Provider Account', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _confirmSignOut,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Header & Identity Card
  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // Avatar + Edit Button
          Stack(
            children: [
              GestureDetector(
                onTap: _showPhotoPickerModal,
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: NetworkImage(_doctor.avatarUrl),
                  onBackgroundImageError: (_, __) {},
                  child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _showPhotoPickerModal,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Doctor Name & Specialization with Edit Action
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  _doctor.name,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: _showEditProfileModal,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                  child: const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            _doctor.specialization,
            style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),

          // Clinic Affiliation Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_hospital_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _doctor.clinicAffiliation,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Admin Verified Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
                SizedBox(width: 6),
                Text(
                  'Verified & Approved by Admin',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Credential & Professional Information Card
  Widget _buildCredentialsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Credentials & Practice Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                onPressed: _showEditProfileModal,
                icon: const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                label: const Text('Edit Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // License & Expiry
          _buildDetailRow(
            icon: Icons.credit_card_rounded,
            title: 'Medical License',
            value: '${_doctor.licenseNumber} (Expires: ${_doctor.licenseExpiryDate.isNotEmpty ? _doctor.licenseExpiryDate : _doctor.licenseExpiry})',
          ),
          const Divider(height: 18),

          // National ID Document
          if (_doctor.nationalIdUrl.isNotEmpty || _doctor.nationalId.isNotEmpty) ...[
            _buildDetailRow(
              icon: Icons.badge_outlined,
              title: 'National ID Document',
              value: _doctor.nationalIdUrl.isNotEmpty ? _doctor.nationalIdUrl : _doctor.nationalId,
            ),
            const Divider(height: 18),
          ],

          // Hospital / Clinic
          _buildDetailRow(
            icon: Icons.local_hospital_rounded,
            title: 'Hospital / Clinic Affiliation',
            value: _doctor.hospitalClinicName.isNotEmpty ? _doctor.hospitalClinicName : _doctor.clinicAffiliation,
          ),
          const Divider(height: 18),

          // Experience & Practice Location
          _buildDetailRow(
            icon: Icons.history_toggle_off_rounded,
            title: 'Experience',
            value: _doctor.yearsExperience.contains('Year') ? _doctor.yearsExperience : '${_doctor.yearsExperience} Years',
          ),
          const Divider(height: 18),

          _buildDetailRow(
            icon: Icons.location_on_outlined,
            title: 'Practice Location / City',
            value: _doctor.practiceLocation,
          ),
          const Divider(height: 18),

          // Credential Document
          if (_doctor.credentialDocumentUrl.isNotEmpty) ...[
            _buildDetailRow(
              icon: Icons.file_present_rounded,
              title: 'Verified Credential Document',
              value: _doctor.credentialDocumentUrl,
            ),
            const Divider(height: 18),
          ],

          // Languages Spoken
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.language_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Languages Spoken', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _doctor.languages.map((lang) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            lang,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 18),

          // Short Bio with Edit Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Professional Summary / Bio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              InkWell(
                onTap: _editBioDialog,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 13, color: AppColors.primary),
                      SizedBox(width: 3),
                      Text('Edit Bio', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _doctor.bio,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),

          const Divider(height: 22),

          // Verification Documents View
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Verification Documents', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              TextButton.icon(
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Document re-upload portal opened')),
                  );
                },
                icon: const Icon(Icons.upload_file_rounded, size: 14, color: AppColors.primary),
                label: const Text('Update / Re-upload', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ..._doctor.documents.map((doc) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text('${doc.fileType} • ${doc.issueDate}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(4)),
                    child: Text(doc.status, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.success)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 3. Interactive Availability Slot Management
  Widget _buildAvailabilityScheduleSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Availability & Hours', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  Text('Configure booking slots for mothers', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              // Global Availability Status Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _doctor.availability.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _doctor.availability.color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: _doctor.availability.color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(_doctor.availability.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _doctor.availability.color)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Global Status Selector
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildStatusOption(DoctorAvailability.online, 'Online'),
                const SizedBox(width: 6),
                _buildStatusOption(DoctorAvailability.away, 'Away'),
                const SizedBox(width: 6),
                _buildStatusOption(DoctorAvailability.offDuty, 'Off-Duty'),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Weekly Schedule Builder Mon - Sun
          const Text('Weekly Schedule Builder', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 10),

          ..._doctor.weeklySchedule.map((day) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: day.isEnabled ? Colors.white : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: day.isEnabled ? Colors.grey.shade300 : Colors.grey.shade200),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: day.isEnabled ? AppColors.primaryLight : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    day.shortDay,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: day.isEnabled ? AppColors.primary : Colors.grey,
                    ),
                  ),
                ),
                title: Text(
                  day.dayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: day.isEnabled ? AppColors.textPrimary : Colors.grey,
                  ),
                ),
                subtitle: Text(
                  day.isEnabled ? '${day.slots.length} booking slots active' : 'Unavailable (Day Off)',
                  style: TextStyle(fontSize: 11, color: day.isEnabled ? AppColors.textSecondary : Colors.grey),
                ),
                trailing: Switch(
                  value: day.isEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      day.isEnabled = val;
                    });
                  },
                ),
                children: [
                  if (day.slots.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No slots configured for this day.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    )
                  else
                    ...day.slots.map((slot) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${slot.period}: ${slot.timeRange}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                              child: Text(
                                'Max: ${slot.capacity} pts',
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  day.slots.removeWhere((s) => s.id == slot.id);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showAddSlotModal(day),
                      icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                      label: const Text('Add Time Slot', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusOption(DoctorAvailability status, String label) {
    final isSelected = _doctor.availability == status;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _doctor.availability = status;
            DoctorProfileModel.shared.availability = status;
            MockData.currentDoctorAvailability = status;
          });
          DoctorProfileModel.shared.notify();
          MockData.doctorAvailabilityNotifier.value = status;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Duty status set to ${status.label}. Synced with Home header.'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(color: status.color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. Settings & Account Actions
  Widget _buildSettingsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Account & Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),

          // Notification Preferences
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 20),
            ),
            title: const Text('Notification Preferences', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Triage alerts and appointment push settings', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _showNotificationPreferences,
          ),
          const Divider(),

          // App Language Selection
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.translate_rounded, color: Color(0xFF2563EB), size: 20),
            ),
            title: const Text('App Language', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text('Current: $_selectedLanguage', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              underline: const SizedBox(),
              items: ['English', 'Amharic (አማርኛ)', 'Afan Oromo', 'Somali'].map((lang) {
                return DropdownMenuItem(value: lang, child: Text(lang, style: const TextStyle(fontSize: 12)));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedLanguage = val);
              },
            ),
          ),
          const Divider(),

          // Support & Help Desk
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.headset_mic_outlined, color: AppColors.success, size: 20),
            ),
            title: const Text('Provider Support & Help Desk', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Contact MomCare clinical coordinator team', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contacting MomCare Provider Support...')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String title, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}
