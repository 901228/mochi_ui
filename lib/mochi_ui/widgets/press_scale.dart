import "dart:async";
import "dart:math" as math;

import "package:flutter/foundation.dart";
import "package:flutter/physics.dart";
import "package:flutter/rendering.dart";
import "package:flutter/widgets.dart";

import "../theme/motion.dart";
import "../theme/theme.dart";

/// Grows [child] while [states] contains [WidgetState.pressed], iOS style, using the
/// springs and limits from [MochiMotion]. Respects [MediaQueryData.disableAnimations].
class MochiPressScale extends StatefulWidget {
  const MochiPressScale({super.key, required this.states, required this.child});

  final ValueListenable<Set<WidgetState>> states;
  final Widget child;

  @override
  State<MochiPressScale> createState() => _MochiPressScaleState();
}

class _MochiPressScaleState extends State<MochiPressScale> with SingleTickerProviderStateMixin {
  // Unbounded: the release spring overshoots below 0 (a slight shrink) before settling.
  late final _progress = AnimationController.unbounded(vsync: this);

  // Quick taps report down and up in the same frame; keep the press visible at least this long.
  static const _minPress = Duration(milliseconds: 90);

  late MochiMotion _motion;
  bool _reduceMotion = false;
  bool _pressed = false;
  final _pressWatch = Stopwatch();
  Timer? _releaseTimer;

  @override
  void initState() {
    super.initState();

    widget.states.addListener(_handleStates);
  }

  @override
  void didUpdateWidget(MochiPressScale old) {
    super.didUpdateWidget(old);

    if (widget.states != old.states) {
      old.states.removeListener(_handleStates);
      widget.states.addListener(_handleStates);
      _handleStates();
    }
  }

  @override
  void dispose() {
    widget.states.removeListener(_handleStates);
    _releaseTimer?.cancel();
    _progress.dispose();

    super.dispose();
  }

  void _handleStates() {
    final pressed = widget.states.value.contains(WidgetState.pressed);
    if (pressed == _pressed) return;
    _pressed = pressed;

    _releaseTimer?.cancel();
    if (_reduceMotion) {
      _progress.value = 0;
      return;
    }
    if (pressed) {
      _pressWatch
        ..reset()
        ..start();
      _spring(_motion.pressSpring, 1);
    } else {
      final remaining = _minPress - _pressWatch.elapsed;
      if (remaining > Duration.zero) {
        _releaseTimer = Timer(remaining, () => _spring(_motion.releaseSpring, 0));
      } else {
        _spring(_motion.releaseSpring, 0);
      }
    }
  }

  void _spring(SpringDescription spring, double target) {
    if (!mounted) return;
    // Springs stop within a tolerance of the target; snap to it so a resting surface has an
    // exact scale of 1 and drops its transform layer.
    _progress.animateWith(SpringSimulation(spring, _progress.value, target, _progress.velocity)).then((_) {
      if (mounted) _progress.value = target;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tappables may be used outside MochiApp; fall back to the default motion.
    _motion =
        context.dependOnInheritedWidgetOfExactType<MochiThemeScope>()?.theme.motion ?? MochiMotion.standard;
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return _PressScale(
      progress: _progress,
      maxScale: _motion.pressScale,
      maxGrowth: _motion.pressMaxGrowth,
      child: widget.child,
    );
  }
}

// Repaints on every tick without rebuilding or relaying out the child.
class _PressScale extends SingleChildRenderObjectWidget {
  const _PressScale({required this.progress, required this.maxScale, required this.maxGrowth, super.child});

  final Animation<double> progress;
  final double maxScale;
  final double maxGrowth;

  @override
  _RenderPressScale createRenderObject(BuildContext context) =>
      _RenderPressScale(progress: progress, maxScale: maxScale, maxGrowth: maxGrowth);

  @override
  void updateRenderObject(BuildContext context, _RenderPressScale renderObject) {
    renderObject
      ..progress = progress
      ..maxScale = maxScale
      ..maxGrowth = maxGrowth;
  }
}

class _RenderPressScale extends RenderProxyBox {
  _RenderPressScale({required this._progress, required this._maxScale, required this._maxGrowth});

  Animation<double> _progress;
  set progress(Animation<double> value) {
    if (value == _progress) return;
    if (attached) _progress.removeListener(markNeedsPaint);
    _progress = value;
    if (attached) _progress.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  double _maxScale;
  set maxScale(double value) {
    if (value == _maxScale) return;
    _maxScale = value;
    markNeedsPaint();
  }

  double _maxGrowth;
  set maxGrowth(double value) {
    if (value == _maxGrowth) return;
    _maxGrowth = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _progress.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _progress.removeListener(markNeedsPaint);
    super.detach();
  }

  double get _scale {
    if (!hasSize || size.isEmpty) return 1;
    final growth = math.min(_maxScale - 1, 2 * _maxGrowth / size.longestSide);
    return 1 + growth * _progress.value;
  }

  Matrix4 get _transform {
    final s = _scale;
    final center = size.center(Offset.zero);
    return Matrix4.diagonal3Values(s, s, 1)..setTranslationRaw(center.dx * (1 - s), center.dy * (1 - s), 0);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    if (_scale == 1) {
      layer = null;
      super.paint(context, offset);
      return;
    }
    layer = context.pushTransform(
      needsCompositing,
      offset,
      _transform,
      super.paint,
      oldLayer: layer is TransformLayer ? layer! as TransformLayer : null,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) => result.addWithPaintTransform(
    transform: _transform,
    position: position,
    hitTest: (result, position) => super.hitTestChildren(result, position: position),
  );

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) => transform.multiply(_transform);
}
