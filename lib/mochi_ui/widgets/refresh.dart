import "dart:math" as math;

import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";

import "../theme/geometry.dart";
import "../theme/size.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "circular_progress.dart";

/// Where a pull-to-refresh is in its errand.
enum _Phase { idle, pulling, refreshing, settling }

/// Pull the top of a list down to ask for it again.
///
/// Wraps a scrollable and watches its overscroll: nothing about the list itself changes, and the
/// indicator is the kit's own [MochiCircularProgress] rather than a second spinner — determinate
/// while the finger is deciding (the ring is how far there is left to pull) and indeterminate
/// once the errand is running and the answer is out of the user's hands.
///
/// It is deliberately not part of the toaster. A toast is time-driven, floats above the
/// navigator and has nothing to do with scrolling; a refresh is gesture-driven, belongs to one
/// scrollable and is paced by a finger.
///
/// ```dart
/// MochiRefresh(
///   onRefresh: () => context.read<Sessions>().reload(),
///   child: ListView(children: [...]),
/// )
/// ```
class MochiRefresh extends StatefulWidget {
  const MochiRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.triggerDistance = 88,
    this.intent = MochiIntent.primary,
    this.enabled = true,
    this.mouseDrags = true,
  }) : assert(triggerDistance > 0);

  /// Run when the pull is let go past [triggerDistance]. The indicator turns and the list is held
  /// down until this completes, so it should be the whole errand rather than the start of one.
  final Future<void> Function() onRefresh;

  final Widget child;

  /// How far the list has to be pulled for letting go to mean something.
  final double triggerDistance;

  final MochiIntent intent;
  final bool enabled;

  /// Whether a mouse may drag the list, and so pull it. On a desktop platform a scrollable
  /// refuses a mouse drag unless it is told otherwise, and a wheel at the top of a list reports
  /// no overscroll at all — so without this there is nothing on a desktop that can pull.
  final bool mouseDrags;

  @override
  State<MochiRefresh> createState() => _MochiRefreshState();
}

class _MochiRefreshState extends State<MochiRefresh> with SingleTickerProviderStateMixin {
  /// How far the indicator has come down, in logical pixels. A notifier rather than state: a
  /// drag changes it every frame, and the list underneath has no business rebuilding for it.
  final _extent = ValueNotifier(0.0);

  late final AnimationController _settle = AnimationController(vsync: this);
  Animation<double>? _travel;

  _Phase _phase = _Phase.idle;

  /// The pull is heavier than the finger: dragging 100 pixels past the end brings the indicator
  /// down half of that, which is what makes the gesture feel like it is against something.
  static const _friction = 0.5;

  /// Where the indicator waits while the errand runs.
  static const _hold = 56.0;

  /// The circle the spinner sits in.
  static const _puck = 36.0;

  @override
  void dispose() {
    _settle.dispose();
    _extent.dispose();
    super.dispose();
  }

  void _moveTo(double target, {VoidCallback? then}) {
    final theme = MochiTheme.maybeRead(context);
    final motion = theme?.motion;
    final instant = MediaQuery.disableAnimationsOf(context);

    _travel?.removeListener(_follow);
    _settle
      ..stop()
      ..duration = instant ? Duration.zero : (motion?.sizeDuration ?? const Duration(milliseconds: 320))
      ..reset();

    _travel = Tween(begin: _extent.value, end: target).animate(
      CurvedAnimation(parent: _settle, curve: motion?.sizeCurve ?? Curves.easeInOutCubic),
    )..addListener(_follow);

    _settle.forward().whenComplete(() {
      if (mounted) then?.call();
    });
  }

  void _follow() => _extent.value = _travel?.value ?? _extent.value;

  bool _onNotification(ScrollNotification notification) {
    if (!widget.enabled || notification.metrics.axis != Axis.vertical) return false;
    if (notification.depth != 0) return false;

    switch (notification) {
      // The list is already at its top and the finger is still pulling: what a clamping physics
      // reports instead of moving.
      case OverscrollNotification(:final overscroll)
          when overscroll < 0 && notification.metrics.extentBefore == 0:
        if (_phase == _Phase.refreshing || _phase == _Phase.settling) break;
        _settle.stop();
        _phase = _Phase.pulling;
        // Never further than it can mean anything: past the trigger the pull only says "yes"
        // louder.
        _extent.value = math.min(_extent.value - overscroll * _friction, widget.triggerDistance * 1.4);

      // What a bouncing physics does instead: the list itself goes past its end.
      case ScrollUpdateNotification() when notification.metrics.pixels < notification.metrics.minScrollExtent:
        if (_phase == _Phase.refreshing || _phase == _Phase.settling) break;
        _settle.stop();
        _phase = _Phase.pulling;
        _extent.value = math.min(
          (notification.metrics.minScrollExtent - notification.metrics.pixels) * _friction,
          widget.triggerDistance * 1.4,
        );

      case ScrollEndNotification():
        _release();

      default:
        break;
    }

    return false;
  }

  void _release() {
    if (_phase != _Phase.pulling) return;

    if (_extent.value < widget.triggerDistance) {
      _phase = _Phase.settling;
      _moveTo(0, then: () => setState(() => _phase = _Phase.idle));
      return;
    }

    setState(() => _phase = _Phase.refreshing);
    _moveTo(_hold);

    // The list stays held down until the errand is done, however it ends: a refresh that threw
    // still has to give the page back. The failure is reported rather than swallowed — and
    // rather than left on a future nobody is holding, which would come out as an unhandled
    // error somewhere else entirely.
    widget
        .onRefresh()
        .then<void>(
          (_) {},
          onError: (Object error, StackTrace stack) {
            FlutterError.reportError(
              FlutterErrorDetails(
                exception: error,
                stack: stack,
                library: "mochi_ui",
                context: ErrorDescription("while refreshing a MochiRefresh"),
              ),
            );
          },
        )
        .whenComplete(() {
          if (!mounted) return;
          setState(() => _phase = _Phase.settling);
          _moveTo(0, then: () => setState(() => _phase = _Phase.idle));
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final tone = colors.of(widget.intent);

    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: Stack(
        children: [
          if (widget.mouseDrags)
            ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {...ScrollConfiguration.of(context).dragDevices, PointerDeviceKind.mouse},
              ),
              child: widget.child,
            )
          else
            widget.child,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            // The indicator is a passenger: everything under it stays as reachable as it was.
            child: IgnorePointer(
              child: ValueListenableBuilder<double>(
                valueListenable: _extent,
                builder: (context, extent, child) {
                  if (extent <= 0) return const SizedBox.shrink();

                  final t = (extent / widget.triggerDistance).clamp(0.0, 1.0);

                  return Transform.translate(
                    // Out of sight above the list at rest, and all the way down at the hold.
                    offset: Offset(0, extent - _puck),
                    child: Center(
                      child: Opacity(
                        opacity: t,
                        child: Transform.scale(scale: 0.7 + 0.3 * t, child: child),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: _puck,
                  height: _puck,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: colors.surface,
                    shape: CircleBorder(
                      side: BorderSide(color: colors.border, width: theme.geometry.borderWidth),
                    ),
                    shadows: theme.geometry.shadows.of(MochiElevation.sm, colors.shadow),
                  ),
                  child: _Spinner(
                    phase: () => _phase,
                    extent: _extent,
                    trigger: widget.triggerDistance,
                    color: tone.onSoft,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The ring inside the puck: how far there is left to pull, then a turn that says nothing about
/// how long is left, because nothing does.
class _Spinner extends StatelessWidget {
  const _Spinner({required this.phase, required this.extent, required this.trigger, required this.color});

  final _Phase Function() phase;
  final ValueNotifier<double> extent;
  final double trigger;
  final Color color;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: extent,
    builder: (context, value, _) => MochiCircularProgress(
      size: MochiSize.sm,
      color: color,
      // A quarter turn is the least that reads as a ring rather than a dot.
      value: phase() == _Phase.refreshing ? null : (0.25 + 0.75 * (value / trigger)).clamp(0.0, 1.0),
    ),
  );
}
