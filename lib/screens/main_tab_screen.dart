import 'dart:async';
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

  StreamSubscription? _farmsSub;
  final Map<String, StreamSubscription> _sensorSubs = {};
  StreamSubscription? _authSub;

  static const List<Widget> _tabs = [
    DashboardTab(),
    FarmsTab(),
    AlertsTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _listenToAlerts();
    // Lắng nghe trạng thái Auth để hủy toàn bộ stream khi đăng xuất
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _cancelAllSubscriptions();
      }
    });
  }

  void _listenToAlerts() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Kích hoạt Firebase Cloud Messaging (FCM) nhận Push Notification 24/7
    NotificationService().setupFCM(user.uid);

    _farmsSub = _firestoreService.watchFarms(user.uid).listen((farms) {
      final currentFarmIds = farms.map((f) => f.id).toSet();
      _sensorSubs.removeWhere((id, sub) {
        if (!currentFarmIds.contains(id)) {
          sub.cancel();
          return true;
        }
        return false;
      });

      for (var farm in farms) {
        if (!_sensorSubs.containsKey(farm.id)) {
          _sensorSubs[farm
              .id] = _rtdbService.watchSensors(user.uid, farm.id).listen((
            sensors,
          ) {
            bool hasAlert = false;
            String? alertMsg;

            for (var sensor in sensors) {
              if (sensor.overallStatus != StatusLevel.normal) {
                hasAlert = true;
                alertMsg =
                    '${farm.name} - Cảm biến ${sensor.id}: ${sensor.overallStatus.label}!';
              }
            }

            if (mounted &&
                (_isRedAlertMode != hasAlert || _redAlertMessage != alertMsg)) {
              setState(() {
                _isRedAlertMode = hasAlert;
                _redAlertMessage = alertMsg;
              });
            }
          });
        }
      }
    });
  }

  /// Hủy toàn bộ stream subscriptions (farms + sensors)
  void _cancelAllSubscriptions() {
    _farmsSub?.cancel();
    _farmsSub = null;
    for (var sub in _sensorSubs.values) {
      sub.cancel();
    }
    _sensorSubs.clear();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _cancelAllSubscriptions();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
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
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CẢNH BÁO ĐỎ - PHÁT HIỆN SỰ CỐ',
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
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${NotificationService().alertFrequencyMinutes} phút/lần',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Main Tab View ──────────────────────────────────────────────────
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _tabs),
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
              ? const Border(
                  top: BorderSide(color: Color(0xFFD32F2F), width: 2),
                )
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
              ? const Color(0xFFFFCDD2)
              : const Color(0xFFC8E6C9),
          animationDuration: const Duration(milliseconds: 300),
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
