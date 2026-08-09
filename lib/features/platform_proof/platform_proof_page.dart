import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shell/breakpoints.dart';
import 'platform_facts.dart';

/// The evidence screen.
///
/// Screenshot this on each of the six targets and the set of screenshots *is*
/// the deliverable: identical code, identical layout logic, six platforms
/// reporting themselves accurately.
class PlatformProofPage extends StatefulWidget {
  const PlatformProofPage({super.key});

  @override
  State<PlatformProofPage> createState() => _PlatformProofPageState();
}

class _PlatformProofPageState extends State<PlatformProofPage> {
  late Future<PlatformFacts> _facts;

  @override
  void initState() {
    super.initState();
    _facts = PlatformFacts.gather();
  }

  Future<void> _refresh() async {
    setState(() {
      _facts = PlatformFacts.gather();
    });
    await _facts;
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      // Physical-keyboard proof. Ctrl+R on Windows/Linux, Cmd+R on macOS —
      // the same binding a desktop user would reach for by reflex.
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyR, control: true): _refresh,
        const SingleActivator(LogicalKeyboardKey.keyR, meta: true): _refresh,
      },
      child: Focus(
        autofocus: true,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<PlatformFacts>(
            future: _facts,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _ErrorView(
                  error: snapshot.error!,
                  onRetry: _refresh,
                );
              }
              return _FactsView(facts: snapshot.data!);
            },
          ),
        ),
      ),
    );
  }
}

class _FactsView extends StatelessWidget {
  const _FactsView({required this.facts});

  final PlatformFacts facts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sizeClass = WindowSizeClass.fromWidth(constraints.maxWidth);
        final columns = sizeClass.contentColumns;
        const gap = 12.0;
        const pad = 16.0;

        final available = constraints.maxWidth - (pad * 2);
        final cardWidth = (available - gap * (columns - 1)) / columns;

        final cards = <Widget>[
          _FactCard(
            title: 'Device',
            icon: Icons.devices_other,
            facts: facts.deviceFacts,
          ),
          _FactCard(
            title: 'Application',
            icon: Icons.inventory_2_outlined,
            facts: facts.appFacts,
          ),
          _FactCard(
            title: 'Display metrics (live)',
            icon: Icons.aspect_ratio,
            facts: _displayFacts(context, sizeClass),
          ),
          const _InputModalityCard(),
        ];

        return ListView(
          padding: const EdgeInsets.all(pad),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _HeaderCard(facts: facts),
            const SizedBox(height: gap),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final card in cards)
                  SizedBox(width: columns == 1 ? available : cardWidth, child: card),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Read from [MediaQuery], so these rows update as the window is resized —
  /// which makes the responsive behaviour self-evident on desktop and web.
  List<Fact> _displayFacts(BuildContext context, WindowSizeClass sizeClass) {
    final mq = MediaQuery.of(context);
    final textScale = mq.textScaler.scale(100) / 100;
    final physicalW = (mq.size.width * mq.devicePixelRatio).round();
    final physicalH = (mq.size.height * mq.devicePixelRatio).round();

    return [
      Fact('Size class', sizeClass.label),
      Fact(
        'Logical size',
        '${mq.size.width.toStringAsFixed(0)} × ${mq.size.height.toStringAsFixed(0)} dp',
      ),
      Fact('Device pixel ratio', mq.devicePixelRatio.toStringAsFixed(2)),
      Fact('Physical pixels', '$physicalW × $physicalH'),
      Fact('Text scale', '×${textScale.toStringAsFixed(2)}'),
      Fact('Platform brightness', mq.platformBrightness.name),
      Fact('Orientation', mq.orientation.name),
      Fact(
        'Safe area insets',
        'T${mq.padding.top.round()}  B${mq.padding.bottom.round()}  '
            'L${mq.padding.left.round()}  R${mq.padding.right.round()}',
      ),
    ];
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.facts});

  final PlatformFacts facts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.verified_outlined,
              size: 40,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Running on ${facts.platformLabel}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    facts.runtimeLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
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

class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.title,
    required this.icon,
    required this.facts,
  });

  final String title;
  final IconData icon;
  final List<Fact> facts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            const Divider(height: 20),
            for (final fact in facts) _FactRow(fact: fact),
          ],
        ),
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.fact});

  final Fact fact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              fact.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              fact.value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Desktop and mobile fail in different ways, so the pilot probes both input
/// models rather than assuming whichever one the developer happened to test.
class _InputModalityCard extends StatefulWidget {
  const _InputModalityCard();

  @override
  State<_InputModalityCard> createState() => _InputModalityCardState();
}

class _InputModalityCardState extends State<_InputModalityCard> {
  bool _hovering = false;
  bool _everHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('Input modalities', style: theme.textTheme.titleMedium),
              ],
            ),
            const Divider(height: 20),
            MouseRegion(
              onEnter: (_) => setState(() {
                _hovering = true;
                _everHovered = true;
              }),
              onExit: (_) => setState(() => _hovering = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _hovering
                      ? theme.colorScheme.secondaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _everHovered ? Icons.mouse : Icons.mouse_outlined,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _everHovered
                            ? 'Mouse detected — hover events are firing'
                            : 'Hover here with a pointer',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _Hint(
              icon: Icons.keyboard_outlined,
              text: 'Press Ctrl+R (or Cmd+R) to re-read every fact',
            ),
            const _Hint(
              icon: Icons.swipe_down_alt_outlined,
              text: 'Pull down to refresh — the touch equivalent',
            ),
            const _Hint(
              icon: Icons.open_in_full,
              text: 'Resize the window to watch the layout re-flow',
            ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Icon(
          Icons.error_outline,
          size: 48,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          'Could not read platform facts',
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '$error',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}
