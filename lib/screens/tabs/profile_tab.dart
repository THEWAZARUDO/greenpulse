import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import 'profile_tab/profile_header.dart';
import 'profile_tab/section_card.dart';
import 'profile_tab/settings_tile.dart';
import 'profile_tab/threshold_reference_card.dart';
import 'profile_tab/profile_dialogs.dart';

export 'profile_tab/profile_header.dart';
export 'profile_tab/section_card.dart';
export 'profile_tab/settings_tile.dart';
export 'profile_tab/threshold_row.dart';
export 'profile_tab/threshold_reference_card.dart';
export 'profile_tab/profile_dialogs.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Vui lòng đăng nhập'));
    }

    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F0),
      body: StreamBuilder<UserModel?>(
        stream: firestoreService.watchUser(user.uid),
        builder: (context, snapshot) {
          final userModel = snapshot.data;
          final username = userModel?.username.isNotEmpty == true
              ? userModel!.username
              : (user.displayName?.isNotEmpty == true
                    ? user.displayName!
                    : 'Người dùng GreenPulse');

          return CustomScrollView(
            slivers: [
              // ── Gradient Header ──────────────────────────────────────────
              ProfileHeader(
                username: username,
                email: user.email ?? '',
                onEditName: () => ProfileDialogs.showEditName(
                  context,
                  user.uid,
                  username,
                ),
              ),

              // ── Body ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Actions card
                      SectionCard(
                        title: 'Tài khoản',
                        icon: Icons.manage_accounts_outlined,
                        children: [
                          SettingsTile(
                            icon: Icons.person_outline,
                            label: 'Đổi tên hiển thị',
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                            ),
                            onTap: () => ProfileDialogs.showEditName(
                              context,
                              user.uid,
                              username,
                            ),
                          ),
                          SettingsTile(
                            icon: Icons.email_outlined,
                            label: user.email ?? '',
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Đã xác thực',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Threshold reference card
                      const ThresholdReferenceCard(),
                      const SizedBox(height: 14),

                      // Thiết lập Thông báo & Cảnh báo card (Dropdown 5 đến 30 phút)
                      StatefulBuilder(
                        builder: (context, setCardState) {
                          final currentFreq =
                              NotificationService().alertFrequencyMinutes;
                          return SectionCard(
                            title: 'Thiết lập Thông báo & Cảnh báo',
                            icon: Icons.notifications_active_outlined,
                            children: [
                              SettingsTile(
                                icon: Icons.timer_outlined,
                                label: 'Tần suất thông báo cảnh báo',
                                trailing: Container(
                                  height: 30,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFA5D6A7),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      isDense: true,
                                      value: currentFreq,
                                      icon: const Icon(
                                        Icons.arrow_drop_down,
                                        size: 18,
                                        color: Color(0xFF2E7D32),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1B5E20),
                                      ),
                                      items: List.generate(
                                        6,
                                        (index) => (index + 1) * 5,
                                      ).map((min) {
                                        return DropdownMenuItem<int>(
                                          value: min,
                                          child: Text('$min phút / lần'),
                                        );
                                      }).toList(),
                                      onChanged: (int? newMin) {
                                        if (newMin != null) {
                                          NotificationService()
                                              .setAlertFrequencyMinutes(newMin);
                                          setCardState(() {});
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Đã cập nhật tần suất thông báo: $newMin phút/lần',
                                              ),
                                              backgroundColor: const Color(
                                                0xFF2E7D32,
                                              ),
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // App info card
                      const SectionCard(
                        title: 'Về ứng dụng',
                        icon: Icons.info_outline,
                        children: [
                          SettingsTile(
                            icon: Icons.verified_outlined,
                            label: 'Phiên bản',
                            trailing: Text(
                              'v1.0.0',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Sign out button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => ProfileDialogs.confirmSignOut(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade800,
                            side: BorderSide(
                              color: Colors.grey.shade400,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text(
                            'Đăng xuất tài khoản',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Delete account button (Google Play standard)
                      Center(
                        child: TextButton.icon(
                          onPressed: () => ProfileDialogs.confirmDeleteAccount(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade600,
                          ),
                          icon: const Icon(Icons.delete_forever_outlined, size: 16),
                          label: const Text(
                            'Xóa vĩnh viễn tài khoản & dữ liệu',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
