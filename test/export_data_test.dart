import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/app_settings.dart';
import 'package:property_management_app/data/livestock_repository.dart';
import 'package:property_management_app/features/developer/dev_data.dart';
import 'package:property_management_app/features/export/export_data.dart';

void main() {
  // The default templates come from the asset bundle.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LivestockRepository repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = LivestockRepository(db);
    await repo.seedTemplatesIfEmpty();
    await repo.settings.load();
    await repo.seedSampleFarm();
  });

  tearDown(() => db.close());

  Future<ExportSheet> sheet(
    ExportList list, {
    ExportRange range = ExportRange.everything,
  }) async => (await repo.exportSheets({list}, range: range)).single;

  Future<String> propertyId(String name) async =>
      (await repo.properties()).firstWhere((p) => p.name == name).id;

  List<Object?> column(ExportSheet sheet, String name) {
    final index = sheet.columns.indexOf(name);
    return [for (final row in sheet.rows) row[index]];
  }

  test('lists come in their own order, whichever are asked for', () async {
    final sheets = await repo.exportSheets({
      ExportList.templates,
      ExportList.movements,
    });
    expect(sheets.map((s) => s.list), [
      ExportList.movements,
      ExportList.templates,
    ]);
    for (final s in sheets) {
      for (final row in s.rows) {
        expect(row, hasLength(s.columns.length));
      }
    }
  });

  test('movements are every one, newest first, named in full', () async {
    final movements = await sheet(ExportList.movements);

    expect(movements.rows, hasLength(9));
    final dates = column(movements, 'Date').cast<DateTime>();
    for (var i = 1; i < dates.length; i++) {
      expect(dates[i].isAfter(dates[i - 1]), isFalse);
    }

    final died = movements.rows.first;
    expect(died[movements.columns.indexOf('Type')], 'End');
    expect(died[movements.columns.indexOf('End destination')], 'Died');
    expect(died[movements.columns.indexOf('Property')], 'Riverbend Downs');
    expect(
      died[movements.columns.indexOf('From class')],
      contains('(Breeder)'),
    );
    expect(died[movements.columns.indexOf('Note')], 'Found in the dam');
    expect(died[movements.columns.indexOf('Tags')], '999 000000000002');

    final replaced = movements.rows.firstWhere(
      (row) => row[movements.columns.indexOf('Tags removed')] != '',
    );
    expect(replaced[movements.columns.indexOf('Reason')], 'lost');
  });

  test('a property narrows movements, stock, tags and paddocks', () async {
    final range = ExportRange(propertyId: await propertyId('Glenmore Station'));

    expect(
      (await sheet(ExportList.movements, range: range)).rows,
      hasLength(4),
    );
    expect(
      column(await sheet(ExportList.stock, range: range), 'Property').toSet(),
      {'Glenmore Station'},
    );
    expect(column(await sheet(ExportList.paddocks, range: range), 'Paddock'), [
      'Bottom Run',
      'Top Run',
    ]);
    expect((await sheet(ExportList.tags, range: range)).rows, isEmpty);
  });

  test('a property leaves templates whole', () async {
    final all = await sheet(ExportList.templates);
    final narrowed = await sheet(
      ExportList.templates,
      range: ExportRange(propertyId: await propertyId('Glenmore Station')),
    );
    expect(narrowed.rows, all.rows);
    expect(column(all, 'Ready to sell'), contains('Yes'));
  });

  test('From and To take in both whole days', () async {
    final now = DateTime.now();
    final movements = await sheet(
      ExportList.movements,
      range: ExportRange(
        from: now.subtract(const Duration(days: 10)),
        to: now.subtract(const Duration(days: 7)),
      ),
    );
    expect(column(movements, 'Type'), ['End', 'Ready to sell', 'Tag']);
  });

  test('stock on hand is each mob, with its tagged head', () async {
    final stock = await sheet(ExportList.stock);
    expect(stock.rows, hasLength(6));
    expect(column(stock, 'Head').cast<int>().fold(0, (a, b) => a + b), 299);
    expect(column(stock, 'Tagged').cast<int>().fold(0, (a, b) => a + b), 2);
    expect(column(stock, 'Animal').toSet(), {'Cattle'});
  });

  test('tags say where each is, or how it left', () async {
    final tags = await sheet(ExportList.tags);
    expect(
      column(tags, 'Status'),
      unorderedEquals(['On hand', 'On hand', 'Died', 'Replaced']),
    );
    expect(column(tags, 'Replaced by'), contains('999 000000000004'));
  });

  test('areas follow the chosen unit', () async {
    await repo.settings.setAreaUnit(AreaUnit.acres);
    final paddocks = await sheet(ExportList.paddocks);

    expect(paddocks.columns, contains('Area (ac)'));
    final northFlat = paddocks.rows.firstWhere((r) => r[2] == 'North Flat');
    expect(northFlat[3], closeTo(296.53, 0.01));
  });

  test('a property with no paddocks still has a row', () async {
    await repo.createProperty('Empty Block');
    final paddocks = await sheet(ExportList.paddocks);
    expect(paddocks.rows.where((r) => r[0] == 'Empty Block').single, [
      'Empty Block',
      null,
      null,
      null,
      0,
    ]);
  });

  test('the backup is every table, deleted rows and settings too', () async {
    await repo.settings.setAreaUnit(AreaUnit.acres);
    final template = (await repo.templates()).last;
    await repo.removeTemplate(template.id);

    final tables = await repo.exportTables();
    expect(tables.keys, {for (final t in db.allTables) t.actualTableName});
    expect(tables['movements'], hasLength(9));
    expect(tables['settings'], isNotEmpty);
    expect(
      tables['templates']!.where((row) => row['id'] == template.id).single,
      containsPair('deleted_at', isNotNull),
    );
  });

  test('the developer reset and export read the same tables', () async {
    final counts = await repo.watchTableCounts().first;
    final tables = await repo.exportTables();
    for (final count in counts) {
      expect(tables[count.name], hasLength(count.total), reason: count.name);
    }
  });
}
