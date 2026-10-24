import 'package:flutter/material.dart';

import '../../data/livestock_repository.dart';
import '../../data/repository_scope.dart';
import '../../data/tables.dart';
import '../../data/tag_numbers.dart';
import '../activity/activity_page.dart';
import 'tag_labels.dart';

Future<void> preloadTag(LivestockRepository repository, String id) =>
    repository.warm([
      repository.watchTag(id),
      repository.watchActivityEntries(tagId: id),
    ]);

/// One tag: where it is now, and everything that has happened to it.
class TagPage extends StatelessWidget {
  const TagPage({super.key, required this.tagId});

  final String tagId;

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryScope.of(context);

    return StreamBuilder<TagStatus?>(
      initialData: repository.latestTag(tagId),
      stream: repository.watchTag(tagId),
      builder: (context, snapshot) =>
          switch ((snapshot.connectionState, snapshot.data)) {
            (ConnectionState.waiting, null) => const Center(
              child: CircularProgressIndicator(),
            ),
            (_, null) => const Center(child: Text('This tag is gone.')),
            (_, final status?) => _TagDetail(status: status),
          },
    );
  }
}

class _TagDetail extends StatelessWidget {
  const _TagDetail({required this.status});

  final TagStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = RepositoryScope.of(context);
    final tag = status.tag;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tag.tagNumber.display,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  tag.scheme.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _Whereabouts(status),
              ],
            ),
          ),
        ),
        if (status.isActive) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => _ReplaceDialog(status: status),
                ),
                icon: const Icon(Icons.find_replace),
                label: const Text('Replace'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => _CancelDialog(status: status),
                ),
                icon: const Icon(Icons.label_off_outlined),
                label: const Text('Cancel tag'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Text('History', style: theme.textTheme.titleMedium),
        const Divider(),
        StreamBuilder<List<ActivityEntry>>(
          initialData: repository.latestActivityEntries(tagId: tag.id),
          stream: repository.watchActivityEntries(tagId: tag.id),
          builder: (context, snapshot) {
            final entries = snapshot.data;
            if (entries == null) return const SizedBox(height: 48);
            return Column(
              children: [
                for (final entry in entries)
                  ActivityTile(entry: entry, currentTagId: tag.id),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Whereabouts extends StatelessWidget {
  const _Whereabouts(this.status);

  final TagStatus status;

  // Through DefaultTextStyle rather than Text.rich's style, which the links in
  // WidgetSpans would not inherit.
  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
    style: Theme.of(context).textTheme.bodyLarge,
    child: _line(),
  );

  Widget _line() {
    if (status.isActive) {
      return Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'In '),
            paddockLink(status.paddock!),
            if (status.property case final property?)
              TextSpan(text: ', ${property.name}'),
            if (status.livestockClass case final c?)
              TextSpan(text: ' · ${c.kind} (${c.ageBand})'),
          ],
        ),
      );
    }
    if (status.replacedBy case final next?) {
      return Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Replaced by '),
            tagLink(next),
            TextSpan(
              text: [
                ' on ${shortDate(status.occurredAt)}',
                ?status.reason?.label,
              ].join(' · '),
            ),
          ],
        ),
      );
    }
    return Text(tagWhereabouts(status));
  }
}

class _ReplaceDialog extends StatefulWidget {
  const _ReplaceDialog({required this.status});

  final TagStatus status;

  @override
  State<_ReplaceDialog> createState() => _ReplaceDialogState();
}

class _ReplaceDialogState extends State<_ReplaceDialog> {
  final _number = TextEditingController();
  final _note = TextEditingController();

  late TagScheme _scheme = widget.status.tag.scheme;
  TagReason _reason = TagReason.lost;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _number.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final replacement = TagNumber.tryParse(_scheme, _number.text);
    final old = widget.status.tag;
    final error = switch (replacement) {
      null when _number.text.trim().isEmpty => 'Enter the new tag number',
      null => nlisFormat,
      final r when r == old.tagNumber => 'That is the tag being replaced',
      _ => null,
    };
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() => _saving = true);
    try {
      await RepositoryScope.of(context).replaceTag(
        old.id,
        replacement!,
        reason: _reason,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } on TagElsewhere catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Replace ${widget.status.tag.tagNumber.display}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<TagScheme>(
              segments: [
                for (final scheme in TagScheme.values)
                  ButtonSegment(value: scheme, label: Text(scheme.label)),
              ],
              selected: {_scheme},
              onSelectionChanged: (s) => setState(() {
                _scheme = s.single;
                _error = null;
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'New tag number',
                errorText: _error,
                errorMaxLines: 3,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TagReason>(
              initialValue: _reason,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final reason in TagReason.values)
                  DropdownMenuItem(value: reason, child: Text(reason.label)),
              ],
              onChanged: (reason) => setState(() => _reason = reason!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: const Text('Replace'),
        ),
      ],
    );
  }
}

class _CancelDialog extends StatefulWidget {
  const _CancelDialog({required this.status});

  final TagStatus status;

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  final _note = TextEditingController();

  TagReason? _reason;
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    await RepositoryScope.of(context).cancelTag(
      widget.status.tag.id,
      reason: _reason!,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;

    return AlertDialog(
      title: Text('Cancel ${status.tag.tagNumber.display}?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'The animal stays in the head count of '
              '${status.paddock?.name ?? 'its paddock'}, untagged.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TagReason>(
              initialValue: _reason,
              isExpanded: true,
              hint: const Text('Choose a reason'),
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final reason in TagReason.values)
                  DropdownMenuItem(value: reason, child: Text(reason.label)),
              ],
              onChanged: (reason) => setState(() => _reason = reason),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Not "Cancel", beside a button that cancels the tag.
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Keep tag'),
        ),
        FilledButton(
          onPressed: _reason == null || _saving ? null : _submit,
          child: const Text('Cancel tag'),
        ),
      ],
    );
  }
}
