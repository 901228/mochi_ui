import "package:flutter/widgets.dart";

/// Casts [shadows] off a rounded rectangle with [radius], under a [child] that draws its own
/// superellipse.
///
/// Every visible corner in the kit is a superellipse, but a shadow is not cast off one: a blur
/// along an arbitrary path is drawn by blurring the whole shape, on every frame on the web, which
/// has no raster cache, while a rounded rectangle has a fast analytic blur. Under a blur the two
/// outlines cannot be told apart. Measured on the web with a 30-row raised tile group scrolling, a
/// frame's raster time went from 52ms to 16ms — 18 frames a second to 56.
///
/// So a [ShapeDecoration] here never carries `shadows`; this goes around it instead. It always
/// builds the same box, with or without shadows, so a shadow that comes and goes (a layering
/// switch) does not remount what is under it.
///
/// Not exported: it is how the kit draws its own surfaces.
class ShapeShadow extends StatelessWidget {
  const ShapeShadow({required this.radius, required this.shadows, required this.child, super.key});

  /// The corners of the superellipse [child] draws.
  final BorderRadiusGeometry radius;
  final List<BoxShadow>? shadows;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(borderRadius: radius, boxShadow: shadows),
    child: child,
  );
}
