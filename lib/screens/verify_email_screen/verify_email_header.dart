import 'package:flutter/material.dart';

class VerifyEmailHeader extends StatelessWidget {
  final String email;

  const VerifyEmailHeader({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
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
                text: 'Chúng tôi đã gửi một liên kết xác thực đến địa chỉ:\n',
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
      ],
    );
  }
}
