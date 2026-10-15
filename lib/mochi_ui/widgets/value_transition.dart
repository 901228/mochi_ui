import "package:flutter/widgets.dart";

/// Animates between two values of [T] whenever [value] changes, and rebuilds with the current
/// blend on every build.
///
/// Sizes derived from the theme (`touch` switching to a denser desktop scale, say) would
/// otherwise jump. An implicit `Animated*` widget cannot do this job: its target is recomputed
/// on every frame of a theme animation, which restarts it each time. This one only restarts when
/// [value] itself changes.
class MochiValueTransition<T> extends StatefulWidget {
  const MochiValueTransition({
    super.key,
    required this.value,
    required this.lerp,
    required this.duration,
    required this.builder,
    this.curve = Curves.easeOut,
    this.initial,
    this.child,
  });

  final T value;
  final T Function(T a, T b, double t) lerp;
  final Duration duration;
  final Curve curve;

  final Widget Function(BuildContext context, T value, Widget? child) builder;

  /// When given, the first build starts from here and eases to [value] instead of settling on it.
  final T? initial;

  /// Passed through untouched, for subtrees that do not depend on [value].
  final Widget? child;

  @override
  State<MochiValueTransition<T>> createState() => _MochiValueTransitionState<T>();
}

class _MochiValueTransitionState<T> extends State<MochiValueTransition<T>>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.initial == null || widget.initial == widget.value ? 1 : 0,
  );

  late T _from = widget.initial ?? widget.value;
  late T _to = widget.value;

  @override
  void initState() {
    super.initState();
    if (_controller.value < 1) _controller.forward();
  }

  @override
  void didUpdateWidget(MochiValueTransition<T> old) {
    super.didUpdateWidget(old);

    _controller.duration = widget.duration;
    if (widget.value == _to) return;

    // Start from where the animation currently is, so a change mid-flight does not snap.
    _from = _blend;
    _to = widget.value;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  T get _blend {
    final t = widget.curve.transform(_controller.value);
    return t >= 1 ? _to : widget.lerp(_from, _to, t);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return widget.builder(context, widget.value, widget.child);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => widget.builder(context, _blend, child),
      child: widget.child,
    );
  }
}
