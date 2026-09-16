import "package:flutter/widgets.dart";

import "../theme/theme.dart";

/// A hairline rule. Takes its thickness from [MochiGeometry.borderWidth] and its color from
/// [MochiColors.border].
///
/// A divider expands along its axis, so that direction must be bounded: a horizontal divider
/// inside a [Column], a vertical one inside a [Row].
class MochiDivider extends StatelessWidget {
  const MochiDivider({
    super.key,
    this.axis = Axis.horizontal,
    this.thickness,
    this.color,
    this.indent = 0,
    this.endIndent = 0,
  });

  final Axis axis;
  final double? thickness;
  final Color? color;

  /// Empty space before the line: on the left of a horizontal divider, above a vertical one.
  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final line = ColoredBox(color: color ?? theme.colors.border);
    final size = thickness ?? theme.geometry.borderWidth;

    return Padding(
      padding: switch (axis) {
        .horizontal => EdgeInsets.only(left: indent, right: endIndent),
        .vertical => EdgeInsets.only(top: indent, bottom: endIndent),
      },
      // Expands along its axis, so it needs a bounded parent in that direction: a horizontal
      // divider in a Column, a vertical one in a Row (or anything with a bounded height).
      child: ConstrainedBox(
        constraints: switch (axis) {
          .horizontal => BoxConstraints.expand(height: size),
          .vertical => BoxConstraints.expand(width: size),
        },
        child: line,
      ),
    );
  }
}
