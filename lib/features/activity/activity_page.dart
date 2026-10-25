import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../data/livestock_repository.dart';
import '../../data/repository_scope.dart';
import '../../data/tables.dart';
import '../../data/tag_numbers.dart';
import '../../shell/tier_route.dart';
import '../properties/paddock_page.dart';
import '../properties/paths.dart';
import '../tags/paths.dart';
import '../tags/tag_labels.dart';
import '../tags/tag_page.dart';
import '../transfers/movement_dialog.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryScope.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: StreamBuilder<List<PropertySummary>>(
        stream: repository.watchPropertySummaries(),
        builder: (context, snapshot) {
          final paddocks = snapshot.data?.any((s) => s.paddockCount > 0);
          if (paddocks != true) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Record movement'),
            onPressed: () => showMovementDialog(context, repository: repository),
          );
        },
      ),
      body: StreamBuilder<List<ActivityEntry>>(
        stream: repository.watchActivityEntries(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data!;
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Nothing recorded yet. Every movement you record appears here.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                ActivityTile(entry: entries[index]),
          );
        },
      ),
    );
  }
}

class ActivityTile extends StatelessWidget {
  const ActivityTile({
    super.key,
    required this.entry,
    this.currentPaddockId,
    this.currentTagId,
  });

  final ActivityEntry entry;

  /// The paddock this tile is shown on, which it names without linking.
  final String? currentPaddockId;

  /// Likewise for the tag whose history this is.
  final String? currentTagId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final movement = entry.movement;

    final when = Text(
      [
        _timestamp(movement.occurredAt),
        if (movement.note != null) movement.note!,
      ].join(' · '),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Icon(
          switch (movement.kind) {
            MovementKind.intake => Icons.add_circle_outline,
            MovementKind.move => Icons.swap_horiz,
            MovementKind.age => Icons.cake_outlined,
            MovementKind.endState => Icons.local_shipping_outlined,
            MovementKind.tag => Icons.sell_outlined,
          },
          size: 20,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '${movement.head} head · '),
            ..._summary(movement),
          ],
        ),
      ),
      subtitle: entry.tags.isEmpty
          ? when
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TagLine(tags: entry.tags, currentTagId: currentTagId),
                when,
              ],
            ),
    );
  }

  List<InlineSpan> _summary(Movement movement) => switch (movement.kind) {
    MovementKind.intake => [
      const TextSpan(text: 'intake to '),
      _paddock(entry.toPaddock),
      TextSpan(text: ' as ${entry.toClass}'),
    ],
    MovementKind.move => [
      _paddock(entry.fromPaddock),
      const TextSpan(text: ' → '),
      _paddock(entry.toPaddock),
      TextSpan(text: ' (${entry.fromClass})'),
    ],
    MovementKind.age => [
      TextSpan(text: '${entry.fromClass} → ${entry.toClass} in '),
      _paddock(entry.fromPaddock),
    ],
    MovementKind.endState => [
      _paddock(entry.fromPaddock),
      TextSpan(text: ' → ${movement.endState?.name ?? 'removed'}'),
    ],
    MovementKind.tag => [
      TextSpan(text: '${_tagEvent(movement)} in '),
      _paddock(entry.toPaddock),
      TextSpan(text: ' (${entry.toClass})'),
    ],
  };

  String _tagEvent(Movement movement) {
    final removed = entry.tags.where((t) => t.role == TagRole.removed).length;
    if (removed == 0) return 'tagged';
    if (removed < entry.tags.length) return 'tag replaced';
    return movement.head == 1 ? 'tag cancelled' : 'tags cancelled';
  }

  InlineSpan _paddock(Paddock? paddock) {
    if (paddock == null ||
        paddock.deletedAt != null ||
        paddock.id == currentPaddockId) {
      return TextSpan(text: paddock?.name ?? 'a removed paddock');
    }
    return paddockLink(paddock);
  }

  String _timestamp(DateTime at) {
    final local = at.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d/$m/${local.year} $h:$min';
  }
}

/// The tags a movement touched. A replacement reads old → new.
class _TagLine extends StatefulWidget {
  const _TagLine({required this.tags, this.currentTagId});

  final List<TagRef> tags;
  final String? currentTagId;

  @override
  State<_TagLine> createState() => _TagLineState();
}

class _TagLineState extends State<_TagLine> {
  static const _shown = 6;
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tags = widget.tags;
    final replacement =
        tags.length == 2 &&
        tags.first.role == TagRole.removed &&
        tags.last.role == TagRole.added;
    final visible = _expanded ? tags : tags.take(_shown).toList();
    final hidden = tags.length - visible.length;

    return Text.rich(
      TextSpan(
        children: [
          if (replacement) ...[
            _tag(tags.first.tag),
            const TextSpan(text: ' → '),
            _tag(tags.last.tag),
            if (tags.first.reason case final reason?)
              TextSpan(text: ' · ${reason.label}'),
          ] else
            for (final (i, ref) in visible.indexed) ...[
              if (i > 0) const TextSpan(text: ', '),
              _tag(ref.tag),
              if (ref.reason case final reason?)
                TextSpan(text: ' · ${reason.label}'),
            ],
          if (!replacement && hidden > 0) ...[
            const TextSpan(text: ' '),
            inlineLink(
              '+$hidden more',
              onTap: () => setState(() => _expanded = true),
            ),
          ],
        ],
      ),
    );
  }

  InlineSpan _tag(LivestockTag tag) => tag.id == widget.currentTagId
      ? TextSpan(text: tag.tagNumber.display)
      : tagLink(tag);
}

InlineSpan paddockLink(Paddock paddock) => WidgetSpan(
  alignment: PlaceholderAlignment.baseline,
  baseline: TextBaseline.alphabetic,
  child: Builder(
    builder: (context) => _InlineLink(
      paddock.name,
      onTap: () => openTier(
        context,
        paddockPath(paddock.propertyId, paddock.id),
        preload: preloadPaddock(RepositoryScope.of(context), paddock.id),
      ),
    ),
  ),
);

InlineSpan tagLink(LivestockTag tag) => WidgetSpan(
  alignment: PlaceholderAlignment.baseline,
  baseline: TextBaseline.alphabetic,
  child: Builder(
    builder: (context) => _InlineLink(
      tag.tagNumber.display,
      onTap: () => openTier(
        context,
        tagPath(tag.id),
        preload: preloadTag(RepositoryScope.of(context), tag.id),
      ),
    ),
  ),
);

InlineSpan inlineLink(String text, {required VoidCallback onTap}) => WidgetSpan(
  alignment: PlaceholderAlignment.baseline,
  baseline: TextBaseline.alphabetic,
  child: _InlineLink(text, onTap: onTap),
);

class _InlineLink extends StatelessWidget {
  const _InlineLink(this.text, {required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      link: true,
      child: InkWell(
        onTap: onTap,
        child: Text(
          text,
          style: TextStyle(
            color: colors.primary,
            decoration: TextDecoration.underline,
            decorationColor: colors.primary,
          ),
        ),
      ),
    );
  }
}
