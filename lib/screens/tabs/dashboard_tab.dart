import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/farm_model.dart';
import '../../models/user_model.dart';
import '../../models/plant_preset_manager.dart';
import '../../services/firestore_service.dart';
import '../../services/rtdb_service.dart';
import '../../services/ai_api_service.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Chào buổi sáng';
    if (h < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

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
          SliverAppBar(
            expandedHeight: 170,
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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            // Avatar icon
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              child: const Icon(
                                Icons.eco,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Greeting
                            Expanded(
                              child: StreamBuilder<UserModel?>(
                                stream: firestoreService.watchUser(user.uid),
                                builder: (context, snap) {
                                  final name =
                                      (snap.data?.username.isNotEmpty == true)
                                      ? snap.data!.username
                                      : (user.displayName?.isNotEmpty == true
                                            ? user.displayName!
                                            : 'Người dùng');
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_greeting()},',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            // Online badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF69F0AE),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'Trực tuyến',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: StreamBuilder<List<FarmModel>>(
              stream: firestoreService.watchFarms(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildError('${snapshot.error}');
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
                  return _buildEmptyState(context, user.uid);
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
                        (farm) => _FarmDashboardCard(
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

  Widget _buildEmptyState(BuildContext context, String uid) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.nature_people_outlined,
                size: 52,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chưa có trang trại nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Vào tab "Nông trại" để thêm nông trại mới\nvà kết nối thiết bị cảm biến ESP32 của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String msg) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Lỗi tải dữ liệu: $msg',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Farm Card ─────────────────────────────────────────────────────────────────

class _FarmDashboardCard extends StatelessWidget {
  final String uid;
  final FarmModel farm;
  final RTDBService rtdbService;

  const _FarmDashboardCard({
    required this.uid,
    required this.farm,
    required this.rtdbService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Farm Header
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.landscape,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    farm.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Sensors
          StreamBuilder<List<SensorData>>(
            stream: rtdbService.watchSensors(uid, farm.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Lỗi cảm biến: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final sensors = snapshot.data ?? [];
              if (sensors.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Chưa có cảm biến nào kết nối.\nVào Tab Nông trại để thêm cảm biến.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: sensors
                    .map((s) => _SensorMetricsView(farmId: farm.id, sensor: s))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Sensor Metrics View ───────────────────────────────────────────────────────

class _SensorMetricsView extends StatelessWidget {
  final String farmId;
  final SensorData sensor;

  const _SensorMetricsView({required this.farmId, required this.sensor});

  @override
  Widget build(BuildContext context) {
    final overall = sensor.overallStatus;
    final adviceList = sensor.adviceList;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sensor header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.sensors,
                      size: 13,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      sensor.id,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              //Debug function: Nút giả lập đổi dữ liệu cảm biến ESP32 trực tiếp trên Dashboard
              IconButton(
                icon: const Icon(Icons.tune, size: 16, color: Color(0xFFE65100)),
                tooltip: 'Giả lập đổi dữ liệu ESP32',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showEditSensorDataDebugDialog(context, farmId, sensor),
              ),
              const Spacer(),
              _StatusBadge(status: overall),
            ],
          ),
          const SizedBox(height: 14),

          // 5 Metric Grid
          Builder(
            builder: (context) {
              final crop = PlantPresetManager.getCropById(sensor.cropId);
              final stage = crop?.getStageById(sensor.stageId);
              final maxLux = (stage?.luxMax ?? 100000.0) <= 0 ? 100000.0 : stage!.luxMax;
              final screenWidth = MediaQuery.of(context).size.width;
              final dynamicRatio = screenWidth < 380 ? 1.58 : 1.70;

              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: dynamicRatio,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _MetricTile(
                    label: 'Nhiệt độ',
                    value: '${sensor.temperature.toStringAsFixed(1)}°C',
                    icon: Icons.thermostat_outlined,
                    status: sensor.tempStatus,
                    progress: ((sensor.temperature - 12) / (35 - 12)).clamp(
                      0.0,
                      1.0,
                    ),
                  ),
                  _MetricTile(
                    label: 'Độ ẩm KK',
                    value: '${sensor.humidity.toStringAsFixed(1)}%',
                    icon: Icons.water_drop_outlined,
                    status: sensor.humidityStatus,
                    progress: (sensor.humidity / 100).clamp(0.0, 1.0),
                  ),
                  _MetricTile(
                    label: 'Độ ẩm đất',
                    value: '${sensor.soil.toStringAsFixed(1)}%',
                    icon: Icons.grass_outlined,
                    status: sensor.soilStatus,
                    progress: (sensor.soil / 100).clamp(0.0, 1.0),
                  ),
                  _MetricTile(
                    label: 'Ánh sáng',
                    value: '${sensor.light.toStringAsFixed(0)} lux',
                    icon: Icons.wb_sunny_outlined,
                    status: sensor.lightStatus,
                    progress: (sensor.light / maxLux).clamp(0.0, 1.0),
                  ),
                  _MetricTile(
                    label: 'pH Đất',
                    value: '${sensor.ph.toStringAsFixed(1)} pH',
                    icon: Icons.science_outlined,
                    status: sensor.phStatus,
                    progress: (sensor.ph / 14.0).clamp(0.0, 1.0),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // AI advice box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1B5E20).withValues(alpha: 0.06),
                  const Color(0xFF2E7D32).withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.psychology_outlined,
                      size: 16,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Đánh giá & Khuyến nghị AI',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const Spacer(),
                    //Debug function: Nhãn báo trạng thái AI Server (Online 🟢 vs Offline 🟡)
                    _buildAiServerStatusBadge(sensor.aiEvaluation?.isOfflineFallback ?? true),
                  ],
                ),
                const SizedBox(height: 8),
                ...adviceList.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      a,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final StatusLevel status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Metric Tile ───────────────────────────────────────────────────────────────

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final StatusLevel status;
  final double progress; // 0.0 – 1.0

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.status,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: status.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: status.color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: status.color,
            ),
          ),
          // Mini progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: status.color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(status.color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

//Debug function: Widget hiển thị nhãn nhận biết trạng thái kết nối Server AI (Online 🟢 vs Offline 🟡 vs Waking Up ⏳)
Widget _buildAiServerStatusBadge(bool isOffline) {
  final isWakingUp = AiApiService.isWakingUp && isOffline;
  final color = isWakingUp
      ? const Color(0xFF0288D1)
      : (isOffline ? const Color(0xFFF57C00) : const Color(0xFF2E7D32));
  final bgColor = isWakingUp
      ? const Color(0xFFE1F5FE)
      : (isOffline ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9));
  final borderColor = isWakingUp
      ? const Color(0xFF81D4FA)
      : (isOffline ? const Color(0xFFFFB74D) : const Color(0xFF81C784));
  final labelText = isWakingUp
      ? 'Render đang dậy...'
      : (isOffline ? 'Offline' : 'AI Online');

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: borderColor),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isWakingUp)
          const SizedBox(
            width: 8,
            height: 8,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Color(0xFF0288D1),
            ),
          )
        else
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        const SizedBox(width: 4),
        Text(
          labelText,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}

//Debug function: Dialog giả lập thay đổi dữ liệu thông số cảm biến ESP32
void _showEditSensorDataDebugDialog(
  BuildContext context,
  String farmId,
  SensorData sensor,
) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  double temp = sensor.temperature;
  double humidity = sensor.humidity;
  double soil = sensor.soil;
  double light = sensor.light;
  double ph = sensor.ph;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.tune, color: Color(0xFFE65100)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Giả lập đổi dữ liệu ${sensor.id}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn nhanh mẫu thông số:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    ActionChip(
                      label: const Text(
                        'An toàn',
                        style: TextStyle(fontSize: 11),
                      ),
                      onPressed: () => setDialogState(() {
                        temp = 25.0;
                        humidity = 65.0;
                        soil = 60.0;
                        light = 1200.0;
                        ph = 6.5;
                      }),
                    ),
                    ActionChip(
                      label: const Text(
                        'Cảnh báo',
                        style: TextStyle(fontSize: 11),
                      ),
                      onPressed: () => setDialogState(() {
                        temp = 33.0;
                        humidity = 45.0;
                        soil = 35.0;
                        light = 2500.0;
                        ph = 5.2;
                      }),
                    ),
                    ActionChip(
                      label: const Text(
                        'Red Alert',
                        style: TextStyle(fontSize: 11, color: Colors.red),
                      ),
                      onPressed: () => setDialogState(() {
                        temp = 42.0;
                        humidity = 20.0;
                        soil = 15.0;
                        light = 4500.0;
                        ph = 4.5;
                      }),
                    ),
                  ],
                ),
                const Divider(height: 16),

                // Nhiệt độ
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nhiệt độ (°C):',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      '${temp.toStringAsFixed(1)}°C',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Slider(
                  value: temp.clamp(0.0, 50.0),
                  min: 0,
                  max: 50,
                  divisions: 50,
                  onChanged: (v) => setDialogState(() => temp = v),
                ),

                // Độ ẩm không khí
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Độ ẩm KK (%):',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      '${humidity.toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Slider(
                  value: humidity.clamp(0.0, 100.0),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  onChanged: (v) => setDialogState(() => humidity = v),
                ),

                // Độ ẩm đất
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Độ ẩm đất (%):',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      '${soil.toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Slider(
                  value: soil.clamp(0.0, 100.0),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  onChanged: (v) => setDialogState(() => soil = v),
                ),

                // Ánh sáng
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ánh sáng (lux):',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      '${light.toStringAsFixed(0)} lux',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Slider(
                  value: light.clamp(0.0, 100000.0),
                  min: 0,
                  max: 100000,
                  divisions: 100,
                  onChanged: (v) => setDialogState(() => light = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final updated = sensor.copyWith(
                  temperature: temp,
                  humidity: humidity,
                  soil: soil,
                  light: light,
                  ph: ph,
                );
                await RTDBService().addOrUpdateSensor(
                  user.uid,
                  farmId,
                  sensor.id,
                  updated,
                );
              },
              child: const Text('Cập nhật dữ liệu ESP'),
            ),
          ],
        );
      },
    ),
  );
}


