import "package:flutter/scheduler.dart";
import "package:flutter/widgets.dart";

import "../theme/theme.dart";

/// How a skeleton says it is waiting.
enum MochiSkeletonEffect {
  /// A highlight travelling across the block. Reads as something on its way.
  shimmer,

  /// The whole block fading in and out. Quieter, and cheaper on a page full of them.
  pulse,

  /// Nothing moves. What [MediaQuery.disableAnimations] leaves.
  none,
}

/// The shape of what is still loading: a block where a picture will be, a few bars where a
/// paragraph will be.
///
/// A skeleton is only worth it when it stands where the real thing will stand, at its size — a
/// block of a different size is a second layout the page flicks through on its way to the first.
///
/// Every skeleton on a page moves in step: the cycle is taken from the clock rather than from
/// when this one happened to be built, so a list of rows waiting together doesn't shimmer in a
/// dozen different phases.
///
/// ```dart
/// const MochiSkeleton(width: 120, height: 120)
/// const MochiSkeleton.text(lines: 3)
/// ```
class MochiSkeleton extends StatefulWidget {
  /// A block, sized by what it is standing in for. A null width fills what it is given.
  const MochiSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius,
    this.effect = MochiSkeletonEffect.shimmer,
  }) : _lines = 0,
       _round = false,
       _lineStyle = null;

  /// A round one: an avatar, a dot.
  const MochiSkeleton.circle({super.key, required double size, this.effect = MochiSkeletonEffect.shimmer})
    : width = size,
      height = size,
      radius = null,
      _lines = 0,
      _round = true,
      _lineStyle = null;

  /// Bars where lines of text will be, the last one short the way a last line is.
  const MochiSkeleton.text({
    super.key,
    int lines = 3,
    this.width,
    TextStyle? style,
    this.radius,
    this.effect = MochiSkeletonEffect.shimmer,
  }) : assert(lines > 0),
       _lines = lines,
       _lineStyle = style,
       height = 0,
       _round = false;

  final double? width;
  final double height;

  /// Defaults to `radius.sm`, or a circle for [MochiSkeleton.circle].
  final BorderRadius? radius;

  final MochiSkeletonEffect effect;

  final int _lines;
  final bool _round;

  /// What the bars are standing in for. Defaults to `typography.body.md`.
  final TextStyle? _lineStyle;

  @override
  State<MochiSkeleton> createState() => _MochiSkeletonState();
}

class _MochiSkeletonState extends State<MochiSkeleton> with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  static double _phaseOf(Duration period) {
    final now = SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds;
    return (now % period.inMicroseconds) / period.inMicroseconds;
  }

  /// The last line of a paragraph is a part of one.
  static const _lastLineFactor = 0.6;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final theme = context.theme;
    final moving = widget.effect != MochiSkeletonEffect.none && !MediaQuery.disableAnimationsOf(context);
    if (!moving) {
      _controller?.dispose();
      _controller = null;
      return;
    }

    final period = theme.motion.indeterminateDuration;
    if (_controller?.duration == period) return;

    _controller?.dispose();
    _controller = AnimationController(vsync: this, duration: period)
      // From the clock the frames come off, not from zero: two skeletons built a frame apart
      // should still be at the same point in the cycle, or a column of them waiting for the same
      // thing reads as noise rather than as one wait. The scheduler's timestamp rather than
      // DateTime.now(), so it follows time in a test the way everything else does.
      ..value = _phaseOf(period)
      ..repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;

    if (widget._lines > 0) {
      final style = widget._lineStyle ?? theme.typography.body.md;
      final height = style.fontSize ?? 16;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: g.space.xs,
        children: [
          for (var line = 0; line < widget._lines; line++)
            if (line == widget._lines - 1 && widget._lines > 1)
              FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: _lastLineFactor,
                child: _bar(height),
              )
            else
              _bar(height),
        ],
      );
    }

    return _bar(widget.height, width: widget.width ?? double.infinity, round: widget._round);
  }

  Widget _bar(double height, {double? width, bool round = false}) => _SkeletonBox(
    // A bar with no width of its own fills the line, the way the text it stands in for would;
    // like a divider, that needs a parent with a width to fill.
    width: width ?? widget.width ?? double.infinity,
    height: height,
    round: round,
    radius: widget.radius,
    effect: widget.effect,
    animation: _controller,
  );
}

/// One block, repainted per tick without rebuilding anything above it.
class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.round,
    required this.radius,
    required this.effect,
    required this.animation,
  });

  final double? width;
  final double height;
  final bool round;
  final BorderRadius? radius;
  final MochiSkeletonEffect effect;
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final shape = round
        ? const CircleBorder()
        : theme.geometry.shape(borderRadius: radius ?? theme.geometry.radius.sm);

    // Between the page and its lines: a fill that reads as "something belongs here", not as a
    // filled-in answer.
    final fill = Color.lerp(colors.surface, colors.border, 0.7)!;
    final highlight = Color.lerp(fill, colors.surface, 0.8)!;

    final box = SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: ShapeDecoration(color: fill, shape: shape),
      ),
    );

    final animation = this.animation;
    if (animation == null) return box;

    return switch (effect) {
      MochiSkeletonEffect.none => box,
      MochiSkeletonEffect.pulse => FadeTransition(
        // Never all the way out: a block that disappears is a layout that flickers.
        opacity: animation.drive(
          Tween(begin: 1.0, end: 0.45).chain(CurveTween(curve: Curves.easeInOut)).chain(_backAndForth),
        ),
        child: box,
      ),
      MochiSkeletonEffect.shimmer => AnimatedBuilder(
        animation: animation,
        // The box is built once and only its shader moves.
        child: box,
        builder: (context, child) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [fill, highlight, fill],
            stops: const [0.0, 0.5, 1.0],
            // Starts and ends off the block, so the highlight enters and leaves rather than
            // appearing in the middle of it.
            transform: _SlideGradient(animation.value * 3 - 1.5),
          ).createShader(bounds),
          child: child,
        ),
      ),
    };
  }

  /// 0 → 1 → 0, so a pulse breathes instead of snapping back at the end of every cycle.
  static final _backAndForth = Animatable<double>.fromCallback((t) => t < 0.5 ? t * 2 : (1 - t) * 2);
}

/// Moves a gradient along its own axis by a fraction of the box it fills.
class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.fraction);

  final double fraction;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * fraction, 0, 0);
}
