import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/livestock_repository.dart';
import '../../data/repository_scope.dart';
import '../../shell/breakpoints.dart';
import '../platform_proof/platform_proof_page.dart';
import 'dev_data.dart';
import 'dev_log.dart';
import 'dev_settings.dart';

/// Debug builds only — reached through `devMode` in the shell.
class DeveloperPage extends StatelessWidget {
  const DeveloperPage({super.key, this.initialTab = 0, this.log});

  final int initialTab;

  /// Defaults to [DevLog.instance].
  final DevLog? log;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: initialTab,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Platform'),
              Tab(text: 'Data'),
              Tab(text: 'Display'),
              Tab(text: 'Log'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                const PlatformProofPage(),
                const _DataTab(),
                const _DisplayTab(),
                _LogTab(log: log ?? DevLog.instance),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DataTab extends StatelessWidget {
  const _DataTab();

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryScope.of(context);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Section(
          title: 'Actions',
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _run(
                    context,
                    repository.seedSampleFarm,
                    'Sample farm seeded',
                  ),
                  icon: const Icon(Icons.agriculture_outlined),
                  label: const Text('Seed sample farm'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _checkLedger(context, repository),
                  icon: const Icon(Icons.rule),
                  label: const Text('Check ledger'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: () => _confirmWipe(context, repository),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('Wipe database'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Tables',
          children: [
            StreamBuilder<List<TableCount>>(
              stream: repository.watchTableCounts(),
              builder: (context, snapshot) {
                final counts = snapshot.data;
                if (counts == null) return const Text('reading…');
                return Column(
                  children: [
                    for (final count in counts)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.table_rows_outlined),
                        title: Text(count.name),
                        subtitle: Text(
                          '${count.live} live · ${count.deleted} deleted',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _RawRowsPage(
                              repository: repository,
                              table: count.name,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String done,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _confirmWipe(
    BuildContext context,
    LivestockRepository repository,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wipe the database?'),
        content: const Text(
          'Every property, paddock and movement on this device is deleted. '
          'Built-in templates are reseeded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Wipe'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _run(context, repository.wipe, 'Database wiped');
  }

  Future<void> _checkLedger(
    BuildContext context,
    LivestockRepository repository,
  ) async {
    final violations = await repository.negativeBalances();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          violations.isEmpty ? 'Ledger consistent' : 'Negative balances',
        ),
        content: violations.isEmpty
            ? const Text('No paddock holds fewer than zero head of any class.')
            : SelectableText(
                [
                  for (final v in violations)
                    'paddock ${v.paddockId}\nclass ${v.classId}\nhead ${v.head}',
                ].join('\n\n'),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _RawRowsPage extends StatelessWidget {
  const _RawRowsPage({required this.repository, required this.table});

  final LivestockRepository repository;
  final String table;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(table)),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: repository.rawRows(table),
        builder: (context, snapshot) {
          final rows = snapshot.data;
          if (rows == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (rows.isEmpty) return const Center(child: Text('No rows'));
          return ListView(
            children: [
              for (final row in rows)
                ExpansionTile(
                  title: Text(
                    '${row['name'] ?? row['kind'] ?? row['id']}',
                    style: row['deleted_at'] == null
                        ? null
                        : TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                  ),
                  subtitle: Text('${row['id']}'),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [
                    SelectableText(
                      [
                        for (final e in row.entries) '${e.key}: ${e.value}',
                      ].join('\n'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DisplayTab extends StatelessWidget {
  const _DisplayTab();

  static const _widths = <double>[360, 700, 1000, 1400, 1700];

  @override
  Widget build(BuildContext context) {
    final settings = DevSettingsScope.maybeOf(context);
    if (settings == null) {
      return const Center(child: Text('Display overrides are not installed'));
    }

    // The real window, not the possibly simulated MediaQuery around us.
    final view = View.of(context);
    final realWidth = view.physicalSize.width / view.devicePixelRatio;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Section(
          title: 'Overlays',
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Paint size'),
              subtitle: const Text('Layout bounds, padding and baselines'),
              value: settings.paintSize,
              onChanged: (v) => settings.paintSize = v,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Repaint rainbow'),
              subtitle: const Text('Recolours each layer as it repaints'),
              value: settings.repaintRainbow,
              onChanged: (v) => settings.repaintRainbow = v,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Performance overlay'),
              subtitle: const Text('Raster and UI frame times; not on web'),
              value: settings.performanceOverlay,
              onChanged: (v) => settings.performanceOverlay = v,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Semantics debugger'),
              subtitle: const Text('What a screen reader sees'),
              value: settings.semanticsDebugger,
              onChanged: (v) => settings.semanticsDebugger = v,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Overrides',
          children: [
            const Text('Theme'),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('System')),
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => settings.themeMode = s.single,
            ),
            const SizedBox(height: 16),
            const Text('Text scale'),
            const SizedBox(height: 8),
            SegmentedButton<double>(
              segments: const [
                ButtonSegment(value: 1.0, label: Text('×1')),
                ButtonSegment(value: 1.3, label: Text('×1.3')),
                ButtonSegment(value: 2.0, label: Text('×2')),
              ],
              selected: {settings.textScale},
              onSelectionChanged: (s) => settings.textScale = s.single,
            ),
            const SizedBox(height: 16),
            const Text('Simulated window width'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Off'),
                  selected: settings.simulatedWidth == null,
                  onSelected: (_) => settings.simulatedWidth = null,
                ),
                for (final width in _widths)
                  ChoiceChip(
                    label: Text(
                      '${width.round()} · '
                      '${WindowSizeClass.fromWidth(width).name}',
                    ),
                    selected: settings.simulatedWidth == width,
                    onSelected: width < realWidth
                        ? (_) => settings.simulatedWidth = width
                        : null,
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _LogTab extends StatelessWidget {
  const _LogTab({required this.log});

  final DevLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: log,
      builder: (context, _) {
        final entries = log.entries;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(child: Text('${entries.length} entries')),
                  TextButton.icon(
                    onPressed: entries.isEmpty
                        ? null
                        : () => Clipboard.setData(
                            ClipboardData(text: entries.join('\n\n')),
                          ),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                  TextButton.icon(
                    onPressed: entries.isEmpty ? null : log.clear,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? const Center(child: Text('Nothing logged'))
                  : ListView(
                      children: [
                        for (final entry in entries)
                          ExpansionTile(
                            leading: Icon(
                              switch (entry.kind) {
                                DevLogKind.error => Icons.error_outline,
                                DevLogKind.async => Icons.sync_problem,
                                DevLogKind.print => Icons.notes,
                              },
                              color: entry.kind == DevLogKind.print
                                  ? null
                                  : theme.colorScheme.error,
                            ),
                            title: Text(
                              entry.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              TimeOfDay.fromDateTime(
                                entry.time,
                              ).format(context),
                            ),
                            childrenPadding: const EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              12,
                            ),
                            children: [
                              SelectableText(
                                entry.toString(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
