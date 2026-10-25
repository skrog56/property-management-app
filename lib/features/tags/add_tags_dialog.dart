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
    final mob = widget.mob;
    final count = _tags.chosen.length;
    final blocker = _blocker;

    return FormDialog(
      title: 'Add tags',
      subtitle:
          '${mob.label} (${mob.livestockClass.ageBand}) in '
          '${widget.paddock.name} · $_untagged of ${mob.head} head untagged',
      actionLabel: blocker ?? 'Record $count ${count == 1 ? 'tag' : 'tags'}',
      onAction: blocker == null && !_saving ? _save : null,
      children: [
        TagField(selection: _tags, label: 'Tags'),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          decoration: const InputDecoration(labelText: 'Note (optional)'),
        ),
      ],
    );
  }
}
