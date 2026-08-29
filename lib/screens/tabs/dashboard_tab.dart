import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/farm_model.dart';
import '../../services/firestore_service.dart';
import '../../services/rtdb_service.dart';
import '../../widgets/weather_card.dart';
import 'dashboard_tab/dashboard_header.dart';
import 'dashboard_tab/farm_dashboard_card.dart';
import 'dashboard_tab/dashboard_empty_view.dart';

export 'dashboard_tab/dashboard_header.dart';
export 'dashboard_tab/status_badge.dart';
export 'dashboard_tab/metric_tile.dart';
export 'dashboard_tab/sensor_metrics_view.dart';
export 'dashboard_tab/farm_dashboard_card.dart';
export 'dashboard_tab/dashboard_empty_view.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Vui lòng đăng nhập'));
    }

    final firestoreService = FirestoreService();
    final rtdbService = RTDBService();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F0),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────
          DashboardHeader(user: user, firestoreService: firestoreService),

          // ── Weather Forecast Banner ──────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: WeatherCard(),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: StreamBuilder<List<FarmModel>>(
              stream: firestoreService.watchFarms(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return DashboardErrorView(error: '${snapshot.error}');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(60),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  );
                }

                final farms = snapshot.data ?? [];
                if (farms.isEmpty) {
                  return const DashboardEmptyView();
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF2E7D32,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.dashboard_outlined,
                              size: 16,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${farms.length} trang trại đang giám sát',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...farms.map(
                        (farm) => FarmDashboardCard(
                          uid: user.uid,
                          farm: farm,
                          rtdbService: rtdbService,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}