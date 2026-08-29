import 'package:flutter/material.dart';

class VerifyEmailActions extends StatelessWidget {
  final bool loadingCheck;
  final bool canResendEmail;
  final int resendCountdown;
  final VoidCallback onManualCheck;
  final VoidCallback onResendEmail;
  final VoidCallback onSignOut;

  const VerifyEmailActions({
    super.key,
    required this.loadingCheck,
    required this.canResendEmail,
    required this.resendCountdown,
    required this.onManualCheck,
    required this.onResendEmail,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Button 1: Kiểm tra ngay
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: loadingCheck ? null : onManualCheck,
            icon: loadingCheck
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
            onPressed: canResendEmail ? onResendEmail : null,
            icon: const Icon(Icons.send_outlined, size: 18),
            label: Text(
              canResendEmail
                  ? 'Gửi lại email xác minh'
                  : 'Gửi lại sau (${resendCountdown}s)',
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
          onPressed: onSignOut,
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
    );
  }
}
