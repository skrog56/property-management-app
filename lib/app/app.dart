import 'package:flutter/material.dart';

import '../data/livestock_repository.dart';
import '../data/repository_scope.dart';
import '../features/about/about_page.dart';
import '../features/activity/activity_page.dart';
import '../features/platform_proof/platform_proof_page.dart';
import '../features/properties/properties_page.dart';
import '../features/templates/templates_page.dart';
import '../shell/adaptive_scaffold.dart';
import 'theme.dart';

class PropertyManagementApp extends StatelessWidget {
  const PropertyManagementApp({super.key, required this.repository});

  final LivestockRepository repository;

  @override
  Widget build(BuildContext context) {
    return RepositoryScope(
      repository: repository,
      child: MaterialApp(
        title: 'Property Management App',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        // Follows the OS setting on all six targets, including the browser's
        // prefers-color-scheme.
        themeMode: ThemeMode.system,
        home: const _HomeShell(),
      ),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _selectedIndex = 0;

  static const _destinations = [
    AppDestination(
      label: 'Properties',
      icon: Icons.home_work_outlined,
      selectedIcon: Icons.home_work,
    ),
    AppDestination(
      label: 'Activity',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
    ),
    AppDestination(
      label: 'Templates',
      icon: Icons.list_alt_outlined,
      selectedIcon: Icons.list_alt,
    ),
    AppDestination(
      label: 'Platform',
      icon: Icons.verified_outlined,
      selectedIcon: Icons.verified,
    ),
    AppDestination(
      label: 'About',
      icon: Icons.info_outline,
      selectedIcon: Icons.info,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      destinations: _destinations,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) =>
          setState(() => _selectedIndex = index),
      body: switch (_selectedIndex) {
        0 => const PropertiesPage(),
        1 => const ActivityPage(),
        2 => const TemplatesPage(),
        3 => const PlatformProofPage(),
        _ => const AboutPage(),
      },
    );
  }
}
