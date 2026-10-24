import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../data/livestock_repository.dart';
import 'tag_field.dart';

Future<void> showAddTagsSheet(
  BuildContext context, {
  required LivestockRepository repository,
  required Paddock paddock,
  required MobLine mob,
  required int tagged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _AddTagsSheet(
        repository: repository,
        paddock: paddock,
        mob: mob,
        tagged: tagged,
      ),
    ),
  );
}

/// Tags head already standing in a mob. Nothing moves.
class _AddTagsSheet extends StatefulWidget {
  const _AddTagsSheet({
    required this.repository,
    required this.paddock,
    required this.mob,
    required this.tagged,
  });

  final LivestockRepository repository;
  final Paddock paddock;
  final MobLine mob;
  final int tagged;

  @override
  State<_AddTagsSheet> createState() => _AddTagsSheetState();
}

class _AddTagsSheetState extends State<_AddTagsSheet> {
  late final _tags = TagSelection(widget.repository)..addListener(_onTags);
  final _note = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _tags.dispose();
    _note.dispose();
    super.dispose();
  }

  void _onTags() {
    if (mounted) setState(() {});
  }

  int get _untagged => widget.mob.head - widget.tagged;

  String? get _blocker {
    if (_tags.draft.trim().isNotEmpty) return 'Finish the typed tag';
    if (_tags.chosen.isEmpty) return 'Enter a tag';
    if (_tags.pending) return 'Checking tags…';
    if (_tags.hasElsewhere) return 'Remove tags recorded elsewhere';
    if (_tags.chosen.length > _untagged) {
      return 'Only $_untagged untagged head here';
    }
    return null;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.repository.applyTags(
        paddockId: widget.paddock.id,
        classId: widget.mob.livestockClass.id,
        tags: _tags.chosen,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } on LedgerConflict catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mob = widget.mob;
    final count = _tags.chosen.length;
    final blocker = _blocker;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Add tags', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            '${mob.label} (${mob.livestockClass.ageBand}) in '
            '${widget.paddock.name} · $_untagged of ${mob.head} head '
            'untagged',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TagField(selection: _tags, label: 'Tags'),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: blocker == null && !_saving ? _save : null,
            child: Text(
              blocker ?? 'Record $count ${count == 1 ? 'tag' : 'tags'}',
            ),
          ),
        ],
      ),
    );
  }
}
