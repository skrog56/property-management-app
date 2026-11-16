import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/livestock_repository.dart';
import 'package:property_management_app/features/export/export_dialog.dart';
import 'package:property_management_app/features/export/export_formats.dart';
import 'package:property_management_app/features/export/save_export.dart';
import 'package:property_management_app/features/settings/settings_page.dart';
import 'package:property_management_app/shell/form_dialog.dart';

import 'support.dart';

void main() {
  late AppDatabase db;
  late LivestockRepository repo;
  late List<ExportFile> saved;
  late bool keep;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = LivestockRepository(db);
    await repo.createProperty('Riverbend Downs');
    saved = [];
    keep = true;
  });

  tearDown(() => db.close());

  Future<bool> save(ExportFile file) async {
    saved.add(file);
    return keep;
  }

  Future<void> open(WidgetTester tester, {double width = 420}) async {
    await pumpPage(
      tester,
      SettingsPage(exportSaver: save),
      repository: repo,
      width: width,
    );
    final button = find.text('Export…');
    await tester.scrollUntilVisible(
      button,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(button);
    await settle(tester);
    await tester.tap(button);
    await settle(tester);
    expect(find.byType(ExportDialog), findsOneWidget);
  }

  Finder exportButton() => find.widgetWithText(FilledButton, 'Export');

  bool exportEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(exportButton()).onPressed != null;

  Future<void> chooseFormat(WidgetTester tester, ExportFormat format) async {
    await tester.tap(find.byType(DropdownButtonFormField<ExportFormat>));
    await settle(tester);
    await tester.tap(find.text(format.label).last);
    await settle(tester);
  }

  /// Types [date] into the picker the field opens.
  Future<void> typeDate(WidgetTester tester, String field, String date) async {
    await tester.tap(
      find.ancestor(of: find.text(field), matching: find.byType(InkWell)).first,
    );
    await settle(tester);
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

  testPage('opens from Settings with every list ticked', (tester) async {
    await open(tester);

    expect(find.text(ExportFormat.xlsx.label), findsOneWidget);
    final boxes = tester.widgetList<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(boxes, hasLength(5));
    expect(boxes.every((box) => box.value!), isTrue);
    expect(find.text('All properties'), findsOneWidget);
    expect(exportEnabled(tester), isTrue);
  });

  testPage('no list ticked blocks the export', (tester) async {
    await open(tester);
    for (final box in find.byType(CheckboxListTile).evaluate().toList()) {
      await tester.tap(find.byWidget(box.widget));
      await tester.pump();
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
      find.descendant(
        of: find.byType(Row),
        matching: find.byType(InputDecorator),
      ),
    );
    expect(
      decorators.where((d) => d.decoration.error == wrongField),
      hasLength(2),
    );

    await tester.tap(find.byTooltip('Clear From'));
    await tester.pump();
    expect(find.text('From is after To'), findsNothing);
    expect(exportEnabled(tester), isTrue);
  });

  testPage('a JSON backup is the whole farm, so asks nothing more', (
    tester,
  ) async {
    await open(tester);
    await chooseFormat(tester, ExportFormat.json);

    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.text('All properties'), findsNothing);
    expect(find.textContaining('always holds the whole farm'), findsOneWidget);

    await tester.tap(exportButton());
    await settle(tester);
    expect(saved.single.name, endsWith('.json'));
  });

  testPage('Export hands the file over, closes and says so', (tester) async {
    await open(tester);
    await tester.tap(exportButton());
    await settle(tester);

    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final name =
        'livestock-export-${now.year}-${two(now.month)}-${two(now.day)}.xlsx';
    expect(saved.single.name, name);
    expect(saved.single.bytes.sublist(0, 2), 'PK'.codeUnits);
    expect(find.byType(ExportDialog), findsNothing);
    expect(find.text('Exported $name'), findsOneWidget);
  });

  testPage('one list as CSV is a file of its own', (tester) async {
    await open(tester);
    await chooseFormat(tester, ExportFormat.csv);
    for (final title in [
      'Movements',
      'Stock on hand',
      'Tags',
      'Templates and classes',
    ]) {
      await tester.tap(find.text(title));
      await tester.pump();
    }
    await tester.tap(exportButton());
    await settle(tester);

    expect(saved.single.name, startsWith('properties-and-paddocks-'));
    expect(saved.single.mimeType, 'text/csv');
  });

  testPage('a cancelled save leaves the dialog open', (tester) async {
    keep = false;
    await open(tester);
    await tester.tap(exportButton());
    await settle(tester);

    expect(saved, hasLength(1));
    expect(find.byType(ExportDialog), findsOneWidget);
    expect(exportEnabled(tester), isTrue);
  });

  testPage('a failed save says why and can be tried again', (tester) async {
    await pumpPage(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showExportDialog(
            context,
            save: (_) async => throw StateError('disk full'),
          ),
          child: const Text('go'),
        ),
      ),
      repository: repo,
    );
    await tester.tap(find.text('go'));
    await settle(tester);
    await tester.tap(exportButton());
    await settle(tester);

    expect(find.textContaining('disk full'), findsOneWidget);
    expect(exportEnabled(tester), isTrue);
  });

  testPage('fits a narrow phone', (tester) async {
    await open(tester, width: 320);
    expect(tester.takeException(), isNull);
  });
}
