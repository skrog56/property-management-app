import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/livestock_repository.dart';
import 'package:property_management_app/data/tables.dart';
import 'package:property_management_app/features/about/about_page.dart';
import 'package:property_management_app/features/paddocks/paddocks_page.dart';
import 'package:property_management_app/features/platform_proof/platform_facts.dart';

import 'support.dart';

void main() {
  group('PaddocksPage', () {
    late AppDatabase db;
    late LivestockRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = LivestockRepository(db);
    });

    tearDown(() => db.close());

    Future<String> seedStock() async {
      final property = await repo.createProperty('Skrog Downs');
      final paddock = await repo.createPaddock(
        property,
        'North Ridge',
        hectares: 42.4,
      );

      await seedBeefTemplate(db);
      await repo.record(
        kind: MovementKind.intake,
        head: 128,
        toPaddockId: paddock,
        toClassId: 'calves',
      );

      return property;
    }

    testPage('offers to create a property when there are none', (
      tester,
    ) async {
      await pumpPage(tester, const PaddocksPage(), repository: repo);

      expect(find.text('No properties yet'), findsOneWidget);
      expect(find.text('Create a property'), findsOneWidget);
    });

    testPage('shows head counts derived from the ledger', (tester) async {
      await seedStock();
      await pumpPage(tester, const PaddocksPage(), repository: repo);

      expect(find.text('North Ridge'), findsOneWidget);
      expect(find.text('128'), findsOneWidget);
      expect(find.textContaining('128 × Calves'), findsOneWidget);
    });

    testPage('an empty paddock reads as empty rather than zero head', (
      tester,
    ) async {
      final property = await repo.createProperty('Skrog Downs');
      await repo.createPaddock(property, 'Woolshed');
      await pumpPage(tester, const PaddocksPage(), repository: repo);

      expect(find.text('Woolshed'), findsOneWidget);
      expect(find.text('Empty'), findsOneWidget);
    });

    testPage('lays out without overflow across size classes', (
      tester,
    ) async {
      await seedStock();

      for (final width in [420.0, 700.0, 1000.0, 1800.0]) {
        await pumpPage(tester, const PaddocksPage(), width: width, repository: repo);
        expect(tester.takeException(), isNull, reason: 'at ${width}px');
      }
    });
  });

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
