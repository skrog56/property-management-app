import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/livestock_repository.dart';
import 'package:property_management_app/data/tables.dart';
import 'package:property_management_app/features/activity/activity_page.dart';
import 'package:property_management_app/features/templates/templates_page.dart';

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

  group('ActivityPage', () {
    testPage('says so when nothing has been recorded', (tester) async {
      await pumpPage(tester, const ActivityPage(), repository: repo);

      expect(find.textContaining('Nothing recorded yet'), findsOneWidget);
    });

    testPage('describes each kind of movement in its own terms', (
      tester,
    ) async {
      final property = await repo.createProperty('Riverbend Downs');
      final north = await repo.createPaddock(property, 'North Ridge');
      final creek = await repo.createPaddock(property, 'Creek Flat');

      await repo.record(
        kind: MovementKind.intake,
        head: 40,
        toPaddockId: north,
        toClassId: 'calves',
      );
      await repo.record(
        kind: MovementKind.move,
        head: 10,
        fromPaddockId: north,
        fromClassId: 'calves',
        toPaddockId: creek,
        toClassId: 'calves',
      );
      await repo.record(
        kind: MovementKind.age,
        head: 30,
        fromPaddockId: north,
        fromClassId: 'calves',
        toPaddockId: north,
        toClassId: 'weaners',
      );
      await repo.record(
        kind: MovementKind.endState,
        head: 5,
        fromPaddockId: creek,
        fromClassId: 'calves',
        endState: EndState.meatworks,
      );

      await pumpPage(tester, const ActivityPage(), width: 900, repository: repo);

      expect(find.textContaining('40 head · intake to North Ridge'), findsOneWidget);
      expect(
        find.textContaining('10 head · North Ridge → Creek Flat'),
        findsOneWidget,
      );
      expect(find.textContaining('30 head · Calves'), findsOneWidget);
      expect(find.textContaining('5 head · Creek Flat → meatworks'), findsOneWidget);
    });
  });

  group('TemplatesPage', () {
    testPage('lists seeded classes and shows the ageing chain', (tester) async {
      await pumpPage(tester, const TemplatesPage(), width: 900, repository: repo);

      expect(find.text('Beef'), findsOneWidget);
      expect(find.text('Calves — under 6 months'), findsOneWidget);
      expect(find.text('Weaners — 6-12 months'), findsOneWidget);
      expect(find.text('→ Weaners'), findsOneWidget);
    });

    testPage('lays out without overflow across size classes', (tester) async {
      for (final width in [420.0, 700.0, 1000.0, 1800.0]) {
        await pumpPage(
          tester,
          const TemplatesPage(),
          width: width,
          repository: repo,
        );
        expect(tester.takeException(), isNull, reason: 'at ${width}px');
      }
    });
  });
}
