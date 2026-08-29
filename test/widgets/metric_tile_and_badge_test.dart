import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenpulse/models/farm_model.dart';

void main() {
  group('StatusLevel and StatusBadge Widget Tests', () {
    testWidgets('StatusLevel extensions return appropriate colors, labels, and icons', (tester) async {
      expect(StatusLevel.normal.label, 'An toàn');
      expect(StatusLevel.warning.label, 'Cảnh báo');
      expect(StatusLevel.danger.label, 'Nguy hiểm');

      expect(StatusLevel.normal.icon, Icons.check_circle_outline);
      expect(StatusLevel.warning.icon, Icons.warning_amber_outlined);
      expect(StatusLevel.danger.icon, Icons.error_outline);

      expect(StatusLevel.normal.color, const Color(0xFF2E7D32));
      expect(StatusLevel.warning.color, const Color(0xFFF57C00));
      expect(StatusLevel.danger.color, const Color(0xFFD32F2F));
    });

    testWidgets('Renders StatusBadge correctly in a Material widget tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                const status = StatusLevel.normal;
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
              },
            ),
          ),
        ),
      );

      expect(find.text('An toàn'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('Renders MetricTile with progress indicator correctly', (tester) async {
      const label = 'Nhiệt độ';
      const value = '28.5°C';
      const status = StatusLevel.warning;
      const progress = 0.7;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: status.color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: status.color.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.thermostat_outlined, size: 13, color: status.color),
                      const SizedBox(width: 4),
                      const Text(label),
                    ],
                  ),
                  const Text(value),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: status.color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(status.color),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text(label), findsOneWidget);
      expect(find.text(value), findsOneWidget);
      expect(find.byIcon(Icons.thermostat_outlined), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
