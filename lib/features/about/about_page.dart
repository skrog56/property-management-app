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
                  'Skrog Property Management — Pilot',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'A proof that one Flutter codebase reaches every device '
                  'Skrog needs, ahead of building livestock transfer '
                  'tracking on top of it.',
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
                Text('Not yet proven', style: theme.textTheme.titleMedium),
                const Divider(height: 20),
                Text(
                  'Offline-first local storage, camera and QR tag scanning, '
                  'and GPS are the parts most likely to behave differently '
                  'per platform. They are deliberately out of scope here and '
                  'should be the next things piloted.',
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
