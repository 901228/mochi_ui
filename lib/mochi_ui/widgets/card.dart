import "package:flutter/widgets.dart";

import "../theme/colors.dart";
import "../theme/geometry.dart";
import "../theme/theme.dart";
import "collapsible.dart";
import "state_transition.dart";
import "tappable.dart";

/// A surface for grouped content: [MochiColors.surface] with a border and an elevation shadow.
///
/// Pass [onPress] to make the whole card tappable; it then reacts to hover, press and focus. Or
/// use [MochiCard.collapsible] for a card whose body opens and closes under a title.
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
  }) : title = null,
       expanded = null,
       initiallyExpanded = false,
       onExpandedChanged = null;

  /// A card that shows only [title] until it is opened. The whole title row is the toggle; see
  /// [MochiCollapsible] for [expanded] (controlled) versus [initiallyExpanded].
  const MochiCard.collapsible({
    super.key,
    required Widget this.title,
    required this.child,
    this.expanded,
    this.initiallyExpanded = false,
    this.onExpandedChanged,
    this.padding,
    this.elevation = MochiElevation.sm,
    this.color,
  }) : onPress = null,
       onLongPress = null,
       onSecondaryPress = null,
       semanticLabel = null;

  /// Set by [MochiCard.collapsible].
  final Widget? title;
  final bool? expanded;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpandedChanged;

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
    if (title case final title?) {
      return _CardSurface(
        elevation: elevation,
        color: color,
        // The padding moves inside, so the title row's hover fill reaches the card's edges.
        padding: EdgeInsets.zero,
        child: _CollapsibleBody(
          padding: padding,
          title: title,
          expanded: expanded,
          initiallyExpanded: initiallyExpanded,
          onExpandedChanged: onExpandedChanged,
          child: child,
        ),
      );
    }

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

class _CollapsibleBody extends StatelessWidget {
  const _CollapsibleBody({
    required this.padding,
    required this.title,
    required this.expanded,
    required this.initiallyExpanded,
    required this.onExpandedChanged,
    required this.child,
  });

  final EdgeInsetsGeometry? padding;
  final Widget title;
  final bool? expanded;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpandedChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;
    final padding = (this.padding ?? EdgeInsets.all(g.space.md)).resolve(Directionality.of(context));

    return MochiCollapsible(
      title: title,
      expanded: expanded,
      initiallyExpanded: initiallyExpanded,
      onExpandedChanged: onExpandedChanged,
      headerPadding: padding,
      // A rule under the title row, rather than the row's own bottom padding standing in for the
      // gap: that padding is inside the row, so the row's hover fill would run into the content.
      bodyPadding: padding,
      divider: true,
      radius: g.radius.md,
      child: child,
    );
  }
}
