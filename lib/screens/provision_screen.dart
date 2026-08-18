import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/farm_model.dart';
import '../services/firestore_service.dart';

/// Màn hình cấu hình kết nối ESP32 qua WiFi AP (Cách 2).
///
/// Luồng hoạt động:
///   1. Bạn bè (phần cứng) lập trình ESP32 để khi cắm điện lần đầu,
///      nó phát WiFi tên "GreenPulse_Setup_XXXX" và chạy HTTP server tại 192.168.4.1.
///   2. User tắt dữ liệu di động, kết nối điện thoại vào WiFi "GreenPulse_Setup_XXXX".
///   3. Mở màn hình này, điền thông tin WiFi nhà + chọn Farm.
///   4. App gửi HTTP POST đến 192.168.4.1/config với toàn bộ thông số.
///   5. ESP32 nhận, lưu vào EEPROM/NVS, khởi động lại và kết nối WiFi nhà.
///   6. Từ đó ESP32 tự gửi dữ liệu cảm biến về đúng UID / farmId / sensorId.
class ProvisionScreen extends StatefulWidget {
  const ProvisionScreen({super.key});

  @override
  State<ProvisionScreen> createState() => _ProvisionScreenState();
}

class _ProvisionScreenState extends State<ProvisionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _wifiSsidCtrl = TextEditingController();
  final _wifiPassCtrl = TextEditingController();
  final _sensorIdCtrl = TextEditingController(text: 'sensor_01');
  final _esp32IpCtrl = TextEditingController(text: '192.168.4.1');

  FarmModel? _selectedFarm;
  List<FarmModel> _farms = [];

  bool _loading = false;
  bool _obscureWifi = true;
  _ProvisionStatus _status = _ProvisionStatus.idle;
  String _statusMessage = '';

  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadFarms();
  }

  Future<void> _loadFarms() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final farms = await _firestoreService.getFarms(uid);
    setState(() {
      _farms = farms;
      if (farms.isNotEmpty) _selectedFarm = farms.first;
    });
  }

  Future<void> _sendConfig() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFarm == null) {
      _showMessage('Vui lòng chọn một Nông trại!', isError: true);
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final payload = {
      'uid': uid,
      'farmId': _selectedFarm!.id,
      'sensorId': _sensorIdCtrl.text.trim(),
      'wifiSsid': _wifiSsidCtrl.text.trim(),
      'wifiPass': _wifiPassCtrl.text,
    };

    setState(() {
      _loading = true;
      _status = _ProvisionStatus.sending;
      _statusMessage = 'Đang gửi cấu hình đến ESP32...';
    });

    try {
      final ip = _esp32IpCtrl.text.trim();
      final uri = Uri.parse('http://$ip/config');

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _status = _ProvisionStatus.success;
          _statusMessage =
              'Gửi thành công! ESP32 sẽ tự khởi động lại và kết nối Wi-Fi nhà của bạn.\n\n'
              'Hãy chờ ~10 giây, sau đó chuyển điện thoại về lại Wi-Fi nhà và kiểm tra Dashboard.';
        });
      } else {
        setState(() {
          _status = _ProvisionStatus.error;
          _statusMessage =
              'ESP32 phản hồi lỗi (HTTP ${response.statusCode}):\n${response.body}';
        });
      }
    } on Exception catch (e) {
      setState(() {
        _status = _ProvisionStatus.error;
        _statusMessage =
            'Không thể kết nối đến ESP32.\n\n'
            'Kiểm tra:\n'
            '• Điện thoại đã vào WiFi "GreenPulse_Setup_..." chưa?\n'
            '• IP đúng chưa? (mặc định: 192.168.4.1)\n'
            '• Lỗi gốc: $e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : const Color(0xFF2E7D32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      appBar: AppBar(
        title: const Text('Kết nối Thiết bị'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hướng dẫn các bước ───────────────────────────────────────
              _StepCard(
                step: 1,
                title: 'Cắm điện cho mạch',
                description:
                    'Mạch sẽ phát sóng Wi-Fi tên "GreenPulse_Setup_XXXX". Khi đèn LED sáng nghĩa là mạch đã sẵn sàng.',
                icon: Icons.electrical_services,
              ),
              _StepCard(
                step: 2,
                title: 'Kết nối điện thoại vào Wi-Fi của mạch',
                description:
                    'Vào Cài đặt → Wi-Fi → Chọn mạng "GreenPulse_Setup_XXXX". '
                    'Vui lòng tắt Dữ liệu di động để tránh bị tự động chuyển mạng.',
                icon: Icons.wifi,
              ),
              _StepCard(
                step: 3,
                title: 'Điền thông tin và gửi cấu hình',
                description:
                    'Điền đầy đủ thông tin bên dưới để mạch có thể kết nối với Wi-fi của nhà bạn. Khi thực hiện xong bước này bạn có thể ngắt kết nối khỏi mạng của mạch ESP32.',
                icon: Icons.send,
              ),
              const SizedBox(height: 20),

              // ── Form ─────────────────────────────────────────────────────
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin cấu hình',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const Divider(height: 24),

                      // Chọn Farm
                      FormField<FarmModel>(
                        initialValue: _selectedFarm,
                        validator: (v) =>
                            v == null ? 'Vui lòng chọn Nông trại' : null,
                        builder: (field) => InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Trang trại nhận dữ liệu',
                            prefixIcon: const Icon(Icons.agriculture),
                            border: const OutlineInputBorder(),
                            errorText: field.errorText,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<FarmModel>(
                              value: _farms.isEmpty ? null : _selectedFarm,
                              isExpanded: true,
                              isDense: true,
                              items: _farms
                                  .map(
                                    (f) => DropdownMenuItem(
                                      value: f,
                                      child: Text(f.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                setState(() => _selectedFarm = v);
                                field.didChange(v);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Sensor ID
                      TextFormField(
                        controller: _sensorIdCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Mã cảm biến (Sensor ID)',
                          hintText: 'VD: sensor_01, sensor_02...',
                          prefixIcon: Icon(Icons.sensors),
                          border: OutlineInputBorder(),
                          helperText: 'Mỗi mạch ESP32 cần một mã khác nhau',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Vui lòng nhập mã cảm biến'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // WiFi SSID
                      TextFormField(
                        controller: _wifiSsidCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tên WiFi nhà (SSID)',
                          hintText: 'VD: MyHomeWifi',
                          prefixIcon: Icon(Icons.wifi),
                          border: OutlineInputBorder(),
                          helperText: 'Tên mạng Wi-Fi của trang trại của bạn.',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Vui lòng nhập tên WiFi'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // WiFi Password
                      TextFormField(
                        controller: _wifiPassCtrl,
                        obscureText: _obscureWifi,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu WiFi',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureWifi
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscureWifi = !_obscureWifi),
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Vui lòng nhập mật khẩu WiFi'
                            : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Status Box ────────────────────────────────────────────────
              if (_status != _ProvisionStatus.idle) _buildStatusBox(),
              const SizedBox(height: 16),

              // ── Nút Gửi ──────────────────────────────────────────────────
              FilledButton.icon(
                onPressed: _loading ? null : _sendConfig,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _loading ? 'Đang gửi...' : 'Gửi Cấu hình đến ESP32',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBox() {
    final isSuccess = _status == _ProvisionStatus.success;
    final isError = _status == _ProvisionStatus.error;
    final color = isSuccess
        ? Colors.green
        : isError
        ? Colors.red
        : Colors.blue;
    final icon = isSuccess
        ? Icons.check_circle_outline
        : isError
        ? Icons.error_outline
        : Icons.sync;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _statusMessage,
              style: TextStyle(color: color.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _wifiSsidCtrl.dispose();
    _wifiPassCtrl.dispose();
    _sensorIdCtrl.dispose();
    _esp32IpCtrl.dispose();
    super.dispose();
  }
}

enum _ProvisionStatus { idle, sending, success, error }

// ── Step Card Widget ──────────────────────────────────────────────────────────
class _StepCard extends StatelessWidget {
  final int step;
  final String title;
  final String description;
  final IconData icon;

  const _StepCard({
    required this.step,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8F5E9),
          child: Text(
            '$step',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 16, color: const Color(0xFF2E7D32)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                softWrap: true,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            description,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
      ),
    );
  }
}
