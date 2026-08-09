import 'package:flutter/material.dart';

import '../features/about/about_page.dart';
import '../features/paddocks/paddocks_page.dart';
import '../features/platform_proof/platform_proof_page.dart';
import '../shell/adaptive_scaffold.dart';
import 'theme.dart';

class PropertyManagementApp extends StatelessWidget {
  const PropertyManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skrog Pilot',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      // Follows the OS setting on all six targets, including the browser's
      // prefers-color-scheme.
      themeMode: ThemeMode.system,
      home: const _HomeShell(),
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
      label: 'Platform',
      icon: Icons.verified_outlined,
      selectedIcon: Icons.verified,
    ),
    AppDestination(
      label: 'Paddocks',
      icon: Icons.grass_outlined,
      selectedIcon: Icons.grass,
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
        0 => const PlatformProofPage(),
        1 => const PaddocksPage(),
        _ => const AboutPage(),
      },
    );
  }
}
