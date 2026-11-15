import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/app/theme.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/livestock_repository.dart';
import 'package:property_management_app/data/tables.dart';
import 'package:property_management_app/features/templates/class_line.dart';
import 'package:property_management_app/shell/search_picker.dart';

import 'support.dart';

void main() {
  late AppDatabase db;
  late LivestockRepository repo;
  late List<StockClass> classes;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = LivestockRepository(db);
    for (final (name, species, kinds) in [
      ('Backgrounders', Species.cattle, ['Steers', 'Heifers']),
      ('Feeders', Species.cattle, ['Steers', 'Heifers']),
      ('Flock', Species.sheep, ['Ewes', 'Wethers']),
    ]) {
      final template = await repo.createTemplate(name, species: species);
      for (final kind in kinds) {
        await repo.createClass(template, kind: kind);
      }
    }
    classes = await repo.allClasses();
  });

  tearDown(() => db.close());

  String idOf(String label) => classes.firstWhere((c) => c.label == label).id;

  /// The picker, and every value it has reported, last first.
  Future<List<String?>> pumpPicker(
    WidgetTester tester, {
    List<StockClass>? among,
    String? initial,
  }) async {
    final reported = <String?>[];
    var value = initial;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (context, setState) => SearchPicker<String>(
                label: 'Class',
                entries: [for (final c in among ?? classes) classEntry(c)],
                emptyHint: 'No classes yet: add one in Templates',
                value: value,
                onChanged: (id) => setState(() {
                  value = id;
                  reported.insert(0, id);
                }),
              ),
            ),
          ),
        ),
      ),
    );
    return reported;
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), text);
    await tester.pumpAndSettle();
  }

  List<String> offered(WidgetTester tester) => [
    for (final text in tester.widgetList<Text>(
      find.descendant(
        of: find.byType(MenuItemButton),
        matching: find.byType(Text),
      ),
    ))
      text.data!,
  ];

  testWidgets('narrows to the classes holding every word, in any order', (
    tester,
  ) async {
    await pumpPicker(tester);
    await type(tester, 'feed hei');
    expect(offered(tester), ['Heifers (Feeders)']);

    await type(tester, 'HEIFERS');
    expect(offered(tester), ['Heifers (Backgrounders)', 'Heifers (Feeders)']);
  });

  testWidgets('finds classes by their animal too', (tester) async {
    await pumpPicker(tester);
    await type(tester, 'sheep');
    expect(offered(tester), ['Ewes (Flock)', 'Wethers (Flock)']);
  });

  testWidgets('Enter chooses the best match, and editing unchooses it', (
    tester,
  ) async {
    final reported = await pumpPicker(tester);
    await type(tester, 'feed st');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(reported.first, idOf('Steers (Feeders)'));
    expect(find.text('Steers (Feeders)'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Steers (Feed');
    await tester.pumpAndSettle();
    expect(reported.first, isNull);
    // Still as typed, not cleared to match.
    expect(find.text('Steers (Feed'), findsOneWidget);
  });

  testWidgets('typing a label exactly chooses it', (tester) async {
    final reported = await pumpPicker(tester);
    await type(tester, 'Ewes (Flock)');
    expect(reported, [idOf('Ewes (Flock)')]);
    expect(find.byTooltip('Sheep'), findsWidgets);
  });

  testWidgets('follows a value the form chooses itself', (tester) async {
    String? value;
    late StateSetter set;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return SearchPicker<String>(
                label: 'Class',
                entries: [for (final c in classes) classEntry(c)],
                emptyHint: '',
                value: value,
                onChanged: (id) => setState(() => value = id),
              );
            },
          ),
        ),
      ),
    );
    set(() => value = idOf('Wethers (Flock)'));
    await tester.pumpAndSettle();
    expect(find.text('Wethers (Flock)'), findsOneWidget);
    set(() => value = null);
    await tester.pumpAndSettle();
    expect(find.text('Wethers (Flock)'), findsNothing);
  });

  testWidgets('shows the class already chosen, with its animal', (
    tester,
  ) async {
    await pumpPicker(tester, initial: idOf('Ewes (Flock)'));
    expect(find.text('Ewes (Flock)'), findsOneWidget);
    expect(find.byTooltip('Sheep'), findsOneWidget);
  });

  testWidgets('a long list scrolls rather than filling the window', (
    tester,
  ) async {
    final flock = await repo.createTemplate('Big', species: Species.goat);
    for (var i = 0; i < 30; i++) {
      await repo.createClass(flock, kind: 'Kind $i');
    }
    await pumpPicker(tester, among: await repo.allClasses());
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    final menu = find.ancestor(
      of: find.byType(MenuItemButton).first,
      matching: find.byType(Scrollable),
    );
    expect(tester.getSize(menu.first).height, lessThanOrEqualTo(360));
  });

  testWidgets('reads as a plain dropdown: its entries, value and hint', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: 'x',
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'x', child: Text('Plain value')),
                  DropdownMenuItem(value: 'y', child: Text('Plain entry')),
                ],
                onChanged: (_) {},
              ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                hint: const Text('Plain hint'),
                items: const [DropdownMenuItem(value: 'x', child: Text('x'))],
                onChanged: (_) {},
              ),
              SearchPicker<String>(
                label: 'Chosen',
                entries: const [SearchEntry('x', 'Picker value')],
                value: 'x',
                onChanged: (_) {},
                emptyHint: '',
              ),
              SearchPicker<String>(
                label: 'Open',
                entries: const [SearchEntry('y', 'Picker entry')],
                value: null,
                hint: 'Picker hint',
                onChanged: (_) {},
                emptyHint: '',
              ),
            ],
          ),
        ),
      ),
    );
    TextStyle shown(String text) => tester
        .widgetList<RichText>(find.byType(RichText))
        .lastWhere((r) => r.text.toPlainText() == text)
        .text
        .style!;
    void expectAlike(TextStyle picker, TextStyle plain, String what) {
      expect(picker.fontSize, plain.fontSize, reason: what);
      expect(picker.fontWeight, plain.fontWeight, reason: what);
      expect(picker.letterSpacing, plain.letterSpacing, reason: what);
      expect(picker.height, plain.height, reason: what);
    }

    expectAlike(
      tester.widget<EditableText>(find.byType(EditableText).first).style,
      shown('Plain value'),
      'value',
    );
    expectAlike(shown('Picker hint'), shown('Plain hint'), 'hint');

    await tester.tap(find.text('Plain value'));
    await tester.pumpAndSettle();
    final plainEntry = shown('Plain entry');
    await tester.tap(find.text('Plain value').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField).last);
    await tester.pumpAndSettle();
    expectAlike(shown('Picker entry'), plainEntry, 'entry');
  });

  testPage('says when there is nothing to choose', (tester) async {
    await pumpPicker(tester, among: const []);
    expect(find.text('No classes yet: add one in Templates'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });
}
