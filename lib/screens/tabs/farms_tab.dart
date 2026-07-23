import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/farm_model.dart';
import '../../services/firestore_service.dart';
import '../../services/rtdb_service.dart';
import '../provision_screen.dart';
import '../../widgets/plant_preset_dropdown.dart';

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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.landscape_outlined,
                        size: 52,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Chưa có nông trại nào',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Bấm nút + bên dưới để thêm nông trại đầu tiên.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddFarmDialog(
                        context,
                        user.uid,
                        firestoreService,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'Thêm Nông Trại Đầu Tiên',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: farms.length,
            itemBuilder: (context, index) {
              return _FarmManagementCard(
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
            onPressed: () =>
                _showAddFarmDialog(context, user.uid, firestoreService),
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

  void _showAddFarmDialog(
    BuildContext context,
    String uid,
    FirestoreService firestoreService,
  ) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Thêm Nông Trại Mới',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Tên nông trại',
            hintText: 'VD: Trang trại Dâu Tây A',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.landscape_outlined),
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
              await firestoreService.addFarm(uid, ctrl.text.trim());
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Đã thêm nông trại mới!'),
                    backgroundColor: Color(0xFF2E7D32),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }
}

// ── Farm Management Card ──────────────────────────────────────────────────────

class _FarmManagementCard extends StatelessWidget {
  final String uid;
  final FarmModel farm;
  final FirestoreService firestoreService;
  final RTDBService rtdbService;

  const _FarmManagementCard({
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
                  child: Text(
                    farm.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
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
                  onPressed: () => _showEditFarmDialog(context),
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
                  onPressed: () => _confirmDeleteFarm(context),
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
                          onPressed: () =>
                              _showCustomSensorDebugDialog(context),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFE65100),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.bug_report, size: 14),
                          label: const Text(
                            'Tạo Mạch Debug',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
                            (e) => _SensorRow(
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

  void _showEditFarmDialog(BuildContext context) {
    final ctrl = TextEditingController(text: farm.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đổi tên Nông trại'),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: 'Tên mới',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              await firestoreService.updateFarm(uid, farm.id, ctrl.text.trim());
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

  void _confirmDeleteFarm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa Nông trại'),
        content: Text(
          'Bạn có chắc muốn xóa "${farm.name}" không?\nThao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await firestoreService.deleteFarm(uid, farm.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showCustomSensorDebugDialog(BuildContext context) {
    final sensorIdCtrl = TextEditingController(
      text: 'sensor_debug_${DateTime.now().second.toString().padLeft(2, '0')}',
    );
    double temp = 28.0;
    double humidity = 65.0;
    double soil = 50.0;
    double light = 1200.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Row(
              children: [
                Icon(Icons.bug_report, color: Color(0xFFE65100)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tạo Mạch Tùy Chỉnh (Debug)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: sensorIdCtrl,
                    decoration: InputDecoration(
                      labelText: 'Mã Mạch (Sensor ID)',
                      hintText: 'VD: sensor_01, sensor_test',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.developer_board),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Chọn mẫu thông số nhanh:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        label: const Text(
                          'An toàn',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          setDialogState(() {
                            temp = 25.0;
                            humidity = 65.0;
                            soil = 55.0;
                            light = 1200.0;
                          });
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(
                          Icons.warning,
                          color: Colors.orange,
                          size: 16,
                        ),
                        label: const Text(
                          'Cảnh báo',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          setDialogState(() {
                            temp = 34.0;
                            humidity = 40.0;
                            soil = 32.0;
                            light = 2700.0;
                          });
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 16,
                        ),
                        label: const Text(
                          'Red Alert',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        onPressed: () {
                          setDialogState(() {
                            temp = 42.0;
                            humidity = 20.0;
                            soil = 15.0;
                            light = 4200.0;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // Nhiệt độ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nhiệt độ:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${temp.round()}°C',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: temp > 35
                              ? Colors.red
                              : (temp > 32 ? Colors.orange : Colors.green),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: temp,
                    min: 0,
                    max: 50,
                    divisions: 50,
                    activeColor: temp > 35
                        ? Colors.red
                        : (temp > 32 ? Colors.orange : const Color(0xFF2E7D32)),
                    onChanged: (v) => setDialogState(() => temp = v),
                  ),

                  // Độ ẩm không khí
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Độ ẩm không khí:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${humidity.round()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: humidity,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    activeColor: const Color(0xFF2E7D32),
                    onChanged: (v) => setDialogState(() => humidity = v),
                  ),

                  // Độ ẩm đất
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Độ ẩm đất:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${soil.round()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: soil < 20
                              ? Colors.red
                              : const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: soil,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    activeColor: soil < 20
                        ? Colors.red
                        : const Color(0xFF2E7D32),
                    onChanged: (v) => setDialogState(() => soil = v),
                  ),

                  // Ánh sáng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ánh sáng:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${light.round()} lux',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: light,
                    min: 0,
                    max: 5000,
                    divisions: 50,
                    activeColor: const Color(0xFF2E7D32),
                    onChanged: (v) => setDialogState(() => light = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Hủy'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  final sensorId = sensorIdCtrl.text.trim();
                  if (sensorId.isEmpty) return;
                  Navigator.of(ctx).pop();

                  final newSensor = SensorData(
                    id: sensorId,
                    temperature: double.parse(temp.toStringAsFixed(1)),
                    humidity: double.parse(humidity.toStringAsFixed(1)),
                    soil: double.parse(soil.toStringAsFixed(1)),
                    light: double.parse(light.toStringAsFixed(1)),
                  );

                  await rtdbService.addOrUpdateSensor(
                    uid,
                    farm.id,
                    sensorId,
                    newSensor,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã nạp dữ liệu mạch $sensorId!'),
                        backgroundColor: const Color(0xFF2E7D32),
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.send, size: 16),
                label: const Text(
                  'Nạp Dữ Liệu Mạch',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Sensor Row ────────────────────────────────────────────────────────────────

class _SensorRow extends StatelessWidget {
  final String farmId;
  final SensorData sensor;
  final bool isLast;
  final VoidCallback onDelete;

  const _SensorRow({
    required this.farmId,
    required this.sensor,
    required this.isLast,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = sensor.overallStatus;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: status.color, width: 3)),
      ),
      child: Row(
        children: [
          Icon(Icons.sensors, size: 16, color: status.color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sensor.id,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${sensor.temperature}°C  •  ${sensor.humidity}%  •  ${sensor.soil}%  •  ${sensor.light.toStringAsFixed(0)} lux',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                PlantPresetDropdown(
                  farmId: farmId,
                  sensorId: sensor.id,
                  currentPlantName: sensor.customThresholds?.plantName,
                  compact: true,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: status.color,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: Colors.red.shade400),
            onPressed: onDelete,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            tooltip: 'Gỡ cảm biến',
          ),
        ],
      ),
    );
  }
}
