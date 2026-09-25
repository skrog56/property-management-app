import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/livestock_repository.dart';
import 'package:property_management_app/data/tables.dart';
import 'package:property_management_app/features/properties/properties_page.dart';

import 'support.dart';

void main() {
  late AppDatabase db;
  late LivestockRepository repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = LivestockRepository(db);
    await seedBeefTemplate(db);
  });

  tearDown(() => db.close());

  /// One property, one stocked paddock and one empty one.
  Future<String> seedStock() async {
    final property = await repo.createProperty('Skrog Downs');
    final north = await repo.createPaddock(
      property,
      'North Ridge',
      hectares: 42.4,
    );
    await repo.createPaddock(property, 'Woolshed');

    await repo.record(
      kind: MovementKind.intake,
      head: 128,
      toPaddockId: north,
      toClassId: 'calves',
    );

    return property;
  }

  group('Properties tier', () {
    testPage('offers to create a property when there are none', (tester) async {
      await pumpPage(tester, const PropertiesPage(), repository: repo);

      expect(find.text('No properties yet'), findsOneWidget);
      expect(find.text('Create a property'), findsOneWidget);
    });

    testPage('lists each property with its paddocks and head', (tester) async {
      await seedStock();
      await repo.createProperty('River Block');

      await pumpPage(tester, const PropertiesPage(), repository: repo);

      expect(find.text('Skrog Downs'), findsOneWidget);
      expect(find.text('2 paddocks · 128 head'), findsOneWidget);
      expect(find.text('River Block'), findsOneWidget);
      expect(find.text('0 paddocks · 0 head'), findsOneWidget);
    });

    testPage('lays out without overflow across size classes', (tester) async {
      await seedStock();

      for (final width in [420.0, 700.0, 1000.0, 1800.0]) {
        await pumpPage(
          tester,
          const PropertiesPage(),
          width: width,
          repository: repo,
        );
        expect(tester.takeException(), isNull, reason: 'at ${width}px');
      }
    });
  });

  group('Drilling down', () {
    testPage('a property opens its paddocks, with counts from the ledger', (
      tester,
    ) async {
      await seedStock();
      await pumpPage(tester, const PropertiesPage(), repository: repo);

      await tester.tap(find.text('Skrog Downs'));
      await drain(tester);

      expect(find.text('North Ridge'), findsOneWidget);
      expect(find.textContaining('128 × Calves'), findsOneWidget);
      expect(find.text('Woolshed'), findsOneWidget);
      expect(find.text('Empty'), findsOneWidget);
    });

    testPage('a paddock opens its mobs and its own history', (tester) async {
      await seedStock();
      await pumpPage(tester, const PropertiesPage(), repository: repo);

      await tester.tap(find.text('Skrog Downs'));
      await drain(tester);
      await tester.tap(find.text('North Ridge'));
      await drain(tester);

      expect(find.text('128 head'), findsOneWidget);
      expect(find.text('42.4 ha · 1 mob'), findsOneWidget);
      expect(find.text('Calves'), findsOneWidget);
      expect(find.text('under 6 months'), findsOneWidget);
      expect(
        find.textContaining('128 head · intake to North Ridge'),
        findsOneWidget,
      );
    });

    testPage('an empty paddock says so rather than showing zero head', (
      tester,
    ) async {
      await seedStock();
      await pumpPage(tester, const PropertiesPage(), repository: repo);

      await tester.tap(find.text('Skrog Downs'));
      await drain(tester);
      await tester.tap(find.text('Woolshed'));
      await drain(tester);

      expect(find.text('This paddock is empty.'), findsOneWidget);
      expect(
        find.text('Nothing has moved in or out of here yet.'),
        findsOneWidget,
      );
    });

    testPage('a paddock only shows movements that touched it', (tester) async {
      final property = await seedStock();
      final paddocks = await repo.paddocksIn(property);
      final woolshed = paddocks.firstWhere((p) => p.name == 'Woolshed');
      final north = paddocks.firstWhere((p) => p.name == 'North Ridge');

      await repo.record(
        kind: MovementKind.move,
        head: 8,
        fromPaddockId: north.id,
        fromClassId: 'calves',
        toPaddockId: woolshed.id,
        toClassId: 'calves',
      );
      await repo.record(
        kind: MovementKind.intake,
        head: 3,
        toPaddockId: north.id,
        toClassId: 'weaners',
      );

      await pumpPage(tester, const PropertiesPage(), repository: repo);
      await tester.tap(find.text('Skrog Downs'));
      await drain(tester);
      await tester.tap(find.text('Woolshed'));
      await drain(tester);

      expect(
        find.textContaining('8 head · North Ridge → Woolshed'),
        findsOneWidget,
      );
      expect(find.textContaining('3 head'), findsNothing);
    });
  });
}
