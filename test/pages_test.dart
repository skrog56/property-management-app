import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/features/about/about_page.dart';
import 'package:property_management_app/features/paddocks/paddocks_page.dart';
import 'package:property_management_app/features/platform_proof/platform_facts.dart';

Future<void> _pump(WidgetTester tester, Widget child, double width) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  await tester.pumpAndSettle();
}

void main() {
  group('PaddocksPage', () {
    testWidgets('renders placeholder paddocks and says so', (tester) async {
      await _pump(tester, const PaddocksPage(), 420);

      expect(find.text('North Ridge'), findsOneWidget);
      expect(find.textContaining('Placeholder data'), findsOneWidget);
    });

    testWidgets('lays out without overflow across size classes', (
      tester,
    ) async {
      for (final width in [420.0, 700.0, 1000.0, 1800.0]) {
        await _pump(tester, const PaddocksPage(), width);
        expect(tester.takeException(), isNull, reason: 'at ${width}px');
      }
    });
  });

  group('AboutPage', () {
    testWidgets('lists all six target platforms', (tester) async {
      await _pump(tester, const AboutPage(), 420);

      for (final name in [
        'Web',
        'Android',
        'iOS',
        'Linux',
        'macOS',
        'Windows',
      ]) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
    });

    testWidgets('marks the platform the test host is running on', (
      tester,
    ) async {
      await _pump(tester, const AboutPage(), 420);

      // Widget tests report the host platform, so exactly one target should be
      // flagged — proving the resolution logic picks a single answer.
      expect(find.text('you are here'), findsOneWidget);
    });
  });

  group('PlatformFacts', () {
    test('resolves a platform name without touching dart:io', () {
      expect(PlatformFacts.platformName, isNotEmpty);
    });

    test('reports a build mode', () {
      expect(
        PlatformFacts.buildMode,
        anyOf('debug', 'profile', 'release'),
      );
    });
  });
}
