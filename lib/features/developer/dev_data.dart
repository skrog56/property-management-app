import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show immutable;

import '../../data/livestock_repository.dart';
import '../../data/tables.dart';
import '../../data/tag_numbers.dart';

@immutable
class TableCount {
  const TableCount({
    required this.name,
    required this.live,
    required this.total,
  });

  final String name;
  final int live;
  final int total;

  int get deleted => total - live;
}

extension DevData on LivestockRepository {
  /// Hard-deletes every row, children first so foreign keys hold, then puts
  /// the built-in templates back. A developer reset, never a domain operation.
  Future<void> wipe() async {
    await db.transaction(() async {
      for (final TableInfo table in [
        db.movementTags,
        db.livestockTags,
        db.movements,
        db.paddocks,
        db.properties,
        db.livestockClasses,
        db.templates,
      ]) {
        await db.delete(table).go();
      }
    });
    await seedTemplatesIfEmpty();
  }

  Stream<List<TableCount>> watchTableCounts() {
    final tables = db.allTables.toList();
    final sql = [
      for (final t in tables)
        "SELECT '${t.actualTableName}' AS name, "
            'COUNT(*) AS total, '
            'COUNT(*) - COUNT(deleted_at) AS live '
            'FROM "${t.actualTableName}"',
    ].join(' UNION ALL ');

    return db
        .customSelect(sql, readsFrom: tables.toSet())
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              TableCount(
                name: row.read<String>('name'),
                live: row.read<int>('live'),
                total: row.read<int>('total'),
              ),
          ],
        );
  }

  Future<List<Map<String, Object?>>> rawRows(
    String tableName, {
    int limit = 200,
  }) async {
    final table = db.allTables.firstWhere(
      (t) => t.actualTableName == tableName,
    );
    final rows = await db
        .customSelect(
          'SELECT * FROM "${table.actualTableName}" '
          'ORDER BY created_at DESC LIMIT ?1',
          variables: [Variable<int>(limit)],
          readsFrom: {table},
        )
        .get();
    return [for (final row in rows) row.data];
  }

  /// Two properties with a few weeks of history, recorded through [record] so
  /// the sample obeys the same ledger rules as real use.
  Future<void> seedSampleFarm() async {
    final classes = await allClasses();
    StockClass find(String template, String kind, {bool ready = false}) =>
        classes.firstWhere(
          (c) =>
              c.template.name == template &&
              c.row.kind == kind &&
              c.isReadyToSell == ready,
          orElse: () => throw StateError('No $kind in $template to draw on'),
        );
    final calves = find('Breeder', 'Calves').id;
    final weaners = find('Breeder', 'Weaners').id;
    final steers = find('Feeders', 'Steers').id;
    final readySteers = find('Feeders', 'Steers', ready: true).id;

    final riverbend = await createProperty('Riverbend Downs', pic: 'QDEV0001');
    final northFlat = await createPaddock(
      riverbend,
      'North Flat',
      hectares: 120,
    );
    final creek = await createPaddock(riverbend, 'Creek Paddock', hectares: 80);
    await createPaddock(riverbend, 'House Yards', hectares: 5);

    final glenmore = await createProperty('Glenmore Station');
    final topRun = await createPaddock(glenmore, 'Top Run', hectares: 300);
    final bottomRun = await createPaddock(
      glenmore,
      'Bottom Run',
      hectares: 250,
    );

    final now = DateTime.now();
    DateTime daysAgo(int days) => now.subtract(Duration(days: days));

    // ISO 11784 reserves manufacturer code 999 for test transponders, so none
    // of these can be a real device's number.
    final tags = [
      for (var i = 1; i <= 4; i++)
        TagNumber.tryParse(TagScheme.nlis, '99900000000000$i')!,
    ];

    await record(
      kind: MovementKind.intake,
      head: 120,
      toPaddockId: northFlat,
      toClassId: calves,
      occurredAt: daysAgo(42),
      tags: tags.sublist(0, 3),
    );
    await record(
      kind: MovementKind.intake,
      head: 200,
      toPaddockId: topRun,
      toClassId: steers,
      occurredAt: daysAgo(35),
    );
    await record(
      kind: MovementKind.move,
      head: 40,
      fromPaddockId: northFlat,
      fromClassId: calves,
      toPaddockId: creek,
      toClassId: calves,
      occurredAt: daysAgo(28),
      tags: [tags[0]],
    );
    await record(
      kind: MovementKind.age,
      head: 30,
      fromPaddockId: creek,
      fromClassId: calves,
      toPaddockId: creek,
      toClassId: weaners,
      occurredAt: daysAgo(21),
      tags: [tags[0]],
    );
    await record(
      kind: MovementKind.move,
      head: 50,
      fromPaddockId: topRun,
      fromClassId: steers,
      toPaddockId: bottomRun,
      toClassId: steers,
      occurredAt: daysAgo(14),
    );
    final lost = await tagStatusByNumber(tags[2]);
    await replaceTag(
      lost!.tag.id,
      tags[3],
      reason: TagReason.lost,
      occurredAt: daysAgo(10),
    );
    await record(
      kind: MovementKind.readyToSell,
      head: 30,
      fromPaddockId: bottomRun,
      fromClassId: steers,
      toPaddockId: bottomRun,
      toClassId: readySteers,
      occurredAt: daysAgo(9),
    );
    await record(
      kind: MovementKind.endState,
      head: 20,
      fromPaddockId: bottomRun,
      fromClassId: readySteers,
      endState: EndState.sold,
      note: 'Sample sale',
      occurredAt: daysAgo(7),
    );
    await record(
      kind: MovementKind.endState,
      head: 1,
      fromPaddockId: northFlat,
      fromClassId: calves,
      endState: EndState.died,
      note: 'Found in the dam',
      occurredAt: daysAgo(2),
      tags: [tags[1]],
    );
  }
}
