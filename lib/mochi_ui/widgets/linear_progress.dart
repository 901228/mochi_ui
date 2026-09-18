import "package:flutter/widgets.dart";

import "../theme/motion.dart";
import "../theme/size.dart";
import "../theme/styles/progress_metrics.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "value_transition.dart";

/// A progress bar. Without [value] an indeterminate bar slides across the track.
///
/// Fills the width it is given, so it needs a bounded parent.
class MochiLinearProgress extends StatefulWidget {
  const MochiLinearProgress({
    super.key,
    this.value,
    this.intent = MochiIntent.primary,
    this.size = MochiSize.md,
    this.metrics,
  });

  /// 0..1, or null for indeterminate.
  final double? value;
  final MochiIntent intent;
  final MochiSize size;

  /// Overrides the metrics [size] would pick.
  final MochiProgressMetrics? metrics;

  @override
  State<MochiLinearProgress> createState() => _MochiLinearProgressState();
}

class _MochiLinearProgressState extends State<MochiLinearProgress> with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(MochiLinearProgress old) {
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
    final tone = theme.colors.of(widget.intent);
    final target = widget.metrics ?? MochiProgressMetrics.of(widget.size, touch: theme.touch);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return MochiValueTransition(
      value: target,
      lerp: MochiProgressMetrics.lerp,
      duration: theme.motion.sizeDuration,
      curve: theme.motion.sizeCurve,
      builder: (context, m, _) => _track(theme, tone, m.thickness, reduceMotion),
    );
  }

  Widget _track(MochiTheme theme, MochiTone tone, double thickness, bool reduceMotion) {
    final radius = BorderRadius.all(Radius.circular(thickness));
    final value = widget.value;

    // Expands to the available width: under loose constraints the track would otherwise shrink
    // to the bar itself, leaving the indeterminate bar nowhere to slide.
    return ConstrainedBox(
      constraints: BoxConstraints.expand(height: thickness),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: tone.soft,
          shape: RoundedSuperellipseBorder(borderRadius: radius),
        ),
        child: ClipRSuperellipse(
          borderRadius: radius,
          child: value != null
              ? Align(
                  alignment: AlignmentDirectional.centerStart,
                  // The value itself is not theme-derived, so an implicit animation is safe here.
                  child: TweenAnimationBuilder(
                    tween: Tween(begin: 0.0, end: value.clamp(0.0, 1.0)),
                    duration: theme.motion.stateDuration * 2,
                    curve: Curves.easeOut,
                    builder: (context, fraction, _) =>
                        FractionallySizedBox(widthFactor: fraction, child: _bar(tone.base, radius)),
                  ),
                )
              : AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => FractionallySizedBox(
                    widthFactor: _indeterminateWidth,
                    // Travels until the bar is fully off both ends, so the wrap is out of sight.
                    alignment: Alignment(
                      reduceMotion ? 0 : _alignmentFor(_controller.value, _indeterminateWidth),
                      0,
                    ),
                    child: _bar(tone.base, radius),
                  ),
                ),
        ),
      ),
    );
  }

  static const _indeterminateWidth = 0.4;

  /// Alignment that puts the bar exactly one track past each edge, so the wrap is off-screen:
  /// solving `(1 + x) / 2 * (1 - width) == 1`.
  static double _alignmentFor(double t, double width) => (t * 2 - 1) * (2 / (1 - width) - 1);

  // Rounded on both ends: the track's clip alone would leave the bar's own ends square.
  Widget _bar(Color color, BorderRadius radius) => DecoratedBox(
    decoration: ShapeDecoration(
      color: color,
      shape: RoundedSuperellipseBorder(borderRadius: radius),
    ),
    child: const SizedBox.expand(),
  );
}
