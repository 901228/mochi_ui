import "package:flutter/widgets.dart";

enum MochiIntent { neutral, primary, info, success, warning, danger }

/// A group of colors derived from one intent, shared by every component.
@immutable
class MochiTone {
  const MochiTone({required this.base, required this.onBase, required this.soft, required this.onSoft});

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
