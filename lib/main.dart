import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/app.dart';
import 'data/app_database.dart';
import 'data/livestock_repository.dart';
import 'features/developer/dev_log.dart';
import 'features/developer/dev_mode.dart';
import 'features/developer/dev_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  if (devMode) DevLog.instance.install();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'Roboto',
    ], await rootBundle.loadString('assets/fonts/Roboto_LICENSE.txt'));
    yield LicenseEntryWithLineBreaks(const [
      'IconOven',
    ], await rootBundle.loadString('assets/icons/IconOven_LICENSE.txt'));
  });

  final repository = LivestockRepository(AppDatabase.defaults());
  await repository.seedTemplatesIfEmpty();

  runApp(
    PropertyManagementApp(
      repository: repository,
      devSettings: devMode ? DevSettings() : null,
    ),
  );
}
