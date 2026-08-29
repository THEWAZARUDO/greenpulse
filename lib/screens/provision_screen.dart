import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/farm_model.dart';
import '../services/firestore_service.dart';
import 'provision_screen/step_card.dart';
import 'provision_screen/provision_status_box.dart';
import 'provision_screen/provision_form.dart';

export 'provision_screen/step_card.dart';
export 'provision_screen/provision_status_box.dart';
export 'provision_screen/provision_form.dart';

/// Màn hình cấu hình kết nối ESP32 qua WiFi AP (Cách 2).
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
  ProvisionStatus _status = ProvisionStatus.idle;
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
      _status = ProvisionStatus.sending;
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
          _status = ProvisionStatus.success;
          _statusMessage =
              'Gửi thành công! ESP32 sẽ tự khởi động lại và kết nối Wi-Fi nhà của bạn.\n\n'
              'Hãy chờ ~10 giây, sau đó chuyển điện thoại về lại Wi-Fi nhà và kiểm tra Dashboard.';
        });
      } else {
        setState(() {
          _status = ProvisionStatus.error;
          _statusMessage =
              'ESP32 phản hồi lỗi (HTTP ${response.statusCode}):\n${response.body}';
        });
      }
    } on Exception catch (e) {
      setState(() {
        _status = ProvisionStatus.error;
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
              const StepCard(
                step: 1,
                title: 'Cắm điện cho mạch',
                description:
                    'Mạch sẽ phát sóng Wi-Fi tên "GreenPulse_Setup_XXXX". Khi đèn LED sáng nghĩa là mạch đã sẵn sàng.',
                icon: Icons.electrical_services,
              ),
              const StepCard(
                step: 2,
                title: 'Kết nối điện thoại vào Wi-Fi của mạch',
                description:
                    'Vào Cài đặt → Wi-Fi → Chọn mạng "GreenPulse_Setup_XXXX". '
                    'Vui lòng tắt Dữ liệu di động để tránh bị tự động chuyển mạng.',
                icon: Icons.wifi,
              ),
              const StepCard(
                step: 3,
                title: 'Điền thông tin và gửi cấu hình',
                description:
                    'Điền đầy đủ thông tin bên dưới để mạch có thể kết nối với Wi-fi của nhà bạn. Khi thực hiện xong bước này bạn có thể ngắt kết nối khỏi mạng của mạch ESP32.',
                icon: Icons.send,
              ),
              const SizedBox(height: 20),

              // ── Form ─────────────────────────────────────────────────────
              ProvisionFormCard(
                farms: _farms,
                selectedFarm: _selectedFarm,
                onFarmSelected: (farm) => setState(() => _selectedFarm = farm),
                sensorIdCtrl: _sensorIdCtrl,
                wifiSsidCtrl: _wifiSsidCtrl,
                wifiPassCtrl: _wifiPassCtrl,
                obscureWifi: _obscureWifi,
                onToggleWifiVisibility: () =>
                    setState(() => _obscureWifi = !_obscureWifi),
              ),
              const SizedBox(height: 20),

              // ── Status Box ────────────────────────────────────────────────
              ProvisionStatusBox(
                status: _status,
                statusMessage: _statusMessage,
              ),
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

  @override
  void dispose() {
    _wifiSsidCtrl.dispose();
    _wifiPassCtrl.dispose();
    _sensorIdCtrl.dispose();
    _esp32IpCtrl.dispose();
    super.dispose();
  }
}
