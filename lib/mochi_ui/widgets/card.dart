import "package:flutter/widgets.dart";

import "../theme/colors.dart";
import "../theme/geometry.dart";
import "../theme/theme.dart";
import "state_transition.dart";
import "tappable.dart";

/// A surface for grouped content: [MochiColors.surface] with a border and an elevation shadow.
///
/// Pass [onPress] to make the whole card tappable; it then reacts to hover, press and focus.
class MochiCard extends StatelessWidget {
  const MochiCard({
    super.key,
    required this.child,
    this.padding,
    this.elevation = MochiElevation.sm,
    this.color,
    this.onPress,
    this.onLongPress,
    this.onSecondaryPress,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final MochiElevation elevation;

  /// Defaults to [MochiColors.surface].
  final Color? color;

  final VoidCallback? onPress;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryPress;
  final String? semanticLabel;

  bool get _interactive => onPress != null || onLongPress != null || onSecondaryPress != null;

  @override
  Widget build(BuildContext context) {
    if (!_interactive) {
      return _CardSurface(elevation: elevation, color: color, padding: padding, child: child);
    }

    return MochiTappable(
      onPress: onPress,
      onLongPress: onLongPress,
      onSecondaryPress: onSecondaryPress,
      semanticLabel: semanticLabel,
      // Cards are large; growing them on press looks wrong. They tint instead.
      scaleOnPress: false,
      builder: (context, states, child) =>
          _CardSurface(elevation: elevation, color: color, padding: padding, states: states, child: child!),
      child: child,
    );
  }
}

class _CardSurface extends StatelessWidget {
  const _CardSurface({
    required this.elevation,
    required this.color,
    required this.padding,
    required this.child,
    this.states = const {},
  });

  final MochiElevation elevation;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final Widget child;
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;
    final base = color ?? colors.surface;

    return MochiStateTransition(
      states: states,
      duration: theme.motion.stateDuration,
      builder: (context, blend) => Container(
        padding: padding ?? EdgeInsets.all(g.space.md),
        decoration: ShapeDecoration(
          color: blend.color((st) => MochiColors.stateLayer(base, colors.foreground, st)),
          shadows: g.shadows.of(elevation, colors.shadow),
          shape: RoundedSuperellipseBorder(
            borderRadius: g.radius.md,
            side: BorderSide(color: colors.border, width: g.borderWidth),
          ),
        ),
        // Clipped so content (rows, scrollbars) stays inside the rounded corners.
        child: ClipRSuperellipse(borderRadius: g.radius.md, child: child),
      ),
    );
  }
}
