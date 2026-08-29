import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class StepCardWidget extends StatelessWidget {
  final int step;
  final String title;
  final String description;
  final IconData icon;

  const StepCardWidget({
    super.key,
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

void main() {
  group('Provision Step Card Widget Tests', () {
    testWidgets('Renders all 3 provision step cards correctly with titles and icons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StepCardWidget(
                  step: 1,
                  title: 'Cắm điện cho mạch',
                  description: 'Mạch sẽ phát sóng Wi-Fi tên "GreenPulse_Setup_XXXX".',
                  icon: Icons.electrical_services,
                ),
                StepCardWidget(
                  step: 2,
                  title: 'Kết nối điện thoại vào Wi-Fi của mạch',
                  description: 'Vào Cài đặt → Wi-Fi → Chọn mạng "GreenPulse_Setup_XXXX".',
                  icon: Icons.wifi,
                ),
                StepCardWidget(
                  step: 3,
                  title: 'Điền thông tin và gửi cấu hình',
                  description: 'Điền đầy đủ thông tin bên dưới để mạch có thể kết nối.',
                  icon: Icons.send,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      expect(find.text('Cắm điện cho mạch'), findsOneWidget);
      expect(find.text('Kết nối điện thoại vào Wi-Fi của mạch'), findsOneWidget);
      expect(find.text('Điền thông tin và gửi cấu hình'), findsOneWidget);

      expect(find.byIcon(Icons.electrical_services), findsOneWidget);
      expect(find.byIcon(Icons.wifi), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });
  });
}
