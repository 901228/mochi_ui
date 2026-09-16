import "dart:math" as math;

import "package:flutter/widgets.dart";

import "../theme/theme.dart";

/// Draws the theme's focus ring around [child] when [visible].
///
/// The ring is painted outside the child's bounds (offset by [MochiGeometry.focusRingGap]),
/// so showing it never changes layout. It follows the child's superellipse [radius].
class MochiFocusRing extends StatelessWidget {
  const MochiFocusRing({
    super.key,
    required this.visible,
    required this.radius,
    this.inset = false,
    required this.child,
  });

  /// How far the ring extends beyond its child on every side.
  ///
  /// The ring is painted outside the child's bounds, so an ancestor that clips (a scroll view,
  /// a clipped card) cuts it off unless the layout reserves this much room around focusable
  /// widgets.
  static double outsetOf(BuildContext context) {
    final g = context.theme.geometry;
    return g.focusRingGap + g.focusRingWidth;
  }

  final bool visible;

  /// Corner radius of [child]; the ring's radius grows by the gap to stay concentric.
  final BorderRadius radius;

  /// Draw the ring just inside the child instead of around it, for rows and other widgets whose
  /// parent clips them. Costs no layout either way; an inset ring overlaps the child's edge.
  final bool inset;

  final Widget child;

  static BorderRadius _shrink(BorderRadius radius, double by) {
    Radius fit(Radius r) => Radius.elliptical(math.max(0, r.x - by), math.max(0, r.y - by));
    return BorderRadius.only(
      topLeft: fit(radius.topLeft),
      topRight: fit(radius.topRight),
      bottomLeft: fit(radius.bottomLeft),
      bottomRight: fit(radius.bottomRight),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;
    final distance = g.focusRingGap + g.focusRingWidth;
    final offset = inset ? distance : -distance;
    final shift = BorderRadius.all(Radius.circular(distance));
    final ringRadius = inset ? _shrink(radius, distance) : radius + shift;

    // Always a Stack, so toggling the ring never reparents (and resets the state of) child.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (visible)
          Positioned.fill(
            left: offset,
            top: offset,
            right: offset,
            bottom: offset,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  shape: RoundedSuperellipseBorder(
                    borderRadius: ringRadius,
                    side: BorderSide(
                      color: theme.colors.focusRing,
                      width: g.focusRingWidth,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
