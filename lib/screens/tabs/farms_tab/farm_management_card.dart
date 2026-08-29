import 'package:flutter/material.dart';
import '../../../models/farm_model.dart';
import '../../../services/firestore_service.dart';
import '../../../services/rtdb_service.dart';
import '../../provision_screen.dart';
import 'sensor_row.dart';
import 'farm_dialogs.dart';

class FarmManagementCard extends StatelessWidget {
  final String uid;
  final FarmModel farm;
  final FirestoreService firestoreService;
  final RTDBService rtdbService;

  const FarmManagementCard({
    super.key,
    required this.uid,
    required this.farm,
    required this.firestoreService,
    required this.rtdbService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Farm header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.park, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farm.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (farm.locationName != null && farm.locationName!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.place, color: Colors.white70, size: 11),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  farm.locationName!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Edit / Delete buttons
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                  onPressed: () => FarmDialogs.showEditFarm(
                    context,
                    uid,
                    farm,
                    firestoreService,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Sửa tên',
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                  onPressed: () => FarmDialogs.confirmDeleteFarm(
                    context,
                    uid,
                    farm,
                    firestoreService,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Xóa farm',
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),

          // Sensor section
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sensor header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.sensors, size: 14, color: Color(0xFF2E7D32)),
                        SizedBox(width: 5),
                        Text(
                          'Danh sách cảm biến',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 4,
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProvisionScreen(),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF2E7D32),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.developer_board, size: 14),
                          label: const Text(
                            'Kết nối ESP32',
                            style: TextStyle(fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Sensor list
                StreamBuilder<List<SensorData>>(
                  stream: rtdbService.watchSensors(uid, farm.id),
                  builder: (context, snapshot) {
                    final sensors = snapshot.data ?? [];
                    if (sensors.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Text(
                          'Chưa có cảm biến nào. Nhấn "Kết nối ESP32" để ghép nối thiết bị.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: sensors
                          .asMap()
                          .entries
                          .map(
                            (e) => SensorRow(
                              farmId: farm.id,
                              sensor: e.value,
                              isLast: e.key == sensors.length - 1,
                              onDelete: () => rtdbService.deleteSensor(
                                uid,
                                farm.id,
                                e.value.id,
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
