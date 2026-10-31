import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/auth/auth_service.dart';
import 'package:doctor_app/auth/pending_approval_screen.dart';
import 'package:doctor_app/auth/login_screen.dart';
import 'package:doctor_app/widget/status_modal.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // 1. Personal & Contact Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // 2. Medical Credentials & Practice
  final _licenseController = TextEditingController();
  final _licenseExpiryController = TextEditingController();
  final _hospitalClinicController = TextEditingController();
  final _locationController = TextEditingController();
  final _yearsExperienceController = TextEditingController();
  final _bioController = TextEditingController();

  // Uploaded Files State (No password fields)
  String? _nationalIdFileName;
  String? _nationalIdUrl;
  bool _isUploadingNationalId = false;
  String? _nationalIdError;

  String? _credentialDocFileName;
  String? _credentialDocUrl;
  bool _isUploadingCredential = false;
  String? _credentialError;

  // Specialization dropdown
  String _selectedSpecialization = 'Obstetrics & Gynecology';
  bool _isLoading = false;

  final List<String> _specializations = [
    'Obstetrics & Gynecology',
    'Maternal-Fetal Medicine (MFM)',
    'Reproductive Endocrinology',
    'Gynecologic Oncology',
    'Neonatologist',
    'Midwifery Specialist',
    'General Practitioner',
    'Pediatric Care Specialist',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _licenseController.dispose();
    _licenseExpiryController.dispose();
    _hospitalClinicController.dispose();
    _locationController.dispose();
    _yearsExperienceController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickLicenseExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 365 * 2)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 15)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {
        _licenseExpiryController.text = formatted;
      });
    }
  }

  void _showDocumentPickerDialog({required bool isNationalId}) {
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
            Text(
              isNationalId ? 'Upload National ID / Kebele Document' : 'Upload Medical Credential Certificate',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select document format (PDF, JPG, PNG, WEBP)',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),

            // Option 1: Gallery Photo (Most reliable on all devices)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB), size: 22),
              ),
              title: const Text('Choose Photo / Scanned Document (Gallery)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Pick scanned image or photo of your ID or degree', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromImagePicker(isNationalId: isNationalId, source: ImageSource.gallery);
              },
            ),
            const Divider(height: 12),

            // Option 2: Camera Capture
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF16A34A), size: 22),
              ),
              title: const Text('Capture with Device Camera', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Take a clear photo of your physical card or certificate', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromImagePicker(isNationalId: isNationalId, source: ImageSource.camera);
              },
            ),
            const Divider(height: 12),

            // Option 3: PDF / Document File
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 22),
              ),
              title: const Text('Choose File from Device Storage (PDF)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Select a .pdf or .doc document file from files', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromFileSystem(isNationalId: isNationalId);
              },
            ),
            const Divider(height: 12),

            // Option 4: Quick Verified Sample Attachment (Demo / Testing)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.verified_user_rounded, color: Color(0xFFD97706), size: 22),
              ),
              title: const Text('Attach Verified Sample Document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Instant attachment for testing / quick registration', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _attachDemoDocument(isNationalId: isNationalId);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _attachDemoDocument({required bool isNationalId}) {
    final fileName = isNationalId
        ? 'National_ID_Card_${_phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : "Verified"}.pdf'
        : 'Medical_Board_Certificate_${_licenseController.text.trim().isNotEmpty ? _licenseController.text.trim() : "MD"}.pdf';
    final sampleUrl = isNationalId
        ? '/uploads/national_id_sample.pdf'
        : '/uploads/medical_license_sample.pdf';

    setState(() {
      if (isNationalId) {
        _nationalIdFileName = fileName;
        _nationalIdUrl = sampleUrl;
        _nationalIdError = null;
      } else {
        _credentialDocFileName = fileName;
        _credentialDocUrl = sampleUrl;
        _credentialError = null;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${isNationalId ? "National ID" : "Credential Certificate"} attached successfully!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickFromFileSystem({required bool isNationalId}) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final path = file.path;
        if (path != null) {
          await _uploadSelectedFile(path: path, fileName: file.name, isNationalId: isNationalId);
          return;
        }
      }
    } catch (e) {
      debugPrint('[FilePicker] Note: $e');
      if (!mounted) return;

      // Gracefully fall back to image picker from gallery so user is not blocked
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Storage plugin requires a full app rebuild. Opening Gallery picker...'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
      await _pickFromImagePicker(isNationalId: isNationalId, source: ImageSource.gallery);
    }
  }

  Future<void> _pickFromImagePicker({required bool isNationalId, required ImageSource source}) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: source, imageQuality: 90);
      if (photo != null) {
        await _uploadSelectedFile(path: photo.path, fileName: photo.name, isNationalId: isNationalId);
      }
    } catch (e) {
      if (!mounted) return;
      AppModals.showFail(context, title: 'Capture Failed', message: e.toString());
    }
  }

  Future<void> _uploadSelectedFile({
    required String path,
    required String fileName,
    required bool isNationalId,
  }) async {
    setState(() {
      if (isNationalId) {
        _isUploadingNationalId = true;
        _nationalIdError = null;
      } else {
        _isUploadingCredential = true;
        _credentialError = null;
      }
    });

    try {
      final uploadedUrl = await AuthService.instance.uploadFile(
        filePath: path,
        fileName: fileName,
      );

      if (!mounted) return;

      setState(() {
        if (isNationalId) {
          _nationalIdFileName = fileName;
          _nationalIdUrl = uploadedUrl;
        } else {
          _credentialDocFileName = fileName;
          _credentialDocUrl = uploadedUrl;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${isNationalId ? "National ID" : "Credential Certificate"} uploaded successfully!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppModals.showFail(
        context,
        title: 'Upload Failed',
        message: 'Could not upload document: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          if (isNationalId) {
            _isUploadingNationalId = false;
          } else {
            _isUploadingCredential = false;
          }
        });
      }
    }
  }

  Future<void> _handleRegister() async {
    final formValid = _formKey.currentState!.validate();

    // Validate files
    bool filesValid = true;
    setState(() {
      if (_nationalIdUrl == null || _nationalIdUrl!.isEmpty) {
        _nationalIdError = 'Please upload your National ID or Kebele document file.';
        filesValid = false;
      } else {
        _nationalIdError = null;
      }

      if (_credentialDocUrl == null || _credentialDocUrl!.isEmpty) {
        _credentialError = 'Please upload your medical credential certificate or license file.';
        filesValid = false;
      } else {
        _credentialError = null;
      }
    });

    if (!formValid || !filesValid) {
      AppModals.showFail(
        context,
        title: 'Missing Required Documents',
        message: 'Please complete all required text fields and upload both your National ID and Medical Certificate files.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final email = _emailController.text.trim();
      final licenseNumber = _licenseController.text.trim();
      final hospitalClinicName = _hospitalClinicController.text.trim();
      final location = _locationController.text.trim();
      final yearsExperienceStr = _yearsExperienceController.text.trim();
      final bio = _bioController.text.trim();
      final licenseExpiryDate = _licenseExpiryController.text.trim();

      await AuthService.instance.register(
        name: name,
        phone: phone,
        password: null, // Password removed
        email: email.isNotEmpty ? email : null,
        specialization: _selectedSpecialization,
        licenseNumber: licenseNumber,
        hospitalClinicName: hospitalClinicName.isNotEmpty ? hospitalClinicName : null,
        location: location.isNotEmpty ? location : null,
        yearsExperience: yearsExperienceStr.isNotEmpty ? yearsExperienceStr : null,
        bio: bio.isNotEmpty ? bio : null,
        licenseExpiryDate: licenseExpiryDate.isNotEmpty ? licenseExpiryDate : null,
        nationalId: _nationalIdFileName,
        nationalIdUrl: _nationalIdUrl,
        credentialDocument: _credentialDocUrl,
      );

      if (!mounted) return;

      // Navigate directly to Waiting for Approval screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PendingApprovalScreen(
            phone: phone,
            name: name,
            licenseNumber: licenseNumber,
            specialization: _selectedSpecialization,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppModals.showFail(
        context,
        title: 'Registration Failed',
        message: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F5),
      appBar: AppBar(
        title: const Text('Doctor Registration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header badge & title
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_hospital_rounded, size: 44, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Join MomCare Clinical Team',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Register your clinical profile with your National ID and Medical Certificate files. Admin verifies credentials before approving access.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // ==========================================
                // SECTION 1: Personal & Contact Details
                // ==========================================
                _buildSectionHeader('1. Personal & Contact Information'),
                const SizedBox(height: 12),

                // Full Name
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name with Title (e.g. Dr. Sarah Jenkins)',
                  icon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                ),
                const SizedBox(height: 14),

                // Phone Number
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number (e.g. 0912345678 or +2519...)',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Phone number is required';
                    final clean = v.replaceAll(RegExp(r'[\s-]'), '');
                    if (clean.length < 9) return 'Enter a valid phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Email Address (Optional)
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address (optional)',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),

                // ==========================================
                // SECTION 2: Document Verification (Uploaded Files)
                // ==========================================
                _buildSectionHeader('2. Verification Documents (Upload Files)'),
                const SizedBox(height: 12),

                // 2.1 National ID Uploaded File
                _buildFileUploaderBox(
                  title: 'National ID / Kebele ID File *',
                  subtitle: 'Tap to upload ID photo or PDF document',
                  icon: Icons.badge_outlined,
                  fileName: _nationalIdFileName,
                  fileUrl: _nationalIdUrl,
                  isUploading: _isUploadingNationalId,
                  errorText: _nationalIdError,
                  onTap: () => _showDocumentPickerDialog(isNationalId: true),
                  onRemove: () => setState(() {
                    _nationalIdUrl = null;
                    _nationalIdFileName = null;
                  }),
                ),
                const SizedBox(height: 16),

                // 2.2 Medical Credential / Certificate Uploaded File
                _buildFileUploaderBox(
                  title: 'Medical Certificate / Board License File *',
                  subtitle: 'Tap to upload Certificate / Degree (PDF or Image)',
                  icon: Icons.file_present_rounded,
                  fileName: _credentialDocFileName,
                  fileUrl: _credentialDocUrl,
                  isUploading: _isUploadingCredential,
                  errorText: _credentialError,
                  onTap: () => _showDocumentPickerDialog(isNationalId: false),
                  onRemove: () => setState(() {
                    _credentialDocUrl = null;
                    _credentialDocFileName = null;
                  }),
                ),
                const SizedBox(height: 24),

                // ==========================================
                // SECTION 3: Licensing & Specialization
                // ==========================================
                _buildSectionHeader('3. Medical Licensing & Specialization'),
                const SizedBox(height: 12),

                // Medical License Number
                _buildTextField(
                  controller: _licenseController,
                  label: 'Medical License Number (e.g. LIC-OBGYN-88421)',
                  icon: Icons.credit_card_outlined,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Medical license number is required' : null,
                ),
                const SizedBox(height: 14),

                // License Expiration Date (with Date Picker)
                _buildTextField(
                  controller: _licenseExpiryController,
                  label: 'License Expiration Date (YYYY-MM-DD)',
                  icon: Icons.calendar_today_outlined,
                  readOnly: true,
                  onTap: _pickLicenseExpiryDate,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.date_range_rounded, color: AppColors.primary),
                    onPressed: _pickLicenseExpiryDate,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'License expiration date is required' : null,
                ),
                const SizedBox(height: 14),

                // Specialization dropdown
                DropdownButtonFormField<String>(
                  value: _selectedSpecialization,
                  decoration: InputDecoration(
                    labelText: 'Medical Specialization',
                    prefixIcon: const Icon(Icons.medical_services_outlined, color: AppColors.primary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  ),
                  items: _specializations
                      .map((spec) => DropdownMenuItem(value: spec, child: Text(spec, style: const TextStyle(fontSize: 14))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSpecialization = val);
                  },
                ),
                const SizedBox(height: 24),

                // ==========================================
                // SECTION 4: Hospital Affiliation & Practice
                // ==========================================
                _buildSectionHeader('4. Hospital Affiliation & Experience'),
                const SizedBox(height: 12),

                // Hospital / Clinic Name
                _buildTextField(
                  controller: _hospitalClinicController,
                  label: 'Hospital / Clinic Name (e.g. St. Paul Hospital)',
                  icon: Icons.apartment_rounded,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Hospital or clinic affiliation is required' : null,
                ),
                const SizedBox(height: 14),

                // Location / City
                _buildTextField(
                  controller: _locationController,
                  label: 'Practice Location / City (e.g. Addis Ababa, Ethiopia)',
                  icon: Icons.location_on_outlined,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Location is required' : null,
                ),
                const SizedBox(height: 14),

                // Years of Experience
                _buildTextField(
                  controller: _yearsExperienceController,
                  label: 'Years of Experience (e.g. 8)',
                  icon: Icons.timeline_rounded,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Years of experience is required';
                    final num = int.tryParse(v.trim());
                    if (num == null || num < 0 || num > 60) return 'Enter a valid number of years';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Professional Bio
                _buildTextField(
                  controller: _bioController,
                  label: 'Professional Bio & Clinical Background',
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Professional bio is required' : null,
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Submit Registration for Review',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
                const SizedBox(height: 20),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have a doctor account? ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildFileUploaderBox({
    required String title,
    required String subtitle,
    required IconData icon,
    required String? fileName,
    required String? fileUrl,
    required bool isUploading,
    required VoidCallback onTap,
    required VoidCallback onRemove,
    String? errorText,
  }) {
    final bool hasFile = fileUrl != null && fileUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: errorText != null
              ? AppColors.error
              : (hasFile ? AppColors.success.withValues(alpha: 0.6) : Colors.grey.shade300),
          width: hasFile ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hasFile ? AppColors.successBg : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasFile ? Icons.check_circle_rounded : icon,
                  color: hasFile ? AppColors.success : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasFile ? (fileName ?? 'Document Attached') : subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: hasFile ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: hasFile ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isUploading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              else if (hasFile)
                IconButton(
                  tooltip: 'Remove document',
                  icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                  onPressed: onRemove,
                )
              else
                ElevatedButton.icon(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.upload_rounded, size: 16),
                  label: const Text('Upload', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          if (hasFile) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, size: 13, color: AppColors.success),
                      SizedBox(width: 4),
                      Text('Uploaded ✓', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                  child: const Text('Change File', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
          if (errorText != null) ...[
            const SizedBox(height: 6),
            Text(
              errorText,
              style: const TextStyle(color: AppColors.error, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
    );
  }
}
