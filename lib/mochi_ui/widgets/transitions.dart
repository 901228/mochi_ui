import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";

import "../theme/geometry.dart";
import "../theme/motion.dart";
import "../theme/theme.dart";

/// Applies the theme's entering and leaving motion to [child].
///
/// Pages and overlays share this, so a dialog, a popover and a pushed page move alike. Honors
/// [MediaQueryData.disableAnimations] by showing the finished state immediately.
class MochiSurfaceTransition extends StatelessWidget {
  const MochiSurfaceTransition({
    super.key,
    required this.animation,
    required this.child,
    this.secondaryAnimation,
    this.transition = MochiTransition.scaleFade,
    this.alignment = Alignment.center,
    this.slideFrom = AxisDirection.right,
    this.scaleFrom = 0.96,
    this.scrim = true,
    this.linear = false,
  });

  /// Runs 0 to 1 as the surface enters.
  final Animation<double> animation;

  /// Runs 0 to 1 as another surface covers this one. Without it a page sits perfectly still while
  /// the next one slides over it, which makes the movement hard to read.
  final Animation<double>? secondaryAnimation;
  final Widget child;
  final MochiTransition transition;

  /// Origin of the scale, so a popover can grow out of the control that opened it.
  final Alignment alignment;

  /// Edge a [MochiTransition.slide] surface comes from. Pages come in from the side; a sheet
  /// passes [AxisDirection.down] (or whichever edge it is anchored to).
  final AxisDirection slideFrom;
  final double scaleFrom;

  /// Whether the surface dims what it covers and casts a shadow while it travels.
  ///
  /// Pages need both: they are opaque and share a background colour, so without them the two
  /// just overlap. A floating surface (a popover, a menu) wants neither — it paints its own
  /// shadow the whole time, and the dimming of a modal belongs to the barrier behind it, which
  /// covers the screen rather than only the surface's own bounds.
  final bool scrim;

  /// Follows [animation] as it is rather than through the theme's curves, for while a finger is
  /// driving it: a curve between the finger and the page makes the page lag behind it and then
  /// catch up.
  final bool linear;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;

    final motion = context.theme.motion;
    final Animation<double> curved = linear
        ? animation
        : CurvedAnimation(
            parent: animation,
            curve: motion.transitionCurve,
            reverseCurve: motion.transitionReverseCurve,
          );

    final raised = scrim ? _EdgeShadow(animation: curved, edge: slideFrom, child: child) : child;

    final surface = switch (transition) {
      .fade => FadeTransition(opacity: curved, child: raised),
      .scaleFade => FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: scaleFrom, end: 1.0).animate(curved),
          alignment: alignment,
          child: raised,
        ),
      ),
      .slide => SlideTransition(
        position: Tween(begin: _edge, end: Offset.zero).animate(curved),
        child: raised,
      ),
    };

    // The dimming sits behind this surface and covers the whole area, rather than riding on the
    // surface below: that one slides and scales away, and anything it uncovers would stay bright.
    final entry = scrim
        ? Stack(
            fit: StackFit.passthrough,
            children: [
              Positioned.fill(
                child: IgnorePointer(child: _Dim(animation: curved)),
              ),
              surface,
            ],
          )
        : surface;

    final secondary = secondaryAnimation;
    if (secondary == null) return entry;

    // A covered surface gives way a little: it recedes, and a sliding one travels a quarter of the
    // way in the same direction. The covering surface brings its own dimming.
    final Animation<double> receding = linear
        ? secondary
        : CurvedAnimation(
            parent: secondary,
            curve: motion.transitionCurve,
            reverseCurve: motion.transitionReverseCurve,
          );

    return switch (transition) {
      .slide => SlideTransition(
        position: Tween(begin: Offset.zero, end: -_edge * 0.25).animate(receding),
        child: entry,
      ),
      .fade || .scaleFade => ScaleTransition(
        scale: Tween(begin: 1.0, end: 0.98).animate(receding),
        alignment: alignment,
        child: entry,
      ),
    };
  }

  Offset get _edge => switch (slideFrom) {
    AxisDirection.up => const Offset(0, -1),
    AxisDirection.down => const Offset(0, 1),
    AxisDirection.left => const Offset(-1, 0),
    AxisDirection.right => const Offset(1, 0),
  };
}

/// Fills its space with the theme's dimming while a transition runs, and with nothing at all
/// once it has settled: routes are transparent (the app paints the page background behind the
/// navigator), so anything left behind would tint the page.
class _Dim extends StatelessWidget {
  const _Dim({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final shadow = context.theme.colors.shadow;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final travelling = _travelling(animation);
        if (travelling == 0) return const SizedBox.shrink();

        return ColoredBox(color: shadow.withValues(alpha: shadow.a * 0.25 * travelling));
      },
    );
  }
}

/// How far along a transition is, or zero when it is not running.
double _travelling(Animation<double> animation) => switch (animation.status) {
  AnimationStatus.forward || AnimationStatus.reverse => animation.value,
  AnimationStatus.completed || AnimationStatus.dismissed => 0,
};

/// Casts the theme's largest shadow along the edge a sliding surface comes from.
class _EdgeShadow extends StatelessWidget {
  const _EdgeShadow({required this.animation, required this.edge, required this.child});

  final Animation<double> animation;
  final AxisDirection edge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final layers = theme.geometry.shadows.of(MochiElevation.lg, theme.colors.shadow);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Only while travelling, for the same reason as the dimming above. The box stays in the
        // tree at rest with no shadow in it: adding it when a transition starts would rebuild
        // everything under it, which loses a drag that is driving the transition.
        final moving = _travelling(animation);
        if (moving == 0) return DecoratedBox(decoration: const BoxDecoration(), child: child);

        return DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              for (final layer in layers)
                BoxShadow(
                  color: layer.color.withValues(alpha: layer.color.a * moving),
                  blurRadius: layer.blurRadius,
                  spreadRadius: layer.spreadRadius,
                  // Pushed away from the edge the surface travels from.
                  // A sliding surface is lit from the edge it came from; one that fades or scales in
                  // has no direction, so its shadow sits evenly around it.
                  offset: switch (edge) {
                    AxisDirection.up => Offset(0, layer.blurRadius / 2),
                    AxisDirection.down => Offset(0, -layer.blurRadius / 2),
                    AxisDirection.left => Offset(layer.blurRadius / 2, 0),
                    AxisDirection.right => Offset(-layer.blurRadius / 2, 0),
                  },
                ),
            ],
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}

/// A route that enters with [MochiSurfaceTransition] and takes its durations from the theme.
///
/// A page that slides in can be dragged back out by its leading edge, the way an iOS page can:
/// the drag drives the route's own animation, so the page underneath comes back with it. Letting
/// go past half way, or flicking, goes back; anything less settles the page where it was.
class MochiPageRoute<T> extends PageRoute<T> {
  MochiPageRoute({required this.builder, this.transition, super.settings, super.fullscreenDialog});

  final WidgetBuilder builder;

  /// Null takes `defaults.transition` from the navigator's theme.
  final MochiTransition? transition;

  // The navigator asks for the durations before buildPage runs, so they are read from the
  // navigator's own context. No dependency is registered: a route cannot change duration midway.
  MochiTheme? get _theme => navigator?.context.getInheritedWidgetOfExactType<MochiThemeScope>()?.theme;

  MochiMotion get _motion => _theme?.motion ?? MochiMotion.standard;

  MochiTransition get _defaults => _theme?.defaults.transition ?? MochiTransition.scaleFade;

  MochiTransition get _transition => transition ?? _defaults;

  /// Driven directly while the page is being dragged back.
  AnimationController? _controller;

  @override
  AnimationController createAnimationController() => _controller = super.createAnimationController();

  /// Whether a drag from the edge may start now. Not [popGestureEnabled], which also refuses a page
  /// with a [PopScope] that says no: here, as with a sheet's drag, the page follows the finger
  /// anyway and asks on release, so the scope hears about the attempt and the page settles back.
  bool get _canDragBack =>
      _transition == MochiTransition.slide &&
      isCurrent &&
      !isFirst &&
      !willHandlePopInternally &&
      animation!.isCompleted &&
      !(navigator?.userGestureInProgress ?? true);

  @override
  Duration get transitionDuration => _motion.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _motion.transitionReverseDuration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => true;

  /// Only a page that covers this one makes it give way. A see-through one on top — a dialog
  /// dressed as a page so a hero can fly into it — leaves this page in view, and moving it aside
  /// slid a scaffold's sidebar clean off the screen behind the dialog.
  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) => nextRoute is PageRoute && nextRoute.opaque;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondary) =>
      builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final transition = _transition;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return MochiSurfaceTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      transition: transition,
      // From the trailing edge, so a right-to-left page comes in from the left and goes back the
      // way it came.
      slideFrom: rtl ? AxisDirection.left : AxisDirection.right,
      // Rebuilt when a gesture starts and stops (the modal scope listens to the navigator for it),
      // which is also what keeps the page underneath, receding on this one's animation, in step.
      linear: navigator?.userGestureInProgress ?? false,
      child: transition == MochiTransition.slide ? _EdgeDrag(route: this, child: child) : child,
    );
  }

  /// Goes back if the route lets it, the same bargain as a sheet's drag: [PopScope] can refuse,
  /// and hears about the attempt either way. Returns whether the page is on its way out.
  bool _popByDrag() {
    if (popDisposition != RoutePopDisposition.pop) {
      navigator?.maybePop();
      return false;
    }
    navigator?.pop();
    return true;
  }
}

/// A strip along a page's leading edge that drags the page back to the one under it.
class _EdgeDrag extends StatefulWidget {
  const _EdgeDrag({required this.route, required this.child});

  final MochiPageRoute<dynamic> route;
  final Widget child;

  @override
  State<_EdgeDrag> createState() => _EdgeDragState();
}

class _EdgeDragState extends State<_EdgeDrag> {
  /// How far in from the edge a drag may start. Narrow, since anything under it — a slider, a
  /// list row's swipe — loses the start of its own drag there.
  static const _edgeWidth = 20.0;

  /// Over this speed towards the trailing edge, letting go goes back however little was dragged.
  static const _flingVelocity = 700.0;

  bool _dragging = false;

  NavigatorState? get _navigator => widget.route.navigator;
  AnimationController? get _controller => widget.route._controller;

  /// Positive when a drag moves the page back out: rightwards, or leftwards in right-to-left.
  double get _sign => Directionality.of(context) == TextDirection.rtl ? -1 : 1;

  @override
  void dispose() {
    if (_dragging) _navigator?.didStopUserGesture();
    super.dispose();
  }

  void _start(DragStartDetails details) {
    if (!widget.route._canDragBack) return;
    _dragging = true;
    _navigator?.didStartUserGesture();
  }

  void _update(DragUpdateDetails details) {
    final controller = _controller;
    final width = context.size?.width ?? 0;
    if (!_dragging || controller == null || width == 0) return;

    controller.value -= _sign * details.delta.dx / width;
  }

  void _end(DragEndDetails details) {
    final controller = _controller;
    if (!_dragging || controller == null) return;
    _dragging = false;

    final velocity = _sign * details.velocity.pixelsPerSecond.dx;
    final back = velocity > _flingVelocity || (velocity > -_flingVelocity && controller.value < 0.5);
    final leaving = back && widget.route._popByDrag();

    // Finished with the theme's curve from wherever the finger let go, over the share of the
    // duration that is left. The gesture ends only once the page has arrived: the transitions are
    // linear until then, and putting their curves back mid-flight would make the page jump.
    final motion = context.theme.motion;
    final navigator = _navigator;
    final TickerFuture done;
    if (leaving) {
      done = controller.animateBack(
        0,
        duration: motion.transitionReverseDuration * controller.value,
        curve: motion.transitionReverseCurve,
      );
    } else {
      done = controller.animateTo(
        1,
        duration: motion.transitionDuration * (1 - controller.value),
        curve: motion.transitionCurve,
      );
    }
    done.whenCompleteOrCancel(() => navigator?.didStopUserGesture());
  }

  void _cancel() {
    if (!_dragging) return;
    _end(DragEndDetails());
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Nothing to go back to: the edge is left to whatever else wants it, such as a scaffold's drawer,
    // which a strip that only refused the drag would still have beaten to it. The strip stays on the
    // tree either way, so the page keeps its state should the one under it come or go.
    final back = !widget.route.isFirst;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        PositionedDirectional(
          start: 0,
          top: 0,
          bottom: 0,
          // The system's own edge padding is added, so the strip starts where the page's content
          // does rather than under a notch.
          width: _edgeWidth + (rtl ? padding.right : padding.left),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            // A finger's gesture: a mouse has no edge to swipe from, and taking its presses
            // would steal the clicks on whatever sits along the page's edge.
            supportedDevices: const {
              PointerDeviceKind.touch,
              PointerDeviceKind.stylus,
              PointerDeviceKind.invertedStylus,
            },
            onHorizontalDragStart: back ? _start : null,
            onHorizontalDragUpdate: back ? _update : null,
            onHorizontalDragEnd: back ? _end : null,
            onHorizontalDragCancel: back ? _cancel : null,
          ),
        ),
      ],
    );
  }
}

/// The [Page] form of [MochiPageRoute], for routers such as go_router.
class MochiPage<T> extends Page<T> {
  const MochiPage({
    required this.child,
    this.transition,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;

  /// Null takes `defaults.transition` from the theme.
  final MochiTransition? transition;

  @override
  Route<T> createRoute(BuildContext context) => _PageBasedRoute<T>(this);
}

/// A [MochiPageRoute] that reads its page every time it builds rather than once when it is made.
///
/// A navigator keeps the route when a page with the same key replaces the old one, and only
/// swaps the route's [settings] for the new page: a route that had captured the first page's
/// child went on showing it however often the page was rebuilt — a router's shell never moved
/// off the tab it opened on.
class _PageBasedRoute<T> extends MochiPageRoute<T> {
  _PageBasedRoute(MochiPage<T> page) : super(builder: _unused, settings: page);

  /// Never called: [buildPage] reads the page instead.
  static Widget _unused(BuildContext _) => throw UnimplementedError();

  MochiPage<T> get _page => settings as MochiPage<T>;

  @override
  MochiTransition? get transition => _page.transition;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondary) =>
      _page.child;
}
