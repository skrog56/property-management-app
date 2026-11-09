import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/livestock_repository.dart';
import 'package:property_management_app/data/tables.dart';
import 'package:property_management_app/features/templates/templates_page.dart';
import 'package:property_management_app/features/templates/species.dart';

import 'support.dart';

void main() {
  // setUp seeds the defaults from the asset bundle, before any widget test
  // has started the binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LivestockRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = LivestockRepository(db);
  });

  tearDown(() => db.close());

  bool isWrong(WidgetTester tester, String label) =>
      tester
          .widget<InputDecorator>(
            find
                .ancestor(
                  of: find.text(label),
                  matching: find.byType(InputDecorator),
                )
                .first,
          )
          .decoration
          .error !=
      null;

  bool enabled(WidgetTester tester, String action) =>
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, action))
          .onPressed !=
      null;

  double top(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dy;

  /// The parts of [text] a search has picked out.
  List<String> picked(WidgetTester tester, String text) => [
    for (final widget in tester.widgetList<Text>(find.text(text)))
      if (widget.textSpan case final TextSpan span?)
        for (final part in [span, ...?span.children])
          if (part is TextSpan && part.style?.backgroundColor != null)
            part.text!,
  ];

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await drain(tester);
  }

  Future<void> sortBy(WidgetTester tester, String current, String by) async {
    await tester.tap(find.text(current));
    await drain(tester);
    await tester.tap(find.text(by).last);
    await drain(tester);
  }

  group('with the defaults', () {
    setUp(() => repo.seedTemplatesIfEmpty());

    testPage('shows each template, with twins where stock is sold', (
      tester,
    ) async {
      await pumpPage(
        tester,
        const TemplatesPage(),
        width: 900,
        height: 2400,
        repository: repo,
      );

      for (final name in ['Breeder', 'Backgrounders', 'Feeders', 'Fats']) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text('Steers · ready to sell'), findsOneWidget);
      expect(find.text('Heifers · ready to sell'), findsOneWidget);
      expect(find.text('Bullocks · ready to sell'), findsOneWidget);
      expect(find.text('Cows · ready to sell'), findsOneWidget);
      expect(find.text('ages into Weaners (Breeder)'), findsOneWidget);
      expect(find.text('ages into Steers (Feeders)'), findsOneWidget);
      expect(find.textContaining('Provisional'), findsNothing);
    });

    testPage('adds a template with its animal, refusing a name taken', (
      tester,
    ) async {
      await pumpPage(
        tester,
        const TemplatesPage(),
        height: 2400,
        repository: repo,
      );

      await tester.tap(find.bySemanticsLabel('Add template'));
      await drain(tester);
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'feeders');
      await drain(tester);

      expect(
        find.text('There is already a template called feeders'),
        findsOneWidget,
      );
      expect(isWrong(tester, 'Name'), isTrue);
      expect(enabled(tester, 'Create'), isFalse);

      await tester.enterText(
        find.widgetWithText(TextField, 'Name'),
        'Trade sheep',
      );
      await drain(tester);
      // No animal is assumed, and none chosen yet is not wrong.
      expect(find.text('Choose an animal'), findsOneWidget);
      expect(isWrong(tester, 'Name'), isFalse);
      expect(enabled(tester, 'Create'), isFalse);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Sheep'));
      await drain(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await drain(tester);

      expect(find.text('Trade sheep'), findsOneWidget);
      expect(find.text('Sheep · 0 head'), findsOneWidget);
      expect(find.text('No classes yet.'), findsOneWidget);
    });

    testPage('edits a template\'s name and animal', (tester) async {
      await pumpPage(
        tester,
        const TemplatesPage(),
        height: 2400,
        repository: repo,
      );
      expect(find.text('Cattle · 0 head'), findsNWidgets(4));

      await tester.tap(find.byTooltip('Actions for Breeder'));
      await drain(tester);
      await tester.tap(find.text('Edit'));
      await drain(tester);
      expect(find.text('Edit template'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Name'),
        'Breeding ewes',
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Sheep'));
      await drain(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await drain(tester);

      expect(find.text('Breeding ewes'), findsOneWidget);
      expect(find.text('Sheep · 0 head'), findsOneWidget);
      // Each group's heading, then its cards.
      expect(
        [
          for (final icon in tester.widgetList<SpeciesIcon>(
            find.byType(SpeciesIcon),
          ))
            icon.species,
        ],
        [...List.filled(4, Species.cattle), Species.sheep, Species.sheep],
      );
    });

    testPage('searches template names and their classes', (tester) async {
      await pumpPage(
        tester,
        const TemplatesPage(),
        height: 2400,
        repository: repo,
      );

      await search(tester, 'heif');
      expect(find.text('Backgrounders'), findsOneWidget);
      expect(find.text('Feeders'), findsOneWidget);
      expect(find.text('Breeder'), findsNothing);
      expect(find.text('Fats'), findsNothing);
      expect(picked(tester, 'Heifers'), ['Heif', 'Heif']);
      expect(picked(tester, 'Heifers · ready to sell'), ['Heif']);

      // Every word must be found, though not in the same place.
      await search(tester, 'FATS cows');
      expect(find.text('Fats'), findsOneWidget);
      expect(find.text('Breeder'), findsNothing);
      expect(picked(tester, 'Fats'), ['Fats']);

      await search(tester, 'ready to sell');
      expect(find.text('Feeders'), findsOneWidget);
      expect(find.text('Fats'), findsOneWidget);
      expect(find.text('Backgrounders'), findsNothing);

      await search(tester, 'goats');
      expect(find.text('No templates match "goats".'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear search'));
      await drain(tester);
      for (final name in ['Breeder', 'Backgrounders', 'Feeders', 'Fats']) {
        expect(find.text(name), findsOneWidget);
        expect(picked(tester, name), isEmpty);
      }
    });

    testPage('groups cards by animal until told not to', (tester) async {
      await repo.createTemplate('Merinos', species: Species.sheep);
      await pumpPage(
        tester,
        const TemplatesPage(),
        height: 2400,
        repository: repo,
      );

      expect(find.text('4 templates'), findsOneWidget);
      expect(find.text('1 template'), findsOneWidget);
      expect(top(tester, 'Cattle'), lessThan(top(tester, 'Fats')));
      expect(top(tester, 'Fats'), lessThan(top(tester, 'Sheep')));
      expect(top(tester, 'Sheep'), lessThan(top(tester, 'Merinos')));

      // A search leaves out a group it empties.
      await search(tester, 'merino');
      expect(find.text('Sheep'), findsOneWidget);
      expect(find.text('Cattle'), findsNothing);

      await search(tester, '');
      await tester.tap(find.text('Group by animal'));
      await drain(tester);
      expect(find.text('Cattle'), findsNothing);
      expect(find.text('Sheep'), findsNothing);
      expect(find.text('Merinos'), findsOneWidget);
    });

    testPage('sorts by most head first, then as chosen', (tester) async {
      final property = await repo.createProperty('Riverbend Downs');
      final north = await repo.createPaddock(property, 'North Flat');
      final classes = await repo.allClasses();
      for (final (label, head) in [
        ('Bullocks (Fats)', 10),
        ('Steers (Feeders)', 5),
      ]) {
        await repo.record(
          kind: MovementKind.intake,
          head: head,
          toPaddockId: north,
          toClassId: classes.singleWhere((c) => c.label == label).id,
        );
      }
      await repo.createTemplate('Angus', species: Species.cattle);
      await pumpPage(
        tester,
        const TemplatesPage(),
        height: 2400,
        repository: repo,
      );

      List<String> order() {
        final names = ['Breeder', 'Backgrounders', 'Feeders', 'Fats', 'Angus'];
        return names..sort((a, b) => top(tester, a).compareTo(top(tester, b)));
      }

      // Ties keep the order the templates were added in.
      expect(order(), ['Fats', 'Feeders', 'Breeder', 'Backgrounders', 'Angus']);
      expect(find.text('Cattle · 10 head'), findsOneWidget);

      await tester.tap(find.text('Most head'));
      await drain(tester);
      expect(
        [
          for (final item in tester.widgetList<MenuItemButton>(
            find.byType(MenuItemButton),
          ))
            (item.child! as Text).data,
        ],
        [
          'Most head',
          'Fewest head',
          'Name (A–Z)',
          'Name (Z–A)',
          'Newest first',
          'Oldest first',
        ],
      );
      await tester.tap(find.text('Fewest head').last);
      await drain(tester);
      expect(order(), ['Breeder', 'Backgrounders', 'Angus', 'Feeders', 'Fats']);

      await sortBy(tester, 'Fewest head', 'Name (A–Z)');
      expect(order(), ['Angus', 'Backgrounders', 'Breeder', 'Fats', 'Feeders']);

      await sortBy(tester, 'Name (A–Z)', 'Name (Z–A)');
      expect(order(), ['Feeders', 'Fats', 'Breeder', 'Backgrounders', 'Angus']);

      await sortBy(tester, 'Name (Z–A)', 'Newest first');
      expect(order().first, 'Angus');

      await sortBy(tester, 'Newest first', 'Oldest first');
      expect(order().last, 'Angus');
    });

    for (final density in [VisualDensity.standard, VisualDensity.compact]) {
      testPage(
        'keeps the search and its chips one height, unmoved by their states, '
        'at ${density == VisualDensity.compact ? 'compact' : 'standard'} '
        'density',
        (tester) async {
          await pumpPage(
            tester,
            Builder(
              builder: (context) => Theme(
                data: Theme.of(context).copyWith(visualDensity: density),
                child: const TemplatesPage(),
              ),
            ),
            width: 1440,
            repository: repo,
          );

          // A chip's outline is drawn outside its box.
          Rect chip(Type type) => tester
              .getRect(
                find
                    .descendant(
                      of: find.byType(type),
                      matching: find.byType(Material),
                    )
                    .first,
              )
              .inflate(1);
          List<Rect> controls() => [
            tester.getRect(find.byType(InputDecorator)),
            chip(FilterChip),
            chip(ActionChip),
          ];

          final before = controls();
          // Within a rounding of the label's line height.
          for (final rect in before) {
            expect(
              rect.height,
              closeTo(
                kMinInteractiveDimension + density.baseSizeAdjustment.dy,
                0.1,
              ),
            );
          }

          await tester.tap(find.text('Group by animal'));
          await drain(tester);
          expect(controls(), before);

          var current = 'Most head';
          for (final by in [
            'Fewest head',
            'Name (A–Z)',
            'Name (Z–A)',
            'Newest first',
            'Oldest first',
          ]) {
            await sortBy(tester, current, by);
            current = by;
            expect(controls(), before, reason: by);
          }

          await search(tester, 'steers');
          expect(find.byTooltip('Clear search'), findsOneWidget);
          expect(controls(), before);
        },
      );
    }

    testPage('sets more cards side by side as the window widens', (
      tester,
    ) async {
      for (final (width, columns) in [
        (420.0, 1),
        (700.0, 2),
        (1000.0, 2),
        (1300.0, 3),
        (1700.0, 4),
      ]) {
        await pumpPage(
          tester,
          const TemplatesPage(),
          width: width,
          height: 2400,
          repository: repo,
        );
        final tops = [
          for (final name in ['Breeder', 'Backgrounders', 'Feeders', 'Fats'])
            tester
                .getTopLeft(
                  find.ancestor(
                    of: find.text(name),
                    matching: find.byType(Card),
                  ),
                )
                .dy,
        ];
        expect(
          tops.where((top) => top == tops.first),
          hasLength(columns),
          reason: 'at ${width}px',
        );
      }

      // Breeder has a class more than Backgrounders beside it, but the row
      // keeps their buttons level.
      await pumpPage(
        tester,
        const TemplatesPage(),
        width: 1000,
        height: 2400,
        repository: repo,
      );
      final buttons = find.widgetWithText(TextButton, 'Add class');
      expect(
        tester.getTopLeft(buttons.at(0)).dy,
        tester.getTopLeft(buttons.at(1)).dy,
      );
    });

    testPage('lays out without overflow across size classes', (tester) async {
      await repo.createTemplate('Merinos', species: Species.sheep);
      for (final width in [360.0, 420.0, 700.0, 1000.0, 1300.0, 1800.0]) {
        await pumpPage(
          tester,
          const TemplatesPage(),
          width: width,
          repository: repo,
        );
        expect(tester.takeException(), isNull, reason: 'at ${width}px');

        await tester.tap(find.text('Group by animal'));
        await drain(tester);
        expect(tester.takeException(), isNull, reason: 'grouped at ${width}px');
        await tester.tap(find.text('Group by animal'));
        await drain(tester);
      }
    });
  });

  group('editing a class', () {
    setUp(() => seedBeefTemplate(db));

    Future<void> openPage(WidgetTester tester) =>
        pumpPage(tester, const TemplatesPage(), width: 900, repository: repo);

    Future<void> fill(WidgetTester tester, String label, String text) async {
      await tester.enterText(find.widgetWithText(TextField, label), text);
      await drain(tester);
    }

    testPage('adds a class that can be marked ready to sell, then edits it', (
      tester,
    ) async {
      await openPage(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Add class'));
      await drain(tester);
      expect(find.text('New class'), findsOneWidget);
      await fill(tester, 'Name', 'Steers');
      await tester.tap(find.text('Can be marked ready to sell'));
      await drain(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await drain(tester);

      expect(find.text('Steers'), findsOneWidget);
      expect(find.text('Steers · ready to sell'), findsOneWidget);

      await tester.tap(find.text('Steers'));
      await drain(tester);
      expect(find.text('Edit class'), findsOneWidget);
      await fill(tester, 'Name', 'Bullocks');
      await fill(tester, 'Age band (optional)', '2 years and over');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await drain(tester);

      expect(find.text('Bullocks'), findsOneWidget);
      expect(find.text('2 years and over'), findsOneWidget);
      expect(find.text('Bullocks · ready to sell'), findsOneWidget);
      expect(find.text('Steers · ready to sell'), findsNothing);
    });

    testPage('refuses a second class of the same name and age band', (
      tester,
    ) async {
      await openPage(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Add class'));
      await drain(tester);
      await fill(tester, 'Name', 'calves');
      await fill(tester, 'Age band (optional)', 'Under 6 months');

      expect(find.text('Already a class in Beef'), findsOneWidget);
      expect(isWrong(tester, 'Name'), isTrue);
      expect(enabled(tester, 'Create'), isFalse);

      await fill(tester, 'Age band (optional)', '6-12 months');
      expect(enabled(tester, 'Create'), isTrue);
    });

    testPage('waits for a class to empty before removing it', (tester) async {
      final property = await repo.createProperty('Riverbend Downs');
      final north = await repo.createPaddock(property, 'North Ridge');
      await repo.record(
        kind: MovementKind.intake,
        head: 5,
        toPaddockId: north,
        toClassId: 'calves',
      );
      await openPage(tester);
      expect(
        find.text(
          'under 6 months · ages into Weaners (Beef) · 6-12 months · '
          '5 head',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byTooltip('Actions for Calves (Beef) · under 6 months'),
      );
      await drain(tester);
      await tester.tap(find.text('Remove'));
      await drain(tester);
      expect(find.text('Move or age its 5 head out first'), findsOneWidget);
      expect(enabled(tester, 'Remove'), isFalse);
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await drain(tester);

      // Weaners has none, and Calves' chain to it goes with it.
      await tester.tap(
        find.byTooltip('Actions for Weaners (Beef) · 6-12 months'),
      );
      await drain(tester);
      await tester.tap(find.text('Remove'));
      await drain(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
      await drain(tester);

      expect(find.text('Weaners'), findsNothing);
      expect(find.text('under 6 months · 5 head'), findsOneWidget);
    });
  });
}
