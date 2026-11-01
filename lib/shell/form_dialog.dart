import 'package:flutter/material.dart';

/// Opens [builder], which should build a [FormDialog], rising from the bottom
/// edge to rest centred.
Future<T?> showFormDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    // Slid as a whole page, so the dialog rises from below the screen edge
    // rather than from just under its own resting place.
    transitionBuilder: (context, animation, _, child) => SlideTransition(
      position: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ).drive(Tween(begin: const Offset(0, 1), end: Offset.zero)),
      child: child,
    ),
    pageBuilder: (context, _, _) => Builder(builder: builder),
  );
}

/// For [InputDecoration.error]: shows a field in its error colours, as focus
/// shows it in the primary, without a message of its own. The dialog's
/// [FormDialog.blocker] says what is wrong.
const Widget wrongField = SizedBox.shrink();

/// The one shape every form and confirmation takes: a title, a scrolling
/// body, and a dismiss button beside an optional primary action.
class FormDialog extends StatelessWidget {
  const FormDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.dismissLabel = 'Cancel',
    this.actionLabel,
    this.onAction,
    this.blocker,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final String dismissLabel;

  /// Left out, the dialog only informs, and [dismissLabel] closes it.
  final String? actionLabel;

  /// Null disables the action.
  final VoidCallback? onAction;

  /// What stops the action, shown above the buttons, which disables it.
  /// Not in [actionLabel]: a label that changes width as the form is filled
  /// in stacks the buttons on a phone whenever it is long.
  final String? blocker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.headlineSmall),
                  if (subtitle case final subtitle?) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (blocker case final blocker?) ...[
                    Text(
                      blocker,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    overflowAlignment: OverflowBarAlignment.end,
                    spacing: 8,
                    overflowSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(dismissLabel),
                      ),
                      if (actionLabel case final label?)
                        FilledButton(
                          onPressed: blocker == null ? onAction : null,
                          child: Text(label),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
