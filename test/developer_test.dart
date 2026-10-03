import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/app/app.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/livestock_repository.dart';
import 'package:property_management_app/data/tables.dart';
import 'package:property_management_app/features/developer/dev_data.dart';
import 'package:property_management_app/features/developer/dev_log.dart';
import 'package:property_management_app/features/developer/dev_settings.dart';
import 'package:property_management_app/features/developer/developer_page.dart';
import 'package:property_management_app/shell/adaptive_scaffold.dart';

import 'support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('homeDestinations', () {
    List<String> labels({required bool developer}) => [
      for (final e in homeDestinations(developer: developer))
        e.destination.label,
    ];

    test('release builds have no Developer destination', () {
      expect(labels(developer: false), [
        'Properties',
        'Activity',
        'Templates',
        'About',
      ]);
    });

    test('debug builds put Developer before About', () {
      expect(labels(developer: true), [
        'Properties',
        'Activity',
        'Templates',
        'Developer',
        'About',
      ]);
    });
  });

  group('DevLog', () {
    test('keeps the newest entries up to capacity', () {
      final log = DevLog(capacity: 3);
      for (var i = 0; i < 5; i++) {
        log.add(DevLogKind.print, 'line $i');
      }

      expect(
        [for (final e in log.entries) e.message],
        ['line 4', 'line 3', 'line 2'],
      );

      log.clear();
      expect(log.entries, isEmpty);
    });
  });

  group('dev data', () {
    late AppDatabase db;
    late LivestockRepository repo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = LivestockRepository(db);
      await repo.seedTemplatesIfEmpty();
    });

    tearDown(() => db.close());

    test('the sample farm is consistent with the ledger', () async {
      await repo.seedSampleFarm();

      expect(await repo.properties(), hasLength(2));
      expect(await repo.movementCount(), 7);
      expect(await repo.negativeBalances(), isEmpty);
    });

    test('negativeBalances flags a count driven below zero', () async {
      final property = await repo.createProperty('Riverbend Downs');
      final paddock = await repo.createPaddock(property, 'North Flat');
      final classId = (await repo.allClasses()).first.id;
      final now = DateTime.now().toUtc();

      // Bypasses `record`, as a merged offline edit would.
      await db
          .into(db.movements)
          .insert(
            MovementsCompanion.insert(
              id: 'out',
              createdAt: now,
              updatedAt: now,
              occurredAt: now,
              kind: MovementKind.endState,
              head: 5,
              actorId: localActorId,
              fromPaddockId: Value(paddock),
              fromClassId: Value(classId),
            ),
          );

      final violations = await repo.negativeBalances();
      expect(violations, hasLength(1));
      expect(violations.single.paddockId, paddock);
      expect(violations.single.head, -5);
    });

    test('wipe empties everything and reseeds templates', () async {
      await repo.seedSampleFarm();
      await repo.wipe();

      expect(await repo.properties(), isEmpty);
      expect(await repo.movementCount(), 0);
      expect(await repo.templates(), isNotEmpty);
    });
  });

  testWidgets('a simulated width drives the layout like a real one', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.reset);

    final settings = DevSettings()..simulatedWidth = 360;

    await tester.pumpWidget(
      MaterialApp(
        builder: settings.apply,
        home: AdaptiveScaffold(
          destinations: [
            for (final e in homeDestinations(developer: false)) e.destination,
          ],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          body: const SizedBox(),
        ),
      ),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testPage('the Data tab lists every table', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = LivestockRepository(db);
    await seedBeefTemplate(db);

    await pumpPage(
      tester,
      const DeveloperPage(initialTab: 1),
      repository: repo,
    );

    expect(find.text('Seed sample farm'), findsOneWidget);
    expect(find.text('templates'), findsOneWidget);
    expect(find.text('livestock_classes'), findsOneWidget);
    expect(find.text('2 live · 0 deleted'), findsOneWidget);
  });

  testPage('tabs stay mounted when switched away from', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = LivestockRepository(db);
    await seedBeefTemplate(db);

    await pumpPage(
      tester,
      const DeveloperPage(initialTab: 1),
      repository: repo,
    );
    await tester.tap(find.text('Log'));
    await drain(tester);

    expect(find.text('Nothing logged'), findsOneWidget);
    expect(find.text('templates', skipOffstage: false), findsOneWidget);
  });
}
