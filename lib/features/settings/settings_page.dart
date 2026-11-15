import 'package:flutter/material.dart';

import '../../data/app_settings.dart';
import '../../data/repository_scope.dart';
import 'retention_dialog.dart';

/// The user's settings, each kept on this device and applied as it changes.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// Counts the times Custom was opened, so the duration field is rebuilt
  /// from the stored choice afterwards, which a cancel leaves as it was.
  var _customOpened = 0;

  Future<void> _chooseCustom(AppSettings settings) async {
    final chosen = await showRetentionDialog(
      context,
      initial: settings.retention,
    );
    if (chosen != null) await settings.setRetention(chosen);
    if (mounted) setState(() => _customOpened++);
  }

  @override
  Widget build(BuildContext context) {
    final settings = RepositoryScope.of(context).settings;

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final theme = Theme.of(context);
        final retention = settings.retention;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Section(
              title: 'Ended stock',
              children: [
                Text(
                  'Stock that is sold, sent to the meatworks, dies or is lost '
                  "leaves its paddock's count at once. This is how long it "
                  "still shows on Home, under a paddock's Deaths and Recently "
                  'left, and in the Tags list. Activity always keeps '
                  'everything.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Retention?>(
                  key: ValueKey((retention, _customOpened)),
                  initialValue: retention,
                  decoration: const InputDecoration(
                    labelText: 'Keep visible for',
                  ),
                  onChanged: (choice) => choice == null
                      ? _chooseCustom(settings)
                      : settings.setRetention(choice),
                  items: [
                    for (final choice in [
                      ...Retention.presets,
                      if (!Retention.presets.contains(retention)) retention,
                    ])
                      DropdownMenuItem(
                        value: choice,
                        child: Text(choice.label),
                      ),
                    const DropdownMenuItem(child: Text('Custom…')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Templates',
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Remember the view'),
                  subtitle: const Text(
                    'Templates opens grouped and sorted as you left it. Off, '
                    'it opens grouped by animal, in custom order.',
                  ),
                  value: settings.remembersTemplatesView,
                  onChanged: settings.setRemembersTemplatesView,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Appearance',
              children: [
                const Text('Theme'),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  // The fill marks the choice; a check as well breaks
                  // "System" over two lines on a phone.
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                    ),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (mode) =>
                      settings.setThemeMode(mode.single),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}
