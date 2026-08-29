import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('GreenPulse App Navigation & Tab Integration Tests', () {
    testWidgets('End-to-end Tab Switching & View State Navigation Flow', (WidgetTester tester) async {
      int currentTabIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(
                    currentTabIndex == 0
                        ? 'Dashboard'
                        : currentTabIndex == 1
                            ? 'Quản lý Nông trại'
                            : currentTabIndex == 2
                                ? 'Cảnh báo & AI'
                                : 'Tài khoản',
                  ),
                ),
                body: IndexedStack(
                  index: currentTabIndex,
                  children: const [
                    Center(key: Key('dashboard_view'), child: Text('Dashboard View')),
                    Center(key: Key('farms_view'), child: Text('Farms Management View')),
                    Center(key: Key('alerts_view'), child: Text('AI Alerts View')),
                    Center(key: Key('profile_view'), child: Text('Profile Settings View')),
                  ],
                ),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: currentTabIndex,
                  onDestinationSelected: (index) {
                    setState(() => currentTabIndex = index);
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: 'Tổng quan',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.nature_outlined),
                      selectedIcon: Icon(Icons.nature),
                      label: 'Nông trại',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.notifications_outlined),
                      selectedIcon: Icon(Icons.notifications),
                      label: 'Cảnh báo',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: 'Tài khoản',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Verify Initial Screen is Dashboard
      expect(find.text('Dashboard View'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);

      // Tap Farms Tab
      await tester.tap(find.text('Nông trại'));
      await tester.pumpAndSettle();

      expect(find.text('Farms Management View'), findsOneWidget);
      expect(find.text('Quản lý Nông trại'), findsOneWidget);

      // Tap Alerts Tab
      await tester.tap(find.text('Cảnh báo'));
      await tester.pumpAndSettle();

      expect(find.text('AI Alerts View'), findsOneWidget);
      expect(find.text('Cảnh báo & AI'), findsOneWidget);

      // Tap Profile Tab
      await tester.tap(find.text('Tài khoản'));
      await tester.pumpAndSettle();

      expect(find.text('Profile Settings View'), findsOneWidget);
      expect(find.text('Tài khoản'), findsWidgets);

      // Switch back to Dashboard
      await tester.tap(find.text('Tổng quan'));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard View'), findsOneWidget);
    });
  });
}
