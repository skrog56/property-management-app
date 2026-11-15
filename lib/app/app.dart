import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/livestock_repository.dart';
import '../data/repository_scope.dart';
import '../features/developer/dev_settings.dart';
import 'locale.dart';
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
    final dev = widget.devSettings;
    final app = ListenableBuilder(
      listenable: Listenable.merge([widget.repository.settings, ?dev]),
      builder: (context, _) => _app(dev),
    );
    return RepositoryScope(
      repository: widget.repository,
      child: dev == null ? app : DevSettingsScope(settings: dev, child: app),
    );
  }

  Widget _app(DevSettings? dev) {
    return MaterialApp.router(
      routerConfig: _router,
      title: appTitle,
      debugShowCheckedModeBanner: false,
      locale: appLocale,
      supportedLocales: const [appLocale],
      localizationsDelegates: appLocalizations,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      // System follows the OS on all six targets, including the browser's
      // prefers-color-scheme.
      themeMode: widget.repository.settings.themeMode,
      showPerformanceOverlay: dev?.performanceOverlay ?? false,
      showSemanticsDebugger: dev?.semanticsDebugger ?? false,
      builder: dev?.apply,
    );
  }
}
