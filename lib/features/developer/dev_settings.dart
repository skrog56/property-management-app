import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Overrides the developer can flip at runtime. Everything defaults to off, so
/// an untouched instance leaves the app exactly as a user would see it.
class DevSettings extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  double _textScale = 1.0;
  double? _simulatedWidth;
  bool _performanceOverlay = false;
  bool _semanticsDebugger = false;

  ThemeMode get themeMode => _themeMode;
  double get textScale => _textScale;
  double? get simulatedWidth => _simulatedWidth;
  bool get performanceOverlay => _performanceOverlay;
  bool get semanticsDebugger => _semanticsDebugger;
  bool get paintSize => debugPaintSizeEnabled;
  bool get repaintRainbow => debugRepaintRainbowEnabled;

  set themeMode(ThemeMode value) => _set(() => _themeMode = value);
  set textScale(double value) => _set(() => _textScale = value);
  set simulatedWidth(double? value) => _set(() => _simulatedWidth = value);
  set performanceOverlay(bool value) => _set(() => _performanceOverlay = value);
  set semanticsDebugger(bool value) => _set(() => _semanticsDebugger = value);

  // Render-layer globals only take effect on the next full repaint, which is
  // what the Flutter inspector forces the same way.
  set paintSize(bool value) {
    debugPaintSizeEnabled = value;
    _repaint();
  }

  set repaintRainbow(bool value) {
    debugRepaintRainbowEnabled = value;
    _repaint();
  }

  void _repaint() {
    WidgetsBinding.instance.reassembleApplication();
    notifyListeners();
  }

  void _set(VoidCallback change) {
    change();
    notifyListeners();
  }

  /// Applied in `MaterialApp.builder`. The simulated width narrows the real
  /// constraints rather than faking a platform, so layout still keys off width
  /// alone.
  Widget apply(BuildContext context, Widget? child) {
    final outer = MediaQuery.of(context);
    final width = _simulatedWidth;
    final narrowed = width != null && width < outer.size.width;

    final content = MediaQuery(
      data: outer.copyWith(
        textScaler: _textScale == 1.0
            ? outer.textScaler
            : TextScaler.linear(_textScale),
        size: narrowed ? Size(width, outer.size.height) : outer.size,
      ),
      child: child ?? const SizedBox.shrink(),
    );

    if (!narrowed) return content;

    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: SizedBox(width: width, child: content),
      ),
    );
  }
}

class DevSettingsScope extends InheritedNotifier<DevSettings> {
  const DevSettingsScope({
    super.key,
    required DevSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static DevSettings? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DevSettingsScope>()?.notifier;
}
