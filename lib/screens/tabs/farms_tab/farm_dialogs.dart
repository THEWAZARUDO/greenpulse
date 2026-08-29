import 'package:flutter/material.dart';
import '../../../models/farm_model.dart';
import '../../../models/weather_model.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/location_picker_dialog.dart';

class FarmDialogs {
  static void showAddFarm(
    BuildContext context,
    String uid,
    FirestoreService firestoreService,
  ) {
    final ctrl = TextEditingController();
    WeatherLocation? selectedLoc;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Thêm Nông Trại Mới',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Tên nông trại',
                    hintText: 'VD: Trang trại Dâu Tây A',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.landscape_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                // Chọn vị trí địa lý
                const Text(
                  'Khu vực địa lý (để dự báo thời tiết):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final loc = await LocationPickerDialog.show(
                      context,
                      currentLocation: selectedLoc,
                    );
                    if (loc != null) {
                      setModalState(() {
                        selectedLoc = loc;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.place, color: Color(0xFF2E7D32), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedLoc != null
                                ? selectedLoc!.displayName
                                : 'Chạm để chọn tỉnh/thành (mặc định: Đà Lạt)',
                            style: TextStyle(
                              fontSize: 13,
                              color: selectedLoc != null ? Colors.black87 : Colors.grey.shade600,
                              fontWeight: selectedLoc != null ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_right, color: Colors.grey, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
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
                await firestoreService.addFarm(
                  uid,
                  ctrl.text.trim(),
                  locationName: selectedLoc?.name,
                  latitude: selectedLoc?.latitude,
                  longitude: selectedLoc?.longitude,
                );
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
      ),
    );
  }

  static void showEditFarm(
    BuildContext context,
    String uid,
    FarmModel farm,
    FirestoreService firestoreService,
  ) {
    final ctrl = TextEditingController(text: farm.name);
    WeatherLocation? selectedLoc = farm.locationName != null && farm.latitude != null && farm.longitude != null
        ? WeatherLocation(
            name: farm.locationName!,
            latitude: farm.latitude!,
            longitude: farm.longitude!,
          )
        : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Cập nhật Nông trại',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: ctrl,
                  decoration: InputDecoration(
                    labelText: 'Tên nông trại',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.landscape_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Khu vực địa lý (dự báo thời tiết):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final loc = await LocationPickerDialog.show(
                      context,
                      currentLocation: selectedLoc,
                    );
                    if (loc != null) {
                      setModalState(() {
                        selectedLoc = loc;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.place, color: Color(0xFF2E7D32), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedLoc != null
                                ? selectedLoc!.displayName
                                : 'Chưa chọn vị trí (Chạm để chọn)',
                            style: TextStyle(
                              fontSize: 13,
                              color: selectedLoc != null ? Colors.black87 : Colors.grey.shade600,
                              fontWeight: selectedLoc != null ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_right, color: Colors.grey, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
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
                await firestoreService.updateFarm(
                  uid,
                  farm.id,
                  ctrl.text.trim(),
                  locationName: selectedLoc?.name,
                  latitude: selectedLoc?.latitude,
                  longitude: selectedLoc?.longitude,
                );
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
      ),
    );
  }

  static void confirmDeleteFarm(
    BuildContext context,
    String uid,
    FarmModel farm,
    FirestoreService firestoreService,
  ) {
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
}
