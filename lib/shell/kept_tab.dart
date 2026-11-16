import 'package:flutter/widgets.dart';

/// `TabBarView` disposes a tab on leaving it, so without this every switch
/// re-runs the tab's queries — each a worker round trip on web — and loses
/// what was chosen on it.
class KeptTab extends StatefulWidget {
  const KeptTab({super.key, required this.child});

  final Widget child;

  @override
  State<KeptTab> createState() => _KeptTabState();
}

class _KeptTabState extends State<KeptTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
