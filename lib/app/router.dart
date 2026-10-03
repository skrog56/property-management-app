import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/about/about_page.dart';
import '../features/activity/activity_page.dart';
import '../features/developer/dev_mode.dart';
import '../features/developer/developer_page.dart';
import '../features/properties/paths.dart';
import '../features/properties/properties_browser.dart';
import '../features/templates/templates_page.dart';
import '../shell/adaptive_scaffold.dart';

const appTitle = 'Property Management App';

typedef HomeDestination = ({AppDestination destination, GoRoute route});

List<HomeDestination> homeDestinations({bool developer = devMode}) => [
  (
    destination: const AppDestination(
      label: 'Properties',
      icon: Icons.home_work_outlined,
      selectedIcon: Icons.home_work,
    ),
    route: GoRoute(
      path: propertiesPath,
      pageBuilder: (_, state) => PropertiesBrowserPage(key: state.pageKey),
      routes: [
        GoRoute(
          path: ':propertyId',
          pageBuilder: (_, state) => PropertiesBrowserPage(
            key: state.pageKey,
            propertyId: state.pathParameters['propertyId'],
          ),
          routes: [
            GoRoute(
              path: 'paddocks/:paddockId',
              pageBuilder: (_, state) => PropertiesBrowserPage(
                key: state.pageKey,
                propertyId: state.pathParameters['propertyId'],
                paddockId: state.pathParameters['paddockId'],
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  (
    destination: const AppDestination(
      label: 'Activity',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
    ),
    route: GoRoute(path: '/activity', builder: (_, _) => const ActivityPage()),
  ),
  (
    destination: const AppDestination(
      label: 'Templates',
      icon: Icons.list_alt_outlined,
      selectedIcon: Icons.list_alt,
    ),
    route: GoRoute(
      path: '/templates',
      builder: (_, _) => const TemplatesPage(),
    ),
  ),
  if (developer)
    (
      destination: const AppDestination(
        label: 'Developer',
        icon: Icons.developer_mode_outlined,
        selectedIcon: Icons.developer_mode,
      ),
      route: GoRoute(
        path: '/developer',
        builder: (_, _) => const DeveloperPage(),
      ),
    ),
  (
    destination: const AppDestination(
      label: 'About',
      icon: Icons.info_outline,
      selectedIcon: Icons.info,
    ),
    route: GoRoute(path: '/about', builder: (_, _) => const AboutPage()),
  ),
];

GoRouter buildRouter({
  String initialLocation = propertiesPath,
  bool developer = devMode,
}) {
  final entries = homeDestinations(developer: developer);

  return GoRouter(
    initialLocation: initialLocation,
    onException: (_, _, router) => router.go(propertiesPath),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => propertiesPath),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AdaptiveScaffold(
          destinations: [for (final e in entries) e.destination],
          selectedIndex: shell.currentIndex,
          // Reselecting the current destination returns to its top.
          onDestinationSelected: (index) => shell.goBranch(
            index,
            initialLocation: index == shell.currentIndex,
          ),
          showAppBar: entries[shell.currentIndex].route.path != propertiesPath,
          title: appTitle,
          body: shell,
        ),
        branches: [
          for (final e in entries) StatefulShellBranch(routes: [e.route]),
        ],
      ),
    ],
  );
}
