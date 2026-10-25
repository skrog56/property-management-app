import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/livestock_repository.dart';
import 'package:property_management_app/data/tables.dart';
import 'package:property_management_app/data/tag_numbers.dart';
import 'package:property_management_app/features/transfers/movement_dialog.dart';

import 'support.dart';

void main() {
  late AppDatabase db;
  late LivestockRepository repo;
  late String property;
  late String north;
  late String creek;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = LivestockRepository(db);
    await seedBeefTemplate(db);
    property = await repo.createProperty('Riverbend Downs');
    north = await repo.createPaddock(property, 'North Ridge');
    creek = await repo.createPaddock(property, 'Creek Flat');
  });

  tearDown(() => db.close());

  /// [anyProperty] opens it as Activity does, without a property in hand.
  Future<void> openForm(
    WidgetTester tester, {
    double width = 800,
    bool anyProperty = false,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(width, 1400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showMovementDialog(
                context,
                repository: repo,
                propertyId: anyProperty ? null : property,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await drain(tester);
  }

  Future<void> pick(
    WidgetTester tester,
    String fieldLabel,
    String itemText,
  ) async {
    await tester.tap(
      find
          .ancestor(
            of: find.text(fieldLabel),
            matching: find.byType(DropdownButtonFormField<String>),
          )
          .first,
    );
    await drain(tester);
    await tester.tap(find.text(itemText).last);
    await drain(tester);
  }

  final a = TagNumber.tryParse(TagScheme.nlis, '999000000000001')!;
  final b = TagNumber.tryParse(TagScheme.nlis, '999000000000002')!;

  Future<List<TagNumber>> tagsIn(String paddock) async => [
    for (final s in await repo.tagsIn(paddock)) s.tag.tagNumber,
  ];

  /// What a reader in keyboard mode does: the number, then Enter.
  Future<void> scan(WidgetTester tester, String number) async {
    await tester.enterText(
      find.widgetWithText(TextField, 'Tags to add (optional)'),
      '$number\n',
    );
    await drain(tester);
  }

  Future<void> openMove(
    WidgetTester tester,
    String mob, {
    double width = 800,
  }) async {
    await openForm(tester, width: width);
    await pick(tester, 'From paddock', 'North Ridge');
    await pick(tester, 'Mob', mob);
    await pick(tester, 'To paddock', 'Creek Flat');
  }

  Future<void> scanInto(WidgetTester tester, String number) async {
    await tester.enterText(
      find.widgetWithText(TextField, 'Scan or find'),
      '$number\n',
    );
    await drain(tester);
  }

  bool chosen(WidgetTester tester, String number) => tester
      .widget<FilterChip>(find.widgetWithText(FilterChip, number))
      .selected;

  Finder record() => find.widgetWithText(FilledButton, 'Record');

  testPage('records an intake and closes', (tester) async {
    await openForm(tester);

    await tester.tap(find.text('Intake'));
    await drain(tester);

    await pick(tester, 'Class', 'Calves (under 6 months)');
    await pick(tester, 'Into', 'North Ridge');
    await tester.enterText(find.widgetWithText(TextField, 'Head'), '40');
    await drain(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Record'));
    await drain(tester);

    expect(await repo.headIn(north, 'calves'), 40);
    expect(find.text('Record movement'), findsNothing);
  });

  testPage('without a property, asks which one and offers its paddocks', (
    tester,
  ) async {
    final block = await repo.createProperty('River Block');
    final back = await repo.createPaddock(block, 'Back Paddock');
    await repo.createProperty('Bare Hill');

    await openForm(tester, anyProperty: true);
    expect(record(), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Choose a property'), findsOne);

    await tester.tap(find.text('Intake'));
    await drain(tester);
    await pick(tester, 'Property', 'Riverbend Downs');
    await pick(tester, 'Into', 'North Ridge');

    // Switching property clears the paddock chosen in the old one.
    await pick(tester, 'Property', 'River Block');
    expect(find.text('North Ridge'), findsNothing);
    await pick(tester, 'Class', 'Calves (under 6 months)');
    await pick(tester, 'Into', 'Back Paddock');
    await tester.enterText(find.widgetWithText(TextField, 'Head'), '12');
    await drain(tester);

    await tester.tap(record());
    await drain(tester);

    expect(await repo.headIn(back, 'calves'), 12);
    expect(await repo.headIn(north, 'calves'), 0);
  });

  testPage('a property without paddocks is not offered', (tester) async {
    await repo.createProperty('Bare Hill');

    await openForm(tester, anyProperty: true);
    await tester.tap(
      find.ancestor(
        of: find.text('Property'),
        matching: find.byType(DropdownButtonFormField<String>),
      ),
    );
    await drain(tester);

    expect(find.text('Bare Hill'), findsNothing);
    // The only property left is chosen already.
    expect(find.text('Riverbend Downs'), findsWidgets);
    expect(
      find.widgetWithText(FilledButton, 'Choose a property'),
      findsNothing,
    );
  });

  testPage('blocks a move of more head than the paddock holds', (tester) async {
    await repo.record(
      kind: MovementKind.intake,
      head: 10,
      toPaddockId: north,
      toClassId: 'calves',
    );

    await openForm(tester);
    await pick(tester, 'From paddock', 'North Ridge');
    await pick(tester, 'Mob', '10 × Calves (under 6 months)');
    await pick(tester, 'To paddock', 'Creek Flat');
    await tester.enterText(find.widgetWithText(TextField, 'Head'), '11');
    await drain(tester);

    expect(find.text('Only 10 head available'), findsOneWidget);
    expect(await repo.headIn(creek, 'calves'), 0);
  });

  testPage('ageing preselects the class from the template chain', (
    tester,
  ) async {
    await repo.record(
      kind: MovementKind.intake,
      head: 20,
      toPaddockId: north,
      toClassId: 'calves',
    );

    await openForm(tester);
    await tester.tap(find.text('Age'));
    await drain(tester);

    await pick(tester, 'From paddock', 'North Ridge');
    await pick(tester, 'Mob', '20 × Calves (under 6 months)');

    // The chain says calves age into weaners, so no destination is asked for.
    expect(find.text('Weaners (6-12 months)'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Head'), '20');
    await drain(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Record'));
    await drain(tester);

    expect(await repo.headIn(north, 'calves'), 0);
    expect(await repo.headIn(north, 'weaners'), 20);
  });

  group('tags', () {
    testPage('an intake records scanned tags, one head each', (tester) async {
      await openForm(tester);
      await tester.tap(find.text('Intake'));
      await drain(tester);
      await pick(tester, 'Class', 'Calves (under 6 months)');
      await pick(tester, 'Into', 'North Ridge');

      await scan(tester, '999 000000000001');
      await scan(tester, '999000000000002');
      expect(
        find.widgetWithText(InputChip, '999 000000000001'),
        findsOneWidget,
      );
      expect(find.textContaining('blank means 2'), findsOneWidget);

      await tester.tap(record());
      await drain(tester);

      expect(await repo.headIn(north, 'calves'), 2);
      expect(await tagsIn(north), [a, b]);
    });

    testPage('a move offers the mob\'s tags and carries the chosen ones', (
      tester,
    ) async {
      await repo.record(
        kind: MovementKind.intake,
        head: 10,
        toPaddockId: north,
        toClassId: 'calves',
        tags: [a, b],
      );

      await openMove(tester, '10 × Calves (under 6 months)');
      await tester.tap(find.widgetWithText(FilterChip, '999 000000000001'));
      await tester.enterText(find.widgetWithText(TextField, 'Head'), '2');
      await drain(tester);
      await tester.tap(record());
      await drain(tester);

      expect(await tagsIn(creek), [a]);
      expect(await tagsIn(north), [b]);
    });

    testPage('moving the whole mob takes every tag', (tester) async {
      await repo.record(
        kind: MovementKind.intake,
        head: 3,
        toPaddockId: north,
        toClassId: 'calves',
        tags: [a, b],
      );

      await openMove(tester, '3 × Calves (under 6 months)');
      await tester.enterText(find.widgetWithText(TextField, 'Head'), '3');
      await drain(tester);

      final chips = tester.widgetList<FilterChip>(find.byType(FilterChip));
      expect(chips.every((chip) => chip.selected), isTrue);

      await tester.tap(record());
      await drain(tester);
      expect(await tagsIn(creek), [a, b]);
    });

    testPage('asks which tags moved when untagged head cannot cover it', (
      tester,
    ) async {
      await repo.record(
        kind: MovementKind.intake,
        head: 2,
        toPaddockId: north,
        toClassId: 'calves',
        tags: [a, b],
      );

      await openMove(tester, '2 × Calves (under 6 months)');
      await tester.enterText(find.widgetWithText(TextField, 'Head'), '1');
      await drain(tester);

      expect(find.text('Select 1 more tag'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, '999 000000000002'));
      await drain(tester);
      expect(find.text('Record'), findsOneWidget);
    });

    testPage('a tag already in another paddock is refused on entry', (
      tester,
    ) async {
      await repo.record(
        kind: MovementKind.intake,
        head: 1,
        toPaddockId: creek,
        toClassId: 'calves',
        tags: [a],
      );

      await openForm(tester);
      await tester.tap(find.text('Intake'));
      await drain(tester);
      await pick(tester, 'Class', 'Calves (under 6 months)');
      await pick(tester, 'Into', 'North Ridge');
      await scan(tester, '999000000000001');

      expect(
        find.text('999 000000000001 is already in Creek Flat'),
        findsOneWidget,
      );
      expect(find.text('Remove tags recorded elsewhere'), findsOneWidget);
    });

    testPage('a number that is not NLIS stays in the box to be fixed', (
      tester,
    ) async {
      await openForm(tester);
      await tester.tap(find.text('Intake'));
      await drain(tester);
      await pick(tester, 'Class', 'Calves (under 6 months)');
      await pick(tester, 'Into', 'North Ridge');
      await tester.enterText(find.widgetWithText(TextField, 'Head'), '1');
      await scan(tester, '12345');

      expect(find.byType(InputChip), findsNothing);
      expect(find.textContaining('Not an NLIS number'), findsOneWidget);
      expect(find.text('12345'), findsOneWidget);
      expect(find.text('Finish the typed tag'), findsOneWidget);
    });

    testPage('fits a narrow phone with chips to choose from', (tester) async {
      await repo.record(
        kind: MovementKind.intake,
        head: 4,
        toPaddockId: north,
        toClassId: 'calves',
        tags: [a, b],
      );
      await repo.record(
        kind: MovementKind.intake,
        head: 1,
        toPaddockId: creek,
        toClassId: 'calves',
        tags: [TagNumber.tryParse(TagScheme.nlis, '999000000000003')!],
      );

      await openMove(tester, '4 × Calves (under 6 months)', width: 360);
      await scanInto(tester, '999000000000003');

      expect(find.byType(FilterChip), findsNWidgets(2));
      expect(find.text('999000000000003 is not in this mob'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testPage('an intake only adds, and offers nothing to pick', (tester) async {
      await openForm(tester);
      await tester.tap(find.text('Intake'));
      await drain(tester);

      expect(find.text('Tags to add (optional)'), findsOneWidget);
      expect(find.text('Scan or find'), findsNothing);

      await scan(tester, '999000000000001');
      await scan(tester, '999000000000002');
      expect(find.text('2 to add'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Clear'));
      await drain(tester);
      expect(find.byType(InputChip), findsNothing);
    });

    testPage('a move out of an untagged mob shows no tags at all', (
      tester,
    ) async {
      await repo.record(
        kind: MovementKind.intake,
        head: 5,
        toPaddockId: north,
        toClassId: 'calves',
      );

      await openMove(tester, '5 × Calves (under 6 months)');

      expect(find.text('Scan or find'), findsNothing);
      expect(find.text('Tags to add (optional)'), findsNothing);
    });

    testPage('scanning in a move selects the mob\'s tag, by its end too', (
      tester,
    ) async {
      await repo.record(
        kind: MovementKind.intake,
        head: 10,
        toPaddockId: north,
        toClassId: 'calves',
        tags: [a, b],
      );

      await openMove(tester, '10 × Calves (under 6 months)');
      expect(find.text('Tags to move · 0 of 2'), findsOneWidget);

      await scanInto(tester, '999 000000000001');
      await scanInto(tester, '999 000000000001');
      expect(chosen(tester, '999 000000000001'), isTrue);

      await scanInto(tester, '0002');
      expect(chosen(tester, '999 000000000002'), isTrue);
      expect(find.text('Tags to move · 2 of 2'), findsOneWidget);
      expect(find.textContaining('blank means 2'), findsOneWidget);

      await tester.tap(record());
      await drain(tester);
      expect(await tagsIn(creek), [a, b]);
      expect(await repo.headIn(creek, 'calves'), 2);
    });

    testPage('typing part of a number narrows the mob\'s tags', (tester) async {
      await repo.record(
        kind: MovementKind.intake,
        head: 10,
        toPaddockId: north,
        toClassId: 'calves',
        tags: [a, b],
      );

      await openMove(tester, '10 × Calves (under 6 months)');
      await tester.enterText(
        find.widgetWithText(TextField, 'Scan or find'),
        '0002',
      );
      await drain(tester);
      expect(find.byType(FilterChip), findsOneWidget);

      await scanInto(tester, '000');
      expect(find.text('000 matches 2 tags'), findsOneWidget);
      expect(find.byType(FilterChip), findsNWidgets(2));
    });

    testPage('an end selects which tags leave, all at once if need be', (
      tester,
    ) async {
      await repo.record(
        kind: MovementKind.intake,
        head: 10,
        toPaddockId: north,
        toClassId: 'calves',
        tags: [a, b],
      );

      await openForm(tester);
      await tester.tap(find.text('End'));
      await drain(tester);
      await pick(tester, 'From paddock', 'North Ridge');
      await pick(tester, 'Mob', '10 × Calves (under 6 months)');

      await tester.tap(find.widgetWithText(TextButton, 'Select all'));
      await drain(tester);
      expect(find.text('Tags to remove · 2 of 2'), findsOneWidget);

      await tester.tap(record());
      await drain(tester);
      expect(await tagsIn(north), isEmpty);
      expect(await repo.headIn(north, 'calves'), 8);
      expect((await repo.tagStatusByNumber(a))!.isActive, isFalse);
    });

    testPage('switching from intake to a move drops the typed tags', (
      tester,
    ) async {
      await repo.record(
        kind: MovementKind.intake,
        head: 3,
        toPaddockId: north,
        toClassId: 'calves',
      );

      await openForm(tester);
      await tester.tap(find.text('Intake'));
      await drain(tester);
      await scan(tester, '999000000000001');
      await tester.tap(find.text('Move'));
      await drain(tester);
      await pick(tester, 'From paddock', 'North Ridge');
      await pick(tester, 'Mob', '3 × Calves (under 6 months)');
      await pick(tester, 'To paddock', 'Creek Flat');
      await tester.enterText(find.widgetWithText(TextField, 'Head'), '1');
      await drain(tester);

      await tester.tap(record());
      await drain(tester);
      expect(await tagsIn(creek), isEmpty);
      expect(await repo.headIn(creek, 'calves'), 1);
    });
  });
}
