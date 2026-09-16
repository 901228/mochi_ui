import "dart:ui" show lerpDouble;

import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";

/// A snapshot of an in-progress transition between two interaction state sets.
///
/// Values are resolved against the current theme on every build, so a theme change
/// is picked up immediately without restarting the state animation.
@immutable
class MochiStateBlend {
  const MochiStateBlend(this.from, this.to, this.t);

  final Set<WidgetState> from;
  final Set<WidgetState> to;
  final double t;

  bool contains(WidgetState state) => to.contains(state);

  Color color(Color Function(Set<WidgetState> states) resolve) =>
      t >= 1 ? resolve(to) : Color.lerp(resolve(from), resolve(to), t)!;

  double number(double Function(Set<WidgetState> states) resolve) =>
      t >= 1 ? resolve(to) : lerpDouble(resolve(from), resolve(to), t)!;
}

/// Animates only when [states] change; rebuilds from a parent never restart the animation.
class MochiStateTransition extends StatefulWidget {
  const MochiStateTransition({
    super.key,
    required this.states,
    required this.duration,
    this.curve = Curves.easeOut,
    required this.builder,
  });

  final Set<WidgetState> states;
  final Duration duration;
  final Curve curve;
  final Widget Function(BuildContext context, MochiStateBlend blend) builder;

  @override
  State<MochiStateTransition> createState() => _MochiStateTransitionState();
}

class _MochiStateTransitionState extends State<MochiStateTransition> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: widget.duration, value: 1);

  // Copies: WidgetStatesController mutates its set in place.
  late Set<WidgetState> _from = {...widget.states};
  late Set<WidgetState> _to = {...widget.states};

  @override
  void didUpdateWidget(MochiStateTransition old) {
    super.didUpdateWidget(old);

    _controller.duration = widget.duration;
    if (!setEquals(widget.states, _to)) {
      _from = _to;
      _to = {...widget.states};
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) =>
          widget.builder(context, MochiStateBlend(_from, _to, widget.curve.transform(_controller.value))),
    );
  }
}
