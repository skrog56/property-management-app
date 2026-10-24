import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/livestock_repository.dart';
import 'package:property_management_app/data/tables.dart';
import 'package:property_management_app/data/tag_numbers.dart';
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

      expect(findRichText('40 head · intake to North Ridge'), findsOneWidget);
      expect(
        findRichText('10 head · North Ridge → Creek Flat'),
        findsOneWidget,
      );
      expect(findRichText('30 head · Calves'), findsOneWidget);
      expect(findRichText('5 head · Creek Flat → meatworks'), findsOneWidget);
    });

    testPage('tag events read as what happened to the tags', (tester) async {
      TagNumber tag(int n) =>
          TagNumber.tryParse(TagScheme.nlis, '99900000000000$n')!;
      Future<String> idOf(int n) async =>
          (await repo.tagStatusByNumber(tag(n)))!.tag.id;

      final property = await repo.createProperty('Riverbend Downs');
      final north = await repo.createPaddock(property, 'North Ridge');
      await repo.record(
        kind: MovementKind.intake,
        head: 5,
        toPaddockId: north,
        toClassId: 'calves',
        tags: [tag(1)],
      );
      await repo.applyTags(
        paddockId: north,
        classId: 'calves',
        tags: [tag(2), tag(3)],
      );
      await repo.replaceTag(await idOf(1), tag(4), reason: TagReason.lost);
      await repo.cancelTag(await idOf(2), reason: TagReason.error);

      await pumpPage(
        tester,
        const ActivityPage(),
        width: 900,
        repository: repo,
      );

      expect(findRichText('2 head · tagged in North Ridge'), findsOneWidget);
      expect(
        findRichText('1 head · tag replaced in North Ridge'),
        findsOneWidget,
      );
      expect(
        findRichText('999 000000000001 → 999 000000000004 · lost'),
        findsOneWidget,
      );
      expect(
        findRichText('1 head · tag cancelled in North Ridge'),
        findsOneWidget,
      );
      expect(
        findRichText('999 000000000002 · recorded in error'),
        findsOneWidget,
      );
    });

    testPage('a long tag list is cut short until asked for', (tester) async {
      final property = await repo.createProperty('Riverbend Downs');
      final north = await repo.createPaddock(property, 'North Ridge');
      await repo.record(
        kind: MovementKind.intake,
        head: 8,
        toPaddockId: north,
        toClassId: 'calves',
        tags: [
          for (var n = 1; n <= 8; n++)
            TagNumber.tryParse(TagScheme.nlis, '99900000000000$n')!,
        ],
      );

      await pumpPage(
        tester,
        const ActivityPage(),
        width: 900,
        repository: repo,
      );
      expect(
        find.textContaining('999 000000000008', findRichText: true),
        findsNothing,
      );

      await tester.tap(find.text('+2 more'));
      await drain(tester);
      expect(
        find.textContaining('999 000000000008', findRichText: true),
        findsOneWidget,
      );
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
