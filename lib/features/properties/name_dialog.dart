import 'package:flutter/material.dart';

import '../../data/app_settings.dart';
import '../../shell/form_dialog.dart';

class NameResult {
  const NameResult(this.value, {this.hectares, this.pic});

  final String value;

  /// Converted from the unit it was entered in.
  final double? hectares;
  final String? pic;
}

Future<NameResult?> promptForName(
  BuildContext context, {
  required String title,
  required String hint,
  AreaUnit? areaIn,
  bool askForPic = false,
}) {
  return showFormDialog<NameResult>(
    context,
    builder: (context) => _NameDialog(
      title: title,
      hint: hint,
      areaIn: areaIn,
      askForPic: askForPic,
    ),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.hint,
    required this.areaIn,
    required this.askForPic,
  });

  final String title;
  final String hint;

  /// Asks for an area, in this unit, when given.
  final AreaUnit? areaIn;
  final bool askForPic;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _name = TextEditingController();
  final _area = TextEditingController();
  final _pic = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    _pic.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final pic = _pic.text.trim();
    final area = double.tryParse(_area.text.trim());
    Navigator.of(context).pop(
      NameResult(
        name,
        hectares: area == null ? null : widget.areaIn?.toHectares(area),
        pic: pic.isEmpty ? null : pic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.areaIn;
    final hasSecondField = unit != null || widget.askForPic;

    return FormDialog(
      title: widget.title,
      actionLabel: 'Create',
      onAction: _submit,
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          textInputAction: hasSecondField
              ? TextInputAction.next
              : TextInputAction.done,
          decoration: InputDecoration(labelText: 'Name', hintText: widget.hint),
          onSubmitted: (_) => hasSecondField ? null : _submit(),
        ),
        if (unit != null) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _area,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: unit.label,
              hintText: switch (unit) {
                AreaUnit.hectares => '42.4',
                AreaUnit.acres => '105',
              },
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
        if (widget.askForPic) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _pic,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'PIC (optional)',
              hintText: 'QABC1234',
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ],
    );
  }
}
