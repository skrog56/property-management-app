import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/app_settings.dart';
import 'package:property_management_app/data/livestock_repository.dart';
import 'package:property_management_app/data/tables.dart';
import 'package:property_management_app/data/tag_numbers.dart';
import 'package:property_management_app/features/home/home_page.dart';

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

  TagNumber tag(int n) =>
      TagNumber.tryParse(TagScheme.nlis, '99900000000000$n')!;

  /// Two properties: calves and an empty paddock on one, steers on the other,
  /// some of them ready to sell.
  Future<({String riverbend, String north, String back})> seed() async {
    final riverbend = await repo.createProperty('Riverbend Downs');
    final north = await repo.createPaddock(
      riverbend,
      'North Ridge',
      hectares: 42.4,
    );
    await repo.createPaddock(riverbend, 'Woolshed');
    final block = await repo.createProperty('River Block');
    final back = await repo.createPaddock(block, 'Back Paddock');

    final steers = await repo.createClass(
      'beef',
      kind: 'Steers',
      readyToSell: true,
    );
    final ready = (await repo.allClasses())
        .firstWhere((c) => c.isReadyToSell)
        .id;

    await repo.record(
      kind: MovementKind.intake,
      head: 128,
      toPaddockId: north,
      toClassId: 'calves',
      tags: [tag(1), tag(2)],
    );
    await repo.record(
      kind: MovementKind.intake,
      head: 40,
      toPaddockId: back,
      toClassId: steers,
    );
    await repo.record(
      kind: MovementKind.readyToSell,
      head: 15,
      fromPaddockId: back,
      fromClassId: steers,
      toPaddockId: back,
      toClassId: ready,
    );
    return (riverbend: riverbend, north: north, back: back);
  }

  group('watchOverview', () {
    test('totals every property, paddock and class from the ledger', () async {
      await seed();
      final overview = await repo.watchOverview().first;

      expect(overview.head, 168);
      expect(overview.properties.map((p) => p.property.name), [
        'River Block',
        'Riverbend Downs',
      ]);
      expect(overview.paddockCount, 3);
      expect(overview.emptyPaddocks, 1);
      expect(
        {for (final c in overview.classes) c.label: c.head},
        {
          'Calves (Beef) · under 6 months': 128,
          'Steers (Beef)': 25,
          'Steers (Beef) · ready to sell': 15,
        },
      );
      expect(overview.headBySpecies, {Species.cattle: 168});
      expect(overview.activeTags, 2);
    });

    test('sums a class across properties', () async {
      final ids = await seed();
      await repo.record(
        kind: MovementKind.intake,
        head: 7,
        toPaddockId: ids.back,
        toClassId: 'calves',
      );

      final overview = await repo.watchOverview().first;
      expect(overview.classes.first.head, 135);
    });

    test('lists the mobs ready to sell and where they stand', () async {
      await seed();
      final ready = (await repo.watchOverview().first).readyToSell;

      expect(ready, hasLength(1));
      expect(ready.single.mob.head, 15);
      expect(ready.single.paddock.name, 'Back Paddock');
      expect(ready.single.property.name, 'River Block');
    });

    test('counts what came and went in the window only', () async {
      final ids = await seed();
      await repo.record(
        kind: MovementKind.intake,
        head: 300,
        toPaddockId: ids.north,
        toClassId: 'weaners',
        occurredAt: DateTime.now().subtract(const Duration(days: 40)),
      );
      await repo.record(
        kind: MovementKind.endState,
        head: 5,
        fromPaddockId: ids.north,
        fromClassId: 'calves',
        endState: EndState.sold,
      );
      await repo.record(
        kind: MovementKind.endState,
        head: 1,
        fromPaddockId: ids.north,
        fromClassId: 'calves',
        endState: EndState.died,
      );

      final flows = (await repo.watchOverview().first).flows;
      expect(flows.retention, Retention.standard);
      expect(flows.broughtIn, 168);
      expect(flows.endedAs(EndState.sold), 5);
      expect(flows.endedAs(EndState.died), 1);
      expect(flows.endedAs(EndState.meatworks), 0);
    });

    test('counts whole days, today the last of them', () async {
      final property = await repo.createProperty('Riverbend Downs');
      final north = await repo.createPaddock(property, 'North Ridge');
      // Just after the midnight that starts the 30 days to 10 March.
      await repo.record(
        kind: MovementKind.intake,
        head: 37,
        toPaddockId: north,
        toClassId: 'calves',
        occurredAt: DateTime(2026, 2, 9, 0, 30),
      );

      Future<int> broughtIn(DateTime now) async =>
          (await repo.watchOverview(clock: () => now).first).flows.broughtIn;

      expect(await broughtIn(DateTime(2026, 3, 10, 23, 59)), 37);
      expect(await broughtIn(DateTime(2026, 3, 11, 0, 1)), 0);
    });

    test('a class edited in the template editor reaches it', () async {
      await seed();
      final labels = repo.watchOverview().map(
        (o) => [for (final c in o.classes) c.label],
      );
      final renamed = expectLater(
        labels,
        emitsThrough(contains('Bobby calves (Beef) · under 6 months')),
      );

      await repo.updateClass(
        'calves',
        kind: 'Bobby calves',
        ageBand: 'under 6 months',
        agesIntoClassId: 'weaners',
        readyToSell: false,
      );
      await renamed;
    });

    test('counts each animal once two are on hand', () async {
      final ids = await seed();
      final flock = await repo.createTemplate('Flock', species: Species.sheep);
      final ewes = await repo.createClass(flock, kind: 'Ewes');
      await repo.record(
        kind: MovementKind.intake,
        head: 12,
        toPaddockId: ids.north,
        toClassId: ewes,
      );

      final overview = await repo.watchOverview().first;
      expect(overview.headBySpecies, {Species.cattle: 168, Species.sheep: 12});
    });

    test('counts over the duration it is given', () async {
      final ids = await seed();
      await repo.record(
        kind: MovementKind.intake,
        head: 300,
        toPaddockId: ids.north,
        toClassId: 'weaners',
        occurredAt: DateTime.now().subtract(const Duration(days: 40)),
      );

      Future<Flows> over(Retention retention) async =>
          (await repo.watchOverview(retention: retention).first).flows;

      expect((await over(Retention.standard)).broughtIn, 168);
      expect(
        (await over(const Retention(2, RetentionUnit.months))).broughtIn,
        468,
      );
      expect((await over(Retention.always)).broughtIn, 468);
      expect((await over(Retention.always)).retention, Retention.always);
    });
  });

  test('figures group their thousands', () {
    expect(figure(0), '0');
    expect(figure(999), '999');
    expect(figure(1000), '1,000');
    expect(figure(1234567), '1,234,567');
    expect(figure(-4200), '-4,200');
    expect(counted(1, 'property', 'properties'), '1 property');
    expect(counted(2, 'paddock'), '2 paddocks');
  });

  group('HomePage', () {
    testPage('its window follows the setting while it is open', (tester) async {
      await seed();
      await pumpPage(tester, const HomePage(), repository: repo, height: 3000);
      expect(find.text('Last 30 days'), findsOneWidget);

      await repo.settings.setRetention(const Retention(1, RetentionUnit.years));
      await drain(tester);

      expect(find.text('Last 30 days'), findsNothing);
      expect(find.text('Past year'), findsOneWidget);
    });

    testPage('a new install shows every section, and where to start', (
      tester,
    ) async {
      await pumpPage(tester, const HomePage(), repository: repo, height: 3000);

      expect(find.text('Head on hand'), findsOneWidget);
      expect(
        find.text('across every property, once stock is recorded'),
        findsOneWidget,
      );
      for (final heading in [
        'Properties',
        'Paddocks',
        'Tagged',
        'Livestock',
        'Last 30 days',
        'Recent activity',
      ]) {
        expect(find.text(heading), findsWidgets, reason: heading);
      }
      // The figure and its section.
      expect(find.text('Ready to sell'), findsNWidgets(2));
      expect(find.textContaining('Mark a mob ready to sell'), findsOneWidget);
      expect(find.textContaining('Nothing on hand yet'), findsOneWidget);
      expect(find.textContaining('Nothing recorded yet'), findsOneWidget);
      expect(find.text('No properties yet'), findsOneWidget);
      expect(find.bySemanticsLabel('Record movement'), findsNothing);

      await tester.tap(find.text('Create a property'));
      await drain(tester);
      expect(find.text('New property'), findsOneWidget);
    });

    testPage('shows the total, the figures and every section', (tester) async {
      await seed();
      await pumpPage(tester, const HomePage(), repository: repo, height: 3000);

      expect(find.text('Head on hand'), findsOneWidget);
      expect(find.text('168'), findsOneWidget);
      expect(find.text('in 3 paddocks on 2 properties'), findsOneWidget);
      expect(find.text('1 empty'), findsOneWidget);
      expect(find.text('1 mob'), findsOneWidget);

      expect(find.text('Back Paddock · River Block'), findsOneWidget);
      expect(find.text('2 paddocks · 128 head'), findsOneWidget);
      expect(find.text('Steers (Beef) · ready to sell'), findsNWidgets(2));
      expect(find.text('Brought in'), findsOneWidget);
      expect(find.text('168 head'), findsOneWidget);
      expect(find.text('Recent activity'), findsOneWidget);
      expect(
        findRichText('15 head · Steers (Beef) marked ready to sell'),
        findsOneWidget,
      );
    });

    testPage('says so while nothing is ready to sell', (tester) async {
      final property = await repo.createProperty('Riverbend Downs');
      final north = await repo.createPaddock(property, 'North Ridge');
      await repo.record(
        kind: MovementKind.intake,
        head: 10,
        toPaddockId: north,
        toClassId: 'calves',
      );
      await pumpPage(tester, const HomePage(), repository: repo);

      expect(find.text('Ready to sell'), findsNWidgets(2));
      expect(find.textContaining('Mark a mob ready to sell'), findsOneWidget);
      expect(find.text('No properties yet'), findsNothing);
    });

    testPage('names each animal only when there are two', (tester) async {
      final ids = await seed();
      await pumpPage(tester, const HomePage(), repository: repo);
      expect(find.text('168 cattle'), findsNothing);

      final flock = await repo.createTemplate('Flock', species: Species.sheep);
      await repo.record(
        kind: MovementKind.intake,
        head: 1200,
        toPaddockId: ids.north,
        toClassId: await repo.createClass(flock, kind: 'Ewes'),
      );
      await drain(tester);

      expect(find.text('1,368'), findsOneWidget);
      expect(find.text('168 cattle'), findsOneWidget);
      expect(find.text('1,200 sheep'), findsOneWidget);
    });

    testPage('keeps up as movements are recorded', (tester) async {
      final ids = await seed();
      await pumpPage(tester, const HomePage(), repository: repo);
      expect(find.text('168'), findsOneWidget);

      await repo.record(
        kind: MovementKind.endState,
        head: 8,
        fromPaddockId: ids.north,
        fromClassId: 'calves',
        endState: EndState.meatworks,
      );
      await drain(tester);

      expect(find.text('160'), findsOneWidget);
      expect(find.text('8 head'), findsOneWidget);
    });

    testPage('moves its 30 days on at midnight', (tester) async {
      final property = await repo.createProperty('Riverbend Downs');
      final north = await repo.createPaddock(property, 'North Ridge');
      await repo.record(
        kind: MovementKind.intake,
        head: 37,
        toPaddockId: north,
        toClassId: 'calves',
        occurredAt: DateTime(2026, 2, 9, 0, 30),
      );

      var now = DateTime(2026, 3, 10, 23);
      await pumpPage(
        tester,
        HomePage(clock: () => now),
        repository: repo,
        height: 3000,
      );
      expect(find.text('37 head'), findsOneWidget);

      now = DateTime(2026, 3, 11, 0, 0, 2);
      await tester.pump(const Duration(hours: 1, seconds: 2));
      await drain(tester);

      expect(find.text('37 head'), findsNothing);
      expect(find.text('1 paddock · 37 head'), findsOneWidget);
    });

    testPage('Ready to sell scrolls its mobs into view', (tester) async {
      await seed();
      await pumpPage(tester, const HomePage(), repository: repo, height: 500);

      final row = find.text('Back Paddock · River Block');
      expect(tester.getRect(row).top, greaterThanOrEqualTo(500));

      // The figure, which comes before the section of the same name.
      await tester.tap(find.text('Ready to sell').first);
      await drain(tester);

      expect(tester.getRect(row).bottom, lessThan(500));
    });

    testPage('offers to record a movement once there is a paddock', (
      tester,
    ) async {
      final property = await repo.createProperty('Riverbend Downs');
      await pumpPage(tester, const HomePage(), repository: repo);
      expect(find.bySemanticsLabel('Record movement'), findsNothing);

      await repo.createPaddock(property, 'North Ridge');
      await drain(tester);
      expect(find.bySemanticsLabel('Record movement'), findsOneWidget);
    });
  });

  group('Home in the shell', () {
    int selected(WidgetTester tester) =>
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

    Future<void> tapShown(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await settle(tester);
      await tester.tap(finder);
      await settle(tester);
    }

    testPage('is where the app opens', (tester) async {
      await seed();
      await pumpRouted(tester, repository: repo, location: '/');

      expect(find.text('Head on hand'), findsOneWidget);
      expect(selected(tester), 0);
    });

    testPage('a property opens its paddocks', (tester) async {
      await seed();
      await pumpRouted(tester, repository: repo, location: '/');

      await tapShown(tester, find.text('Riverbend Downs'));

      expect(selected(tester), 1);
      expect(find.text('North Ridge'), findsOneWidget);
      expect(find.text('Woolshed'), findsOneWidget);
    });

    testPage('a mob ready to sell opens its paddock', (tester) async {
      await seed();
      await pumpRouted(tester, repository: repo, location: '/');

      await tapShown(tester, find.text('Back Paddock · River Block'));

      expect(selected(tester), 1);
      expect(find.text('0.0 ha · 2 mobs'), findsOneWidget);
    });

    testPage('Tagged opens the tags', (tester) async {
      await seed();
      await pumpRouted(tester, repository: repo, location: '/');

      await tapShown(tester, find.text('Tagged'));

      expect(selected(tester), 3);
      expect(find.text('999 000000000001'), findsOneWidget);
    });

    testPage('each section leads to its page', (tester) async {
      await seed();
      for (final (link, index) in [('Templates', 4), ('Activity', 2)]) {
        await pumpRouted(tester, repository: repo, location: '/');
        await tapShown(tester, find.widgetWithText(TextButton, link));
        expect(selected(tester), index, reason: link);
      }
    });

    testPage('an empty install lays out without overflow at every width', (
      tester,
    ) async {
      for (final width in [320.0, 360.0, 700.0, 1000.0, 1300.0, 1900.0]) {
        await pumpRouted(tester, repository: repo, location: '/', width: width);
        expect(tester.takeException(), isNull, reason: 'at ${width}px');
      }
    });

    testPage('lays out without overflow at every width', (tester) async {
      final ids = await seed();
      final flock = await repo.createTemplate('Flock', species: Species.sheep);
      await repo.record(
        kind: MovementKind.intake,
        head: 123456,
        toPaddockId: ids.north,
        toClassId: await repo.createClass(flock, kind: 'Ewes'),
      );

      for (final width in [320.0, 360.0, 700.0, 1000.0, 1300.0, 1900.0]) {
        await pumpRouted(tester, repository: repo, location: '/', width: width);
        expect(tester.takeException(), isNull, reason: 'at ${width}px');
      }
    });
  });
}
