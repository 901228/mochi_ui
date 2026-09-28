import "package:flutter/widgets.dart";

/// A size scale for one font family. Sizes and line heights follow Tailwind's type scale,
/// with `md` as the 16px base. Styles carry no color; it comes from [DefaultTextStyle].
@immutable
class MochiTypeface {
  MochiTypeface({
    required this.fontFamily,
    this.fontFamilyFallback = const [],
    this.weight = FontWeight.w400,
    this.fontFeatures = const [],
  }) : xs3 = _style(fontFamily, fontFamilyFallback, weight, fontFeatures, 10, 14),
       xs2 = _style(fontFamily, fontFamilyFallback, weight, fontFeatures, 11, 16),
       xs = _style(fontFamily, fontFamilyFallback, weight, fontFeatures, 12, 16),
       sm = _style(fontFamily, fontFamilyFallback, weight, fontFeatures, 14, 20),
       md = _style(fontFamily, fontFamilyFallback, weight, fontFeatures, 16, 24),
       lg = _style(fontFamily, fontFamilyFallback, weight, fontFeatures, 18, 28),
       xl = _style(fontFamily, fontFamilyFallback, weight, fontFeatures, 20, 28),
       xl2 = _style(fontFamily, fontFamilyFallback, weight, fontFeatures, 24, 32),
       xl3 = _style(fontFamily, fontFamilyFallback, weight, fontFeatures, 30, 36),
       xl4 = _style(fontFamily, fontFamilyFallback, weight, fontFeatures, 36, 40),
       xl5 = _style(fontFamily, fontFamilyFallback, weight, fontFeatures, 48, 48),
       xl6 = _style(fontFamily, fontFamilyFallback, weight, fontFeatures, 60, 60),
       xl7 = _style(fontFamily, fontFamilyFallback, weight, fontFeatures, 72, 72),
       xl8 = _style(fontFamily, fontFamilyFallback, weight, fontFeatures, 96, 96);

  const MochiTypeface.raw({
    required this.fontFamily,
    required this.fontFamilyFallback,
    required this.weight,
    this.fontFeatures = const [],
    required this.xs3,
    required this.xs2,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xl2,
    required this.xl3,
    required this.xl4,
    required this.xl5,
    required this.xl6,
    required this.xl7,
    required this.xl8,
  });

  final String fontFamily;
  final List<String> fontFamilyFallback;

  /// Default weight of every style in this typeface.
  final FontWeight weight;

  /// OpenType features every style in this typeface carries.
  ///
  /// This is where a readout gets `FontFeature.tabularFigures()`: most families space their
  /// digits proportionally, so a timer set in one shuffles sideways as it counts, and changing
  /// the family alone does not stop it.
  final List<FontFeature> fontFeatures;

  final TextStyle xs3;
  final TextStyle xs2;
  final TextStyle xs;
  final TextStyle sm;
  final TextStyle md;
  final TextStyle lg;
  final TextStyle xl;
  final TextStyle xl2;
  final TextStyle xl3;
  final TextStyle xl4;
  final TextStyle xl5;
  final TextStyle xl6;
  final TextStyle xl7;
  final TextStyle xl8;

  static TextStyle _style(
    String family,
    List<String> fallback,
    FontWeight weight,
    List<FontFeature> features,
    double size,
    double lineHeight,
  ) => TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontFeatures: features.isEmpty ? null : features,
    fontSize: size,
    height: lineHeight / size,
    leadingDistribution: TextLeadingDistribution.even,
  ).withWeight(weight);

  MochiTypeface scale(double factor) {
    TextStyle s(TextStyle style) => style.copyWith(fontSize: style.fontSize! * factor);
    return MochiTypeface.raw(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      weight: weight,
      fontFeatures: fontFeatures,
      xs3: s(xs3),
      xs2: s(xs2),
      xs: s(xs),
      sm: s(sm),
      md: s(md),
      lg: s(lg),
      xl: s(xl),
      xl2: s(xl2),
      xl3: s(xl3),
      xl4: s(xl4),
      xl5: s(xl5),
      xl6: s(xl6),
      xl7: s(xl7),
      xl8: s(xl8),
    );
  }
}

@immutable
class MochiTypography {
  const MochiTypography({required this.title, required this.body});

  /// Headings.
  final MochiTypeface title;

  /// Content, labels, buttons.
  final MochiTypeface body;

  static final standard = MochiTypography(
    title: MochiTypeface(fontFamily: "Comfortaa", fontFamilyFallback: _fallback, weight: FontWeight.w700),
    body: MochiTypeface(fontFamily: "Comfortaa", fontFamilyFallback: _fallback),
  );

  // Comfortaa has no CJK glyphs.
  static const _fallback = ["FakePearl"];

  MochiTypography scale(double factor) =>
      MochiTypography(title: title.scale(factor), body: body.scale(factor));
}

extension MochiTextStyleX on TextStyle {
  /// Sets `fontWeight` (selects static faces, e.g. the FakePearl fallback) together with the
  /// `wght` axis of variable fonts such as Comfortaa. The web renderer maps `fontWeight` to
  /// `wght` on its own; setting the axis explicitly avoids relying on that per renderer.
  TextStyle withWeight(FontWeight weight) =>
      copyWith(fontWeight: weight, fontVariations: [FontVariation.weight(weight.value.toDouble())]);
}
