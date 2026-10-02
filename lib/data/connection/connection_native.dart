import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

const storageBackend = 'sqlite3 — native library, file on disk';

/// Application support, not documents. Drift's default is the documents
/// directory, which is user-visible clutter and on many machines is cloud
/// synced — and a sync client copying a live SQLite file can corrupt it.
QueryExecutor openConnection() => driftDatabase(
  name: 'livestock',
  native: DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory),
);

Future<String> storageLocation() async =>
    (await getApplicationSupportDirectory()).path;
