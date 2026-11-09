import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../data/livestock_repository.dart';
import '../../shell/form_dialog.dart';

/// Adds a class to [template], or edits [editing]. [classes] is every live
/// class, for the ageing chain and for names already taken. [twinHead] is
/// the head [editing] has marked ready to sell, which turning that off has to
/// wait for.
Future<void> showClassDialog(
  BuildContext context, {
  required LivestockRepository repository,
  required Template template,
  required List<StockClass> classes,
  StockClass? editing,
  int twinHead = 0,
}) {
  return showFormDialog<void>(
    context,
    builder: (context) => _ClassDialog(
      repository: repository,
      template: template,
      classes: classes,
      editing: editing,
      twinHead: twinHead,
    ),
  );
}

class _ClassDialog extends StatefulWidget {
  const _ClassDialog({
    required this.repository,
    required this.template,
    required this.classes,
    required this.editing,
    required this.twinHead,
  });

  final LivestockRepository repository;
  final Template template;
  final List<StockClass> classes;
  final StockClass? editing;
  final int twinHead;

  @override
  State<_ClassDialog> createState() => _ClassDialogState();
}

class _ClassDialogState extends State<_ClassDialog> {
  late final _kind = TextEditingController(text: widget.editing?.row.kind);
  late final _breed = TextEditingController(text: widget.editing?.row.breed);
  late final _ageBand = TextEditingController(
    text: widget.editing?.row.ageBand,
  );

  /// Ready-to-sell twins are left out: marking goes through a mob's shortcut.
  late final List<StockClass> _targets = [
    for (final c in widget.classes)
      if (!c.isReadyToSell && c.id != widget.editing?.id) c,
  ];

  late String? _agesInto = switch (widget.editing?.row.agesIntoClassId) {
    final id? when _targets.any((c) => c.id == id) => id,
    _ => null,
  };
  late bool _readyToSell = widget.editing?.readyToSellClassId != null;
  bool _saving = false;

  @override
  void dispose() {
    _kind.dispose();
    _breed.dispose();
    _ageBand.dispose();
    super.dispose();
  }

  static String? _text(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  /// [wrong] when the name is at fault, not merely empty.
  ({String reason, bool wrong})? get _blocker {
    final kind = _text(_kind);
    if (kind == null) return (reason: 'Enter a name', wrong: false);

    String key(String? breed, String kind, String? ageBand) =>
        [breed, kind, ageBand].join('|').toLowerCase();
    final mine = key(_text(_breed), kind, _text(_ageBand));
    final taken = widget.classes.any(
      (c) =>
          c.template.id == widget.template.id &&
          !c.isReadyToSell &&
          c.id != widget.editing?.id &&
          key(c.row.breed, c.row.kind, c.row.ageBand) == mine,
    );
    if (taken) {
      return (
        reason: 'Already a class in ${widget.template.name}',
        wrong: true,
      );
    }

    if (!_readyToSell && widget.twinHead > 0) {
      return (
        reason:
            '${widget.twinHead} head are ready to sell. Sell them or take '
            'them off first',
        wrong: false,
      );
    }
    return null;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final kind = _text(_kind)!;
    final editing = widget.editing;
    if (editing == null) {
      await widget.repository.createClass(
        widget.template.id,
        kind: kind,
        breed: _text(_breed),
        ageBand: _text(_ageBand),
        agesIntoClassId: _agesInto,
        readyToSell: _readyToSell,
      );
    } else {
      await widget.repository.updateClass(
        editing.id,
        kind: kind,
        breed: _text(_breed),
        ageBand: _text(_ageBand),
        agesIntoClassId: _agesInto,
        readyToSell: _readyToSell,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.editing;
    final blocker = _blocker;

    return FormDialog(
      title: editing == null ? 'New class' : 'Edit class',
      subtitle: editing?.label ?? widget.template.name,
      actionLabel: editing == null ? 'Create' : 'Save',
      onAction: _saving ? null : _save,
      blocker: blocker?.reason,
      children: [
        TextField(
          controller: _kind,
          autofocus: editing == null,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: 'Steers',
            error: blocker?.wrong ?? false ? wrongField : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _breed,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Breed (optional)',
            hintText: 'Angus',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ageBand,
          decoration: const InputDecoration(
            labelText: 'Age band (optional)',
            hintText: 'under 6 months',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          initialValue: _agesInto,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Ages into'),
          hint: const Text('Nothing'),
          items: [
            const DropdownMenuItem<String?>(child: Text('Nothing')),
            for (final c in _targets)
              DropdownMenuItem(value: c.id, child: Text(c.label)),
          ],
          onChanged: (id) => setState(() => _agesInto = id),
        ),
        const SizedBox(height: 4),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Can be marked ready to sell'),
          subtitle: const Text('Adds a ready-to-sell class beside it'),
          value: _readyToSell,
          onChanged: (value) => setState(() => _readyToSell = value),
        ),
      ],
    );
  }
}
