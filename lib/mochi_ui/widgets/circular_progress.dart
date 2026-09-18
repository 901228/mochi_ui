import "dart:math" as math;

import "package:flutter/widgets.dart";

import "../theme/motion.dart";
import "../theme/size.dart";
import "../theme/styles/progress_metrics.dart";
import "../theme/theme.dart";
import "value_transition.dart";

/// A ring spinner. Without [value] it spins indefinitely; with one it shows that fraction.
///
/// The color defaults to the surrounding [DefaultTextStyle], so a spinner inside a button or a
/// tile picks up that component's foreground.
class MochiCircularProgress extends StatefulWidget {
  const MochiCircularProgress({super.key, this.value, this.size = MochiSize.md, this.metrics, this.color});

  /// 0..1, or null for indeterminate.
  final double? value;

  /// `sm` matches the icon in a default button, for a spinner in its prefix.
  final MochiSize size;

  /// Overrides the metrics [size] would pick.
  final MochiProgressMetrics? metrics;

  final Color? color;

  @override
  State<MochiCircularProgress> createState() => _MochiCircularProgressState();
}

class _MochiCircularProgressState extends State<MochiCircularProgress> with SingleTickerProviderStateMixin {
  // Replaced by the theme's duration on the first build; repeat() in initState needs one already.
  late final _controller = AnimationController(
    vsync: this,
    duration: MochiMotion.standard.indeterminateDuration,
  );

  @override
  void initState() {
    super.initState();

    if (widget.value == null) _controller.repeat();
  }

  @override
  void didUpdateWidget(MochiCircularProgress old) {
    super.didUpdateWidget(old);

    switch ((widget.value, _controller.isAnimating)) {
      case (null, false):
        _controller.repeat();
      case (_?, true):
        _controller.stop();
      case _:
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    _controller.duration = theme.motion.indeterminateDuration;
    final target = widget.metrics ?? MochiProgressMetrics.of(widget.size, touch: theme.touch);
    final color = widget.color ?? DefaultTextStyle.of(context).style.color ?? theme.colors.foreground;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return MochiValueTransition(
      value: target,
      lerp: MochiProgressMetrics.lerp,
      duration: theme.motion.sizeDuration,
      curve: theme.motion.sizeCurve,
      builder: (context, m, _) => SizedBox.square(
        dimension: m.diameter,
        child: CustomPaint(
          painter: _RingPainter(
            // A stopped controller keeps a fixed arc, which is what reduced motion should show.
            spin: reduceMotion ? const AlwaysStoppedAnimation(0.0) : _controller,
            value: widget.value,
            color: color,
            strokeWidth: m.strokeWidth,
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.spin, required this.value, required this.color, required this.strokeWidth})
    : super(repaint: spin);

  final Animation<double> spin;
  final double? value;
  final Color color;
  final double strokeWidth;

  static const _sweepTurns = 0.5;
  static const _tau = math.pi * 2;
  static const _start = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final arc = (Offset.zero & size).deflate(strokeWidth / 2);

    canvas.drawArc(
      arc,
      _start,
      _tau,
      false,
      Paint()
        ..color = color.withValues(alpha: color.a * 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    final value = this.value;
    final (from, sweep) = value != null
        ? (_start, _tau * value.clamp(0.0, 1.0))
        // Constant arc, constant speed. Half a turn, like Bulma's loader.
        : (spin.value * _tau + _start, _tau * _sweepTurns);

    if (sweep <= 0) return;

    canvas.drawArc(
      arc,
      from,
      sweep,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.strokeWidth != strokeWidth;
}
