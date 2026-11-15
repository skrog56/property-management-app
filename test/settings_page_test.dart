import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/app_settings.dart';
import 'package:property_management_app/data/livestock_repository.dart';
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

  FilledButton save(WidgetTester tester) =>
      tester.widget(inDialog(find.widgetWithText(FilledButton, 'Save')));

  testPage('starts at 30 days and the system theme', (tester) async {
    await open(tester);

    expect(shownDuration(tester), '30 days');
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
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);

    await tester.tap(toggle);
    await settle(tester);

    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(repo.settings.remembersTemplatesView, isFalse);
    expect(repo.settings[AppSettings.templatesSort], isNull);
  });

  testPage('keeps the theme chosen', (tester) async {
    await open(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await settle(tester);
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

  testPage('a phone reaches it through More', (tester) async {
    await pumpRouted(tester, repository: repo, location: '/', width: 360);

    await tester.tap(find.text('More'));
    await settle(tester);
    await tester.tap(find.text('Settings'));
    await settle(tester);

    expect(find.text('Ended stock'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Appearance'), 200);
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
