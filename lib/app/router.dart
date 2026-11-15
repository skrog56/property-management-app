import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/about/about_page.dart';
import '../features/activity/activity_page.dart';
import '../features/developer/dev_mode.dart';
import '../features/developer/developer_page.dart';
import '../features/home/home_page.dart';
import '../features/properties/paths.dart';
import '../features/properties/properties_browser.dart';
import '../features/tags/paths.dart';
import '../features/tags/tags_browser.dart';
import '../features/templates/templates_page.dart';
import '../shell/adaptive_scaffold.dart';
import '../shell/tier_route.dart';
import '../shell/trail_bar.dart';

const appTitle = 'Property Management App';

const homePath = '/';

/// Destinations whose browser draws its own bar, extending the trail with
/// the tiers it shows.
const _drawOwnBar = {propertiesPath, tagsPath};

typedef HomeDestination = ({AppDestination destination, GoRoute route});

// Not a house, which beside Properties' would read as the same place.
const _home = AppDestination(
  label: 'Home',
  icon: Icons.space_dashboard_outlined,
  selectedIcon: Icons.space_dashboard,
);

const _properties = AppDestination(
  label: 'Properties',
  icon: Icons.home_work_outlined,
  selectedIcon: Icons.home_work,
);

const _tags = AppDestination(
  label: 'Tags',
  icon: Icons.sell_outlined,
  selectedIcon: Icons.sell,
);

/// A destination as a step in a trail, by the icon it has in the rail.
Crumb _crumb(AppDestination destination, String path) =>
    Crumb(icon: destination.icon, label: Text(destination.label), path: path);

/// Every trail starts at Home.
List<Crumb> _trailTo(AppDestination destination, String path) => [
  _crumb(_home, homePath),
  if (path != homePath) _crumb(destination, path),
];

List<HomeDestination> homeDestinations({bool developer = devMode}) {
  final propertiesTrail = _trailTo(_properties, propertiesPath);
  final tagsTrail = _trailTo(_tags, tagsPath);

  return [
    (
      destination: _home,
      route: GoRoute(path: homePath, builder: (_, _) => const HomePage()),
    ),
    (
      destination: _properties,
      route: GoRoute(
        path: propertiesPath,
        pageBuilder: (_, state) => TierPage(
          key: state.pageKey,
          child: PropertiesBrowser(trail: propertiesTrail),
        ),
        routes: [
          GoRoute(
            path: ':propertyId',
            pageBuilder: (_, state) => TierPage(
              key: state.pageKey,
              child: PropertiesBrowser(
                trail: propertiesTrail,
                propertyId: state.pathParameters['propertyId'],
              ),
            ),
            routes: [
              GoRoute(
                path: 'paddocks/:paddockId',
                pageBuilder: (_, state) => TierPage(
                  key: state.pageKey,
                  child: PropertiesBrowser(
                    trail: propertiesTrail,
                    propertyId: state.pathParameters['propertyId'],
                    paddockId: state.pathParameters['paddockId'],
                  ),
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
      route: GoRoute(
        path: '/activity',
        builder: (_, _) => const ActivityPage(),
      ),
    ),
    (
      destination: _tags,
      route: GoRoute(
        path: tagsPath,
        pageBuilder: (_, state) => TierPage(
          key: state.pageKey,
          child: TagsBrowser(
            trail: tagsTrail,
            query: state.uri.queryParameters['q'] ?? '',
          ),
        ),
        routes: [
          GoRoute(
            path: ':tagId',
            pageBuilder: (_, state) => TierPage(
              key: state.pageKey,
              child: TagsBrowser(
                trail: tagsTrail,
                tagId: state.pathParameters['tagId'],
                query: state.uri.queryParameters['q'] ?? '',
              ),
            ),
          ),
        ],
      ),
    ),
    (
      destination: const AppDestination(
        label: 'Templates',
        icon: Icons.list_alt_outlined,
        selectedIcon: Icons.list_alt,
        secondary: true,
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
          secondary: true,
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
        secondary: true,
      ),
      route: GoRoute(path: '/about', builder: (_, _) => const AboutPage()),
    ),
  ];
}

GoRouter buildRouter({
  String initialLocation = homePath,
  bool developer = devMode,
}) {
  final entries = homeDestinations(developer: developer);

  return GoRouter(
    initialLocation: initialLocation,
    onException: (_, _, router) => router.go(homePath),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AdaptiveScaffold(
          destinations: [for (final e in entries) e.destination],
          selectedIndex: shell.currentIndex,
          // Reselecting the current destination returns to its top.
          onDestinationSelected: (index) => shell.goBranch(
            index,
            initialLocation: index == shell.currentIndex,
          ),
          appBar: switch (entries[shell.currentIndex]) {
            (:final route, destination: _)
                when _drawOwnBar.contains(route.path) =>
              null,
            (:final destination, :final route) => TrailBar(
              _trailTo(destination, route.path),
            ),
          },
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
