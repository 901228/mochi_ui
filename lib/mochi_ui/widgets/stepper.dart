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
///
/// Pressing the number types it instead, which beats holding a button for a value with a wide
/// range: Enter or leaving the field takes what was typed (out of range is pulled back to [min]
/// or [max], nonsense is put back the way it was), Escape drops it, and the arrows still step.
/// [format] is for showing the value, so what is being typed is `15` rather than `15s`.
class MochiStepper extends StatefulWidget {
  const MochiStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min,
    this.max,
    this.step = 1,
    this.size = MochiSize.md,
    this.editable = true,
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

  /// Whether pressing the number lets it be typed. Off, the buttons and the keyboard are the only
  /// ways to change it.
  final bool editable;

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

  // Typing the value: the field only exists while it is being edited.
  final _editController = TextEditingController();
  FocusNode? _editFocusNode;
  FocusNode get _editFocus => _editFocusNode ??= FocusNode(debugLabel: "MochiStepper field");
  bool _editing = false;

  bool get _canDecrease => _enabled && (widget.min == null || _value > widget.min!);
  bool get _canIncrease => _enabled && (widget.max == null || _value < widget.max!);

  @override
  void initState() {
    super.initState();

    _editFocus.addListener(_handleEditFocus);
  }

  @override
  void didUpdateWidget(MochiStepper old) {
    super.didUpdateWidget(old);

    _sent = null;
    // Turning editing off puts away a field that is open, without another setState in here.
    if (!widget.editable) _editing = false;
  }

  @override
  void dispose() {
    _repeat?.cancel();
    _ownFocusNode?.dispose();
    _editController.dispose();
    _editFocusNode?.dispose();

    super.dispose();
  }

  void _startEditing() {
    if (_editing || !widget.editable || !_enabled) return;
    // The plain number, not the formatted one: "15s" is for reading, not for typing.
    _editController.value = TextEditingValue(
      text: "$_value",
      selection: TextSelection(baseOffset: 0, extentOffset: "$_value".length),
    );
    setState(() => _editing = true);
    // Asked for rather than autofocused: `autofocus` only takes when nothing in the scope holds
    // the focus, so pressing one stepper's number while another's field is open would leave the
    // typing going to the old one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _editing) _editFocus.requestFocus();
    });
  }

  /// Takes what was typed, or puts the old value back. Empty or nonsense counts as nothing typed.
  void _finishEditing({required bool commit, bool returnFocus = false}) {
    if (!_editing) return;
    final typed = int.tryParse(_editController.text.trim());
    setState(() => _editing = false);
    if (commit && typed != null) _set(typed);
    // Enter and Escape leave the stepper itself focused, so the arrows carry on working; a press
    // elsewhere or a Tab has already sent the focus where it was going.
    if (returnFocus) _focusNode.requestFocus();
  }

  // Leaving the field for anything else takes what is in it.
  void _handleEditFocus() {
    if (_editing && !_editFocus.hasFocus) _finishEditing(commit: true);
  }

  /// An arrow while typing steps the value and writes the result back into the field.
  void _stepWhileEditing(int direction) {
    final base = int.tryParse(_editController.text.trim()) ?? _value;
    final next = _clamp(base + widget.step * direction);
    _editController.value = TextEditingValue(
      text: "$next",
      selection: TextSelection.collapsed(offset: "$next".length),
    );
    _set(next);
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
        states: {
          // The field takes the focus while it is open, so the box has to be told it is still
          // the thing being used.
          if (_focusVisible || _editing) WidgetState.focused,
          if (!_enabled) WidgetState.disabled,
        },
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
                    child: _editing
                        ? _field(theme, textStyle)
                        : GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _startEditing,
                            child: MouseRegion(
                              cursor: widget.editable && _enabled
                                  ? SystemMouseCursors.text
                                  : MouseCursor.defer,
                              child: Text(
                                format(value),
                                style: textStyle,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                              ),
                            ),
                          ),
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

extension on _MochiStepperState {
  /// The field the number turns into while it is being typed.
  Widget _field(MochiTheme theme, TextStyle textStyle) {
    final colors = theme.colors;
    final negatives = widget.min == null || widget.min! < 0;

    return CallbackShortcuts(
      // Bound inside the field, where the nearest binding wins: out here the arrows would walk
      // the caret about instead of stepping.
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _stepWhileEditing(1),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _stepWhileEditing(-1),
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            _finishEditing(commit: false, returnFocus: true),
      },
      child: EditableText(
        controller: _editController,
        focusNode: _editFocus,
        style: textStyle,
        strutStyle: StrutStyle.fromTextStyle(textStyle, forceStrutHeight: true),
        cursorColor: colors.of(MochiIntent.primary).base,
        backgroundCursorColor: colors.mutedForeground,
        selectionColor: colors.of(MochiIntent.primary).base.withValues(alpha: 0.3),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.numberWithOptions(signed: negatives),
        textInputAction: TextInputAction.done,
        inputFormatters: [
          FilteringTextInputFormatter.allow(negatives ? RegExp(r"[0-9-]") : RegExp(r"[0-9]")),
        ],
        cursorWidth: 2,
        cursorRadius: const Radius.circular(1),
        // One number in one box: no selection toolbar of its own.
        contextMenuBuilder: null,
        onSubmitted: (_) => _finishEditing(commit: true, returnFocus: true),
      ),
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
