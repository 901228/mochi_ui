import "package:flutter/widgets.dart";

import "../theme/geometry.dart";
import "../theme/theme.dart";

/// Clips [child] to a box with [borderRadius], with the theme's corners (`MochiGeometry.corners`):
/// a `ClipRSuperellipse` or a `ClipRRect`. Components clip through this rather than naming either,
/// so a theme drawn with rounded corners does not keep a superellipse clip anywhere — on the web
/// that clip is the expensive half.
///
/// Reads the theme with a fallback, so it works outside a `MochiApp`.
class MochiClip extends StatelessWidget {
  const MochiClip({
    super.key,
    this.borderRadius = BorderRadius.zero,
    this.clipBehavior = Clip.antiAlias,
    this.child,
  });

  final BorderRadiusGeometry borderRadius;
  final Clip clipBehavior;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final corners =
        context.dependOnInheritedWidgetOfExactType<MochiThemeScope>()?.theme.geometry.corners ??
        MochiCorners.platform;

    return switch (corners) {
      .superellipse => ClipRSuperellipse(
        borderRadius: borderRadius,
        clipBehavior: clipBehavior,
        child: child,
      ),
      .rounded => ClipRRect(borderRadius: borderRadius, clipBehavior: clipBehavior, child: child),
    };
  }
}
