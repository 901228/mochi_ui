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

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;

    final motion = context.theme.motion;
    final curved = CurvedAnimation(
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
    final receding = CurvedAnimation(
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
        // Only while travelling, for the same reason as the dimming above.
        final moving = _travelling(animation);
        if (moving == 0) return child!;

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

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondary) =>
      builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => MochiSurfaceTransition(
    animation: animation,
    secondaryAnimation: secondaryAnimation,
    transition: transition ?? _defaults,
    child: child,
  );
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
  Route<T> createRoute(BuildContext context) =>
      MochiPageRoute<T>(builder: (_) => child, transition: transition, settings: this);
}
