import 'package:flutter/material.dart';

import '../../data/app_settings.dart';
import '../../data/livestock_repository.dart';
import '../../data/repository_scope.dart';
import '../../data/tables.dart';
import '../../shell/search_picker.dart';
import '../export/export_dialog.dart';
import '../export/save_export.dart';
import '../tags/tag_labels.dart';
import '../transfers/movement_dialog.dart';
import 'retention_dialog.dart';

/// The user's settings, each kept on this device and applied as it changes.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.exportSaver = saveWithPicker});

  final ExportSaver exportSaver;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// Counts the times Custom was opened, so the duration field is rebuilt
  /// from the stored choice afterwards, which a cancel leaves as it was.
  var _customOpened = 0;

  // Watched once rather than per build, which every setting changed triggers.
  LivestockRepository? _repository;
  late Stream<List<PropertySummary>> _properties;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = RepositoryScope.of(context);
    if (repository != _repository) {
      _repository = repository;
      _properties = repository.watchPropertySummaries();
    }
  }

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
              title: 'Movements',
              children: [
                DropdownButtonFormField<MovementKind>(
                  key: ValueKey(settings.movementKind),
                  initialValue: recordableKinds.contains(settings.movementKind)
                      ? settings.movementKind
                      : MovementKind.move,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Default movement type',
                    helperText:
                        'Chosen to begin with when the movement form opens. '
                        'Each movement can still choose another.',
                    helperMaxLines: 3,
                  ),
                  onChanged: (kind) => settings.setMovementKind(kind!),
                  items: [
                    for (final kind in recordableKinds)
                      DropdownMenuItem(
                        value: kind,
                        child: Row(
                          spacing: 12,
                          children: [
                            Icon(kind.icon, size: 20),
                            Flexible(child: Text(kind.label)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<PropertySummary>>(
                  stream: _properties,
                  builder: (context, snapshot) => SearchPicker<String>(
                    label: 'Default property',
                    hint: 'Ask each time',
                    optional: true,
                    searchIcon: true,
                    value: settings.defaultPropertyId,
                    onChanged: settings.setDefaultPropertyId,
                    entries: [
                      for (final s
                          in snapshot.data ?? const <PropertySummary>[])
                        SearchEntry(
                          s.property.id,
                          s.property.name,
                          alsoFoundBy: s.property.pic,
                        ),
                    ],
                    emptyHint: 'No properties yet',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Text(
                    'Chosen to begin with when recording from Home or '
                    'Activity. Cleared, the form asks which property each '
                    'time. '
                    'Recording from a property or paddock always uses that '
                    'one.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<EndState>(
                  key: ValueKey(settings.endState),
                  initialValue: settings.endState,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Default end destination',
                    helperText:
                        'Chosen to begin with when ending stock in the '
                        'movement form. Each movement can still choose '
                        'another.',
                    helperMaxLines: 3,
                  ),
                  onChanged: (state) => settings.setEndState(state!),
                  items: [
                    for (final state in EndState.values)
                      DropdownMenuItem(
                        value: state,
                        child: Text(_capitalised(state.name)),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Tags',
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Use tags'),
                  subtitle: const Text(
                    "Off, the Tags page, Home's Tagged count and the ways to "
                    'add tags are hidden. Tags already recorded are kept, and '
                    'still move with their mobs.',
                  ),
                  value: settings.usesTags,
                  onChanged: settings.setUsesTags,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TagScheme>(
                  key: ValueKey(settings.tagScheme),
                  initialValue: settings.tagScheme,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Default tag type',
                    helperText:
                        'Chosen to begin with when typing or scanning a new '
                        'tag. Each tag can still be given the other.',
                    helperMaxLines: 3,
                  ),
                  onChanged: settings.usesTags
                      ? (scheme) => settings.setTagScheme(scheme!)
                      : null,
                  items: [
                    for (final scheme in TagScheme.values)
                      DropdownMenuItem(
                        value: scheme,
                        child: Text(scheme.label),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Units',
              children: [
                Text(
                  'Paddock areas are shown in this unit, and a new '
                  "paddock's area is entered in it. They are kept in "
                  'hectares, so switching converts what is shown and '
                  'changes nothing recorded.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                const Text('Area unit'),
                const SizedBox(height: 8),
                SegmentedButton<AreaUnit>(
                  showSelectedIcon: false,
                  segments: [
                    for (final unit in AreaUnit.values)
                      ButtonSegment(value: unit, label: Text(unit.label)),
                  ],
                  selected: {settings.areaUnit},
                  onSelectionChanged: (unit) =>
                      settings.setAreaUnit(unit.single),
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
            const SizedBox(height: 12),
            _Section(
              title: 'Data',
              children: [
                Text(
                  "Save the farm's records as a spreadsheet, CSV, a PDF "
                  'report, or a JSON backup of everything recorded.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FilledButton.tonalIcon(
                    onPressed: () =>
                        showExportDialog(context, save: widget.exportSaver),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Export…'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

String _capitalised(String word) =>
    '${word[0].toUpperCase()}${word.substring(1)}';

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
