import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/livestock_repository.dart';
import '../data/repository_scope.dart';
import '../features/developer/dev_settings.dart';
import 'router.dart';
import 'theme.dart';

export 'router.dart' show HomeDestination, homeDestinations;

class PropertyManagementApp extends StatefulWidget {
  const PropertyManagementApp({
    super.key,
    required this.repository,
    this.devSettings,
  });

  final LivestockRepository repository;

  /// Null outside debug builds.
  final DevSettings? devSettings;

  @override
  State<PropertyManagementApp> createState() => _PropertyManagementAppState();
}

class _PropertyManagementAppState extends State<PropertyManagementApp> {
  // Built once, so a theme or dev-setting change keeps the navigation state.
  final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.devSettings;
    return RepositoryScope(
      repository: widget.repository,
      child: settings == null
          ? _app()
          : DevSettingsScope(
              settings: settings,
              child: ListenableBuilder(
                listenable: settings,
                builder: (context, _) => _app(settings),
              ),
            ),
    );
  }

  Widget _app([DevSettings? settings]) {
    return MaterialApp.router(
      routerConfig: _router,
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      // Follows the OS setting on all six targets, including the browser's
      // prefers-color-scheme.
      themeMode: settings?.themeMode ?? ThemeMode.system,
      showPerformanceOverlay: settings?.performanceOverlay ?? false,
      showSemanticsDebugger: settings?.semanticsDebugger ?? false,
      builder: settings?.apply,
    );
  }
}
