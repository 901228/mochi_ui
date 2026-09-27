import "package:flutter/gestures.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";

import "press_scale.dart";

/// What every pressable thing here is built on: the gestures, the keyboard, the focus, the
/// cursor, the semantics and the interaction states, with nothing drawn.
///
/// It owns a [WidgetStatesController] (hovered / focused / pressed / selected / disabled) and
/// hands the set to [builder], so a component decides what those states look like. Disabled is
/// `enabled: false`, or every callback being null.
class MochiTappable extends StatefulWidget {
  const MochiTappable({
    super.key,
    required this.builder,
    this.child,
    this.enabled = true,
    this.selected = false,
    this.scaleOnPress = true,
    this.onPress,
    this.onLongPress,
    this.onDoublePress,
    this.onSecondaryPress,
    this.onSecondaryLongPress,
    this.onHoverChange,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
    this.semanticLabel,
    this.mouseCursor,
  });

  final ValueWidgetBuilder<Set<WidgetState>> builder;
  final Widget? child;

  /// Set to false to disable without removing callbacks.
  final bool enabled;
  final bool selected;

  /// Grow while pressed (see [MochiPressScale]). Turn off for list rows and other
  /// surfaces that should stay in place.
  final bool scaleOnPress;

  final VoidCallback? onPress;
  final VoidCallback? onLongPress;

  /// Registering this delays [onPress] by the double-tap timeout (~300ms), since a
  /// single tap can't be confirmed until a second one has had time to arrive.
  final VoidCallback? onDoublePress;
  final VoidCallback? onSecondaryPress;
  final VoidCallback? onSecondaryLongPress;
  final ValueChanged<bool>? onHoverChange;
  final ValueChanged<bool>? onFocusChange;

  final FocusNode? focusNode;
  final bool autofocus;
  final WidgetStatesController? statesController;
  final String? semanticLabel;
  final MouseCursor? mouseCursor;

  bool get _hasPrimary => onPress != null || onLongPress != null || onDoublePress != null;
  bool get _hasSecondary => onSecondaryPress != null || onSecondaryLongPress != null;

  /// Interactive only when [enabled] and at least one press callback is set.
  bool get interactive => enabled && (_hasPrimary || _hasSecondary);

  @override
  State<MochiTappable> createState() => _MochiTappableState();
}

/// Which kind of thing the app last heard from, a pointer or a key.
///
/// This is the difference between a ring nobody asked for and one a keyboard user cannot do
/// without, and Flutter's own highlight mode cannot tell them apart: on a desktop a mouse and a
/// keyboard are both [FocusHighlightMode.traditional]. The web draws exactly this line with
/// `:focus-visible`. It starts as a keyboard, so focus taken in code — an autofocused field, a
/// test — shows its ring.
abstract final class _LastInput {
  /// True while the last thing heard from was a pointer. A notifier rather than a flag because
  /// the thing that is focused has to be told when it changes: the framework only reports a
  /// *change* of highlight, so a widget focused by a mouse and then reached by a key would
  /// otherwise never hear that it should be wearing a ring after all.
  static final pointer = ValueNotifier(false);

  /// How many tappables are on screen. The routes are counted rather than registered once and
  /// left: a test binding clears the keyboard's handlers between tests, so a registration that
  /// happened in the first test would be gone — and silently — by the tenth.
  static int _watchers = 0;

  static void _onPointer(PointerEvent event) {
    if (event is PointerDownEvent) pointer.value = true;
  }

  static bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent) pointer.value = false;
    return false;
  }

  static void watch() {
    if (_watchers++ > 0) return;

    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  static void unwatch() {
    if (--_watchers > 0) return;

    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    HardwareKeyboard.instance.removeHandler(_onKey);
    // Nothing is listening, so the next thing to arrive starts the question again.
    pointer.value = false;
  }
}

class _MochiTappableState extends State<MochiTappable> {
  WidgetStatesController? _internal;
  WidgetStatesController get _states => widget.statesController ?? (_internal ??= WidgetStatesController());

  FocusNode? _ownNode;
  FocusNode get _focusNode => widget.focusNode ?? (_ownNode ??= FocusNode());

  @override
  void initState() {
    super.initState();

    _LastInput.watch();
    _LastInput.pointer.addListener(_applyFocus);
    _focusNode.addListener(_applyFocus);
    _states.update(WidgetState.disabled, !widget.interactive);
    _states.update(WidgetState.selected, widget.selected);
  }

  @override
  void didUpdateWidget(MochiTappable old) {
    super.didUpdateWidget(old);

    if (widget.focusNode != old.focusNode) {
      (old.focusNode ?? _ownNode)?.removeListener(_applyFocus);
      _focusNode.addListener(_applyFocus);
      _applyFocus();
    }

    if (widget.interactive != old.interactive) {
      _states.update(WidgetState.disabled, !widget.interactive);
      if (!widget.interactive) {
        _states.update(WidgetState.pressed, false);
        _states.update(WidgetState.hovered, false);
      }
    }
    if (widget.selected != old.selected) {
      _states.update(WidgetState.selected, widget.selected);
    }
  }

  @override
  void dispose() {
    _LastInput.pointer.removeListener(_applyFocus);
    _LastInput.unwatch();
    _focusNode.removeListener(_applyFocus);
    _internal?.dispose();
    _ownNode?.dispose();

    super.dispose();
  }

  /// What the framework last said about the highlight, which it only reports when it changes.
  bool _highlight = false;

  void _handleFocusHighlight(bool visible) {
    _highlight = visible;
    _applyFocus();
  }

  /// A ring is for the keyboard. Three things have to hold, and any of them can change without
  /// the others: the framework wants a highlight, *this* is the thing that is focused rather than
  /// something inside it (a row whose button is focused wears no ring — the button has one), and
  /// the focus was not taken by a pointer, which asks for no ring at all.
  void _applyFocus() {
    if (!mounted) return;
    _states.update(
      WidgetState.focused,
      _highlight && _focusNode.hasPrimaryFocus && !_LastInput.pointer.value,
    );
  }

  // Created once so rebuilds (e.g. every frame of a theme animation) don't notify Actions dependents.
  late final _actions = <Type, Action<Intent>>{
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _press()),
    ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(onInvoke: (_) => _press()),
  };

  void _press() {
    if (widget.interactive) widget.onPress?.call();
  }

  void _setPressed(bool value) => _states.update(WidgetState.pressed, value);

  Widget _scaled(Widget child) =>
      widget.scaleOnPress ? MochiPressScale(states: _states, child: child) : child;

  @override
  Widget build(BuildContext context) {
    final interactive = widget.interactive;
    final primary = interactive && widget._hasPrimary;
    final secondary = interactive && widget._hasSecondary;

    return Semantics(
      button: true,
      enabled: interactive,
      selected: widget.selected,
      label: widget.semanticLabel,
      onTap: interactive && widget.onPress != null ? _press : null,
      onLongPress: interactive ? widget.onLongPress : null,
      child: FocusableActionDetector(
        enabled: interactive,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        mouseCursor:
            widget.mouseCursor ?? (interactive ? SystemMouseCursors.click : SystemMouseCursors.basic),
        onShowHoverHighlight: (v) {
          _states.update(WidgetState.hovered, v);
          widget.onHoverChange?.call(v);
        },
        onShowFocusHighlight: _handleFocusHighlight,
        onFocusChange: widget.onFocusChange,
        actions: _actions,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Pressed feedback is only wired for buttons that have a matching callback,
          // so e.g. a right-click on a button without secondary callbacks does nothing.
          onTapDown: primary ? (_) => _setPressed(true) : null,
          onTapUp: primary ? (_) => _setPressed(false) : null,
          onTapCancel: primary ? () => _setPressed(false) : null,
          onTap: primary && widget.onPress != null ? _press : null,
          // Null unless provided: any double-tap recognizer delays single taps.
          onDoubleTap: primary ? widget.onDoublePress : null,
          onLongPress: primary ? widget.onLongPress : null,
          // A long press cancels the tap recognizer; keep the pressed state until release.
          onLongPressStart: primary && widget.onLongPress != null ? (_) => _setPressed(true) : null,
          onLongPressEnd: primary && widget.onLongPress != null ? (_) => _setPressed(false) : null,
          onLongPressCancel: primary && widget.onLongPress != null ? () => _setPressed(false) : null,
          onSecondaryTapDown: secondary ? (_) => _setPressed(true) : null,
          onSecondaryTapUp: secondary ? (_) => _setPressed(false) : null,
          onSecondaryTapCancel: secondary ? () => _setPressed(false) : null,
          onSecondaryTap: secondary ? widget.onSecondaryPress : null,
          onSecondaryLongPress: secondary ? widget.onSecondaryLongPress : null,
          onSecondaryLongPressStart: secondary && widget.onSecondaryLongPress != null
              ? (_) => _setPressed(true)
              : null,
          onSecondaryLongPressEnd: secondary && widget.onSecondaryLongPress != null
              ? (_) => _setPressed(false)
              : null,
          onSecondaryLongPressCancel: secondary && widget.onSecondaryLongPress != null
              ? () => _setPressed(false)
              : null,
          child: _scaled(
            ValueListenableBuilder(
              valueListenable: _states,
              builder: (context, states, child) => widget.builder(context, states, child),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
