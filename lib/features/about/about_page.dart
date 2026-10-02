import 'package:flutter/material.dart';

import '../platform_proof/platform_facts.dart';

/// Explains what the pilot is for, and tracks the six-target checklist.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const List<_Target> _targets = [
    _Target('Web', Icons.language, 'Chrome, Edge, Safari, Firefox'),
    _Target('Android', Icons.android, 'Phones and tablets'),
    _Target('iOS', Icons.phone_iphone, 'iPhone and iPad'),
    _Target('Linux', Icons.desktop_windows_outlined, 'GTK desktop'),
    _Target('macOS', Icons.laptop_mac, 'Apple silicon and Intel'),
    _Target('Windows', Icons.window_outlined, 'Win32 desktop'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = PlatformFacts.platformName;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Property Management App',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Livestock transfers, from one codebase on every device. '
                  'Properties, paddocks, movements and templates are stored '
                  'on this device.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Target platforms', style: theme.textTheme.titleMedium),
                const Divider(height: 20),
                for (final target in _targets)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(target.icon),
                    title: Text(target.name),
                    subtitle: Text(target.detail),
                    trailing: target.name == current
                        ? Chip(
                            label: const Text('you are here'),
                            backgroundColor:
                                theme.colorScheme.primaryContainer,
                            side: BorderSide.none,
                          )
                        : null,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Not yet built', style: theme.textTheme.titleMedium),
                const Divider(height: 20),
                Text(
                  'There is no backend: no accounts, no roles, no syncing '
                  'between devices, and no admin approvals. Paddock mapping, '
                  'tag scanning and reporting are still to come.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

@immutable
class _Target {
  const _Target(this.name, this.icon, this.detail);

  final String name;
  final IconData icon;
  final String detail;
}
