import "dart:ui" show lerpDouble;

import "package:flutter/widgets.dart";

import "../colors.dart";
import "../geometry.dart";
import "../size.dart";
import "../tone.dart";
import "../typography.dart";

enum MochiButtonAppearance { solid, soft, outlined, ghost, text, inverted }

/// Size-dependent layout of a button. Heights follow forui: desktop 28/32/36/40, touch 32/40/44/48.
@immutable
class MochiButtonMetrics {
  const MochiButtonMetrics({
    required this.height,
    required this.horizontalPadding,
    required this.gap,
    required this.iconSize,
    required this.radius,
    required this.textStyle,
  });

  /// Minimum height; also the width of icon-only buttons.
  final double height;
  final double horizontalPadding;

  /// Space between prefix, child and suffix.
  final double gap;
  final double iconSize;
  final BorderRadius Function(MochiRadius radius) radius;
  final TextStyle Function(MochiTypography typography) textStyle;

  factory MochiButtonMetrics.of(MochiSize size, {required bool touch}) => switch ((size, touch)) {
    (.xs, false) => const MochiButtonMetrics(
      height: 28,
      horizontalPadding: 8,
      gap: 4,
      iconSize: 14,
      radius: _xsRadius,
      textStyle: _xs,
    ),
    (.sm, false) => const MochiButtonMetrics(
      height: 32,
      horizontalPadding: 10,
      gap: 6,
      iconSize: 16,
      radius: _smRadius,
      textStyle: _sm,
    ),
    (.md, false) => const MochiButtonMetrics(
      height: 36,
      horizontalPadding: 12,
      gap: 6,
      iconSize: 16,
      radius: _smRadius,
      textStyle: _sm,
    ),
    (.lg, false) => const MochiButtonMetrics(
      height: 40,
      horizontalPadding: 14,
      gap: 8,
      iconSize: 18,
      radius: _smRadius,
      textStyle: _md,
    ),
    (.xs, true) => const MochiButtonMetrics(
      height: 32,
      horizontalPadding: 10,
      gap: 4,
      iconSize: 16,
      radius: _xsRadius,
      textStyle: _xs,
    ),
    (.sm, true) => const MochiButtonMetrics(
      height: 40,
      horizontalPadding: 12,
      gap: 6,
      iconSize: 18,
      radius: _smRadius,
      textStyle: _sm,
    ),
    (.md, true) => const MochiButtonMetrics(
      height: 44,
      horizontalPadding: 14,
      gap: 6,
      iconSize: 18,
      radius: _smRadius,
      textStyle: _sm,
    ),
    (.lg, true) => const MochiButtonMetrics(
      height: 48,
      horizontalPadding: 16,
      gap: 8,
      iconSize: 20,
      radius: _smRadius,
      textStyle: _md,
    ),
  };

  // Value equality matters: MochiValueTransition restarts whenever the value changes, and metrics
  // are rebuilt on every frame of a theme animation.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MochiButtonMetrics &&
          height == other.height &&
          horizontalPadding == other.horizontalPadding &&
          gap == other.gap &&
          iconSize == other.iconSize &&
          radius == other.radius &&
          textStyle == other.textStyle;

  @override
  int get hashCode => Object.hash(height, horizontalPadding, gap, iconSize, radius, textStyle);

  /// Blends two sizes, so a button changing scale grows into the new one instead of jumping.
  static MochiButtonMetrics lerp(MochiButtonMetrics a, MochiButtonMetrics b, double t) => MochiButtonMetrics(
    height: lerpDouble(a.height, b.height, t)!,
    horizontalPadding: lerpDouble(a.horizontalPadding, b.horizontalPadding, t)!,
    gap: lerpDouble(a.gap, b.gap, t)!,
    iconSize: lerpDouble(a.iconSize, b.iconSize, t)!,
    radius: (r) => BorderRadius.lerp(a.radius(r), b.radius(r), t)!,
    textStyle: (typography) => TextStyle.lerp(a.textStyle(typography), b.textStyle(typography), t)!,
  );

  static BorderRadius _xsRadius(MochiRadius r) => r.xs;
  static BorderRadius _smRadius(MochiRadius r) => r.sm;

  static TextStyle _xs(MochiTypography t) => t.body.xs;
  static TextStyle _sm(MochiTypography t) => t.body.sm;
  static TextStyle _md(MochiTypography t) => t.body.md;
}

typedef MochiStateColor = Color Function(MochiColors colors, Set<WidgetState> states);

bool _never(Set<WidgetState> states) => false;

@immutable
class MochiButtonStyle {
  const MochiButtonStyle({
    required this.background,
    required this.foreground,
    required this.border,
    this.underline = _never,
    this.duration,
  });

  final MochiStateColor background;
  final MochiStateColor foreground;
  final MochiStateColor border;
  final bool Function(Set<WidgetState> states) underline;

  /// Defaults to [MochiMotion.stateDuration].
  final Duration? duration;

  factory MochiButtonStyle.of(MochiIntent intent, MochiButtonAppearance appearance) {
    // Selected steps the appearance up one level of emphasis.
    MochiButtonAppearance painted(Set<WidgetState> s) => s.contains(WidgetState.selected)
        ? switch (appearance) {
            .text || .ghost || .outlined => .soft,
            .soft || .inverted || .solid => .solid,
          }
        : appearance;

    // A selected solid button has nowhere to step up to, so it is deepened instead.
    bool deepen(Set<WidgetState> s) => appearance == .solid && s.contains(WidgetState.selected);

    return MochiButtonStyle(
      background: (c, s) => _background(c.of(intent), painted(s), s, deepen: deepen(s)),
      foreground: (c, s) => _foreground(c.of(intent), painted(s)),
      border: (c, s) => appearance == .outlined
          ? c.of(intent).base
          : _border(c.of(intent), painted(s), s, deepen: deepen(s)),
      underline: (s) =>
          painted(s) == .text && (s.contains(WidgetState.hovered) || s.contains(WidgetState.pressed)),
    );
  }

  // Transparent colors keep the hue of the color they fade to: lerping from
  // 0x00000000 passes through a translucent gray.
  static Color _background(
    MochiTone t,
    MochiButtonAppearance a,
    Set<WidgetState> s, {
    required bool deepen,
  }) => switch (a) {
    .solid => MochiColors.stateLayer(
      deepen ? Color.alphaBlend(t.onBase.withValues(alpha: 0.2), t.base) : t.base,
      t.onBase,
      s,
    ),
    .soft => MochiColors.stateLayer(t.soft, t.onSoft, s),
    .outlined || .ghost => _tinted(t, s),
    .text => t.soft.withValues(alpha: 0),
    .inverted => MochiColors.stateLayer(t.onBase, t.base, s),
  };

  static Color _foreground(MochiTone t, MochiButtonAppearance a) => switch (a) {
    .solid => t.onBase,
    .soft || .outlined || .ghost || .text => t.onSoft,
    .inverted => t.base,
  };

  // Filled appearances keep a transparent border: stroking the same color as the fill paints
  // the antialiased edge twice, which hardens it into visible stair steps.
  static Color _border(MochiTone t, MochiButtonAppearance a, Set<WidgetState> s, {required bool deepen}) =>
      switch (a) {
        .outlined => t.base,
        .solid || .inverted || .soft || .ghost || .text => t.base.withValues(alpha: 0),
      };

  // Transparent at rest, tinted with the soft color on interaction.
  static Color _tinted(MochiTone t, Set<WidgetState> s) {
    if (s.contains(WidgetState.pressed)) return MochiColors.stateLayer(t.soft, t.onSoft, s);
    if (s.contains(WidgetState.hovered)) return t.soft;
    return t.soft.withValues(alpha: 0);
  }
}
