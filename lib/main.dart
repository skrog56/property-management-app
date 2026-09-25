import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/app_database.dart';
import 'data/livestock_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = LivestockRepository(AppDatabase.defaults());
  await repository.seedTemplatesIfEmpty();

  runApp(PropertyManagementApp(repository: repository));
}
