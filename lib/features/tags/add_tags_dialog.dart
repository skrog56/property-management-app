import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../data/livestock_repository.dart';
import '../../shell/form_dialog.dart';
import 'tag_field.dart';

Future<void> showAddTagsDialog(
  BuildContext context, {
  required LivestockRepository repository,
  required Paddock paddock,
  required MobLine mob,
  required int tagged,
}) {
  return showFormDialog<void>(
    context,
    builder: (context) => _AddTagsDialog(
      repository: repository,
      paddock: paddock,
      mob: mob,
      tagged: tagged,
    ),
  );
}

/// Tags head already standing in a mob. Nothing moves.
class _AddTagsDialog extends StatefulWidget {
  const _AddTagsDialog({
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
  State<_AddTagsDialog> createState() => _AddTagsDialogState();
}

class _AddTagsDialogState extends State<_AddTagsDialog> {
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

  /// [wrong] when the tags entered are at fault, not merely missing.
  ({String reason, bool wrong})? get _blocker {
    if (_tags.draft.trim().isNotEmpty) {
      return (reason: 'Finish the typed tag', wrong: true);
    }
    if (_tags.chosen.isEmpty) return (reason: 'Enter a tag', wrong: false);
    if (_tags.pending) return (reason: 'Checking tags…', wrong: false);
    if (_tags.hasElsewhere) {
      return (reason: 'Remove tags recorded elsewhere', wrong: true);
    }
    if (_tags.chosen.length > _untagged) {
      return (reason: 'Only $_untagged untagged head here', wrong: true);
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
    final mob = widget.mob;
    final count = _tags.chosen.length;
    final blocker = _blocker;

    return FormDialog(
      title: 'Add tags',
      subtitle:
          '${mob.label} (${mob.livestockClass.ageBand}) in '
          '${widget.paddock.name} · $_untagged of ${mob.head} head untagged',
      actionLabel: switch (count) {
        0 => 'Record tags',
        1 => 'Record 1 tag',
        _ => 'Record $count tags',
      },
      onAction: _saving ? null : _save,
      blocker: blocker?.reason,
      children: [
        TagField(
          selection: _tags,
          label: 'Tags',
          wrong: blocker?.wrong ?? false,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          decoration: const InputDecoration(labelText: 'Note (optional)'),
        ),
      ],
    );
  }
}
