import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

const storageBackend = 'sqlite3 — WebAssembly, in the browser';

/// `web/sqlite3.wasm` and `web/drift_worker.js` come from the drift release
/// matching the pinned version; without them this compiles and then fails at
/// runtime.
QueryExecutor openConnection() => driftDatabase(
  name: 'livestock',
  web: DriftWebOptions(
    sqlite3Wasm: Uri.parse('sqlite3.wasm'),
    driftWorker: Uri.parse('drift_worker.js'),
  ),
);

/// Drift picks between OPFS and IndexedDB based on what the browser offers;
/// either way it is origin-scoped rather than a path.
Future<String> storageLocation() async => 'Browser origin storage';
