import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/livestock_repository.dart';
import 'package:property_management_app/features/export/export_formats.dart';
import 'package:property_management_app/features/export/export_panel.dart';
import 'package:property_management_app/features/export/save_export.dart';
import 'package:property_management_app/features/settings/settings_page.dart';
import 'package:property_management_app/shell/form_dialog.dart';
import 'package:property_management_app/shell/search_picker.dart';
import 'package:property_management_app/shell/trail_bar.dart';

import 'support.dart';

void main() {
  late AppDatabase db;
  late LivestockRepository repo;
  late List<ExportFile> saved;
  late Future<bool> Function(ExportFile) save;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = LivestockRepository(db);
    await repo.createProperty('Riverbend Downs');
    saved = [];
    save = (file) async {
      saved.add(file);
      return true;
    };
  });

  tearDown(() => db.close());

  String today() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}';
  }

  /// Settings on its Data tab.
  Future<void> open(WidgetTester tester, {double width = 420}) async {
    await pumpPage(
      tester,
      SettingsPage(tab: SettingsTab.data, exportSaver: (f) => save(f)),
      repository: repo,
      width: width,
      // Tall enough that the list builds every card.
      height: 2400,
    );
    expect(find.byType(ExportPanel), findsOneWidget);
  }

  Finder inPanel(Finder finder) =>
      find.descendant(of: find.byType(ExportPanel), matching: finder);

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await settle(tester);
  }

  Finder exportButton() => find.widgetWithText(FilledButton, 'Export');

  bool exportEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(exportButton()).onPressed != null;

  /// Types [date] into the picker the field opens.
  Future<void> typeDate(WidgetTester tester, String field, String date) async {
    await tap(
      tester,
      find.ancestor(of: find.text(field), matching: find.byType(InkWell)).first,
    );
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await settle(tester);
    await tester.enterText(
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.byType(TextField),
      ),
      date,
    );
    await tester.tap(find.text('OK'));
    await settle(tester);
  }

  testPage('Settings opens on its settings, Data beside them', (tester) async {
    await pumpPage(tester, const SettingsPage(), repository: repo);
    expect(find.text('Ended stock'), findsOneWidget);
    expect(find.byType(ExportPanel), findsNothing);

    await tester.tap(find.widgetWithText(Tab, 'Data'));
    await settle(tester);
    expect(find.byType(ExportPanel), findsOneWidget);
  });

  testPage('starts as a PDF of every list', (tester) async {
    await open(tester);

    final boxes = tester.widgetList<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(boxes, hasLength(5));
    expect(boxes.every((box) => box.value!), isTrue);
    expect(find.text('All properties'), findsOneWidget);
    expect(find.text('livestock-export-${today()}.pdf'), findsOneWidget);
    expect(exportEnabled(tester), isTrue);
  });

  testPage('offers PDF, Excel, CSV and JSON, in that order', (tester) async {
    await open(tester, width: 1200);
    final lefts = [
      for (final label in [
        'PDF Report',
        'Excel Workbook',
        'CSV',
        'JSON Backup',
      ])
        tester.getTopLeft(inPanel(find.text(label))).dx,
    ];
    expect([...lefts]..sort(), lefts);
  });

  Finder picker(String label) => find.byWidgetPredicate(
    (w) => w is SearchPicker<String> && w.label == label,
  );

  List<String> offered(WidgetTester tester, String label) => [
    for (final entry
        in tester.widget<SearchPicker<String>>(picker(label)).entries)
      entry.label,
  ];

  Future<void> choose(WidgetTester tester, String label, String entry) async {
    await tester.enterText(
      find.descendant(of: picker(label), matching: find.byType(TextField)),
      entry,
    );
    await settle(tester);
  }

  testPage('offers a property added after it opened', (tester) async {
    await open(tester);
    expect(offered(tester, 'Property'), ['Riverbend Downs']);

    await tester.runAsync(() => repo.createProperty('Glenmore Station'));
    await drain(tester);
    expect(offered(tester, 'Property'), [
      'Glenmore Station',
      'Riverbend Downs',
    ]);
  });

  testPage("offers a property's paddocks once it is chosen", (tester) async {
    final riverbend = (await repo.properties()).single.id;
    final glenmore = await repo.createProperty('Glenmore Station');
    await repo.createPaddock(riverbend, 'North Flat');
    await repo.createPaddock(glenmore, 'Top Run');
    await open(tester);

    expect(find.text('Choose a property first'), findsOneWidget);
    expect(offered(tester, 'Paddock'), isEmpty);

    await choose(tester, 'Property', 'Riverbend Downs');
    expect(offered(tester, 'Paddock'), ['North Flat']);
    await choose(tester, 'Paddock', 'North Flat');
    expect(
      tester.widget<SearchPicker<String>>(picker('Paddock')).value,
      isNotNull,
    );

    // Another property's paddocks, and none of them chosen.
    await choose(tester, 'Property', 'Glenmore Station');
    expect(offered(tester, 'Paddock'), ['Top Run']);
    expect(
      tester.widget<SearchPicker<String>>(picker('Paddock')).value,
      isNull,
    );

    await tester.runAsync(() => repo.createPaddock(glenmore, 'Bottom Run'));
    await drain(tester);
    expect(offered(tester, 'Paddock'), ['Bottom Run', 'Top Run']);
  });

  testPage("leads the file name with the format's icon", (tester) async {
    await open(tester);
    Finder fileIcon(IconData icon) => find.descendant(
      of: find
          .ancestor(
            of: find.textContaining('livestock-export-'),
            matching: find.byType(Row),
          )
          .first,
      matching: find.byIcon(icon),
    );
    expect(fileIcon(Icons.picture_as_pdf_outlined), findsOneWidget);

    await tap(tester, find.text(ExportFormat.xlsx.label));
    expect(fileIcon(Icons.table_chart_outlined), findsOneWidget);
  });

  testPage('no list ticked blocks the export', (tester) async {
    await open(tester);
    for (final box in find.byType(CheckboxListTile).evaluate().toList()) {
      await tap(tester, find.byWidget(box.widget));
    }

    expect(find.text('Choose at least one list'), findsOneWidget);
    expect(exportEnabled(tester), isFalse);
  });

  testPage('From after To blocks the export and marks both', (tester) async {
    await open(tester);
    await typeDate(tester, 'From', '01/06/2024');
    await typeDate(tester, 'To', '01/01/2024');

    expect(find.text('01/06/2024'), findsOneWidget);
    expect(find.text('From is after To'), findsOneWidget);
    expect(exportEnabled(tester), isFalse);
    final decorators = tester.widgetList<InputDecorator>(
      inPanel(
        find.descendant(
          of: find.byType(Row),
          matching: find.byType(InputDecorator),
        ),
      ),
    );
    expect(
      decorators.where((d) => d.decoration.error == wrongField),
      hasLength(2),
    );

    await tap(tester, find.byTooltip('Clear From'));
    expect(find.text('From is after To'), findsNothing);
    expect(exportEnabled(tester), isTrue);
  });

  testPage('a JSON backup is the whole farm, so asks nothing more', (
    tester,
  ) async {
    await open(tester);
    await tap(tester, find.text(ExportFormat.json.label));

    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.text('All properties'), findsNothing);
    expect(find.text('What a backup holds'), findsOneWidget);

    await tap(tester, exportButton());
    expect(saved.single.name, 'livestock-export-${today()}.json');
  });

  testPage('Export hands the file over and says so', (tester) async {
    await open(tester);
    // Built outside the test's fake clock, as the fonts load for real.
    await tester.runAsync(() async {
      await tester.tap(exportButton());
      while (saved.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await settle(tester);

    final name = 'livestock-export-${today()}.pdf';
    expect(saved.single.name, name);
    expect(String.fromCharCodes(saved.single.bytes.sublist(0, 5)), '%PDF-');
    expect(find.text('Exported $name'), findsOneWidget);
    // The panel stays, for another export.
    expect(exportEnabled(tester), isTrue);
  });

  testPage('one list as CSV is a file of its own', (tester) async {
    await open(tester);
    await tap(tester, find.text(ExportFormat.csv.label));
    expect(find.text('livestock-export-${today()}.zip'), findsOneWidget);
    for (final title in [
      'Movements',
      'Stock on hand',
      'Tags',
      'Templates and classes',
    ]) {
      await tap(tester, inPanel(find.text(title)));
    }
    await tap(tester, exportButton());

    expect(saved.single.name, 'properties-and-paddocks-${today()}.csv');
    expect(saved.single.mimeType, 'text/csv');
  });

  testPage('a cancelled save says nothing', (tester) async {
    save = (file) async {
      saved.add(file);
      return false;
    };
    await open(tester);
    await tap(tester, exportButton());

    expect(saved, hasLength(1));
    expect(find.textContaining('Exported'), findsNothing);
    expect(exportEnabled(tester), isTrue);
  });

  testPage('a failed save says why and can be tried again', (tester) async {
    save = (_) async => throw StateError('disk full');
    await open(tester);
    await tap(tester, exportButton());

    expect(find.textContaining('disk full'), findsOneWidget);
    expect(exportEnabled(tester), isTrue);
  });

  for (final width in [320.0, 700.0, 1000.0, 1700.0]) {
    testPage('fits ${width.round()} dp', (tester) async {
      await open(tester, width: width);
      expect(tester.takeException(), isNull);
      await tap(tester, find.text(ExportFormat.json.label));
      expect(tester.takeException(), isNull);
    });
  }

  group('the bar leads to the Data tab', () {
    Finder inBar(Finder finder) =>
        find.descendant(of: find.byType(TrailBar), matching: finder);

    for (final location in ['/', '/activity']) {
      testPage('from $location, labelled on a wide window', (tester) async {
        await pumpRouted(
          tester,
          repository: repo,
          location: location,
          width: 1200,
        );
        await tester.tap(inBar(find.widgetWithText(TextButton, 'Export')));
        await settle(tester);
        expect(find.byType(ExportPanel), findsOneWidget);
        expect(find.byType(FormDialog), findsNothing);
      });

      testPage('from $location, as an icon on a phone', (tester) async {
        await pumpRouted(tester, repository: repo, location: location);
        expect(inBar(find.text('Export')), findsNothing);
        await tester.tap(inBar(find.byTooltip('Export')));
        await settle(tester);
        expect(find.byType(ExportPanel), findsOneWidget);
      });
    }

    testPage('not on Settings, which holds it', (tester) async {
      await pumpRouted(tester, repository: repo, location: '/settings');
      expect(inBar(find.byTooltip('Export')), findsNothing);
    });

    testPage('again after leaving it for the settings tab', (tester) async {
      await pumpRouted(tester, repository: repo, location: '/', width: 1200);
      Future<void> export() async {
        await tester.tap(inBar(find.widgetWithText(TextButton, 'Export')));
        await settle(tester);
      }

      await export();
      await tester.tap(find.widgetWithText(Tab, 'Settings'));
      await settle(tester);
      expect(find.text('Ended stock'), findsOneWidget);

      await tester.tap(find.text('Home').first);
      await settle(tester);
      await export();
      expect(find.byType(ExportPanel), findsOneWidget);
      expect(find.text('Ended stock'), findsNothing);
    });

    testPage("from a paddock's history, with it and its property chosen", (
      tester,
    ) async {
      final property = (await repo.properties()).single.id;
      await repo.createProperty('Glenmore Station');
      final paddock = await repo.createPaddock(property, 'North Flat');

      await pumpRouted(
        tester,
        repository: repo,
        location: '/activity?paddock=$paddock',
        width: 1200,
      );
      await tester.tap(inBar(find.widgetWithText(TextButton, 'Export')));
      await settle(tester);

      expect(
        tester.widget<SearchPicker<String>>(picker('Property')).value,
        property,
      );
      expect(
        tester.widget<SearchPicker<String>>(picker('Paddock')).value,
        paddock,
      );
      expect(inPanel(find.text('Riverbend Downs')), findsOneWidget);
      expect(inPanel(find.text('North Flat')), findsOneWidget);
    });
  });
}
