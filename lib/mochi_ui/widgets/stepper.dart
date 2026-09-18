import "dart:async";

import "package:flutter/services.dart";
import "package:flutter/widgets.dart";

import "../theme/size.dart";
import "../theme/styles/button_style.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "button.dart";
import "focus_ring.dart";
import "state_transition.dart";
import "value_transition.dart";

/// A whole number with a − and a + beside it: an inspection time, how many solves an average
/// takes.
///
/// Holding a button repeats it, quicker the longer it is held. From the keyboard the stepper is
/// one tab stop: up or right adds [step], down or left takes it away, Home and End go to [min]
/// and [max]. Its height is a [MochiButton]'s of the same [size], so it lines up with fields and
/// buttons in a row.
class MochiStepper extends StatefulWidget {
  const MochiStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min,
    this.max,
    this.step = 1,
    this.size = MochiSize.md,
    this.format,
    this.width,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  }) : assert(min == null || max == null || min <= max),
       assert(step > 0);

  final int value;

  /// Null disables the stepper.
  final ValueChanged<int>? onChanged;

  final int? min;
  final int? max;
  final int step;
  final MochiSize size;

  /// How the value is shown, such as `(v) => "${v}s"`. Defaults to the plain number.
  final String Function(int value)? format;

  /// Of the value between the buttons. Defaults to enough for the widest of [min], [max] and the
  /// current value, so the buttons don't move as the number grows a digit.
  final double? width;

  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;

  @override
  State<MochiStepper> createState() => _MochiStepperState();
}

class _MochiStepperState extends State<MochiStepper> {
  FocusNode? _ownFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  bool _focusVisible = false;

  // Hold to repeat: a pause, then steps that come quicker the longer the button is held.
  Timer? _repeat;
  int _repeats = 0;
  bool _repeated = false;

  static const _holdDelay = Duration(milliseconds: 400);

  // The last value handed to onChanged, until the parent rebuilds with it. Steps can come faster
  // than frames — a held button, a key held down — and each must build on the one before, not on
  // the value this widget was last built with.
  int? _sent;
  int get _value => _sent ?? widget.value;

  bool get _enabled => widget.onChanged != null;

  bool get _canDecrease => _enabled && (widget.min == null || _value > widget.min!);
  bool get _canIncrease => _enabled && (widget.max == null || _value < widget.max!);

  @override
  void didUpdateWidget(MochiStepper old) {
    super.didUpdateWidget(old);

    _sent = null;
  }

  @override
  void dispose() {
    _repeat?.cancel();
    _ownFocusNode?.dispose();

    super.dispose();
  }

  int _clamp(int value) {
    var result = value;
    if (widget.min case final min? when result < min) result = min;
    if (widget.max case final max? when result > max) result = max;
    return result;
  }

  void _set(int value) {
    final next = _clamp(value);
    if (next == _value) return;
    _sent = next;
    widget.onChanged?.call(next);
  }

  void _stepBy(int direction) => _set(_value + widget.step * direction);

  void _startHold(int direction) {
    _stopHold();
    _repeated = false;
    _repeats = 0;
    _repeat = Timer(_holdDelay, () => _tick(direction));
  }

  void _tick(int direction) {
    if (!mounted) return;
    _repeated = true;
    _stepBy(direction);
    _repeats++;
    // 120ms apart at first, down to 40ms after a couple of seconds.
    final gap = Duration(milliseconds: (120 - _repeats * 4).clamp(40, 120));
    _repeat = Timer(gap, () => _tick(direction));
  }

  void _stopHold() {
    _repeat?.cancel();
    _repeat = null;
  }

  // A press that turned into a hold has already stepped; its release mustn't step once more.
  void _press(int direction) {
    if (_repeated) {
      _repeated = false;
      return;
    }
    _stepBy(direction);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final target = MochiButtonMetrics.of(widget.size, touch: theme.touch, density: theme.density);

    return MochiValueTransition(
      value: target,
      lerp: MochiButtonMetrics.lerp,
      duration: theme.motion.sizeDuration,
      curve: theme.motion.sizeCurve,
      builder: (context, m, _) => _build(context, theme, m),
    );
  }

  Widget _build(BuildContext context, MochiTheme theme, MochiButtonMetrics m) {
    final colors = theme.colors;
    final g = theme.geometry;
    final radius = m.radius(g.radius);
    final format = widget.format ?? (int value) => "$value";
    final textStyle = m
        .textStyle(theme.typography)
        .copyWith(color: colors.foreground, fontFeatures: const [FontFeature.tabularFigures()]);

    final widest = [
      widget.value,
      ?widget.min,
      ?widget.max,
    ].map(format).reduce((a, b) => a.length >= b.length ? a : b);
    final painter = TextPainter(
      text: TextSpan(text: widest, style: textStyle),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final valueWidth = widget.width ?? painter.width + m.horizontalPadding;
    painter.dispose();

    Widget button(int direction) {
      final enabled = direction < 0 ? _canDecrease : _canIncrease;
      return Listener(
        onPointerDown: enabled ? (_) => _startHold(direction) : null,
        onPointerUp: (_) => _stopHold(),
        onPointerCancel: (_) => _stopHold(),
        // The stepper as a whole takes focus and the arrow keys; its buttons are for the pointer.
        child: ExcludeFocus(
          child: MochiButton.icon(
            appearance: MochiButtonAppearance.ghost,
            intent: MochiIntent.neutral,
            // A step down, so the pair and the value fit inside the box's own height.
            metrics: MochiButtonMetrics(
              height: m.height - 2 * g.borderWidth - 4,
              horizontalPadding: 0,
              gap: 0,
              iconSize: m.iconSize,
              radius: (r) => r.xs,
              textStyle: m.textStyle,
            ),
            enabled: enabled,
            onPress: () => _press(direction),
            icon: Icon(direction < 0 ? theme.icons.minus : theme.icons.plus),
          ),
        ),
      );
    }

    final value = widget.value;
    final semantic = Semantics(
      label: widget.semanticLabel,
      value: format(value),
      increasedValue: _canIncrease ? format(_clamp(value + widget.step)) : null,
      decreasedValue: _canDecrease ? format(_clamp(value - widget.step)) : null,
      onIncrease: _canIncrease ? () => _stepBy(1) : null,
      onDecrease: _canDecrease ? () => _stepBy(-1) : null,
      child: MochiStateTransition(
        states: {if (_focusVisible) WidgetState.focused, if (!_enabled) WidgetState.disabled},
        duration: theme.motion.stateDuration,
        builder: (context, blend) => Opacity(
          opacity: blend.number((st) => st.contains(WidgetState.disabled) ? 0.4 : 1),
          child: MochiFocusRing(
            visible: blend.contains(WidgetState.focused),
            radius: radius,
            child: Container(
              height: m.height,
              padding: const EdgeInsets.all(2),
              decoration: ShapeDecoration(
                color: colors.surface,
                shape: RoundedSuperellipseBorder(
                  borderRadius: radius,
                  side: BorderSide(
                    width: g.borderWidth,
                    color: blend.color(
                      (st) => st.contains(WidgetState.focused)
                          ? colors.of(MochiIntent.primary).base
                          : colors.border,
                    ),
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  button(-1),
                  SizedBox(
                    width: valueWidth,
                    child: Text(format(value), style: textStyle, textAlign: TextAlign.center, maxLines: 1),
                  ),
                  button(1),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return FocusableActionDetector(
      enabled: _enabled,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onShowFocusHighlight: (visible) => setState(() => _focusVisible = visible),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowUp): _StepIntent(1),
        SingleActivator(LogicalKeyboardKey.arrowRight): _StepIntent(1),
        SingleActivator(LogicalKeyboardKey.arrowDown): _StepIntent(-1),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _StepIntent(-1),
        SingleActivator(LogicalKeyboardKey.home): _EndIntent(toMax: false),
        SingleActivator(LogicalKeyboardKey.end): _EndIntent(toMax: true),
      },
      actions: {
        _StepIntent: CallbackAction<_StepIntent>(onInvoke: (intent) => _stepBy(intent.direction)),
        _EndIntent: CallbackAction<_EndIntent>(
          onInvoke: (intent) {
            final end = intent.toMax ? widget.max : widget.min;
            if (end != null) _set(end);
            return null;
          },
        ),
      },
      child: semantic,
    );
  }
}

class _StepIntent extends Intent {
  const _StepIntent(this.direction);

  final int direction;
}

class _EndIntent extends Intent {
  const _EndIntent({required this.toMax});

  final bool toMax;
}
