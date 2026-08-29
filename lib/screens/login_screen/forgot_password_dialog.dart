import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

class ForgotPasswordDialog {
  static void show(BuildContext context, {String initialEmail = ''}) {
    final resetEmailCtrl = TextEditingController(text: initialEmail);
    final dialogFormKey = GlobalKey<FormState>();
    final authService = AuthService();
    bool sending = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: const [
                  Icon(Icons.lock_reset, color: Color(0xFF2E7D32)),
                  SizedBox(width: 8),
                  Text(
                    'Quên mật khẩu?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: Form(
                key: dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nhập địa chỉ email đăng ký của bạn. Chúng tôi sẽ gửi một liên kết để bạn thiết lập lại mật khẩu.',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: resetEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email đăng ký',
                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF6FAF6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        if (!v.contains('@')) return 'Email không hợp lệ';
                        return null;
                      },
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        dialogError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: sending ? null : () => Navigator.pop(ctx),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: sending
                      ? null
                      : () async {
                          if (!dialogFormKey.currentState!.validate()) return;
                          setDialogState(() {
                            sending = true;
                            dialogError = null;
                          });
                          try {
                            await authService.sendPasswordResetEmail(
                              email: resetEmailCtrl.text,
                            );
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Đã gửi email khôi phục! Vui lòng kiểm tra hộp thư của bạn.',
                                  ),
                                  backgroundColor: Color(0xFF1B5E20),
                                ),
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() {
                              sending = false;
                              if (e.code == 'user-not-found') {
                                dialogError =
                                    'Tài khoản email này chưa được đăng ký.';
                              } else if (e.code == 'invalid-email') {
                                dialogError = 'Địa chỉ email không hợp lệ.';
                              } else {
                                dialogError =
                                    'Không thể gửi email. Vui lòng thử lại sau.';
                              }
                            });
                          } catch (_) {
                            setDialogState(() {
                              sending = false;
                              dialogError = 'Đã xảy ra lỗi. Vui lòng thử lại.';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Gửi yêu cầu'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
