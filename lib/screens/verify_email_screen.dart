import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'main_tab_screen.dart';
import 'verify_email_screen/verify_email_header.dart';
import 'verify_email_screen/verify_email_actions.dart';

export 'verify_email_screen/verify_email_header.dart';
export 'verify_email_screen/verify_email_actions.dart';

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
                      VerifyEmailHeader(email: email),
                      const SizedBox(height: 24),
                      VerifyEmailActions(
                        loadingCheck: _loadingCheck,
                        canResendEmail: _canResendEmail,
                        resendCountdown: _resendCountdown,
                        onManualCheck: _manualCheck,
                        onResendEmail: _resendVerificationEmail,
                        onSignOut: () => _authService.signOut(),
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
