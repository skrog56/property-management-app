import 'package:flutter/material.dart';

/// Paddock green. A single seed colour generates the full Material 3 palette
/// for both brightnesses, so the pilot demonstrates that one theme definition
/// renders coherently on all six targets rather than being tuned per platform.
const Color seedColour = Color(0xFF4C6B2F);

ThemeData buildTheme(Brightness brightness) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColour,
      brightness: brightness,
    ),
    // Tightens control spacing on desktop while leaving touch targets alone on
    // mobile. One of the few places where per-platform adaptation is desirable.
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
