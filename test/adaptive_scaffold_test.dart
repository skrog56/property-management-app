import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/shell/adaptive_scaffold.dart';

const _destinations = [
  AppDestination(
    label: 'Platform',
    icon: Icons.verified_outlined,
    selectedIcon: Icons.verified,
  ),
  AppDestination(
    label: 'Paddocks',
    icon: Icons.grass_outlined,
    selectedIcon: Icons.grass,
  ),
  AppDestination(
    label: 'About',
    icon: Icons.info_outline,
    selectedIcon: Icons.info,
  ),
];

/// Renders the shell at a specific window width, the way a resized desktop
/// window or a rotated tablet would present it.
Future<void> _pumpAtWidth(
  WidgetTester tester,
  double width, {
  ValueChanged<int>? onDestinationSelected,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: AdaptiveScaffold(
        destinations: _destinations,
        selectedIndex: 0,
        onDestinationSelected: onDestinationSelected ?? (_) {},
        body: const Center(child: Text('body')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AdaptiveScaffold', () {
    testWidgets('uses a bottom navigation bar on a compact window', (
      tester,
    ) async {
      await _pumpAtWidth(tester, 420);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('switches to a collapsed rail on a medium window', (
      tester,
    ) async {
      await _pumpAtWidth(tester, 700);

      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(NavigationRail), findsOneWidget);

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isFalse);
    });

    testWidgets('extends the rail once the window is expanded', (tester) async {
      await _pumpAtWidth(tester, 1000);

      expect(find.byType(NavigationBar), findsNothing);

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
    });

    testWidgets('titles the app bar with the selected destination', (
      tester,
    ) async {
      await _pumpAtWidth(tester, 420);

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Platform'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('reports destination taps to the caller', (tester) async {
      final tapped = <int>[];
      await _pumpAtWidth(tester, 420, onDestinationSelected: tapped.add);

      await tester.tap(find.text('Paddocks'));
      await tester.pumpAndSettle();

      expect(tapped, [1]);
    });

    testWidgets('renders the body on every size class', (tester) async {
      for (final width in [420.0, 700.0, 1000.0, 1400.0, 1800.0]) {
        await _pumpAtWidth(tester, width);
        expect(find.text('body'), findsOneWidget, reason: 'at ${width}px');
      }
    });
  });
}
