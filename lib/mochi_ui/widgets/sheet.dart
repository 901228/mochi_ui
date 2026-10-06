import "package:flutter/widgets.dart";

import "../theme/geometry.dart";
import "../theme/motion.dart";
import "../theme/strings.dart";
import "../theme/theme.dart";
import "modal_heading.dart";
import "transitions.dart";

/// The edge a sheet is anchored to and slides in from.
enum MochiSheetSide { left, right, top, bottom }

/// A panel anchored to an edge of the screen: a menu, a picker, a form too big for a dialog.
///
/// Show it with [showMochiSheet], which supplies the barrier, the motion and the drag.
class MochiSheet extends StatelessWidget {
  const MochiSheet({
    super.key,
    required this.child,
    this.title,
    this.titleSuffix,
    this.side = MochiSheetSide.bottom,
    this.handle,
    this.constraints,
    this.padding,
    this.semanticLabel,
  });

  final Widget child;

  /// The heading over [child], drawn exactly as a [MochiDialog]'s: the same typeface, size and
  /// gap. It stays put while [child] scrolls, which is what a long sheet wants.
  final Widget? title;

  /// At the end of the title's line: a close button, or an action that belongs to the sheet
  /// rather than to an answer. See [MochiDialog.titleSuffix].
  final Widget? titleSuffix;

  final MochiSheetSide side;

  /// The grab bar on a sheet that can be dragged away. Defaults to on for a sheet from the top or
  /// bottom at the touch scale, where dragging is how it is usually dismissed.
  final bool? handle;

  /// Defaults to half the screen along the sheet's own axis, and all of it across.
  final BoxConstraints? constraints;

  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;

  bool get _vertical => side == MochiSheetSide.top || side == MochiSheetSide.bottom;

  /// Rounded on the edges that face into the screen; the anchored edge runs off it.
  BorderRadius _radius(MochiGeometry g) {
    final r = g.radius.xl.topLeft;

    return switch (side) {
      MochiSheetSide.bottom => BorderRadius.only(topLeft: r, topRight: r),
      MochiSheetSide.top => BorderRadius.only(bottomLeft: r, bottomRight: r),
      MochiSheetSide.left => BorderRadius.only(topRight: r, bottomRight: r),
      MochiSheetSide.right => BorderRadius.only(topLeft: r, bottomLeft: r),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;
    final view = MediaQuery.sizeOf(context);
    final showHandle = handle ?? (_vertical && theme.touch);

    // As tall as its content needs, up to nine tenths of the screen: the cap only bites when the
    // content is taller than it, so raising it never makes a short sheet taller — it only decides
    // whether a tall one is scrolled through or simply shown. What the last tenth is for is the
    // strip of page behind, which is what says this is a sheet and where to press to be rid of
    // it. A side sheet keeps to half the width, since one covering the screen is a page.
    final limits =
        constraints ??
        BoxConstraints(
          maxWidth: _vertical ? double.infinity : view.width / 2,
          maxHeight: _vertical ? view.height * 0.9 : double.infinity,
        );

    final raised = theme.layering == .raised;

    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      namesRoute: true,
      label: semanticLabel,
      child: ConstrainedBox(
        constraints: limits,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: colors.overlay,
            shadows: raised
                ? g.shadows.raised(MochiElevation.lg, colors)
                : g.shadows.of(MochiElevation.lg, colors.shadow),
            shape: RoundedSuperellipseBorder(
              borderRadius: _radius(g),
              side: BorderSide(
                color: raised ? colors.overlay.withValues(alpha: 0) : colors.border,
                width: g.borderWidth,
              ),
            ),
          ),
          child: ClipRSuperellipse(
            borderRadius: _radius(g),
            child: Column(
              // A sheet from an edge fills the screen across its own axis and is only as big as
              // its content along it: the column shrink-wraps a bottom sheet's height, and runs
              // the whole height for one from the side.
              mainAxisSize: _vertical ? MainAxisSize.min : MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // On the edge that faces into the screen, which is the one you drag from: the
                // bottom of a sheet that came down from the top.
                if (showHandle && side != MochiSheetSide.top) const _SheetHandle(),
                Flexible(
                  child: Padding(
                    // The sheet runs to the edge of the screen, so its own padding has to clear
                    // whatever the system puts there.
                    padding: (padding ?? EdgeInsets.all(g.space.md)).add(_safeArea(context)),
                    child: title == null && titleSuffix == null
                        ? child
                        : Column(
                            mainAxisSize: _vertical ? MainAxisSize.min : MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ModalHeading(title: title, suffix: titleSuffix),
                              SizedBox(height: ModalHeading.gapOf(context)),
                              Flexible(child: child),
                            ],
                          ),
                  ),
                ),
                if (showHandle && side == MochiSheetSide.top) const _SheetHandle(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Only the edges the sheet actually touches: the anchored edge is off screen, and the opposite
  /// one is covered by the sheet's own rounded corner.
  EdgeInsets _safeArea(BuildContext context) {
    final p = MediaQuery.paddingOf(context);

    return switch (side) {
      MochiSheetSide.bottom => EdgeInsets.only(left: p.left, right: p.right, bottom: p.bottom),
      MochiSheetSide.top => EdgeInsets.only(left: p.left, right: p.right, top: p.top),
      MochiSheetSide.left => EdgeInsets.only(left: p.left, top: p.top, bottom: p.bottom),
      MochiSheetSide.right => EdgeInsets.only(right: p.right, top: p.top, bottom: p.bottom),
    };
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.geometry.space.xs),
      child: Center(
        child: SizedBox(
          width: 36,
          height: 4,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: theme.colors.border,
              shape: RoundedSuperellipseBorder(borderRadius: theme.geometry.radius.full),
            ),
          ),
        ),
      ),
    );
  }
}

/// The route [showMochiSheet] pushes.
///
/// Exposed so a router can create one directly.
class MochiSheetRoute<T> extends PopupRoute<T> {
  MochiSheetRoute({
    required this.builder,
    this.side = MochiSheetSide.bottom,
    this.barrierDismissible = true,
    this._barrierLabel,
    this.dragToDismiss = true,
    super.settings,
  });

  final WidgetBuilder builder;
  final MochiSheetSide side;

  /// Whether dragging the sheet towards its edge dismisses it.
  final bool dragToDismiss;

  @override
  final bool barrierDismissible;

  /// Defaults to [MochiStrings.dismiss].
  @override
  String get barrierLabel => _barrierLabel ?? (_theme?.strings ?? MochiStrings.standard).dismiss;
  final String? _barrierLabel;

  /// Driven directly while the sheet is being dragged, so the barrier fades with it.
  AnimationController? _controller;

  // Read from the navigator's context, as MochiPageRoute does: the durations and the barrier are
  // asked for before the page is built.
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
  AnimationController createAnimationController() => _controller = super.createAnimationController();

  Alignment get _alignment => switch (side) {
    MochiSheetSide.bottom => Alignment.bottomCenter,
    MochiSheetSide.top => Alignment.topCenter,
    MochiSheetSide.left => Alignment.centerLeft,
    MochiSheetSide.right => Alignment.centerRight,
  };

  AxisDirection get _from => switch (side) {
    MochiSheetSide.bottom => AxisDirection.down,
    MochiSheetSide.top => AxisDirection.up,
    MochiSheetSide.left => AxisDirection.left,
    MochiSheetSide.right => AxisDirection.right,
  };

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondary) {
    final sheet = builder(context);

    // The sheet alone, with no full-screen wrapper: the transition below slides its child by a
    // fraction of that child's own size, and the drag measures it the same way, so both have to
    // see the sheet rather than a box the size of the screen.
    return dragToDismiss
        ? _SheetDrag(side: side, controller: _controller, onDismiss: _dismissByDrag, child: sheet)
        : sheet;
  }

  /// Goes through [NavigatorState.maybePop], so a [PopScope] inside the sheet can refuse the drag
  /// the same way it refuses the barrier or the back button — and hears about it either way,
  /// which is how an app asks "discard this?" before the sheet goes. Returns whether the sheet is
  /// on its way out, so a refused drag can settle back where it came from.
  ///
  /// Only [RoutePopDisposition.pop] counts as going: `doNotPop` is a refusal, and `bubble` hands
  /// the gesture to the platform without this route closing, so both leave the sheet standing.
  bool _dismissByDrag() {
    final leaving = popDisposition == RoutePopDisposition.pop;
    navigator?.maybePop();

    return leaving;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => Padding(
    // The keyboard takes the bottom of the screen, so the sheet stands on top of it rather than
    // under it: without this a bottom sheet with a field in it is entirely behind the keys, and
    // the cap on its height is measured against room it does not have.
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Align(
      alignment: _alignment,
      child: MochiSurfaceTransition(
        animation: animation,
        transition: MochiTransition.slide,
        slideFrom: _from,
        // The barrier dims the screen; the sheet brings its own shadow.
        scrim: false,
        child: child,
      ),
    ),
  );
}

/// Turns a drag towards the sheet's edge into the route's animation running backwards, so the
/// sheet follows the finger and the barrier fades with it.
class _SheetDrag extends StatefulWidget {
  const _SheetDrag({
    required this.side,
    required this.controller,
    required this.onDismiss,
    required this.child,
  });

  final MochiSheetSide side;
  final AnimationController? controller;

  /// Returns false when the route refuses to close, and the sheet settles back.
  final bool Function() onDismiss;
  final Widget child;

  @override
  State<_SheetDrag> createState() => _SheetDragState();
}

class _SheetDragState extends State<_SheetDrag> {
  /// Past this much of the sheet, or over this speed towards the edge, letting go dismisses it
  /// instead of settling it back.
  static const _closeBelow = 0.5;
  static const _flingVelocity = 700.0;

  /// However short the sheet is, it takes this much travel to dismiss it: half of a sheet only a
  /// hundred pixels tall is a twitch, and there would be no way to change your mind. The gesture
  /// itself is longer by the touch slop the recognizer eats before the first update arrives.
  static const _minTravel = 48.0;

  final _key = GlobalKey();
  bool get _vertical => widget.side == MochiSheetSide.top || widget.side == MochiSheetSide.bottom;

  /// Positive when the drag moves the sheet off screen.
  double get _sign => switch (widget.side) {
    MochiSheetSide.bottom || MochiSheetSide.right => 1,
    MochiSheetSide.top || MochiSheetSide.left => -1,
  };

  double get _extent {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return 0;
    return _vertical ? box.size.height : box.size.width;
  }

  void _update(DragUpdateDetails details) {
    final controller = widget.controller;
    final extent = _extent;
    if (controller == null || extent == 0 || controller.status == AnimationStatus.reverse) return;

    final delta = _vertical ? details.primaryDelta ?? 0 : details.delta.dx;
    controller.value -= _sign * delta / extent;
  }

  void _end(DragEndDetails details) {
    final controller = widget.controller;
    if (controller == null || controller.status == AnimationStatus.reverse) return;

    final velocity = _vertical ? details.velocity.pixelsPerSecond.dy : details.velocity.pixelsPerSecond.dx;

    final travelled = (1 - controller.value) * _extent;
    final dragged = controller.value < _closeBelow && travelled >= _minTravel;

    if ((_sign * velocity > _flingVelocity || dragged) && widget.onDismiss()) return;
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final child = KeyedSubtree(key: _key, child: widget.child);

    // Registered above the sheet's content, so a scroll view or a slider inside it wins the arena.
    return _vertical
        ? GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragUpdate: _update,
            onVerticalDragEnd: _end,
            child: child,
          )
        : GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: _update,
            onHorizontalDragEnd: _end,
            child: child,
          );
  }
}

/// Shows [builder]'s widget, usually a [MochiSheet], anchored to [side].
///
/// Returns what the sheet was popped with, or null when it was dismissed by the barrier, Escape
/// or a drag.
Future<T?> showMochiSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  MochiSheetSide side = MochiSheetSide.bottom,
  bool barrierDismissible = true,
  String? barrierLabel,
  bool dragToDismiss = true,
  bool useRootNavigator = true,
  RouteSettings? settings,
}) => Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
  MochiSheetRoute<T>(
    builder: builder,
    side: side,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    dragToDismiss: dragToDismiss,
    settings: settings,
  ),
);
