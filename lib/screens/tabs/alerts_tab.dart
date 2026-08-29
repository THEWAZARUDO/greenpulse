import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/farm_model.dart';
import '../../services/firestore_service.dart';
import '../../services/rtdb_service.dart';
import 'alerts_tab/alert_card.dart';
import 'alerts_tab/empty_alerts_view.dart';

export 'alerts_tab/alert_card.dart';
export 'alerts_tab/empty_alerts_view.dart';

class AlertsTab extends StatelessWidget {
  const AlertsTab({super.key});

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
        title: const Text(
          'Cảnh báo & Khuyến nghị AI',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<FarmModel>>(
        stream: firestoreService.watchFarms(user.uid),
        builder: (context, farmSnap) {
          if (farmSnap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            );
          }

          final farms = farmSnap.data ?? [];
          if (farms.isEmpty) {
            return const EmptyAlertsView();
          }

          return StreamBuilder<List<SensorData>>(
            stream: rtdbService.watchAllSensors(user.uid),
            builder: (context, sensorSnap) {
              if (sensorSnap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                );
              }

              final allSensors = sensorSnap.data ?? [];
              final warningSensors = allSensors
                  .where((s) => s.overallStatus != StatusLevel.normal)
                  .toList();

              if (warningSensors.isEmpty) {
                return const EmptyAlertsView();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: warningSensors.length,
                itemBuilder: (context, index) {
                  final sensor = warningSensors[index];
                  final farmId = farms.isNotEmpty ? farms.first.id : '';
                  return AlertCard(sensor: sensor, farmId: farmId);
                },
              );
            },
          );
        },
      ),
    );
  }
}