import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/farm_model.dart';
import '../services/firestore_service.dart';
import '../services/rtdb_service.dart';
import '../services/notification_service.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/farms_tab.dart';
import 'tabs/alerts_tab.dart';
import 'tabs/profile_tab.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;
  bool _isRedAlertMode = false;
  String? _redAlertMessage;

  final FirestoreService _firestoreService = FirestoreService();
  final RTDBService _rtdbService = RTDBService();
  final NotificationService _notificationService = NotificationService();

  final List<Widget> _tabs = const [
    DashboardTab(),
    FarmsTab(),
    AlertsTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Column(
        children: [
          // ── Stream Listener phát hiện Cảnh báo & Đổi Chế độ Màu Đỏ ─────────────
          if (user != null)
            StreamBuilder<List<FarmModel>>(
              stream: _firestoreService.watchFarms(user.uid),
              builder: (context, farmSnap) {
                final farms = farmSnap.data ?? [];
                if (farms.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: farms.map((farm) {
                    return StreamBuilder<List<SensorData>>(
                      stream: _rtdbService.watchSensors(user.uid, farm.id),
                      builder: (context, sensorSnap) {
                        final sensors = sensorSnap.data ?? [];
                        bool hasAlert = false;
                        String? alertMsg;

                        for (var sensor in sensors) {
                          if (sensor.overallStatus != StatusLevel.normal) {
                            hasAlert = true;
                            alertMsg =
                                '${farm.name} - Cảm biến ${sensor.id}: ${sensor.overallStatus.label}!';
                            // Xử lý thông báo đẩy 1 phút / 1 lần lên điện thoại
                            _notificationService.processSensorAlerts(
                                farm.name, sensor);
                          }
                        }

                        // Cập nhật chế độ Màu Đỏ Khẩn Cấp
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && (_isRedAlertMode != hasAlert || _redAlertMessage != alertMsg)) {
                            setState(() {
                              _isRedAlertMode = hasAlert;
                              _redAlertMessage = alertMsg;
                            });
                          }
                        });

                        return const SizedBox.shrink();
                      },
                    );
                  }).toList(),
                );
              },
            ),

          // ── Top Red Alert Banner ───────────────────────────────────────────
          if (_isRedAlertMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🚨 CẢNH BÁO ĐỎ - PHÁT HIỆN SỰ CỐ',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            _redAlertMessage ??
                                'Thông số nông trại vượt ngưỡng an toàn!',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '1 phút/lần',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Main Tab View ──────────────────────────────────────────────────
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _tabs,
            ),
          ),
        ],
      ),

      // ── NavigationBar (Đổi sang tông màu Đỏ khi ở Red Alert Mode) ───────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
          border: _isRedAlertMode
              ? const Border(top: BorderSide(color: Color(0xFFD32F2F), width: 2))
              : null,
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          height: 68,
          backgroundColor: Colors.white,
          indicatorColor: _isRedAlertMode
              ? const Color(0xFFFFCDD2) // Màu đỏ nhạt khi Red Alert
              : const Color(0xFFC8E6C9), // Màu xanh nõn chuối bình thường
          animationDuration: const Duration(milliseconds: 400),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined, size: 22),
              selectedIcon: Icon(
                Icons.dashboard_rounded,
                color: _isRedAlertMode
                    ? const Color(0xFFD32F2F)
                    : const Color(0xFF1B5E20),
                size: 22,
              ),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: const Icon(Icons.landscape_outlined, size: 22),
              selectedIcon: Icon(
                Icons.landscape_rounded,
                color: _isRedAlertMode
                    ? const Color(0xFFD32F2F)
                    : const Color(0xFF1B5E20),
                size: 22,
              ),
              label: 'Nông trại',
            ),
            NavigationDestination(
              icon: const Icon(Icons.notifications_outlined, size: 22),
              selectedIcon: Icon(
                Icons.notifications_rounded,
                color: _isRedAlertMode
                    ? const Color(0xFFD32F2F)
                    : const Color(0xFF1B5E20),
                size: 22,
              ),
              label: 'Cảnh báo AI',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded, size: 22),
              selectedIcon: Icon(
                Icons.person_rounded,
                color: _isRedAlertMode
                    ? const Color(0xFFD32F2F)
                    : const Color(0xFF1B5E20),
                size: 22,
              ),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }
}
