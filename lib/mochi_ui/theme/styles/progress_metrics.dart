import "dart:ui" show lerpDouble;

import "package:flutter/foundation.dart";

import "../size.dart";

/// Size-dependent layout of the progress indicators, shared by the ring and the bar so that a
/// `size` means the same weight for both.
///
/// Desktop ring diameters 12 / 16 / 20 / 28 and bar thicknesses 3 / 4 / 6 / 10; touch runs a
/// little larger. `md` is the default.
@immutable
class MochiProgressMetrics {
  const MochiProgressMetrics({required this.diameter, required this.strokeWidth, required this.thickness});

  /// Of [MochiCircularProgress].
  final double diameter;

  /// The ring's line. A sixth of the diameter: thinner leaves about a pixel of antialiasing on a
  /// 1x display, which shimmers as it rotates.
  final double strokeWidth;

  /// Of [MochiLinearProgress].
  final double thickness;

  factory MochiProgressMetrics.of(MochiSize size, {required bool touch}) {
    final (diameter, thickness) = switch ((size, touch)) {
      (.xs, false) => (12.0, 3.0),
      (.sm, false) => (16.0, 4.0),
      (.md, false) => (20.0, 6.0),
      (.lg, false) => (28.0, 10.0),
      (.xs, true) => (14.0, 4.0),
      (.sm, true) => (18.0, 6.0),
      (.md, true) => (22.0, 8.0),
      (.lg, true) => (32.0, 12.0),
    };

    return MochiProgressMetrics(diameter: diameter, strokeWidth: diameter / 6, thickness: thickness);
  }

  static MochiProgressMetrics lerp(MochiProgressMetrics a, MochiProgressMetrics b, double t) =>
      MochiProgressMetrics(
        diameter: lerpDouble(a.diameter, b.diameter, t)!,
        strokeWidth: lerpDouble(a.strokeWidth, b.strokeWidth, t)!,
        thickness: lerpDouble(a.thickness, b.thickness, t)!,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MochiProgressMetrics &&
          diameter == other.diameter &&
          strokeWidth == other.strokeWidth &&
          thickness == other.thickness;

  @override
  int get hashCode => Object.hash(diameter, strokeWidth, thickness);
}
