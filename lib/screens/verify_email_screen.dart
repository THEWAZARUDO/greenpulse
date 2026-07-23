import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'main_tab_screen.dart';

/// Màn hình chờ xác thực Email
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _authService = AuthService();
  bool _canResendEmail = true;
  bool _loadingCheck = false;
  int _resendCountdown = 0;

  Timer? _timer;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.emailVerified) {
      // Nếu đã xác thực trước đó, chuyển ngay đến Dashboard
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToDashboard();
      });
    } else {
      // Tự động kiểm tra trạng thái mỗi 3 giây bằng cách reload user
      _timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _navigateToDashboard() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainTabScreen()),
      (route) => false,
    );
  }

  Future<void> _checkEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await user.reload();
      final reloadedUser = FirebaseAuth.instance.currentUser;

      if (reloadedUser != null && reloadedUser.emailVerified) {
        _timer?.cancel();
        _navigateToDashboard();
      }
    } catch (_) {}
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResendEmail) return;

    // Bắt đầu đếm ngược 60s lập tức để ngăn bấm liên tục
    _startCountdown();

    try {
      await _authService.sendEmailVerification();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã gửi lại link xác thực! Vui lòng kiểm tra hộp thư của bạn.',
          ),
          backgroundColor: Color(0xFF1B5E20),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = 'Không thể gửi lại email. Vui lòng thử lại sau.';
      if (e.code == 'too-many-requests') {
        msg =
            'Link xác thực đã được gửi gần đây. Vui lòng kiểm tra hòm thư (kể cả mục Spam) hoặc đợi 60s rồi gửi lại.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã xảy ra lỗi. Vui lòng thử lại sau.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _startCountdown() {
    setState(() {
      _canResendEmail = false;
      _resendCountdown = 60;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _canResendEmail = true;
            _resendCountdown = 0;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _resendCountdown--;
          });
        }
      }
    });
  }

  Future<void> _manualCheck() async {
    setState(() => _loadingCheck = true);
    await _checkEmailVerified();
    if (mounted) {
      setState(() => _loadingCheck = false);
      final isVerified =
          FirebaseAuth.instance.currentUser?.emailVerified ?? false;
      if (!isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa ghi nhận xác thực. Vui lòng bấm vào liên kết trong email trước.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1A3C34),
                  Color(0xFF1B5E20),
                  Color(0xFF2E7D32),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon & Badge
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFA5D6A7),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.mark_email_unread_outlined,
                          size: 56,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      const Text(
                        'Xác Thực Email Của Bạn',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(
                              text:
                                  'Chúng tôi đã gửi một liên kết xác thực đến địa chỉ:\n',
                            ),
                            TextSpan(
                              text: email,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const TextSpan(
                              text:
                                  '\n\nVui lòng kiểm tra hộp thư (bao gồm cả thư rác/Spam) và nhấn vào liên kết để kích hoạt tài khoản.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Progress indicator / Pulse info
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8E9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Row(
                          children: const [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Tự động kiểm tra sau mỗi 3 giây...',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Button 1: Kiểm tra ngay
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _loadingCheck ? null : _manualCheck,
                          icon: _loadingCheck
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.refresh, size: 20),
                          label: const Text(
                            'Tôi đã bấm link xác thực / Kiểm tra ngay',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Button 2: Gửi lại email
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _canResendEmail
                              ? _resendVerificationEmail
                              : null,
                          icon: const Icon(Icons.send_outlined, size: 18),
                          label: Text(
                            _canResendEmail
                                ? 'Gửi lại email xác minh'
                                : 'Gửi lại sau (${_resendCountdown}s)',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2E7D32),
                            side: const BorderSide(color: Color(0xFF81C784)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Button 3: Đăng xuất
                      TextButton.icon(
                        onPressed: () => _authService.signOut(),
                        icon: const Icon(
                          Icons.logout,
                          size: 18,
                          color: Colors.grey,
                        ),
                        label: const Text(
                          'Đăng xuất / Dùng tài khoản khác',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
