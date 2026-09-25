import 'package:flutter/material.dart';

class NameResult {
  const NameResult(this.value, {this.hectares, this.pic});

  final String value;
  final double? hectares;
  final String? pic;
}

Future<NameResult?> promptForName(
  BuildContext context, {
  required String title,
  required String hint,
  bool askForHectares = false,
  bool askForPic = false,
}) {
  return showDialog<NameResult>(
    context: context,
    builder: (context) => _NameDialog(
      title: title,
      hint: hint,
      askForHectares: askForHectares,
      askForPic: askForPic,
    ),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.hint,
    required this.askForHectares,
    required this.askForPic,
  });

  final String title;
  final String hint;
  final bool askForHectares;
  final bool askForPic;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _name = TextEditingController();
  final _hectares = TextEditingController();
  final _pic = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _hectares.dispose();
    _pic.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final pic = _pic.text.trim();
    Navigator.of(context).pop(
      NameResult(
        name,
        hectares: double.tryParse(_hectares.text.trim()),
        pic: pic.isEmpty ? null : pic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSecondField = widget.askForHectares || widget.askForPic;

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            textInputAction: hasSecondField
                ? TextInputAction.next
                : TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: widget.hint,
            ),
            onSubmitted: (_) => hasSecondField ? null : _submit(),
          ),
          if (widget.askForHectares) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _hectares,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Hectares',
                hintText: '42.4',
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }
}
