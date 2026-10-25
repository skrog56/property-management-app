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
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final String dismissLabel;

  /// Left out, the dialog only informs, and [dismissLabel] closes it.
  final String? actionLabel;

  /// Null disables the action. Forms then name what is missing in
  /// [actionLabel], rather than leaving a dead button unexplained.
  final VoidCallback? onAction;

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
              child: OverflowBar(
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
                    FilledButton(onPressed: onAction, child: Text(label)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
