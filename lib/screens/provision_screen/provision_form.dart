import 'package:flutter/material.dart';
import '../../models/farm_model.dart';

class ProvisionFormCard extends StatelessWidget {
  final List<FarmModel> farms;
  final FarmModel? selectedFarm;
  final ValueChanged<FarmModel?> onFarmSelected;
  final TextEditingController sensorIdCtrl;
  final TextEditingController wifiSsidCtrl;
  final TextEditingController wifiPassCtrl;
  final bool obscureWifi;
  final VoidCallback onToggleWifiVisibility;

  const ProvisionFormCard({
    super.key,
    required this.farms,
    required this.selectedFarm,
    required this.onFarmSelected,
    required this.sensorIdCtrl,
    required this.wifiSsidCtrl,
    required this.wifiPassCtrl,
    required this.obscureWifi,
    required this.onToggleWifiVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
              initialValue: selectedFarm,
              validator: (v) => v == null ? 'Vui lòng chọn Nông trại' : null,
              builder: (field) => InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Trang trại nhận dữ liệu',
                  prefixIcon: const Icon(Icons.agriculture),
                  border: const OutlineInputBorder(),
                  errorText: field.errorText,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<FarmModel>(
                    value: farms.isEmpty ? null : selectedFarm,
                    isExpanded: true,
                    isDense: true,
                    items: farms
                        .map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(f.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      onFarmSelected(v);
                      field.didChange(v);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Sensor ID
            TextFormField(
              controller: sensorIdCtrl,
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
              controller: wifiSsidCtrl,
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
              controller: wifiPassCtrl,
              obscureText: obscureWifi,
              decoration: InputDecoration(
                labelText: 'Mật khẩu WiFi',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureWifi
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: onToggleWifiVisibility,
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
    );
  }
}
