import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/livestock_repository.dart';
import 'package:property_management_app/data/tables.dart';
import 'package:property_management_app/data/tag_numbers.dart';

import 'support.dart';

void main() {
  // The defaults come from the asset bundle.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LivestockRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = LivestockRepository(db);
  });

  tearDown(() => db.close());

  StockClass labelled(List<StockClass> classes, String label) =>
      classes.singleWhere((c) => c.label == label);

  TagNumber tag(int n) =>
      TagNumber.tryParse(TagScheme.nlis, '99900000000000$n')!;

  Future<String> paddock([String name = 'North Flat']) async {
    final property = await repo.createProperty('Riverbend Downs');
    return repo.createPaddock(property, name);
  }

  group('the default templates', () {
    test('are the four, in order, with their ready-to-sell twins', () async {
      await repo.seedTemplatesIfEmpty();

      final templates = await repo.templates();
      expect(
        [for (final t in templates) t.name],
        ['Breeder', 'Backgrounders', 'Feeders', 'Fats'],
      );
      expect(templates.every((t) => t.isBuiltIn), isTrue);
      expect({for (final t in templates) t.species}, {Species.cattle});
      expect(
        [for (final c in await repo.allClasses()) c.label],
        [
          'Cows (Breeder)',
          'Calves (Breeder)',
          'Weaners (Breeder)',
          'Steers (Backgrounders)',
          'Heifers (Backgrounders)',
          'Steers (Feeders)',
          'Heifers (Feeders)',
          'Steers (Feeders) · ready to sell',
          'Heifers (Feeders) · ready to sell',
          'Bullocks (Fats)',
          'Cows (Fats)',
          'Bullocks (Fats) · ready to sell',
          'Cows (Fats) · ready to sell',
        ],
      );
    });

    test('chain ageing, across templates too', () async {
      await repo.seedTemplatesIfEmpty();
      final classes = await repo.allClasses();
      String? next(String label) {
        final id = labelled(classes, label).row.agesIntoClassId;
        return classes.where((c) => c.id == id).firstOrNull?.label;
      }

      expect(next('Calves (Breeder)'), 'Weaners (Breeder)');
      expect(next('Steers (Backgrounders)'), 'Steers (Feeders)');
      expect(next('Heifers (Backgrounders)'), 'Heifers (Feeders)');
      expect(next('Weaners (Breeder)'), isNull);
      expect(next('Cows (Fats)'), isNull);
    });

    test('point each sellable class at its twin, and back', () async {
      await repo.seedTemplatesIfEmpty();
      final classes = await repo.allClasses();
      final steers = labelled(classes, 'Steers (Feeders)');
      final twin = labelled(classes, 'Steers (Feeders) · ready to sell');

      expect(steers.readyToSellClassId, twin.id);
      expect(twin.row.readyToSellOfClassId, steers.id);
      expect(
        labelled(classes, 'Steers (Backgrounders)').readyToSellClassId,
        isNull,
      );
    });

    test('are not seeded over templates already there', () async {
      await seedBeefTemplate(db);
      await repo.seedTemplatesIfEmpty();

      expect([for (final t in await repo.templates()) t.name], ['Beef']);
    });
  });

  group('the template editor', () {
    setUp(() => seedBeefTemplate(db));

    test('adds a template after the others, then edits it', () async {
      final id = await repo.createTemplate(
        'Trade cattle',
        species: Species.cattle,
      );
      await repo.updateTemplate(id, name: 'Wethers', species: Species.sheep);

      expect(
        [for (final t in await repo.templates()) (t.name, t.species)],
        [('Beef', Species.cattle), ('Wethers', Species.sheep)],
      );
    });

    test('gives a ready-to-sell class a twin that follows its edits', () async {
      final id = await repo.createClass(
        'beef',
        kind: 'Steers',
        readyToSell: true,
      );
      await repo.updateClass(
        id,
        kind: 'Steers',
        breed: 'Angus',
        ageBand: '1-2 years',
        readyToSell: true,
      );

      expect(
        [for (final c in await repo.allClasses()) c.label],
        [
          'Calves (Beef) · under 6 months',
          'Weaners (Beef) · 6-12 months',
          'Angus Steers (Beef) · 1-2 years',
          'Angus Steers (Beef) · 1-2 years · ready to sell',
        ],
      );
    });

    test(
      'turning ready to sell off and on again keeps the same twin',
      () async {
        final id = await repo.createClass(
          'beef',
          kind: 'Steers',
          readyToSell: true,
        );
        Future<List<StockClass>> twins() async => [
          for (final c in await repo.allClasses())
            if (c.isReadyToSell) c,
        ];
        final twin = (await twins()).single.id;

        await repo.updateClass(id, kind: 'Steers', readyToSell: false);
        expect(await twins(), isEmpty);

        await repo.updateClass(id, kind: 'Steers', readyToSell: true);
        expect((await twins()).single.id, twin);
      },
    );

    test('turning ready to sell off waits for the twin to empty', () async {
      final id = await repo.createClass(
        'beef',
        kind: 'Steers',
        readyToSell: true,
      );
      final twin = (await repo.allClasses()).singleWhere(
        (c) => c.isReadyToSell,
      );
      await repo.record(
        kind: MovementKind.intake,
        head: 3,
        toPaddockId: await paddock(),
        toClassId: twin.id,
      );

      await expectLater(
        repo.updateClass(id, kind: 'Bullocks', readyToSell: false),
        throwsStateError,
      );
      // Refused whole: the rename did not land either.
      expect(
        (await repo.allClasses()).where((c) => c.row.kind == 'Steers'),
        hasLength(2),
      );
    });

    test(
      'removing a class waits for its head, then clears chains to it',
      () async {
        final north = await paddock();
        await repo.record(
          kind: MovementKind.intake,
          head: 5,
          toPaddockId: north,
          toClassId: 'weaners',
        );
        await expectLater(repo.removeClass('weaners'), throwsStateError);

        await repo.record(
          kind: MovementKind.endState,
          head: 5,
          fromPaddockId: north,
          fromClassId: 'weaners',
          endState: EndState.sold,
        );
        await repo.removeClass('weaners');

        final classes = await repo.allClasses();
        expect([for (final c in classes) c.id], ['calves']);
        expect(classes.single.row.agesIntoClassId, isNull);
        // Its history still names it.
        final latest = (await repo.watchActivityEntries().first).first;
        expect(latest.fromClass?.label, 'Weaners (Beef) · 6-12 months');
      },
    );

    test('removing a template takes its classes out of the pickers', () async {
      final id = await repo.createTemplate(
        'Trade cattle',
        species: Species.cattle,
      );
      await repo.createClass(id, kind: 'Steers', readyToSell: true);
      await repo.removeTemplate(id);

      expect([for (final t in await repo.templates()) t.name], ['Beef']);
      expect(
        {for (final c in await repo.allClasses()) c.template.name},
        {'Beef'},
      );
    });
  });

  group('ready to sell', () {
    late String north;
    late String steers;
    late String twin;

    setUp(() async {
      await repo.seedTemplatesIfEmpty();
      final classes = await repo.allClasses();
      steers = labelled(classes, 'Steers (Feeders)').id;
      twin = labelled(classes, 'Steers (Feeders) · ready to sell').id;
      north = await paddock();
      await repo.record(
        kind: MovementKind.intake,
        head: 10,
        toPaddockId: north,
        toClassId: steers,
        tags: [tag(1), tag(2)],
      );
    });

    Future<String> mark(
      int head, {
      required bool ready,
      List<TagNumber>? tags,
    }) => repo.record(
      kind: MovementKind.readyToSell,
      head: head,
      fromPaddockId: north,
      fromClassId: ready ? steers : twin,
      toPaddockId: north,
      toClassId: ready ? twin : steers,
      tags: tags ?? const [],
    );

    test('moves head to the twin and back, tags and all', () async {
      await mark(4, ready: true, tags: [tag(1)]);
      expect(await repo.headIn(north, steers), 6);
      expect(await repo.headIn(north, twin), 4);
      expect((await repo.tagStatusByNumber(tag(1)))!.stockClass!.id, twin);

      await mark(1, ready: false, tags: [tag(1)]);
      expect(await repo.headIn(north, twin), 3);
      expect((await repo.tagStatusByNumber(tag(1)))!.stockClass!.id, steers);
      expect(await repo.negativeBalances(), isEmpty);
      expect(await repo.overTaggedMobs(), isEmpty);
    });

    test('refuses classes that are not a class and its twin', () async {
      final heifers = labelled(
        await repo.allClasses(),
        'Heifers (Feeders) · ready to sell',
      ).id;

      await expectLater(
        repo.record(
          kind: MovementKind.readyToSell,
          head: 1,
          fromPaddockId: north,
          fromClassId: steers,
          toPaddockId: north,
          toClassId: heifers,
        ),
        throwsArgumentError,
      );
      expect(await repo.movementCount(), 1);
    });

    test('refuses to leave the paddock', () async {
      final creek = await repo.createPaddock(
        (await repo.properties()).single.id,
        'Creek',
      );

      await expectLater(
        repo.record(
          kind: MovementKind.readyToSell,
          head: 1,
          fromPaddockId: north,
          fromClassId: steers,
          toPaddockId: creek,
          toClassId: twin,
        ),
        throwsArgumentError,
      );
    });
  });
}
