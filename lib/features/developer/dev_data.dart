import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show immutable;

import '../../data/livestock_repository.dart';
import '../../data/tables.dart';

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
    final templates = await this.templates();
    if (templates.isEmpty) {
      throw StateError('No templates to draw livestock classes from');
    }
    final template = templates.firstWhere(
      (t) => t.name == 'Beef',
      orElse: () => templates.first,
    );
    final classes = await classesIn(template.id);
    if (classes.length < 2) {
      throw StateError('Template ${template.name} needs at least two classes');
    }

    final young = classes.first;
    final older = classes.firstWhere(
      (c) => c.id == young.agesIntoClassId,
      orElse: () => classes[1],
    );

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

    await record(
      kind: MovementKind.intake,
      head: 120,
      toPaddockId: northFlat,
      toClassId: young.id,
      occurredAt: daysAgo(42),
    );
    await record(
      kind: MovementKind.intake,
      head: 200,
      toPaddockId: topRun,
      toClassId: older.id,
      occurredAt: daysAgo(35),
    );
    await record(
      kind: MovementKind.move,
      head: 40,
      fromPaddockId: northFlat,
      fromClassId: young.id,
      toPaddockId: creek,
      toClassId: young.id,
      occurredAt: daysAgo(28),
    );
    await record(
      kind: MovementKind.age,
      head: 30,
      fromPaddockId: creek,
      fromClassId: young.id,
      toPaddockId: creek,
      toClassId: older.id,
      occurredAt: daysAgo(21),
    );
    await record(
      kind: MovementKind.move,
      head: 50,
      fromPaddockId: topRun,
      fromClassId: older.id,
      toPaddockId: bottomRun,
      toClassId: older.id,
      occurredAt: daysAgo(14),
    );
    await record(
      kind: MovementKind.endState,
      head: 20,
      fromPaddockId: bottomRun,
      fromClassId: older.id,
      endState: EndState.sold,
      note: 'Sample sale',
      occurredAt: daysAgo(7),
    );
    await record(
      kind: MovementKind.endState,
      head: 1,
      fromPaddockId: northFlat,
      fromClassId: young.id,
      endState: EndState.died,
      occurredAt: daysAgo(2),
    );
  }
}
