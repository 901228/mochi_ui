import "package:flutter/services.dart";
import "package:flutter/widgets.dart";

import "../theme/size.dart";
import "../theme/styles/button_style.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "field_frame.dart";
import "focus_ring.dart";
import "state_transition.dart";
import "value_transition.dart";

/// A one-time code, a character to a box: the code from an email, a PIN.
///
/// One field underneath, drawn as [length] boxes — so a paste drops the whole code into place,
/// backspace walks back through it, and the platform's one-time-code autofill can fill it — with
/// the box the next character goes into marked and carrying the caret.
///
/// ```dart
/// MochiOtpField(
///   length: 6,
///   onCompleted: (code) => verify(code),
/// )
/// ```
class MochiOtpField extends StatefulWidget {
  const MochiOtpField({
    super.key,
    this.length = 6,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.label,
    this.description,
    this.error,
    this.digitsOnly = true,
    this.obscure = false,
    this.enabled = true,
    this.autofocus = false,
    this.size = MochiSize.md,
    this.onChanged,
    this.onCompleted,
  }) : assert(length > 0),
       assert(controller == null || initialValue == null, "Pass the text in the controller instead.");

  /// How many boxes, and how long the code is.
  final int length;

  final TextEditingController? controller;

  /// The starting code when the field owns its controller.
  final String? initialValue;

  final FocusNode? focusNode;
  final Widget? label;
  final Widget? description;
  final String? error;

  /// Takes only 0-9 and asks for the number keyboard. Turn off for a code with letters in it.
  final bool digitsOnly;

  /// Shows a dot in place of each character, for a PIN.
  final bool obscure;

  final bool enabled;
  final bool autofocus;

  /// A box is as tall as a [MochiButton] of this size, and as wide as it is tall.
  final MochiSize size;

  final ValueChanged<String>? onChanged;

  /// Called once the last box is filled, with the whole code.
  final ValueChanged<String>? onCompleted;

  @override
  State<MochiOtpField> createState() => _MochiOtpFieldState();
}

class _MochiOtpFieldState extends State<MochiOtpField> {
  TextEditingController? _ownController;
  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController(text: widget.initialValue));

  FocusNode? _ownFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  final _editableKey = GlobalKey<EditableTextState>();

  String _last = "";

  @override
  void initState() {
    super.initState();

    _last = _controller.text;
    _controller.addListener(_handleText);
    _focusNode.addListener(_handleFocus);
  }

  @override
  void didUpdateWidget(MochiOtpField old) {
    super.didUpdateWidget(old);

    if (widget.controller != old.controller) {
      (old.controller ?? _ownController)?.removeListener(_handleText);
      if (widget.controller != null) {
        _ownController?.dispose();
        _ownController = null;
      }
      _controller.addListener(_handleText);
    }
    if (widget.focusNode != old.focusNode) {
      (old.focusNode ?? _ownFocusNode)?.removeListener(_handleFocus);
      if (widget.focusNode != null) {
        _ownFocusNode?.dispose();
        _ownFocusNode = null;
      }
      _focusNode.addListener(_handleFocus);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleText);
    _focusNode.removeListener(_handleFocus);
    _ownController?.dispose();
    _ownFocusNode?.dispose();

    super.dispose();
  }

  void _handleFocus() => setState(() {});

  void _handleText() {
    final text = _controller.text;
    // There is nowhere in the code to put a caret but the end: a character always goes in the
    // next empty box, and backspace always takes the last one out.
    final end = TextSelection.collapsed(offset: text.length);
    if (_controller.selection != end) _controller.selection = end;

    if (text == _last) return;
    _last = text;
    setState(() {});
    widget.onChanged?.call(text);
    if (text.length == widget.length) widget.onCompleted?.call(text);
  }

  void _requestFocus() {
    if (!widget.enabled) return;
    _focusNode.requestFocus();
    _editableKey.currentState?.requestKeyboard();
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
    final text = _controller.text;
    final focused = _focusNode.hasFocus;
    final style = m.textStyle(theme.typography).copyWith(color: colors.foreground);

    // The field that holds the code, kept out of sight: the boxes are what is drawn, and it only
    // takes the typing, the paste and the platform's autofill.
    final editable = EditableText(
      key: _editableKey,
      controller: _controller,
      focusNode: _focusNode,
      style: style.copyWith(color: const Color(0x00000000)),
      cursorColor: const Color(0x00000000),
      backgroundCursorColor: const Color(0x00000000),
      selectionColor: const Color(0x00000000),
      enableInteractiveSelection: false,
      showSelectionHandles: false,
      showCursor: false,
      readOnly: !widget.enabled,
      autofocus: widget.autofocus,
      keyboardType: widget.digitsOnly ? TextInputType.number : TextInputType.text,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [
        if (widget.digitsOnly) FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(widget.length),
      ],
      // The row of boxes takes the pointer, so this never needs to.
      rendererIgnoresPointer: true,
      contextMenuBuilder: null,
    );

    final boxes = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: g.space.xs,
      children: [
        for (var index = 0; index < widget.length; index++)
          _Box(
            character: index < text.length ? text[index] : null,
            obscure: widget.obscure,
            // The box the next character goes into, and only while the field has the keyboard.
            active: focused && index == text.length.clamp(0, widget.length - 1),
            full: text.length == widget.length,
            error: widget.error != null,
            metrics: m,
            style: style,
          ),
      ],
    );

    return MochiFieldFrame(
      label: widget.label,
      description: widget.description,
      error: widget.error,
      enabled: widget.enabled,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: MochiFocusRing(
          visible: focused,
          radius: m.radius(g.radius),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _requestFocus,
            child: Stack(
              children: [
                boxes,
                // Behind the boxes and the size of one line, so it can't show or take a tap.
                Positioned(width: 1, height: 1, child: ExcludeSemantics(child: editable)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One box: the character in it, or the caret when it is the one being filled.
class _Box extends StatefulWidget {
  const _Box({
    required this.character,
    required this.obscure,
    required this.active,
    required this.full,
    required this.error,
    required this.metrics,
    required this.style,
  });

  final String? character;
  final bool obscure;
  final bool active;

  /// The whole code is there: every box reads as done rather than one of them waiting.
  final bool full;
  final bool error;
  final MochiButtonMetrics metrics;
  final TextStyle style;

  @override
  State<_Box> createState() => _BoxState();
}

class _BoxState extends State<_Box> with SingleTickerProviderStateMixin {
  late final _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

  @override
  void initState() {
    super.initState();

    if (widget.active) _blink.repeat();
  }

  @override
  void didUpdateWidget(_Box old) {
    super.didUpdateWidget(old);

    if (widget.active == old.active) return;
    if (widget.active) {
      _blink.repeat();
    } else {
      _blink.stop();
    }
  }

  @override
  void dispose() {
    _blink.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;
    final m = widget.metrics;
    final primary = colors.of(MochiIntent.primary);
    final danger = colors.of(MochiIntent.danger);
    final character = widget.character;
    // A caret that never stops blinking is one more thing moving on the screen.
    final blink = (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ? null : _blink;

    return MochiStateTransition(
      states: {
        if (widget.active) WidgetState.focused,
        if (widget.error) WidgetState.error,
        if (character != null) WidgetState.selected,
      },
      duration: theme.motion.stateDuration,
      builder: (context, state) => Container(
        width: m.height,
        height: m.height,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: colors.surface,
          shape: g.shape(
            borderRadius: m.radius(g.radius),
            side: BorderSide(
              width: g.borderWidth,
              color: state.color(
                (st) => switch (st) {
                  _ when st.contains(WidgetState.error) => danger.base,
                  _ when st.contains(WidgetState.focused) => primary.base,
                  // A filled box keeps a stronger edge than an empty one waiting its turn.
                  _ when st.contains(WidgetState.selected) => Color.lerp(
                    colors.border,
                    colors.mutedForeground,
                    0.5,
                  )!,
                  _ => colors.border,
                },
              ),
            ),
          ),
        ),
        child: character != null
            ? (widget.obscure
                  ? _Dot(color: colors.foreground, size: m.iconSize * 0.4)
                  : Text(character, style: widget.style))
            : (widget.active && !widget.full
                  ? _Caret(blink: blink, color: primary.base, style: widget.style)
                  : null),
      ),
    );
  }
}

/// What a filled box shows when the code is a PIN.
class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: ShapeDecoration(color: color, shape: const CircleBorder()),
    ),
  );
}

/// The line in the box waiting to be filled: the text field's caret, drawn where the character
/// will land.
class _Caret extends StatelessWidget {
  const _Caret({required this.blink, required this.color, required this.style});

  final Animation<double>? blink;
  final Color color;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final bar = SizedBox(
      width: 2,
      height: (style.fontSize ?? 14) * 1.2,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: color,
          shape: context.theme.geometry.shape(borderRadius: BorderRadius.all(Radius.circular(1))),
        ),
      ),
    );
    final blink = this.blink;
    if (blink == null) return bar;

    return AnimatedBuilder(
      animation: blink,
      // On for the first half of every second, off for the rest, the way a caret goes.
      builder: (context, child) => Opacity(opacity: blink.value < 0.5 ? 1 : 0, child: child),
      child: bar,
    );
  }
}
