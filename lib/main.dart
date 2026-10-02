import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/app_database.dart';
import 'data/livestock_repository.dart';
import 'features/developer/dev_log.dart';
import 'features/developer/dev_mode.dart';
import 'features/developer/dev_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (devMode) DevLog.instance.install();

  final repository = LivestockRepository(AppDatabase.defaults());
  await repository.seedTemplatesIfEmpty();

  runApp(
    PropertyManagementApp(
      repository: repository,
      devSettings: devMode ? DevSettings() : null,
    ),
  );
}
