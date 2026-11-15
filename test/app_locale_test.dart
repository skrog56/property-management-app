import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/app/app.dart';
import 'package:property_management_app/app/locale.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/livestock_repository.dart';

import 'support.dart';

void main() {
  testPage('the app reads and writes dates in Australian English', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      PropertyManagementApp(repository: LivestockRepository(db)),
    );
    await drain(tester);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, appLocale);
    expect(
      MaterialLocalizations.of(
        tester.element(find.byType(Scaffold).first),
      ).formatCompactDate(DateTime(2001, 1, 15)),
      '15/01/2001',
    );
  });
}
