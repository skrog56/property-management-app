import 'package:flutter/material.dart';

import '../data/livestock_repository.dart';
import '../data/repository_scope.dart';
import '../features/about/about_page.dart';
import '../features/activity/activity_page.dart';
import '../features/developer/dev_mode.dart';
import '../features/developer/dev_settings.dart';
import '../features/developer/developer_page.dart';
import '../features/properties/properties_page.dart';
import '../features/templates/templates_page.dart';
import '../shell/adaptive_scaffold.dart';
import 'theme.dart';

class PropertyManagementApp extends StatelessWidget {
  const PropertyManagementApp({
    super.key,
    required this.repository,
    this.devSettings,
  });

  final LivestockRepository repository;

  /// Null outside debug builds.
  final DevSettings? devSettings;

  @override
  Widget build(BuildContext context) {
    final settings = devSettings;
    return RepositoryScope(
      repository: repository,
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
    return MaterialApp(
      title: 'Property Management App',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      // Follows the OS setting on all six targets, including the browser's
      // prefers-color-scheme.
      themeMode: settings?.themeMode ?? ThemeMode.system,
      showPerformanceOverlay: settings?.performanceOverlay ?? false,
      showSemanticsDebugger: settings?.semanticsDebugger ?? false,
      builder: settings?.apply,
      home: const _HomeShell(),
    );
  }
}

typedef HomeDestination = ({AppDestination destination, WidgetBuilder page});

List<HomeDestination> homeDestinations({bool developer = devMode}) => [
  (
    destination: const AppDestination(
      label: 'Properties',
      icon: Icons.home_work_outlined,
      selectedIcon: Icons.home_work,
    ),
    page: (_) => const PropertiesPage(),
  ),
  (
    destination: const AppDestination(
      label: 'Activity',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
    ),
    page: (_) => const ActivityPage(),
  ),
  (
    destination: const AppDestination(
      label: 'Templates',
      icon: Icons.list_alt_outlined,
      selectedIcon: Icons.list_alt,
    ),
    page: (_) => const TemplatesPage(),
  ),
  if (developer)
    (
      destination: const AppDestination(
        label: 'Developer',
        icon: Icons.developer_mode_outlined,
        selectedIcon: Icons.developer_mode,
      ),
      page: (_) => const DeveloperPage(),
    ),
  (
    destination: const AppDestination(
      label: 'About',
      icon: Icons.info_outline,
      selectedIcon: Icons.info,
    ),
    page: (_) => const AboutPage(),
  ),
];

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  final _entries = homeDestinations();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      destinations: [for (final e in _entries) e.destination],
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      body: _entries[_selectedIndex].page(context),
    );
  }
}
