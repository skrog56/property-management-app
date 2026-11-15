import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_settings.dart';
import '../../shell/form_dialog.dart';

/// Asks for a duration of the user's own, starting from [initial].
Future<Retention?> showRetentionDialog(
  BuildContext context, {
  required Retention initial,
}) => showFormDialog<Retention>(
  context,
  builder: (_) => _RetentionDialog(initial: initial),
);

class _RetentionDialog extends StatefulWidget {
  const _RetentionDialog({required this.initial});

  final Retention initial;

  @override
  State<_RetentionDialog> createState() => _RetentionDialogState();
}

class _RetentionDialogState extends State<_RetentionDialog> {
  late final _count = TextEditingController(
    text: widget.initial.isAlways ? '' : '${widget.initial.count}',
  );
  late var _unit = widget.initial.isAlways
      ? RetentionUnit.days
      : widget.initial.unit;

  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  int? get _number => int.tryParse(_count.text);

  String? get _blocker => switch (_number) {
    null => 'Enter how many.',
    < 1 => 'Enter at least 1.',
    _ => null,
  };

  void _submit() {
    if (_blocker != null) return;
    Navigator.of(context).pop(Retention(_number!, _unit));
  }

  @override
  Widget build(BuildContext context) {
    final number = _number;

    return FormDialog(
      title: 'Custom duration',
      subtitle: 'How long ended stock stays visible',
      actionLabel: 'Save',
      onAction: _submit,
      blocker: _blocker,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Expanded(
              child: TextField(
                controller: _count,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  labelText: 'Number',
                  error: number != null && number < 1 ? wrongField : null,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),
            ),
            Expanded(
              child: DropdownButtonFormField<RetentionUnit>(
                initialValue: _unit,
                // Half a phone's dialog is narrow for "Months".
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Unit'),
                onChanged: (unit) => setState(() => _unit = unit!),
                items: [
                  for (final unit in RetentionUnit.values)
                    DropdownMenuItem(
                      value: unit,
                      child: Text(_capitalised(unit.counted(number ?? 0))),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _capitalised(String word) =>
      '${word[0].toUpperCase()}${word.substring(1)}';
}
