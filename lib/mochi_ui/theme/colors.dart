import "package:flutter/widgets.dart";

import "palette.dart";
import "tone.dart";

@immutable
class MochiColors {
  const MochiColors({
    required this.brightness,
    required this.softAlpha,
    required this.background,
    required this.surface,
    required this.overlay,
    required this.border,
    required this.foreground,
    required this.mutedForeground,
    required this.focusRing,
    required this.shadow,
    required this.neutral,
    required this.primary,
    required this.info,
    required this.success,
    required this.warning,
    required this.danger,
  });

  final Brightness brightness;

  /// How much of an accent a soft fill carries. Pastel accents over a dark background wash out,
  /// so the dark theme uses more of the accent than the light one.
  final double softAlpha;

  // Neutrals
  final Color background;
  final Color surface;
  final Color overlay;
  final Color border;
  final Color foreground;
  final Color mutedForeground;

  /// Keyboard focus indicator, see [MochiFocusRing].
  final Color focusRing;

  /// Base color of elevation shadows; layers in [MochiShadows] scale its alpha.
  final Color shadow;

  // Intents
  final MochiTone neutral;
  final MochiTone primary;
  final MochiTone info;
  final MochiTone success;
  final MochiTone warning;
  final MochiTone danger;

  MochiTone of(MochiIntent intent) => switch (intent) {
    .neutral => neutral,
    .primary => primary,
    .info => info,
    .success => success,
    .warning => warning,
    .danger => danger,
  };

  /// A soft fill of [tone] over [background], for surfaces that do not sit on the page background
  /// (a selected row inside a card, say): [MochiTone.soft] is mixed over the page and turns out
  /// too dark there.
  Color softOn(MochiTone tone, Color background) =>
      Color.alphaBlend(tone.base.withValues(alpha: softAlpha), background);

  /// Blends [on] over [base] according to the interaction state.
  static Color stateLayer(Color base, Color on, Set<WidgetState> states) {
    if (states.contains(WidgetState.pressed)) return Color.alphaBlend(on.withValues(alpha: 0.16), base);
    if (states.contains(WidgetState.hovered)) return Color.alphaBlend(on.withValues(alpha: 0.08), base);
    return base;
  }

  static MochiTone _accent({
    required Color base,
    required Color onBase,
    required Color onSoft,
    required Color background,
    required double softAlpha,
  }) => MochiTone(
    base: base,
    onBase: onBase,
    soft: Color.alphaBlend(base.withValues(alpha: softAlpha), background),
    onSoft: onSoft,
  );

  static const _lightSoftAlpha = 0.14;
  static const _darkSoftAlpha = 0.26;

  static final light = MochiColors(
    brightness: .light,
    softAlpha: _lightSoftAlpha,
    background: LattePalette.base,
    surface: LattePalette.mantle,
    overlay: LattePalette.white,
    border: LattePalette.surface1,
    foreground: LattePalette.text,
    mutedForeground: LattePalette.subtext0,
    focusRing: LattePalette.blue,
    shadow: LattePalette.text,
    neutral: const MochiTone(
      base: LattePalette.text,
      onBase: LattePalette.base,
      soft: LattePalette.crust,
      onSoft: LattePalette.text,
    ),
    primary: _lightAccent(LattePalette.blue, LattePalette.white, LattePalette.blueDark),
    info: _lightAccent(LattePalette.teal, LattePalette.white, LattePalette.tealDark),
    success: _lightAccent(LattePalette.green, LattePalette.white, LattePalette.greenDark),
    warning: _lightAccent(LattePalette.yellow, LattePalette.ink, LattePalette.yellowDark),
    danger: _lightAccent(LattePalette.red, LattePalette.white, LattePalette.redDark),
  );

  static final dark = MochiColors(
    brightness: .dark,
    softAlpha: _darkSoftAlpha,
    background: MochaPalette.base,
    surface: MochaPalette.surface0,
    overlay: MochaPalette.surface0,
    // surface1 is nearly invisible against the base in the dark theme; borders need one step more.
    border: MochaPalette.surface2,
    foreground: MochaPalette.text,
    mutedForeground: MochaPalette.subtext0,
    focusRing: MochaPalette.blue,
    shadow: MochaPalette.shadow,
    neutral: const MochiTone(
      base: MochaPalette.text,
      onBase: MochaPalette.crust,
      soft: MochaPalette.surface1,
      onSoft: MochaPalette.text,
    ),
    primary: _darkAccent(MochaPalette.blue),
    info: _darkAccent(MochaPalette.teal),
    success: _darkAccent(MochaPalette.green),
    warning: _darkAccent(MochaPalette.yellow),
    danger: _darkAccent(MochaPalette.red),
  );

  static MochiTone _lightAccent(Color base, Color onBase, Color onSoft) => _accent(
    base: base,
    onBase: onBase,
    onSoft: onSoft,
    background: LattePalette.base,
    softAlpha: _lightSoftAlpha,
  );

  static MochiTone _darkAccent(Color base) => _accent(
    base: base,
    onBase: MochaPalette.crust,
    onSoft: base,
    background: MochaPalette.base,
    softAlpha: _darkSoftAlpha,
  );

  static MochiColors lerp(MochiColors a, MochiColors b, double t) => MochiColors(
    brightness: t < 0.5 ? a.brightness : b.brightness,
    softAlpha: t < 0.5 ? a.softAlpha : b.softAlpha,
    background: Color.lerp(a.background, b.background, t)!,
    surface: Color.lerp(a.surface, b.surface, t)!,
    overlay: Color.lerp(a.overlay, b.overlay, t)!,
    border: Color.lerp(a.border, b.border, t)!,
    foreground: Color.lerp(a.foreground, b.foreground, t)!,
    mutedForeground: Color.lerp(a.mutedForeground, b.mutedForeground, t)!,
    focusRing: Color.lerp(a.focusRing, b.focusRing, t)!,
    shadow: Color.lerp(a.shadow, b.shadow, t)!,
    neutral: MochiTone.lerp(a.neutral, b.neutral, t),
    primary: MochiTone.lerp(a.primary, b.primary, t),
    info: MochiTone.lerp(a.info, b.info, t),
    success: MochiTone.lerp(a.success, b.success, t),
    warning: MochiTone.lerp(a.warning, b.warning, t),
    danger: MochiTone.lerp(a.danger, b.danger, t),
  );
}
