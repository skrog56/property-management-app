import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/app_settings.dart';
import 'package:property_management_app/data/livestock_repository.dart';
import 'package:property_management_app/data/tables.dart';
import 'package:property_management_app/data/tag_numbers.dart';
import 'package:property_management_app/features/transfers/movement_dialog.dart';
import 'package:property_management_app/shell/adaptive_scaffold.dart';
import 'package:property_management_app/shell/search_picker.dart';

import 'support.dart';

/// What each setting changes elsewhere in the app.
void main() {
  late AppDatabase db;
  late LivestockRepository repo;
  late String property;
  late String north;

  const mob = 'Calves (Beef) · under 6 months';
  final tag = TagNumber.tryParse(TagScheme.nlis, '999000000000001')!;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = LivestockRepository(db);
    await seedBeefTemplate(db);
    property = await repo.createProperty('Riverbend Downs');
    north = await repo.createPaddock(property, 'North Ridge', hectares: 120);
  });

  tearDown(() => db.close());

  /// [anyProperty] opens it as Home and Activity do.
  Future<void> openForm(WidgetTester tester, {bool anyProperty = false}) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1400);
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

  Finder inRail(String label) => find.descendant(
    of: find.byType(ExtendedRail),
    matching: find.text(label),
  );

  group('Use tags off', () {
    setUp(() => repo.settings.setUsesTags(false));

    testPage('drops Tags from the rail and Tagged from Home', (tester) async {
      await pumpRouted(tester, repository: repo, location: '/', width: 1000);

      expect(inRail('Tags'), findsNothing);
      expect(inRail('Activity'), findsOneWidget);
      expect(find.text('Tagged'), findsNothing);

      await repo.settings.setUsesTags(true);
      await settle(tester);
      expect(inRail('Tags'), findsOneWidget);
      expect(find.text('Tagged'), findsOneWidget);
    });

    testPage('drops Tags from a phone\'s bar, and its More', (tester) async {
      await pumpRouted(tester, repository: repo, location: '/', width: 360);

      final bar = find.byType(NavigationBar);
      expect(
        find.descendant(of: bar, matching: find.text('Tags')),
        findsNothing,
      );
      await tester.tap(find.text('More'));
      await settle(tester);
      expect(find.text('Tags'), findsNothing);
      expect(find.text('Settings'), findsOneWidget);
    });

    testPage('a tag recorded before still opens from a link', (tester) async {
      await repo.record(
        kind: MovementKind.intake,
        head: 1,
        toPaddockId: north,
        toClassId: 'calves',
        tags: [tag],
      );
      final id = (await repo.tagStatusByNumber(tag))!.tag.id;
      await pumpRouted(
        tester,
        repository: repo,
        location: '/tags/$id',
        width: 1000,
      );

      expect(tester.takeException(), isNull);
      expect(find.text(tag.display), findsWidgets);
      expect(inRail('Tags'), findsNothing);
    });

    testPage('an intake asks for no tags', (tester) async {
      await openForm(tester);
      await tester.tap(find.byTooltip('Intake'));
      await drain(tester);

      expect(find.text('Tags to add (optional)'), findsNothing);
    });

    testPage('a move still offers the tags its mob already has', (
      tester,
    ) async {
      await repo.record(
        kind: MovementKind.intake,
        head: 1,
        toPaddockId: north,
        toClassId: 'calves',
        tags: [tag],
      );
      await openForm(tester);
      await tester.tap(find.widgetWithText(TextField, 'From paddock'));
      await drain(tester);
      await tester.tap(find.text('North Ridge').last);
      await drain(tester);
      await tester.tap(find.widgetWithText(TextField, 'Mob'));
      await drain(tester);
      await tester.tap(find.text('1 × $mob').last);
      await drain(tester);

      expect(find.widgetWithText(FilterChip, tag.display), findsOneWidget);
    });

    testPage('a mob offers no Add tags', (tester) async {
      await repo.record(
        kind: MovementKind.intake,
        head: 5,
        toPaddockId: north,
        toClassId: 'calves',
      );
      await pumpRouted(
        tester,
        repository: repo,
        location: '/properties/$property/paddocks/$north',
      );

      await tester.tap(find.byTooltip('Actions for $mob'));
      await settle(tester);
      final menu = find.byWidgetPredicate((w) => w is PopupMenuItem);
      expect(
        find.descendant(of: menu, matching: find.text('Record death')),
        findsOneWidget,
      );
      expect(find.text('Add tags'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
    });
  });

  testPage('new tags start as the type chosen', (tester) async {
    await repo.settings.setTagScheme(TagScheme.other);
    await openForm(tester);
    await tester.tap(find.byTooltip('Intake'));
    await drain(tester);

    final field = find.widgetWithText(TextField, 'Tags to add (optional)');
    expect(
      find.descendant(of: field, matching: find.text('Other ID')),
      findsOneWidget,
    );
  });

  testPage('the form opens on the movement type chosen', (tester) async {
    await repo.settings.setMovementKind(MovementKind.intake);
    await openForm(tester);

    expect(
      tester
          .widget<SegmentedButton<MovementKind>>(
            find.byType(SegmentedButton<MovementKind>),
          )
          .selected,
      {MovementKind.intake},
    );
    expect(find.text('Tags to add (optional)'), findsOneWidget);
  });

  group('default property', () {
    late String glenmore;

    setUp(() async {
      glenmore = await repo.createProperty('Glenmore');
      await repo.createPaddock(glenmore, 'Top Run');
    });

    String? chosen(WidgetTester tester) => tester
        .widget<SearchPicker<String>>(
          find.widgetWithText(SearchPicker<String>, 'Property'),
        )
        .value;

    testPage('starts the form from Home or Activity on it', (tester) async {
      await repo.settings.setDefaultPropertyId(glenmore);
      await openForm(tester, anyProperty: true);

      expect(chosen(tester), glenmore);
      await tester.tap(find.widgetWithText(TextField, 'From paddock'));
      await drain(tester);
      expect(find.text('Top Run'), findsWidgets);
    });

    testPage('asks, as without one, once its paddocks are gone', (
      tester,
    ) async {
      final empty = await repo.createProperty('Bare Hill');
      await repo.settings.setDefaultPropertyId(empty);
      await openForm(tester, anyProperty: true);

      expect(chosen(tester), isNull);
    });

    testPage('leaves a form opened from a property on that one', (
      tester,
    ) async {
      await repo.settings.setDefaultPropertyId(glenmore);
      await openForm(tester);

      expect(
        find.widgetWithText(SearchPicker<String>, 'Property'),
        findsNothing,
      );
      await tester.tap(find.widgetWithText(TextField, 'From paddock'));
      await drain(tester);
      expect(find.text('North Ridge'), findsWidgets);
      expect(find.text('Top Run'), findsNothing);
    });
  });

  testPage('End starts at the destination chosen', (tester) async {
    await repo.settings.setEndState(EndState.sold);
    await openForm(tester);
    await tester.tap(find.byTooltip('End'));
    await drain(tester);

    expect(
      tester
          .widget<DropdownButtonFormField<EndState>>(
            find.byType(DropdownButtonFormField<EndState>),
          )
          .initialValue,
      EndState.sold,
    );
  });

  group('acres', () {
    setUp(() => repo.settings.setAreaUnit(AreaUnit.acres));

    testPage('show on a paddock and its card, and follow a change', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        repository: repo,
        location: '/properties/$property/paddocks/$north',
        width: 1900,
      );
      // The card, and the paddock's own page beside it.
      expect(find.text('296.5 ac'), findsNWidgets(2));

      await repo.settings.setAreaUnit(AreaUnit.hectares);
      await settle(tester);
      expect(find.text('120.0 ha'), findsNWidgets(2));
    });

    testPage('a new paddock is entered in them, and kept in hectares', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        repository: repo,
        location: '/properties/$property',
        width: 1000,
      );
      await tester.tap(find.text('Add paddock'));
      await settle(tester);

      expect(find.widgetWithText(TextField, 'Acres'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Flat');
      await tester.enterText(find.widgetWithText(TextField, 'Acres'), '100');
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await settle(tester);

      final flat = (await repo.paddocksIn(
        property,
      )).singleWhere((p) => p.name == 'Flat');
      expect(flat.hectares, closeTo(40.47, 0.01));
      expect(find.text('100.0 ac'), findsOneWidget);
    });
  });
}
