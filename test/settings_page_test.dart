import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/app_settings.dart';
import 'package:property_management_app/data/livestock_repository.dart';
import 'package:property_management_app/data/tables.dart';
import 'package:property_management_app/shell/form_dialog.dart';

import 'support.dart';

void main() {
  late AppDatabase db;
  late LivestockRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = LivestockRepository(db);
  });

  tearDown(() => db.close());

  Future<void> open(WidgetTester tester, {double width = 420}) =>
      pumpRouted(tester, repository: repo, location: '/settings', width: width);

  Finder inDialog(Finder finder) =>
      find.descendant(of: find.byType(FormDialog), matching: finder);

  /// Opens the duration's list and takes [choice] from it.
  Future<void> choose(WidgetTester tester, String choice) async {
    await tester.tap(find.byType(DropdownButtonFormField<Retention?>));
    await settle(tester);
    await tester.tap(find.text(choice).last);
    await settle(tester);
  }

  String shownDuration(WidgetTester tester) {
    final field = find.byType(DropdownButtonFormField<Retention?>);
    final shown = tester.widgetList<Text>(
      find.descendant(of: field, matching: find.byType(Text)),
    );
    // The label, then the chosen entry.
    return [
      for (final text in shown) ?text.data,
    ].where((t) => t != 'Keep visible for').single;
  }

  Future<void> openCustom(WidgetTester tester) async {
    await choose(tester, 'Custom…');
    expect(find.byType(FormDialog), findsOneWidget);
  }

  /// Builds [finder] if it is below the fold, then brings it to the top,
  /// clear of a phone's bottom bar.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await settle(tester);
  }

  FilledButton save(WidgetTester tester) =>
      tester.widget(inDialog(find.widgetWithText(FilledButton, 'Save')));

  testPage('starts from the defaults', (tester) async {
    await open(tester);

    expect(shownDuration(tester), '30 days');
    await reveal(tester, find.byType(DropdownButtonFormField<EndState>));
    expect(find.text('Move'), findsOneWidget);
    // Nothing to choose from on a new install.
    expect(find.text('No properties yet'), findsOneWidget);
    expect(find.text('Meatworks'), findsOneWidget);
    await reveal(tester, find.byType(DropdownButtonFormField<TagScheme>));
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Use tags'),
          )
          .value,
      isTrue,
    );
    expect(find.text('NLIS'), findsOneWidget);
    await reveal(tester, find.byType(SegmentedButton<ThemeMode>));
    expect(
      tester
          .widget<SegmentedButton<AreaUnit>>(
            find.byType(SegmentedButton<AreaUnit>),
          )
          .selected,
      {AreaUnit.hectares},
    );
    expect(
      tester
          .widget<SegmentedButton<ThemeMode>>(
            find.byType(SegmentedButton<ThemeMode>),
          )
          .selected,
      {ThemeMode.system},
    );
  });

  testPage('keeps a duration chosen from the list', (tester) async {
    await open(tester);
    await choose(tester, '90 days');

    expect(repo.settings.retention, const Retention(90, RetentionUnit.days));
    expect(shownDuration(tester), '90 days');

    final next = AppSettings(db);
    await tester.runAsync(next.load);
    expect(next.retention, const Retention(90, RetentionUnit.days));
  });

  testPage('takes a custom duration, and lists it', (tester) async {
    await open(tester);
    await openCustom(tester);

    final number = inDialog(find.byType(TextField));
    expect(save(tester).onPressed, isNotNull);

    await tester.enterText(number, '');
    await drain(tester);
    expect(inDialog(find.text('Enter how many.')), findsOneWidget);
    expect(save(tester).onPressed, isNull);
    // Only empty, so not wrong.
    expect(tester.widget<TextField>(number).decoration?.error, isNull);

    await tester.enterText(number, '0');
    await drain(tester);
    expect(inDialog(find.text('Enter at least 1.')), findsOneWidget);
    expect(save(tester).onPressed, isNull);
    expect(tester.widget<TextField>(number).decoration?.error, isNotNull);

    await tester.enterText(number, '6');
    await drain(tester);
    await tester.tap(inDialog(find.text('Days')));
    await settle(tester);
    await tester.tap(find.text('Weeks').last);
    await settle(tester);
    await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Save')));
    await settle(tester);

    expect(find.byType(FormDialog), findsNothing);
    expect(repo.settings.retention, const Retention(6, RetentionUnit.weeks));
    expect(shownDuration(tester), '6 weeks');

    // Listed beside the presets while it is chosen.
    await tester.tap(find.byType(DropdownButtonFormField<Retention?>));
    await settle(tester);
    for (final entry in ['7 days', '30 days', '1 year', 'Always']) {
      expect(find.text(entry), findsOneWidget, reason: entry);
    }
    expect(find.text('6 weeks'), findsNWidgets(2));
  });

  testPage('leaves the duration as it was when Custom is cancelled', (
    tester,
  ) async {
    await open(tester);
    await openCustom(tester);
    await tester.enterText(inDialog(find.byType(TextField)), '2');
    await tester.tap(inDialog(find.widgetWithText(TextButton, 'Cancel')));
    await settle(tester);

    expect(repo.settings.retention, Retention.standard);
    expect(shownDuration(tester), '30 days');
  });

  testPage('turns off remembering the Templates view', (tester) async {
    await repo.settings.put(AppSettings.templatesSort, 'newest');
    await open(tester);

    final toggle = find.widgetWithText(SwitchListTile, 'Remember the view');
    await reveal(tester, toggle);
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);

    await tester.tap(toggle);
    await settle(tester);

    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(repo.settings.remembersTemplatesView, isFalse);
    expect(repo.settings[AppSettings.templatesSort], isNull);
  });

  testPage('keeps the theme chosen', (tester) async {
    await open(tester);
    await reveal(tester, find.text('Dark'));
    await tester.tap(find.text('Dark'));
    await settle(tester);

    expect(repo.settings.themeMode, ThemeMode.dark);
    expect(
      tester
          .widget<SegmentedButton<ThemeMode>>(
            find.byType(SegmentedButton<ThemeMode>),
          )
          .selected,
      {ThemeMode.dark},
    );
  });

  testPage('keeps the default movement type', (tester) async {
    await open(tester);
    final field = find.byType(DropdownButtonFormField<MovementKind>);
    await reveal(tester, field);
    await tester.tap(field);
    await settle(tester);
    await tester.tap(find.text('Intake').last);
    await settle(tester);

    expect(repo.settings.movementKind, MovementKind.intake);
  });

  testPage('keeps a default property, and asks again once cleared', (
    tester,
  ) async {
    final glenmore = await repo.createProperty('Glenmore', pic: 'QGLN0001');
    await repo.createProperty('Riverbend Downs');
    await open(tester);

    final field = find.widgetWithText(TextField, 'Default property');
    await reveal(tester, field);
    expect(find.text('Ask each time'), findsOneWidget);
    await tester.tap(field);
    await settle(tester);
    await tester.enterText(field, 'qgln');
    await settle(tester);
    await tester.tap(find.text('Glenmore').last);
    await settle(tester);
    expect(repo.settings.defaultPropertyId, glenmore);

    await tester.tap(find.byTooltip('Clear'));
    await settle(tester);
    expect(repo.settings.defaultPropertyId, isNull);
    expect(find.text('Ask each time'), findsOneWidget);
  });

  testPage('keeps where End starts', (tester) async {
    await open(tester);
    final field = find.byType(DropdownButtonFormField<EndState>);
    await reveal(tester, field);
    await tester.tap(field);
    await settle(tester);
    await tester.tap(find.text('Sold').last);
    await settle(tester);

    expect(repo.settings.endState, EndState.sold);
    expect(
      find.descendant(of: field, matching: find.text('Sold')),
      findsOneWidget,
    );
  });

  testPage('keeps the tag type, and greys it out with tags off', (
    tester,
  ) async {
    await open(tester);
    final field = find.byType(DropdownButtonFormField<TagScheme>);
    await reveal(tester, field);
    await tester.tap(field);
    await settle(tester);
    await tester.tap(find.text('Other ID').last);
    await settle(tester);
    expect(repo.settings.tagScheme, TagScheme.other);

    final toggle = find.widgetWithText(SwitchListTile, 'Use tags');
    await reveal(tester, toggle);
    await tester.tap(toggle);
    await settle(tester);

    expect(repo.settings.usesTags, isFalse);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(
      tester
          .widget<DropdownButton<TagScheme>>(
            find.byType(DropdownButton<TagScheme>),
          )
          .onChanged,
      isNull,
    );
    // Kept for when tags are back.
    expect(repo.settings.tagScheme, TagScheme.other);
  });

  testPage('keeps the area unit', (tester) async {
    await open(tester);
    await reveal(tester, find.text('Acres'));
    await tester.tap(find.text('Acres'));
    await settle(tester);

    expect(repo.settings.areaUnit, AreaUnit.acres);
  });

  testPage('a phone reaches it through More', (tester) async {
    await pumpRouted(tester, repository: repo, location: '/', width: 360);

    await tester.tap(find.text('More'));
    await settle(tester);
    await tester.tap(find.text('Settings'));
    await settle(tester);

    expect(find.text('Ended stock'), findsOneWidget);
    await reveal(tester, find.text('Appearance'));
    expect(find.text('Appearance'), findsOneWidget);
  });

  testPage('lays out without overflow at every width', (tester) async {
    for (final width in const <double>[320, 600, 1000, 1900]) {
      await open(tester, width: width);
      expect(tester.takeException(), isNull, reason: '$width');
      await openCustom(tester);
      expect(tester.takeException(), isNull, reason: 'Custom at $width');
    }
  });
}
