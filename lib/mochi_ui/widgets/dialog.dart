import "package:flutter/widgets.dart";

import "../theme/geometry.dart";
import "../theme/motion.dart";
import "../theme/theme.dart";
import "transitions.dart";

/// A modal box: a title, some content, and the actions that answer it.
///
/// Show it with [showMochiDialog], which supplies the barrier and the motion.
class MochiDialog extends StatelessWidget {
  const MochiDialog({
    super.key,
    required this.title,
    this.body,
    this.actions = const [],
    this.actionsAxis,
    this.constraints = const BoxConstraints(minWidth: 280, maxWidth: 560),
    this.padding,
    this.semanticLabel,
  });

  final Widget title;

  /// The question or detail under the title. Scrolls when it outgrows the screen.
  final Widget? body;

  /// Answers to the dialog, in reading order: the one that dismisses it first, the one that
  /// carries it out last.
  final List<Widget> actions;

  /// Defaults to a column of full-width buttons on touch and a row aligned to the end on the
  /// desktop scale, which is where the pointer already is.
  final Axis? actionsAxis;

  final BoxConstraints constraints;
  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;
    final axis = actionsAxis ?? (theme.touch ? Axis.vertical : Axis.horizontal);

    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      namesRoute: true,
      label: semanticLabel,
      child: ConstrainedBox(
        constraints: constraints,
        child: Container(
          padding: padding ?? EdgeInsets.all(theme.touch ? g.space.lg : g.space.md),
          decoration: ShapeDecoration(
            // The same ground as a popover: a dialog floats above the page rather than being part
            // of it.
            color: colors.overlay,
            shadows: g.shadows.of(MochiElevation.lg, colors.shadow),
            shape: RoundedSuperellipseBorder(
              borderRadius: g.radius.lg,
              side: BorderSide(color: colors.border, width: g.borderWidth),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DefaultTextStyle(
                style: theme.typography.title.md.copyWith(color: colors.foreground),
                child: title,
              ),
              if (body case final body?) ...[
                SizedBox(height: g.space.xs),
                Flexible(
                  child: SingleChildScrollView(
                    child: DefaultTextStyle(
                      style: theme.typography.body.sm.copyWith(color: colors.mutedForeground),
                      child: body,
                    ),
                  ),
                ),
              ],
              if (actions.isNotEmpty) ...[
                SizedBox(height: g.space.lg),
                if (axis == Axis.horizontal)
                  Row(mainAxisAlignment: MainAxisAlignment.end, spacing: g.space.xs, children: actions)
                else
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: g.space.xs,
                    children: actions,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The route [showMochiDialog] pushes: a barrier plus a [MochiSurfaceTransition].
///
/// Exposed so a router can create one directly.
class MochiDialogRoute<T> extends PopupRoute<T> {
  MochiDialogRoute({
    required this.builder,
    this.barrierDismissible = true,
    this.barrierLabel = "Dismiss",
    this.transition = MochiTransition.scaleFade,
    super.settings,
  });

  final WidgetBuilder builder;
  final MochiTransition transition;

  @override
  final bool barrierDismissible;

  @override
  final String? barrierLabel;

  // Read from the navigator's context, the same way MochiPageRoute does: the navigator asks for
  // the durations and the barrier before the page is built.
  MochiTheme? get _theme => navigator?.context.getInheritedWidgetOfExactType<MochiThemeScope>()?.theme;

  MochiMotion get _motion => _theme?.motion ?? MochiMotion.standard;

  @override
  Color? get barrierColor {
    final shadow = _theme?.colors.shadow ?? const Color(0xFF000000);
    return shadow.withValues(alpha: shadow.a * 0.5);
  }

  @override
  Duration get transitionDuration => _motion.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _motion.transitionReverseDuration;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondary) {
    final g = context.theme.geometry;

    return Center(
      child: Padding(padding: EdgeInsets.all(g.space.lg), child: builder(context)),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => MochiSurfaceTransition(
    animation: animation,
    transition: transition,
    // The barrier does the dimming, over the whole screen rather than the dialog's own box.
    scrim: false,
    child: child,
  );
}

/// Shows [builder]'s widget, usually a [MochiDialog], over the page.
///
/// Returns what the dialog was popped with, or null when it was dismissed by the barrier or
/// Escape.
Future<T?> showMochiDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String barrierLabel = "Dismiss",
  bool useRootNavigator = true,
  RouteSettings? settings,
}) => Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
  MochiDialogRoute<T>(
    builder: builder,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    settings: settings,
  ),
);
