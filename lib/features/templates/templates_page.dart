import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../data/livestock_repository.dart';
import '../../data/repository_scope.dart';

/// Read-only. The template editor the specification calls for comes later;
/// the seeded lists are provisional and awaiting Alex.
class TemplatesPage extends StatelessWidget {
  const TemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryScope.of(context);

    return FutureBuilder<List<Template>>(
      future: repository.templates(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _ProvisionalBanner(),
            const SizedBox(height: 12),
            for (final template in snapshot.data!)
              _TemplateCard(template: template, repository: repository),
          ],
        );
      },
    );
  }
}

class _ProvisionalBanner extends StatelessWidget {
  const _ProvisionalBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              Icons.construction_outlined,
              color: theme.colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Provisional lists, pending the real ones. Editing templates '
                'comes in a later round.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.repository});

  final Template template;
  final LivestockRepository repository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template.name, style: theme.textTheme.titleMedium),
            const Divider(height: 20),
            FutureBuilder<List<LivestockClass>>(
              future: repository.classesIn(template.id),
              builder: (context, snapshot) {
                final classes = snapshot.data ?? const <LivestockClass>[];
                final byId = {for (final c in classes) c.id: c};

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final c in classes)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${c.kind} — ${c.ageBand}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            if (byId[c.agesIntoClassId] case final next?)
                              Text(
                                '→ ${next.kind}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
