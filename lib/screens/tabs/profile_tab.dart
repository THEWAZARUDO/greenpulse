import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/plant_preset_manager.dart';
import '../../services/rtdb_service.dart';
import '../../services/notification_service.dart';
import '../../models/farm_model.dart';

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

          // Initial letter for avatar
          final initial = username.isNotEmpty ? username[0].toUpperCase() : 'G';

          return CustomScrollView(
            slivers: [
              // ── Gradient Header ──────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 220,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: const Color(0xFF1B5E20),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF1A3C34),
                          Color(0xFF1B5E20),
                          Color(0xFF2E7D32),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          // Avatar
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 34,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              // Edit badge
                              GestureDetector(
                                onTap: () => _showEditNameDialog(
                                  context,
                                  user.uid,
                                  username,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.15,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 14,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Name
                          Text(
                            username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email ?? '',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Role badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.eco, size: 13, color: Colors.white),
                                SizedBox(width: 5),
                                Text(
                                  'Nông hộ GreenPulse',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                      _SectionCard(
                        title: 'Tài khoản',
                        icon: Icons.manage_accounts_outlined,
                        children: [
                          _SettingsTile(
                            icon: Icons.person_outline,
                            label: 'Đổi tên hiển thị',
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                            ),
                            onTap: () => _showEditNameDialog(
                              context,
                              user.uid,
                              username,
                            ),
                          ),
                          _SettingsTile(
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
                      const _ThresholdReferenceCard(),
                      const SizedBox(height: 14),

                      // Thiết lập Thông báo & Cảnh báo card (Dropdown 1 đến 10 phút)
                      StatefulBuilder(
                        builder: (context, setCardState) {
                          final currentFreq =
                              NotificationService().alertFrequencyMinutes;
                          return _SectionCard(
                            title: 'Thiết lập Thông báo & Cảnh báo',
                            icon: Icons.notifications_active_outlined,
                            children: [
                              _SettingsTile(
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
                                        (index) => (index + 1)*5,
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
                      _SectionCard(
                        title: 'Về ứng dụng',
                        icon: Icons.info_outline,
                        children: [
                          _SettingsTile(
                            icon: Icons.verified_outlined,
                            label: 'Phiên bản',
                            trailing: const Text(
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
                          onPressed: () => _confirmSignOut(context),
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
                          onPressed: () => _confirmDeleteAccount(context),
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

  void _showEditNameDialog(
    BuildContext context,
    String uid,
    String currentName,
  ) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đổi tên hiển thị'),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: 'Tên mới',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.person_outline),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.of(ctx).pop();
              await FirestoreService().updateUsername(uid, ctrl.text.trim());
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi ứng dụng không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await AuthService().signOut();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi đăng xuất: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Xóa tài khoản'),
          ],
        ),
        content: const Text(
          'Hành động này sẽ xóa vĩnh viễn tài khoản của bạn và toàn bộ cấu hình trang trại trên hệ thống. Bạn không thể khôi phục lại dữ liệu sau khi xóa.\n\nBạn có chắc chắn muốn xóa không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await AuthService().deleteAccount();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khi xóa tài khoản: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Xác nhận Xóa'),
          ),
        ],
      ),
    );
  }
}

// ── Reusable section card ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? titleTrailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.titleTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      shadowColor: Colors.black.withValues(alpha: 0.2),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF2E7D32)),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ),
                ?titleTrailing,
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Settings row tile ─────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF2E7D32)),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

// ── Threshold row ─────────────────────────────────────────────────────────────

class _ThresholdRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ThresholdRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: color,
        ),
      ),
    );
  }
}

// ── Stateful Threshold Reference Card ──────────────────────────────────────────

class _ThresholdReferenceCard extends StatefulWidget {
  const _ThresholdReferenceCard();

  @override
  State<_ThresholdReferenceCard> createState() =>
      _ThresholdReferenceCardState();
}

class _ThresholdReferenceCardState extends State<_ThresholdReferenceCard> {
  String? _selectedSensorId;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox();

    return StreamBuilder<List<SensorData>>(
      stream: RTDBService().watchAllSensors(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _SectionCard(
            title: 'Ngưỡng an toàn cây trồng',
            icon: Icons.tune_outlined,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ],
          );
        }

        final sensors = snapshot.data!;
        if (sensors.isEmpty) {
          return const _SectionCard(
            title: 'Ngưỡng an toàn cây trồng',
            icon: Icons.tune_outlined,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text('Bạn chưa có mạch/cảm biến nào.'),
              ),
            ],
          );
        }

        // Đảm bảo selectedSensorId hợp lệ
        if (_selectedSensorId == null ||
            !sensors.any((s) => s.id == _selectedSensorId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedSensorId = sensors.first.id);
          });
        }

        final safeSensorId = _selectedSensorId ?? sensors.first.id;
        final selectedSensor = sensors.firstWhere(
          (s) => s.id == safeSensorId,
          orElse: () => sensors.first,
        );

        final crop = PlantPresetManager.getCropById(selectedSensor.cropId);
        final stage = crop?.getStageById(selectedSensor.stageId);

        return _SectionCard(
          title: 'Ngưỡng an toàn cho cây trồng.',
          icon: Icons.tune_outlined,
          titleTrailing: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isDense: true,
                value: safeSensorId,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: Color(0xFF2E7D32),
                ),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
                items: sensors.map((sensor) {
                  String display = sensor.id;
                  if (display.length > 10) {
                    display = '${display.substring(0, 10)}...';
                  }
                  return DropdownMenuItem<String>(
                    value: sensor.id,
                    child: Text(display),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSensorId = val);
                },
              ),
            ),
          ),
          children: (crop == null || stage == null)
              ? [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Không có dữ liệu loại cây'),
                  ),
                ]
              : [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'Cây: ${crop.cropName} • Giai đoạn: ${stage.stageName}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                  _ThresholdRow(
                    icon: Icons.science_outlined,
                    label: 'Độ pH đất an toàn',
                    value: '${crop.soilPhMin} – ${crop.soilPhMax} pH',
                    color: const Color(0xFF8E24AA),
                  ),
                  _ThresholdRow(
                    icon: Icons.thermostat_outlined,
                    label: 'Nhiệt độ tối ưu',
                    value: '${stage.tempMin} – ${stage.tempMax} °C',
                    color: const Color(0xFFEF5350),
                  ),
                  _ThresholdRow(
                    icon: Icons.water_drop_outlined,
                    label: 'Độ ẩm không khí',
                    value: '${stage.airHumidityMin} – ${stage.airHumidityMax} %',
                    color: const Color(0xFF42A5F5),
                  ),
                  _ThresholdRow(
                    icon: Icons.grass_outlined,
                    label: 'Độ ẩm đất tối ưu',
                    value: '${stage.soilMoistureMin} – ${stage.soilMoistureMax} %',
                    color: const Color(0xFF8D6E63),
                  ),
                  _ThresholdRow(
                    icon: Icons.wb_sunny_outlined,
                    label: 'Ánh sáng tối ưu',
                    value: '${stage.luxMin} – ${stage.luxMax} lux',
                    color: const Color(0xFFFFA726),
                  ),
                ],
        );
      },
    );
  }
}
