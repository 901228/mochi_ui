import "package:flutter/widgets.dart";

import "../theme/theme.dart";

/// Draws the theme's focus ring around [child] when [visible].
///
/// The ring is painted outside the child's bounds (offset by [MochiGeometry.focusRingGap]),
/// so showing it never changes layout. It follows the child's superellipse [radius].
class MochiFocusRing extends StatelessWidget {
  const MochiFocusRing({super.key, required this.visible, required this.radius, required this.child});

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
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;
    final outset = g.focusRingGap + g.focusRingWidth;

    // Always a Stack, so toggling the ring never reparents (and resets the state of) child.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (visible)
          Positioned.fill(
            left: -outset,
            top: -outset,
            right: -outset,
            bottom: -outset,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  shape: RoundedSuperellipseBorder(
                    borderRadius: radius + BorderRadius.all(Radius.circular(outset)),
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
