import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
    final property = await repo.createProperty('Riverbend Downs');
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

      expect(find.text('Riverbend Downs'), findsOneWidget);
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
      await pumpRouted(tester, repository: repo);

      await tester.tap(find.text('Riverbend Downs'));
      await settle(tester);

      expect(find.text('North Ridge'), findsOneWidget);
      expect(find.textContaining('128 × Calves'), findsOneWidget);
      expect(find.text('Woolshed'), findsOneWidget);
      expect(find.text('Empty'), findsOneWidget);
    });

    testPage('a paddock opens its mobs and its own history', (tester) async {
      await seedStock();
      await pumpRouted(tester, repository: repo);

      await tester.tap(find.text('Riverbend Downs'));
      await settle(tester);
      await tester.tap(find.text('North Ridge'));
      await settle(tester);

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
      await pumpRouted(tester, repository: repo);

      await tester.tap(find.text('Riverbend Downs'));
      await settle(tester);
      await tester.tap(find.text('Woolshed'));
      await settle(tester);

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

      await pumpRouted(tester, repository: repo);
      await tester.tap(find.text('Riverbend Downs'));
      await settle(tester);
      await tester.tap(find.text('Woolshed'));
      await settle(tester);

      expect(findRichText('8 head · North Ridge → Woolshed'), findsOneWidget);
      expect(find.textContaining('3 head'), findsNothing);
    });
  });

  group('Activity links', () {
    Finder link(String name) => find.ancestor(
      of: find.text(name),
      matching: find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.link ?? false),
      ),
    );

    testPage('a paddock named in Activity opens that paddock', (tester) async {
      await seedStock();
      await pumpRouted(tester, repository: repo, location: '/activity');

      await tester.tap(link('North Ridge'));
      await settle(tester);

      expect(find.text('42.4 ha · 1 mob'), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
    });

    testPage('a paddock does not link to itself, but links where stock went', (
      tester,
    ) async {
      final property = await seedStock();
      final paddocks = await repo.paddocksIn(property);
      final north = paddocks.firstWhere((p) => p.name == 'North Ridge');
      final woolshed = paddocks.firstWhere((p) => p.name == 'Woolshed');
      await repo.record(
        kind: MovementKind.move,
        head: 8,
        fromPaddockId: north.id,
        fromClassId: 'calves',
        toPaddockId: woolshed.id,
        toClassId: 'calves',
      );

      await pumpRouted(
        tester,
        repository: repo,
        location: '/properties/$property/paddocks/${north.id}',
      );

      expect(findRichText('8 head · North Ridge → Woolshed'), findsOneWidget);
      expect(link('North Ridge'), findsNothing);

      await tester.tap(link('Woolshed'));
      await settle(tester);
      expect(findRichText('8 head · North Ridge → Woolshed'), findsOneWidget);
      expect(link('Woolshed'), findsNothing);
      expect(link('North Ridge'), findsOneWidget);
    });

    testPage('a removed paddock is named but not linked', (tester) async {
      final property = await seedStock();
      final north = (await repo.paddocksIn(
        property,
      )).firstWhere((p) => p.name == 'North Ridge');
      await (db.update(db.paddocks)..where((p) => p.id.equals(north.id))).write(
        PaddocksCompanion(deletedAt: Value(DateTime.now())),
      );

      await pumpRouted(tester, repository: repo, location: '/activity');

      expect(findRichText('128 head · intake to North Ridge'), findsOneWidget);
      expect(link('North Ridge'), findsNothing);
    });
  });

  group('Panes and URLs', () {
    Future<({String property, String north})> ids() async {
      final property = await seedStock();
      final paddocks = await repo.paddocksIn(property);
      return (
        property: property,
        north: paddocks.firstWhere((p) => p.name == 'North Ridge').id,
      );
    }

    testPage('a compact window shows one tier and keeps the bottom bar', (
      tester,
    ) async {
      await ids();
      await pumpRouted(tester, repository: repo);

      await tester.tap(find.text('Riverbend Downs'));
      await settle(tester);
      await tester.tap(find.text('North Ridge'));
      await settle(tester);

      expect(find.text('42.4 ha · 1 mob'), findsOneWidget);
      expect(find.text('Woolshed'), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(find.text('Woolshed'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(find.text('2 paddocks · 128 head'), findsOneWidget);
    });

    testPage('drilling in never shows a spinner', (tester) async {
      await ids();
      await pumpRouted(tester, repository: repo);

      Future<void> tapAndWatch(String name) async {
        await tester.tap(find.text(name));
        for (var frame = 0; frame < 50; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          expect(
            find.byType(CircularProgressIndicator),
            findsNothing,
            reason: 'opening $name, frame $frame',
          );
        }
      }

      await tapAndWatch('Riverbend Downs');
      expect(find.text('Woolshed'), findsOneWidget);
      await tapAndWatch('North Ridge');
      expect(find.text('42.4 ha · 1 mob'), findsOneWidget);
    });

    testPage('the forward transition animates the page live, not a snapshot', (
      tester,
    ) async {
      // Linux and Windows default to the zoom transition, which snapshots.
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await ids();
        await pumpRouted(tester, repository: repo);

        await tester.tap(find.text('Riverbend Downs'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final snapshotting = tester
            .widgetList<SnapshotWidget>(find.byType(SnapshotWidget))
            .where((w) => w.controller.allowSnapshotting);
        expect(snapshotting, isEmpty);
        await settle(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testPage('a wide window puts the parent beside the current tier', (
      tester,
    ) async {
      final id = await ids();
      await repo.createProperty('River Block');
      await pumpRouted(
        tester,
        repository: repo,
        location: '/properties/${id.property}',
        width: 1200,
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('River Block'), findsOneWidget);
      expect(find.text('Woolshed'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Properties'), findsOneWidget);
      expect(find.text('Riverbend Downs'), findsNWidgets(2));

      await tester.tap(find.text('North Ridge'));
      await settle(tester);

      expect(find.text('River Block'), findsNothing);
      expect(find.text('Woolshed'), findsOneWidget);
      expect(find.text('42.4 ha · 1 mob'), findsOneWidget);
    });

    testPage('a deep link on a very wide window opens all three tiers', (
      tester,
    ) async {
      final id = await ids();
      await pumpRouted(
        tester,
        repository: repo,
        location: '/properties/${id.property}/paddocks/${id.north}',
        width: 1900,
      );

      // Once on the property's card, once atop its paddocks.
      expect(find.text('2 paddocks · 128 head'), findsNWidgets(2));
      expect(find.text('Woolshed'), findsOneWidget);
      expect(find.text('128 head'), findsOneWidget);
      expect(find.text('Calves'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Properties'));
      await settle(tester);
      expect(find.text('Select a property'), findsOneWidget);
    });

    testPage('a deep link survives having nothing to pop back to', (
      tester,
    ) async {
      final id = await ids();
      await pumpRouted(
        tester,
        repository: repo,
        location: '/properties/${id.property}/paddocks/${id.north}',
      );

      await tester.tap(find.byType(BackButton));
      await settle(tester);

      expect(find.text('Woolshed'), findsOneWidget);
    });

    testPage('unknown or mismatched ids say what is gone', (tester) async {
      final id = await ids();
      final other = await repo.createProperty('River Block');

      await pumpRouted(tester, repository: repo, location: '/properties/nope');
      expect(find.text('This property is gone.'), findsOneWidget);

      await pumpRouted(
        tester,
        repository: repo,
        location: '/properties/$other/paddocks/${id.north}',
      );
      expect(find.text('This paddock is gone.'), findsOneWidget);
    });

    testPage('an unknown path lands on Properties', (tester) async {
      await ids();
      await pumpRouted(tester, repository: repo, location: '/nowhere');

      expect(find.text('Riverbend Downs'), findsOneWidget);
    });

    testPage('every tier lays out without overflow at every width', (
      tester,
    ) async {
      final id = await ids();

      for (final location in [
        '/properties',
        '/properties/${id.property}',
        '/properties/${id.property}/paddocks/${id.north}',
      ]) {
        for (final width in [360.0, 700.0, 1000.0, 1300.0, 1900.0]) {
          await pumpRouted(
            tester,
            repository: repo,
            location: location,
            width: width,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '$location at ${width}px',
          );
        }
      }
    });
  });
}
