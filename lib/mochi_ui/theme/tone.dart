import "package:flutter/widgets.dart";

import "contrast.dart";

/// What a colour means, rather than what it is: every component takes one of these and looks
/// the matching [MochiTone] up in [MochiColors].
enum MochiIntent { neutral, primary, info, success, warning, danger }

/// A group of colors derived from one intent, shared by every component.
@immutable
class MochiTone {
  const MochiTone({required this.base, required this.onBase, required this.soft, required this.onSoft});

  /// The other three worked out from [base], so an app changing its accent colour hands over one
  /// colour rather than four.
  ///
  /// [onBase] is a choice between two inks — [light] and [dark] — whichever reads better on the
  /// fill, falling back to plain white or black when neither of them reaches [contrast]: the
  /// theme's own inks are softer than either, and a mid-toned accent leaves them both short.
  /// [onSoft] is [base] itself, darkened or lightened until it reads against [background]
  /// (which is the page, not [soft]: intent-coloured text sits on both). [soft] is [base] laid
  /// over the page at [softAlpha]. Pass any of them to say so yourself; nothing is worked out
  /// that was given.
  ///
  /// [contrast] is the ratio those two have to reach: WCAG AA for body text by default.
  ///
  /// ```dart
  /// MochiTone.from(brandPurple, background: colors.background, softAlpha: colors.softAlpha)
  /// ```
  factory MochiTone.from(
    Color base, {
    required Color background,
    required double softAlpha,
    Color? onBase,
    Color? soft,
    Color? onSoft,
    double contrast = 4.5,
    Color light = const Color(0xFFFFFFFF),
    Color dark = const Color(0xFF11111B),
  }) => MochiTone(
    base: base,
    onBase: onBase ?? _ink(base, light, dark, contrast),
    soft: soft ?? Color.alphaBlend(base.withValues(alpha: softAlpha), background),
    onSoft: onSoft ?? readableOn(background, base, target: contrast),
  );

  static Color _ink(Color base, Color light, Color dark, double contrast) {
    final soft = mostReadable(base, [light, dark]);
    if (contrastRatio(base, soft) >= contrast) return soft;

    return mostReadable(base, const [Color(0xFFFFFFFF), Color(0xFF000000)]);
  }

  /// Solid fills, borders, indicators, icons.
  final Color base;

  /// Text and icons placed on [base].
  final Color onBase;

  /// Tinted backgrounds: soft buttons, alerts, tags, selection.
  final Color soft;

  /// Intent-colored text placed on [soft] or the page background.
  final Color onSoft;

  // Value equality, so a theme that interpolates to the colors it already has compares equal and
  // no animation is started for it.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MochiTone &&
          base == other.base &&
          onBase == other.onBase &&
          soft == other.soft &&
          onSoft == other.onSoft;

  @override
  int get hashCode => Object.hash(base, onBase, soft, onSoft);

  static MochiTone lerp(MochiTone a, MochiTone b, double t) => MochiTone(
    base: Color.lerp(a.base, b.base, t)!,
    onBase: Color.lerp(a.onBase, b.onBase, t)!,
    soft: Color.lerp(a.soft, b.soft, t)!,
    onSoft: Color.lerp(a.onSoft, b.onSoft, t)!,
  );
}
