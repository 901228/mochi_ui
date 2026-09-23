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

  /// One of the two themes with its accents replaced, which is how an app puts its own colour on
  /// the kit: the neutrals — page, surface, border, text — are the ones that were tuned against
  /// each other, and a brand colour is not one of them.
  ///
  /// Each accent given is expanded by [MochiTone.from], so what an app hands over is one colour
  /// per intent rather than four, and the text colours come out at [contrast] against what they
  /// sit on. The intents left null keep the theme's own.
  ///
  /// ```dart
  /// MochiApp(
  ///   lightTheme: MochiTheme.light.copyWith(colors: MochiColors.branded(primary: brandPurple)),
  ///   darkTheme: MochiTheme.dark.copyWith(
  ///     colors: MochiColors.branded(brightness: .dark, primary: brandPurple),
  ///   ),
  /// )
  /// ```
  factory MochiColors.branded({
    Brightness brightness = Brightness.light,
    required Color primary,
    Color? info,
    Color? success,
    Color? warning,
    Color? danger,
    double contrast = 4.5,
  }) {
    final base = brightness == Brightness.light ? MochiColors.light : MochiColors.dark;
    // The two inks an accent's text can be, taken from the theme being branded rather than pure
    // black and white, which are both a shade sharper than anything else on the page.
    final (light, dark) = brightness == Brightness.light
        ? (LattePalette.white, LattePalette.ink)
        : (MochaPalette.text, MochaPalette.crust);

    MochiTone? tone(Color? accent) => accent == null
        ? null
        : MochiTone.from(
            accent,
            background: base.background,
            softAlpha: base.softAlpha,
            contrast: contrast,
            light: light,
            dark: dark,
          );

    return base.copyWith(
      primary: tone(primary),
      info: tone(info),
      success: tone(success),
      warning: tone(warning),
      danger: tone(danger),
    );
  }

  MochiColors copyWith({
    Brightness? brightness,
    double? softAlpha,
    Color? background,
    Color? surface,
    Color? overlay,
    Color? border,
    Color? foreground,
    Color? mutedForeground,
    Color? focusRing,
    Color? shadow,
    MochiTone? neutral,
    MochiTone? primary,
    MochiTone? info,
    MochiTone? success,
    MochiTone? warning,
    MochiTone? danger,
  }) => MochiColors(
    brightness: brightness ?? this.brightness,
    softAlpha: softAlpha ?? this.softAlpha,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    overlay: overlay ?? this.overlay,
    border: border ?? this.border,
    foreground: foreground ?? this.foreground,
    mutedForeground: mutedForeground ?? this.mutedForeground,
    focusRing: focusRing ?? this.focusRing,
    shadow: shadow ?? this.shadow,
    neutral: neutral ?? this.neutral,
    primary: primary ?? this.primary,
    info: info ?? this.info,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    danger: danger ?? this.danger,
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

  // See [MochiTone] on why these carry value equality.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MochiColors &&
          brightness == other.brightness &&
          softAlpha == other.softAlpha &&
          background == other.background &&
          surface == other.surface &&
          overlay == other.overlay &&
          border == other.border &&
          foreground == other.foreground &&
          mutedForeground == other.mutedForeground &&
          focusRing == other.focusRing &&
          shadow == other.shadow &&
          neutral == other.neutral &&
          primary == other.primary &&
          info == other.info &&
          success == other.success &&
          warning == other.warning &&
          danger == other.danger;

  @override
  int get hashCode => Object.hash(
    brightness,
    softAlpha,
    background,
    surface,
    overlay,
    border,
    foreground,
    mutedForeground,
    focusRing,
    shadow,
    neutral,
    primary,
    info,
    success,
    warning,
    danger,
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
