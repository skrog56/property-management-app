import 'package:drift/drift.dart';

const storageBackend = 'unknown';

QueryExecutor openConnection() =>
    throw UnsupportedError('No drift connection for this platform');

Future<String> storageLocation() async => 'not reported';
