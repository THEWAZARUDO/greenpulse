import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/farm_model.dart';
import '../../services/firestore_service.dart';
import '../../services/rtdb_service.dart';
import '../provision_screen.dart';
import 'farms_tab/farm_management_card.dart';
import 'farms_tab/farm_dialogs.dart';
import 'farms_tab/farms_empty_view.dart';

export 'farms_tab/sensor_row.dart';
export 'farms_tab/farm_management_card.dart';
export 'farms_tab/farm_dialogs.dart';
export 'farms_tab/farms_empty_view.dart';

class FarmsTab extends StatelessWidget {
  const FarmsTab({super.key});

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
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10, right: 2),
          child: ClipOval(
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: const Text(
          'Quản lý Nông trại',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Kết nối thiết bị ESP32 mới',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.developer_board, size: 20),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProvisionScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: StreamBuilder<List<FarmModel>>(
        stream: firestoreService.watchFarms(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            );
          }

          final farms = snapshot.data ?? [];
          if (farms.isEmpty) {
            return FarmsEmptyView(
              onAddFarm: () => FarmDialogs.showAddFarm(
                context,
                user.uid,
                firestoreService,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: farms.length,
            itemBuilder: (context, index) {
              return FarmManagementCard(
                uid: user.uid,
                farm: farms[index],
                firestoreService: firestoreService,
                rtdbService: rtdbService,
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ESP32 FAB
          FloatingActionButton.small(
            heroTag: 'fab_device',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProvisionScreen()),
            ),
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            tooltip: 'Kết nối ESP32 mới',
            child: const Icon(Icons.developer_board, size: 20),
          ),
          const SizedBox(height: 10),
          // Add Farm FAB
          FloatingActionButton.extended(
            heroTag: 'fab_add',
            onPressed: () => FarmDialogs.showAddFarm(
              context,
              user.uid,
              firestoreService,
            ),
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text(
              'Thêm Farm',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
