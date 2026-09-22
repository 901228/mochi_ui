import "dart:ui" show lerpDouble;

import "package:flutter/services.dart";
import "package:flutter/widgets.dart";

import "../theme/geometry.dart";
import "../theme/size.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "field_frame.dart";
import "focus_ring.dart";
import "state_transition.dart";
import "value_transition.dart";

/// A number picked by sliding: inspection time, a volume, a weight.
///
/// Drag the thumb, press anywhere on the track to send it there, or use the arrows once it has
/// focus (Home and End go to the ends). With [divisions] it snaps to that many steps.
///
/// ```dart
/// MochiSlider(
///   value: volume,
///   label: const Text("Volume"),
///   valueLabel: (value) => "${(value * 100).round()}%",
///   onChanged: (value) => setState(() => volume = value),
/// )
/// ```
class MochiSlider extends StatefulWidget {
  const MochiSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.step,
    this.label,
    this.valueLabel,
    this.description,
    this.error,
    this.intent = MochiIntent.primary,
    this.size = MochiSize.md,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.onChangeStart,
    this.onChangeEnd,
  }) : assert(min < max),
       assert(divisions == null || divisions > 0),
       assert(step == null || step > 0);

  final double value;

  /// Null disables the slider.
  final ValueChanged<double>? onChanged;

  final double min;
  final double max;

  /// Snaps to this many equal steps between [min] and [max]; null slides freely.
  final int? divisions;

  /// How far one arrow key moves it. Defaults to one division, or a tenth of the range.
  final double? step;

  /// Above the slider.
  final Widget? label;

  /// The value written out, shown at the end of the label's line — where a slider usually says
  /// what it is set to.
  final String Function(double value)? valueLabel;

  final Widget? description;
  final String? error;
  final MochiIntent intent;
  final MochiSize size;
  final bool enabled;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;

  /// The drag or press started.
  final ValueChanged<double>? onChangeStart;

  /// The drag or press finished, with the value it settled on.
  final ValueChanged<double>? onChangeEnd;

  @override
  State<MochiSlider> createState() => _MochiSliderState();
}

class _MochiSliderState extends State<MochiSlider> {
  FocusNode? _ownFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  bool _focusVisible = false;
  bool _hovered = false;
  bool _dragging = false;

  // The last value handed to onChanged, until the parent rebuilds with it: a drag moves faster
  // than frames arrive, and a held arrow key steps on what it sent rather than on widget.value.
  double? _sent;
  double get _value => _sent ?? widget.value;

  bool get _enabled => widget.enabled && widget.onChanged != null;

  double get _step =>
      widget.step ??
      (widget.divisions == null
          ? (widget.max - widget.min) / 10
          : (widget.max - widget.min) / widget.divisions!);

  @override
  void didUpdateWidget(MochiSlider old) {
    super.didUpdateWidget(old);

    _sent = null;
  }

  @override
  void dispose() {
    _ownFocusNode?.dispose();

    super.dispose();
  }

  /// Where the value sits between the ends, 0 to 1.
  double get _fraction => ((_value - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);

  double _snap(double value) {
    final clamped = value.clamp(widget.min, widget.max);
    final divisions = widget.divisions;
    if (divisions == null) return clamped;

    final size = (widget.max - widget.min) / divisions;
    return widget.min + (((clamped - widget.min) / size).round() * size);
  }

  void _set(double value) {
    final next = _snap(value);
    if (next == _value) return;
    _sent = next;
    widget.onChanged?.call(next);
  }

  void _stepBy(double direction) => _set(_value + _step * direction);

  /// A press or a drag: the thumb goes to the pointer, which is where it can reach.
  void _moveTo(double dx, double trackLength, {required bool rtl}) {
    final fraction = (dx / trackLength).clamp(0.0, 1.0);
    _set(widget.min + (rtl ? 1 - fraction : fraction) * (widget.max - widget.min));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final target = MochiSliderMetrics.of(widget.size, touch: theme.touch);

    return MochiValueTransition(
      value: target,
      lerp: MochiSliderMetrics.lerp,
      duration: theme.motion.sizeDuration,
      curve: theme.motion.sizeCurve,
      builder: (context, m, _) => _build(context, theme, m),
    );
  }

  Widget _build(BuildContext context, MochiTheme theme, MochiSliderMetrics m) {
    final colors = theme.colors;
    final g = theme.geometry;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final valueLabel = widget.valueLabel;
    String say(double value) => valueLabel?.call(value) ?? "$value";

    final states = {
      if (_focusVisible) WidgetState.focused,
      if (_hovered) WidgetState.hovered,
      if (_dragging) WidgetState.pressed,
      if (!_enabled) WidgetState.disabled,
    };

    final bar = LayoutBuilder(
      builder: (context, constraints) {
        // The thumb's centre runs from one end of the track to the other, so it never hangs off.
        final width = constraints.maxWidth;
        final travel = (width - m.thumb).clamp(0.0, double.infinity);

        void start(Offset local) {
          if (!_enabled) return;
          _focusNode.requestFocus();
          setState(() => _dragging = true);
          widget.onChangeStart?.call(_value);
          _moveTo(local.dx - m.thumb / 2, travel, rtl: rtl);
        }

        void end() {
          if (!_dragging) return;
          setState(() => _dragging = false);
          widget.onChangeEnd?.call(_value);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => start(details.localPosition),
          onTapUp: (_) => end(),
          onTapCancel: end,
          onHorizontalDragStart: (details) => start(details.localPosition),
          onHorizontalDragUpdate: (details) {
            if (!_enabled) return;
            _moveTo(details.localPosition.dx - m.thumb / 2, travel, rtl: rtl);
          },
          onHorizontalDragEnd: (_) => end(),
          onHorizontalDragCancel: end,
          child: MouseRegion(
            cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: MochiStateTransition(
              states: states,
              duration: theme.motion.stateDuration,
              builder: (context, blend) => SizedBox(
                // Room for the thumb to grow into, and a band deep enough to aim at: the track
                // and the knob are centred in it.
                height: [m.hit, m.thumb + 2 * m.grow].reduce((a, b) => a > b ? a : b),
                child: Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: [
                    _Track(
                      fraction: _fraction,
                      thickness: m.track,
                      color: colors.border,
                      filled: blend.color(
                        (st) => st.contains(WidgetState.disabled)
                            ? colors.mutedForeground
                            : colors.of(widget.intent).base,
                      ),
                      radius: g.radius.full,
                    ),
                    PositionedDirectional(
                      start: _fraction * travel,
                      child: _Thumb(
                        diameter: m.thumb,
                        // Grows while held or hovered, the way a pressed button does.
                        grow: blend.number(
                          (st) => switch (st) {
                            _ when st.contains(WidgetState.disabled) => 0,
                            _ when st.contains(WidgetState.pressed) => 1,
                            _ when st.contains(WidgetState.hovered) => 0.5,
                            _ => 0,
                          },
                        ),
                        maxGrow: m.grow,
                        focusVisible: blend.contains(WidgetState.focused),
                        color: colors.surface,
                        border: blend.color(
                          (st) => st.contains(WidgetState.disabled)
                              ? colors.mutedForeground
                              : colors.of(widget.intent).base,
                        ),
                        shadows: g.shadows.of(MochiElevation.sm, colors.shadow),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    final label = widget.label;
    return MochiFieldFrame(
      label: label == null && valueLabel == null
          ? null
          : Row(
              children: [
                Expanded(child: label ?? const SizedBox.shrink()),
                if (valueLabel != null)
                  DefaultTextStyle.merge(
                    style: theme.typography.body.sm.copyWith(color: colors.mutedForeground),
                    child: Text(valueLabel(_value)),
                  ),
              ],
            ),
      description: widget.description,
      error: widget.error,
      enabled: _enabled,
      child: Semantics(
        slider: true,
        label: widget.semanticLabel,
        value: say(_value),
        // A screen reader is told where a step would land, so the pair has to come with the
        // action that takes it.
        increasedValue: _enabled ? say(_snap(_value + _step)) : null,
        decreasedValue: _enabled ? say(_snap(_value - _step)) : null,
        onIncrease: _enabled ? () => _stepBy(1) : null,
        onDecrease: _enabled ? () => _stepBy(-1) : null,
        child: FocusableActionDetector(
          enabled: _enabled,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          onShowFocusHighlight: (visible) => setState(() => _focusVisible = visible),
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.arrowRight): _SlideIntent(1),
            SingleActivator(LogicalKeyboardKey.arrowUp): _SlideIntent(1),
            SingleActivator(LogicalKeyboardKey.arrowLeft): _SlideIntent(-1),
            SingleActivator(LogicalKeyboardKey.arrowDown): _SlideIntent(-1),
            SingleActivator(LogicalKeyboardKey.home): _EndIntent(toMax: false),
            SingleActivator(LogicalKeyboardKey.end): _EndIntent(toMax: true),
          },
          actions: {
            _SlideIntent: CallbackAction<_SlideIntent>(
              // The arrows move the thumb the way they point: in right-to-left the track runs
              // the other way, so left is more.
              onInvoke: (intent) => _stepBy(rtl ? -intent.direction : intent.direction),
            ),
            _EndIntent: CallbackAction<_EndIntent>(
              onInvoke: (intent) => _set(intent.toMax ? widget.max : widget.min),
            ),
          },
          child: bar,
        ),
      ),
    );
  }
}

class _SlideIntent extends Intent {
  const _SlideIntent(this.direction);

  final double direction;
}

class _EndIntent extends Intent {
  const _EndIntent({required this.toMax});

  final bool toMax;
}

/// The line the thumb runs along: filled up to the value, plain after it.
class _Track extends StatelessWidget {
  const _Track({
    required this.fraction,
    required this.thickness,
    required this.color,
    required this.filled,
    required this.radius,
  });

  final double fraction;
  final double thickness;
  final Color color;
  final Color filled;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: thickness,
    child: Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: color,
              shape: RoundedSuperellipseBorder(borderRadius: radius),
            ),
          ),
        ),
        // A fraction of the width, measured the way the text runs.
        Positioned.fill(
          child: FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: fraction,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: filled,
                shape: RoundedSuperellipseBorder(borderRadius: radius),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  @override
  String toStringShort() => "track";
}

/// The knob, which grows a little while it is held.
class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.diameter,
    required this.grow,
    required this.maxGrow,
    required this.focusVisible,
    required this.color,
    required this.border,
    required this.shadows,
  });

  final double diameter;

  /// How far into its growth it is, 0 to 1.
  final double grow;
  final double maxGrow;
  final bool focusVisible;
  final Color color;
  final Color border;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    final size = diameter + grow * maxGrow * 2;
    final full = context.theme.geometry.radius.full;

    return SizedBox.square(
      dimension: diameter,
      child: Center(
        child: MochiFocusRing(
          visible: focusVisible,
          radius: full,
          child: SizedBox.square(
            dimension: size,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: color,
                shadows: shadows,
                shape: RoundedSuperellipseBorder(
                  borderRadius: full,
                  // Thick enough to read as the intent's colour at a glance.
                  side: BorderSide(color: border, width: diameter / 5),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Size-dependent layout of a slider. The thumb is 12 / 16 / 20 / 24 on the desktop scale, and
/// the whole thing is 28 tall to the pointer (44 on touch) whatever size it is.
@immutable
class MochiSliderMetrics {
  const MochiSliderMetrics({required this.track, required this.thumb, required this.grow, required this.hit});

  /// How thick the line is.
  final double track;

  /// The knob at rest.
  final double thumb;

  /// How far the knob grows per side while it is held.
  final double grow;

  /// How tall the slider is to the pointer. A line and a small knob are a few pixels of target,
  /// which is nothing to aim at — and a miss inside a scrolling page scrolls the page instead.
  final double hit;

  factory MochiSliderMetrics.of(MochiSize size, {required bool touch}) {
    final extra = touch ? 4.0 : 0.0;
    final (track, thumb) = switch (size) {
      MochiSize.xs => (3.0, 12.0),
      MochiSize.sm => (4.0, 16.0),
      MochiSize.md => (5.0, 20.0),
      MochiSize.lg => (6.0, 24.0),
    };

    final grow = 2 + extra / 4;

    return MochiSliderMetrics(track: track, thumb: thumb + extra, grow: grow, hit: touch ? 44 : 28);
  }

  static MochiSliderMetrics lerp(MochiSliderMetrics a, MochiSliderMetrics b, double t) => MochiSliderMetrics(
    track: lerpDouble(a.track, b.track, t)!,
    thumb: lerpDouble(a.thumb, b.thumb, t)!,
    grow: lerpDouble(a.grow, b.grow, t)!,
    hit: lerpDouble(a.hit, b.hit, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is MochiSliderMetrics &&
      track == other.track &&
      thumb == other.thumb &&
      grow == other.grow &&
      hit == other.hit;

  @override
  int get hashCode => Object.hash(track, thumb, grow, hit);
}
