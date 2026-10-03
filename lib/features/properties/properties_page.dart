import 'package:flutter/material.dart';

import '../../data/livestock_repository.dart';
import '../../data/repository_scope.dart';
import '../../shell/breakpoints.dart';
import 'name_dialog.dart';
import 'paths.dart';
import 'property_page.dart';

/// The top of the three tiers: properties, then their paddocks, then the
/// livestock standing in one paddock.
class PropertiesPage extends StatelessWidget {
  const PropertiesPage({super.key, this.selectedId, this.primary = true});

  final String? selectedId;

  /// Whether this is the deepest tier on screen, and so owns the action button.
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryScope.of(context);

    return StreamBuilder<List<PropertySummary>>(
      stream: repository.watchPropertySummaries(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final summaries = snapshot.data!;
        if (summaries.isEmpty) return _FirstRun(repository: repository);

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: primary
              ? FloatingActionButton.extended(
                  icon: const Icon(Icons.add),
                  label: const Text('Add property'),
                  onPressed: () => addProperty(context, repository),
                )
              : null,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final sizeClass = WindowSizeClass.fromWidth(constraints.maxWidth);

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: sizeClass.contentColumns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 112,
                ),
                itemCount: summaries.length,
                itemBuilder: (context, index) => _PropertyCard(
                  summary: summaries[index],
                  selected: summaries[index].property.id == selectedId,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

Future<void> addProperty(
  BuildContext context,
  LivestockRepository repository,
) async {
  final name = await promptForName(
    context,
    title: 'New property',
    hint: 'Riverbend Downs',
    askForPic: true,
  );
  if (name != null) await repository.createProperty(name.value, pic: name.pic);
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.summary, required this.selected});

  final PropertySummary summary;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final property = summary.property;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: selected ? theme.colorScheme.secondaryContainer : null,
      child: InkWell(
        onTap: () => openTier(
          context,
          propertyPath(property.id),
          preload: preloadProperty(RepositoryScope.of(context), property.id),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.home_work_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      property.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.paddockCount} '
                      '${summary.paddockCount == 1 ? 'paddock' : 'paddocks'} · '
                      '${summary.head} head',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (property.pic != null)
                      Text(
                        'PIC ${property.pic}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
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
                onPressed: () => addProperty(context, repository),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
