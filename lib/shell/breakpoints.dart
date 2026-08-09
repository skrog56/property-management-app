/// Material 3 window size classes.
///
/// Layout decisions key off the *window width*, never off the operating system.
/// That distinction is the whole point: a phone in landscape, a tablet, a small
/// desktop window and a narrow browser tab should all get the same treatment,
/// and they only do if the breakpoint is the input.
///
/// See https://m3.material.io/foundations/layout/applying-layout
enum WindowSizeClass {
  compact,
  medium,
  expanded,
  large,
  extraLarge;

  static WindowSizeClass fromWidth(double width) {
    if (width < 600) return WindowSizeClass.compact;
    if (width < 840) return WindowSizeClass.medium;
    if (width < 1200) return WindowSizeClass.expanded;
    if (width < 1600) return WindowSizeClass.large;
    return WindowSizeClass.extraLarge;
  }

  String get label => switch (this) {
    WindowSizeClass.compact => 'Compact (< 600 dp)',
    WindowSizeClass.medium => 'Medium (600–839 dp)',
    WindowSizeClass.expanded => 'Expanded (840–1199 dp)',
    WindowSizeClass.large => 'Large (1200–1599 dp)',
    WindowSizeClass.extraLarge => 'Extra large (≥ 1600 dp)',
  };

  /// Phones get a bottom bar because the top of the screen is out of thumb
  /// reach; everything wider gets a side rail.
  bool get usesBottomBar => this == WindowSizeClass.compact;

  /// Only show rail labels once there is width to spare for them.
  bool get usesExtendedRail => index >= WindowSizeClass.expanded.index;

  /// Multi-column content once the window is genuinely wide.
  int get contentColumns => switch (this) {
    WindowSizeClass.compact || WindowSizeClass.medium => 1,
    WindowSizeClass.expanded || WindowSizeClass.large => 2,
    WindowSizeClass.extraLarge => 3,
  };
}
