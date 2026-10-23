import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/screens/auth/login_page.dart';
import 'package:pregnancy_appp/screens/auth/otp_verification_page.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/auth_service.dart';
import 'package:pregnancy_appp/services/push_service.dart';
import 'package:pregnancy_appp/widget/status_modal.dart';

/// Shown to a mother whose account exists but is still `status = 'pending'`
/// in the backend. Automatically polls and listens to push/socket updates.
/// As soon as the admin approves the account, an OTP is dispatched via AfroMessage
/// and the user is guided to verify OTP, enter their LMP, and view their pregnancy week.
class PendingApprovalPage extends StatefulWidget {
  final String? phone;
  const PendingApprovalPage({super.key, this.phone});

  @override
  State<PendingApprovalPage> createState() => _PendingApprovalPageState();
}

class _PendingApprovalPageState extends State<PendingApprovalPage>
    with SingleTickerProviderStateMixin {
  bool _isChecking = false;
  bool _isLoggingOut = false;
  String _accountStatus = 'pending'; // 'pending' | 'active' | 'rejected'
  String? _userPhone;
  Timer? _pollTimer;
  StreamSubscription? _statusSubscription;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _userPhone = widget.phone;
    _resolveUserPhone();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initRealtimeListeners();

    // Start automatic polling every 6 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted && _accountStatus == 'pending') {
        _checkApprovalStatus(silent: true);
      }
    });

    // Initial check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkApprovalStatus(silent: true);
    });
  }

  Future<void> _resolveUserPhone() async {
    if (_userPhone == null || _userPhone!.isEmpty) {
      final savedPhone = await ApiService.getUserPhone();
      if (savedPhone != null && savedPhone.isNotEmpty && mounted) {
        setState(() => _userPhone = savedPhone);
      }
    }
  }

  Future<void> _initRealtimeListeners() async {
    try {
      final token = await ApiService.getToken();
      if (token != null && mounted) {
        // Connect socket to receive real-time 'user:approved' event
        PushService.connectSocket(
          token,
          (data) {},
          (notification) {
            final action = notification['data']?['action'] ?? notification['action'];
            if (action == 'account_approved' && mounted) {
              _onAccountApproved();
            }
          },
        );
      }

      // Listen to broadcast stream from PushService
      _statusSubscription = PushService.onStatusUpdate.listen((event) {
        if (!mounted) return;
        final status = event['status']?.toString();
        if (status == 'active' || event['approved'] == true) {
          _onAccountApproved();
        } else if (status == 'rejected') {
          setState(() => _accountStatus = 'rejected');
        }
      });
    } catch (e) {
      debugPrint('[PendingApproval] Listener setup note: $e');
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _statusSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkApprovalStatus({bool silent = false}) async {
    if (_isChecking) return;
    if (!silent) setState(() => _isChecking = true);

    try {
      final data = await AuthService.checkStatus();
      if (!mounted) return;

      final user = data['user'] as Map<String, dynamic>? ?? {};
      final phone = user['phone']?.toString();
      if (phone != null && phone.isNotEmpty) {
        _userPhone = phone;
        await ApiService.saveUserPhone(phone);
      }

      final status = data['status']?.toString() ?? 'pending';
      final isApproved = data['isApproved'] == true || status == 'active';
      final isRejected = data['isRejected'] == true || status == 'rejected';

      if (isApproved) {
        _onAccountApproved(phone: phone);
        return;
      }

      if (isRejected) {
        setState(() => _accountStatus = 'rejected');
        _pollTimer?.cancel();
        if (!silent) {
          AppStatusModal.showError(
            context: context,
            title: 'Application Not Approved',
            message: 'Your registration was reviewed and could not be approved at this time. Please contact support.',
          );
        }
        return;
      }

      // Still pending
      setState(() => _accountStatus = 'pending');
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF61183E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Text(
              'Your account is still under admin review. Once approved, an OTP will be sent to your phone!',
              style: TextStyle(color: Colors.white),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not check status: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted && !silent) {
        setState(() => _isChecking = false);
      }
    }
  }

  void _onAccountApproved({String? phone}) async {
    _pollTimer?.cancel();
    _statusSubscription?.cancel();
    setState(() => _accountStatus = 'active');

    final targetPhone = phone ?? _userPhone ?? await ApiService.getUserPhone();

    // Trigger local welcome notification banner
    await PushService.showWelcomeNotification();

    // Request AfroMessage OTP for login
    if (targetPhone != null && targetPhone.isNotEmpty) {
      try {
        await AuthService.sendOtp(phone: targetPhone);
      } catch (e) {
        debugPrint('[PendingApproval] Note sending OTP: $e');
      }
    }

    if (!mounted) return;

    AppStatusModal.showSuccess(
      context: context,
      title: 'Account Approved! 🎉',
      message: targetPhone != null && targetPhone.isNotEmpty
          ? 'Your account has been approved by the  admin! A 6-digit login verification code was sent to $targetPhone via AfroMessage.\n\nPlease enter the code to verify your phone and enter your pregnancy details.'
          : 'Your account has been approved by the  admin! Please verify your login to continue.',
      buttonText: 'Verify OTP & Setup Week',
      onDismiss: () {
        if (!mounted) return;
        if (targetPhone != null && targetPhone.isNotEmpty) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationPage(
                isLogin: true,
                phone: targetPhone,
              ),
            ),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      },
    );
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);
    _pollTimer?.cancel();
    _statusSubscription?.cancel();
    await ApiService.clearSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRejected = _accountStatus == 'rejected';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F5),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _checkApprovalStatus(silent: false),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 100,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Animated Hero Icon
                  Center(
                    child: ScaleTransition(
                      scale: isRejected
                          ? const AlwaysStoppedAnimation(1.0)
                          : _pulseAnimation,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: isRejected
                              ? Colors.red.shade50
                              : AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: isRejected
                                  ? Colors.red.withValues(alpha: 0.15)
                                  : AppColors.primary.withValues(alpha: 0.18),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          isRejected
                              ? Icons.error_outline_rounded
                              : Icons.hourglass_top_rounded,
                          color: isRejected ? Colors.red : AppColors.primary,
                          size: 54,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Status Tag Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isRejected
                            ? Colors.red.shade50
                            : const Color(0xFFFFF7ED),
                        border: Border.all(
                          color: isRejected
                              ? Colors.red.shade200
                              : const Color(0xFFFDBA74),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isRejected
                                  ? Colors.red
                                  : const Color(0xFFEA580C),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isRejected
                                ? 'Application Status: Not Approved'
                                : 'Status: Waiting for Admin Approval',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isRejected
                                  ? Colors.red.shade800
                                  : const Color(0xFFC2410C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Main Heading
                  Text(
                    isRejected
                        ? 'Account Review Finished'
                        : 'Waiting for Approval',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D1625),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Descriptive text
                  Text(
                    isRejected
                        ? 'Your mother account was not approved by the admin. Please get in touch with your care provider or clinic.'
                        : 'Your account is waiting for admin approval.\nOnce approved, an SMS OTP will be sent to your phone so you can log in and filter your pregnancy week.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Display phone number if known
                  if (_userPhone != null && _userPhone!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone_android_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Registered Phone: $_userPhone',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),

                  // Notification promise
                  if (!isRejected)
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sms_outlined,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'AfroMessage will deliver your login verification code automatically when the admin confirms your registration.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Check Status Button
                  if (!isRejected) ...[
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isChecking
                            ? null
                            : () => _checkApprovalStatus(silent: false),
                        icon: _isChecking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, size: 20),
                        label: Text(
                          _isChecking ? 'Checking...' : 'Check Status Now',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Logout / Switch Account Button
                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _isLoggingOut ? null : _handleLogout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF61183E),
                        side: const BorderSide(
                          color: Color(0xFFE5D5DD),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoggingOut
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Log out / Switch Account',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
