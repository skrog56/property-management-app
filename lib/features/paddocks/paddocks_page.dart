import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../data/livestock_repository.dart';
import '../../data/repository_scope.dart';
import '../../shell/breakpoints.dart';
import '../transfers/movement_sheet.dart';
import 'name_dialog.dart';

class PaddocksPage extends StatefulWidget {
  const PaddocksPage({super.key});

  @override
  State<PaddocksPage> createState() => _PaddocksPageState();
}

class _PaddocksPageState extends State<PaddocksPage> {
  String? _propertyId;

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryScope.of(context);

    return StreamBuilder<List<Property>>(
      stream: repository.watchProperties(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final properties = snapshot.data!;
        if (properties.isEmpty) {
          return _FirstRun(repository: repository);
        }

        final property = properties.firstWhere(
          (p) => p.id == _propertyId,
          orElse: () => properties.first,
        );

        return _PaddockList(
          repository: repository,
          property: property,
          properties: properties,
          onPropertySelected: (id) => setState(() => _propertyId = id),
        );
      },
    );
  }
}

/// The quick-start from the specification, reduced to its one unskippable
/// step: without a property there is nowhere to put a paddock.
class _FirstRun extends StatelessWidget {
  const _FirstRun({required this.repository});

  final LivestockRepository repository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.agriculture_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text('No properties yet', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Create a property, add its paddocks, then record movements '
                'between them.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Create a property'),
                onPressed: () async {
                  final name = await promptForName(
                    context,
                    title: 'New property',
                    hint: 'Skrog Downs',
                  );
                  if (name != null) await repository.createProperty(name.value);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaddockList extends StatelessWidget {
  const _PaddockList({
    required this.repository,
    required this.property,
    required this.properties,
    required this.onPropertySelected,
  });

  final LivestockRepository repository;
  final Property property;
  final List<Property> properties;
  final ValueChanged<String> onPropertySelected;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PaddockSummary>>(
      stream: repository.watchPaddockSummaries(property.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final summaries = snapshot.data!;

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: summaries.isEmpty
              ? FloatingActionButton.extended(
                  icon: const Icon(Icons.add),
                  label: const Text('Add paddock'),
                  onPressed: () => _addPaddock(context),
                )
              : FloatingActionButton.extended(
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Record movement'),
                  onPressed: () => showMovementSheet(
                    context,
                    repository: repository,
                    propertyId: property.id,
                  ),
                ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final sizeClass = WindowSizeClass.fromWidth(constraints.maxWidth);

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  _PropertyHeader(
                    property: property,
                    properties: properties,
                    summaries: summaries,
                    onPropertySelected: onPropertySelected,
                    onAddPaddock: () => _addPaddock(context),
                  ),
                  const SizedBox(height: 12),
                  if (summaries.isEmpty)
                    const _EmptyHint(
                      text: 'No paddocks yet. Add one to get started.',
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: sizeClass.contentColumns,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            mainAxisExtent: 132,
                          ),
                      itemCount: summaries.length,
                      itemBuilder: (context, index) =>
                          _PaddockCard(summary: summaries[index]),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _addPaddock(BuildContext context) async {
    final name = await promptForName(
      context,
      title: 'New paddock',
      hint: 'North Ridge',
      askForHectares: true,
    );
    if (name == null) return;
    await repository.createPaddock(
      property.id,
      name.value,
      hectares: name.hectares ?? 0,
    );
  }
}

class _PropertyHeader extends StatelessWidget {
  const _PropertyHeader({
    required this.property,
    required this.properties,
    required this.summaries,
    required this.onPropertySelected,
    required this.onAddPaddock,
  });

  final Property property;
  final List<Property> properties;
  final List<PaddockSummary> summaries;
  final ValueChanged<String> onPropertySelected;
  final VoidCallback onAddPaddock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = summaries.fold(0, (sum, s) => sum + s.head);

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (properties.length > 1)
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: property.id,
                        isDense: true,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        onChanged: (id) {
                          if (id != null) onPropertySelected(id);
                        },
                        items: [
                          for (final p in properties)
                            DropdownMenuItem(value: p.id, child: Text(p.name)),
                        ],
                      ),
                    )
                  else
                    Text(
                      property.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${summaries.length} paddocks · $total head',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: onAddPaddock,
              icon: const Icon(Icons.add),
              tooltip: 'Add paddock',
            ),
          ],
        ),
      ),
    );
  }
}

class _PaddockCard extends StatelessWidget {
  const _PaddockCard({required this.summary});

  final PaddockSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = summary.isEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: empty
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.primaryContainer,
              child: Text(
                '${summary.head}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: empty
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    summary.paddock.name,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  if (empty)
                    Text(
                      'Empty',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    for (final mob in summary.mobs)
                      Text(
                        '${mob.head} × ${mob.label} (${mob.livestockClass.ageBand})',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  const Spacer(),
                  Text(
                    '${summary.paddock.hectares.toStringAsFixed(1)} ha',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
