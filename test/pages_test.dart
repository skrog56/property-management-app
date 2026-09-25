import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/features/about/about_page.dart';
import 'package:property_management_app/features/platform_proof/platform_facts.dart';

import 'support.dart';

void main() {
  group('AboutPage', () {
    testWidgets('lists all six target platforms', (tester) async {
      await pumpPage(tester, const AboutPage());

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
      await pumpPage(tester, const AboutPage());

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
      expect(PlatformFacts.buildMode, anyOf('debug', 'profile', 'release'));
    });
  });
}
