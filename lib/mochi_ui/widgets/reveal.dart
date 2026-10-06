import "package:flutter/widgets.dart";

import "../theme/theme.dart";

/// Shows and hides its [child] by growing it open and folding it shut, with nothing to press.
///
/// The body of a [MochiCollapsible] without the header, for when what opens it is somewhere
/// else — a switch that turns on a group of settings, a choice that brings its own options with
/// it. The app owns [expanded]; this only moves between the two. It opens the way a collapsible
/// does, over `motion.sizeDuration` along `motion.sizeCurve`, since a size that nothing is
/// dragging wants to ease at both ends.
///
/// ```dart
/// MochiSwitch(value: advanced, onChanged: (v) => setState(() => advanced = v)),
/// MochiReveal(expanded: advanced, child: const AdvancedOptions()),
/// ```
class MochiReveal extends StatefulWidget {
  const MochiReveal({super.key, required this.expanded, this.maintainState = false, required this.child});

  final bool expanded;

  /// Keep the child built while it is hidden, so its state (a scroll position, a half-filled
  /// field) survives. Off by default: a hidden child costs nothing.
  final bool maintainState;

  final Widget child;

  @override
  State<MochiReveal> createState() => _MochiRevealState();
}

class _MochiRevealState extends State<MochiReveal> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, value: widget.expanded ? 1 : 0);
  // The curve is set from the theme on every build.
  late final _progress = CurvedAnimation(parent: _controller, curve: Curves.linear);

  @override
  void didUpdateWidget(MochiReveal old) {
    super.didUpdateWidget(old);

    if (widget.expanded == old.expanded) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = widget.expanded ? 1 : 0;
    } else if (widget.expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = context.theme.motion;
    _controller.duration = motion.sizeDuration;
    _progress.curve = motion.sizeCurve;

    return RevealBody(
      progress: _progress,
      open: widget.expanded,
      maintainState: widget.maintainState,
      child: widget.child,
    );
  }
}

/// The growing and folding itself, driven by an animation someone else owns — a collapsible's,
/// which turns its chevron and rounds its header off the same one. Not exported.
class RevealBody extends StatelessWidget {
  const RevealBody({
    super.key,
    required this.progress,
    required this.open,
    required this.maintainState,
    required this.child,
  });

  /// 0 hidden, 1 shown.
  final Animation<double> progress;

  /// Where it is headed, which is not the same as [progress] while it moves: a closing child is
  /// still on screen but can no longer be reached with Tab.
  final bool open;

  final bool maintainState;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, body) {
        final t = progress.value;
        final closed = t == 0 && !open;
        if (closed && !maintainState) return const SizedBox.shrink();
        // The same tree open or closed, so a kept child's state survives.
        return Offstage(
          offstage: closed,
          // Align rather than SizeTransition, which would also clip the child's own shadows and
          // focus rings sideways; the ClipRect only needs to cut along the axis that grows.
          child: ClipRect(
            // Open, nothing is clipped: a raised group's shadow reaches past its box on every
            // side, and a clip at the box's edge cut it off. Moving, only the growing axis is cut,
            // with room sideways. Same widget either way, so the child keeps its state.
            clipper: const _AlongHeight(),
            clipBehavior: t == 1 ? Clip.none : Clip.hardEdge,
            child: Align(
              alignment: AlignmentDirectional.topStart,
              heightFactor: t,
              child: Opacity(opacity: t, child: body),
            ),
          ),
        );
      },
      child: ExcludeFocus(excluding: !open, child: child),
    );
  }
}

/// Cuts along the height only: the width gets room for a shadow to spill into.
class _AlongHeight extends CustomClipper<Rect> {
  const _AlongHeight();

  static const _room = 64.0;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(-_room, 0, size.width + _room, size.height);

  @override
  bool shouldReclip(_AlongHeight oldClipper) => false;
}
