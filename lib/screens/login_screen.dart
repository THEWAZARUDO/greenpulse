import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'login_screen/login_header.dart';
import 'login_screen/login_form.dart';
import 'login_screen/forgot_password_dialog.dart';

export 'login_screen/login_header.dart';
export 'login_screen/login_form.dart';
export 'login_screen/forgot_password_dialog.dart';

/// Màn hình đăng nhập – kết nối thật với Firebase Auth.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    // Yêu cầu quyền thông báo ngay khi giao diện hiển thị
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().requestPermissions();
    });

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await _authService.signIn(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _mapFirebaseError(e.code));
    } on Exception catch (e) {
      final msg = e.toString().toLowerCase();
      setState(
        () =>
            _errorMessage = (msg.contains('network') || msg.contains('socket'))
            ? 'Không có kết nối mạng. Kiểm tra Wi-Fi hoặc dữ liệu di động.'
            : 'Đã xảy ra lỗi. Vui lòng thử lại.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng.';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa. Liên hệ quản trị viên để được hỗ trợ.';
      case 'too-many-requests':
        return 'Quá nhiều lần đăng nhập thất bại. Vui lòng đợi vài phút rồi thử lại.';
      case 'network-request-failed':
        return 'Không có kết nối mạng. Kiểm tra Wi-Fi hoặc dữ liệu di động.';
      case 'permission-denied':
      case 'api-key-not-valid':
        return 'Dịch vụ tạm thời gián đoạn. Vui lòng thử lại sau hoặc liên hệ quản trị viên.';
      case 'internal-error':
        return 'Lỗi máy chủ. Vui lòng thử lại sau.';
      default:
        return 'Đăng nhập thất bại. Vui lòng thử lại.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient Background ──────────────────────────────────────────
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
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
          // ── Decorative Circles ───────────────────────────────────────────
          const Positioned(
            top: -100,
            right: -70,
            child: DecorativeCircle(size: 260, opacity: 0.06),
          ),
          const Positioned(
            top: 80,
            right: 60,
            child: DecorativeCircle(size: 80, opacity: 0.04),
          ),
          const Positioned(
            bottom: -120,
            left: -80,
            child: DecorativeCircle(size: 320, opacity: 0.05),
          ),
          const Positioned(
            bottom: 160,
            left: 30,
            child: DecorativeCircle(size: 50, opacity: 0.07),
          ),
          // ── Main Content ─────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      children: [
                        const LoginHeader(),
                        const SizedBox(height: 36),
                        LoginFormCard(
                          formKey: _formKey,
                          emailCtrl: _emailCtrl,
                          passwordCtrl: _passwordCtrl,
                          loading: _loading,
                          obscurePassword: _obscurePassword,
                          errorMessage: _errorMessage,
                          onTogglePassword: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                          onForgotPassword: () =>
                              ForgotPasswordDialog.show(context, initialEmail: _emailCtrl.text.trim()),
                          onSubmit: _submit,
                        ),
                      ],
                    ),
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
