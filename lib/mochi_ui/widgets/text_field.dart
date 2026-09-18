import "package:flutter/gestures.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";

import "../theme/size.dart";
import "../theme/strings.dart";
import "../theme/styles/button_style.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "../theme/typography.dart";
import "close_button.dart";
import "focus_ring.dart";
import "menu.dart";
import "popover.dart";
import "state_transition.dart";
import "value_transition.dart";

/// A text input: a bordered box around an [EditableText], with an optional label above it and a
/// description or an error below.
///
/// Its height, padding and text size are those of a [MochiButton] of the same [size], so a field
/// and a button in one row line up. Selecting, the context menu (cut, copy, paste, select all, in
/// [MochiStrings]) and the touch selection handles come from the widgets layer's own machinery,
/// drawn in Mochi's style.
///
/// Pass a [controller] to own the text, or an [initialValue] to let the field keep it.
class MochiTextField extends StatefulWidget {
  const MochiTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.label,
    this.hint,
    this.description,
    this.error,
    this.prefix,
    this.suffix,
    this.clearable = false,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    this.minLines,
    this.maxLines = 1,
    this.size = MochiSize.md,
    this.textAlign = TextAlign.start,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
  }) : assert(controller == null || initialValue == null, "Pass the text in the controller instead.");

  /// Several lines, growing from [minLines] with its content; Enter starts a new line.
  const MochiTextField.multiline({
    super.key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.label,
    this.hint,
    this.description,
    this.error,
    this.prefix,
    this.suffix,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.inputFormatters,
    this.maxLength,
    this.minLines = 3,
    this.maxLines,
    this.size = MochiSize.md,
    this.textAlign = TextAlign.start,
    this.autofillHints,
    this.onChanged,
    this.onEditingComplete,
  }) : assert(controller == null || initialValue == null, "Pass the text in the controller instead."),
       clearable = false,
       obscureText = false,
       keyboardType = TextInputType.multiline,
       textInputAction = TextInputAction.newline,
       onSubmitted = null;

  final TextEditingController? controller;

  /// The starting text when the field owns its controller.
  final String? initialValue;

  final FocusNode? focusNode;

  /// Above the box.
  final Widget? label;

  /// Shown in the box while it is empty.
  final String? hint;

  /// Below the box, in muted text. Replaced by [error] when there is one.
  final Widget? description;

  /// Marks the field invalid: the border turns to the danger tone and this replaces
  /// [description].
  final String? error;

  /// Inside the box, before the text: usually an icon.
  final Widget? prefix;

  /// Inside the box, after the text.
  final Widget? suffix;

  /// Adds a × that empties the field, shown only while there is something to clear.
  final bool clearable;

  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  /// Stops input at this many characters and shows a count below the box.
  final int? maxLength;

  final int? minLines;

  /// Null grows without limit.
  final int? maxLines;

  /// Matches [MochiButton.size].
  final MochiSize size;

  final TextAlign textAlign;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;

  @override
  State<MochiTextField> createState() => _MochiTextFieldState();
}

class _MochiTextFieldState extends State<MochiTextField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  TextEditingController? _ownController;
  TextEditingController get _controller => widget.controller ?? (_ownController ??= _createController());

  FocusNode? _ownFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  late final _gestures = _GestureBuilder(this);

  bool _hovered = false;
  bool _showHandles = false;

  @override
  final editableTextKey = GlobalKey<EditableTextState>();

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => true;

  TextEditingController _createController() => TextEditingController(text: widget.initialValue);

  @override
  void initState() {
    super.initState();

    _controller.addListener(_handleText);
    _focusNode.addListener(_handleFocus);
  }

  @override
  void didUpdateWidget(MochiTextField old) {
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

  // The hint, the clear button and the counter all follow the text.
  void _handleText() => setState(() {});

  void _handleFocus() => setState(() {});

  EditableTextState? get _editable => editableTextKey.currentState;

  // Follows TextField: handles appear for a touch selection that has something in it, never for
  // one made with the keyboard.
  void _handleSelectionChanged(TextSelection selection, SelectionChangedCause? cause) {
    final show = switch (cause) {
      _ when !_gestures.shouldShowSelectionToolbar => false,
      SelectionChangedCause.keyboard => false,
      _ when widget.readOnly && selection.isCollapsed => false,
      _ when !widget.enabled => false,
      SelectionChangedCause.longPress => true,
      _ => _controller.text.isNotEmpty,
    };
    if (show != _showHandles) setState(() => _showHandles = show);
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call("");
  }

  Set<WidgetState> get _states => {
    if (_hovered) WidgetState.hovered,
    if (_focusNode.hasFocus) WidgetState.focused,
    if (!widget.enabled) WidgetState.disabled,
    if (widget.error != null) WidgetState.error,
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final target = MochiButtonMetrics.of(widget.size, touch: theme.touch, density: theme.density);

    // Sizes come from the theme, so switching scales would otherwise jump.
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
    final primary = colors.of(MochiIntent.primary);
    final danger = colors.of(MochiIntent.danger);
    final textStyle = m.textStyle(theme.typography).copyWith(color: colors.foreground);
    final radius = m.radius(g.radius);
    final lineHeight = (textStyle.fontSize ?? 14) * (textStyle.height ?? 1.4);
    // One line sits centred in a box as tall as a button; more lines keep that padding.
    final verticalPadding = ((m.height - lineHeight) / 2 - g.borderWidth).clamp(0.0, double.infinity);
    final text = _controller.text;
    final maxLength = widget.maxLength;

    final editable = EditableText(
      key: editableTextKey,
      controller: _controller,
      focusNode: _focusNode,
      style: textStyle,
      strutStyle: StrutStyle.fromTextStyle(textStyle, forceStrutHeight: true),
      cursorColor: primary.base,
      backgroundCursorColor: colors.mutedForeground,
      selectionColor: primary.base.withValues(alpha: 0.3),
      readOnly: widget.readOnly || !widget.enabled,
      obscureText: widget.obscureText,
      autofocus: widget.autofocus,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: [
        ...?widget.inputFormatters,
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      textAlign: widget.textAlign,
      autofillHints: widget.autofillHints,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
      onSelectionChanged: _handleSelectionChanged,
      selectionControls: _selectionControls,
      showSelectionHandles: _showHandles,
      // The gesture detector around the box handles the pointer, so the whole box is a target.
      rendererIgnoresPointer: true,
      enableInteractiveSelection: widget.enabled,
      cursorWidth: 2,
      cursorRadius: const Radius.circular(1),
      contextMenuBuilder: (context, editable) => _TextContextMenu(editable: editable),
    );

    final hint = widget.hint;
    final field = Stack(
      children: [
        if (hint != null && text.isEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: Text(
                hint,
                style: textStyle.copyWith(color: colors.mutedForeground),
                textAlign: widget.textAlign,
                maxLines: widget.maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        editable,
      ],
    );

    final box = MochiStateTransition(
      states: _states,
      duration: theme.motion.stateDuration,
      builder: (context, blend) => MochiFocusRing(
        // A field shows its ring whenever it is focused, not only from the keyboard: it is where
        // the typing goes.
        visible: blend.contains(WidgetState.focused),
        radius: radius,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: colors.surface,
            shape: RoundedSuperellipseBorder(
              borderRadius: radius,
              side: BorderSide(
                width: g.borderWidth,
                color: blend.color(
                  (st) => switch (st) {
                    _ when st.contains(WidgetState.error) => danger.base,
                    _ when st.contains(WidgetState.focused) => primary.base,
                    _ when st.contains(WidgetState.hovered) => Color.lerp(
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
          // As tall as a button of the same size, with a single line centred in it; the padding
          // only matters once several lines push the box taller.
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: m.height),
            child: Align(
              heightFactor: 1,
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: m.horizontalPadding,
                  // A single line is centred by the minimum height alone, so the × appearing
                  // beside it can't push the box taller.
                  vertical: widget.maxLines == 1 ? 0 : verticalPadding,
                ),
                child: IconTheme.merge(
                  data: IconThemeData(color: colors.mutedForeground, size: m.iconSize),
                  child: Row(
                    spacing: m.gap,
                    crossAxisAlignment: widget.maxLines == 1
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      ?widget.prefix,
                      Expanded(child: field),
                      if (widget.clearable && text.isNotEmpty && widget.enabled && !widget.readOnly)
                        MochiCloseButton(
                          // Grows with the field, a little inside its height, so it stays an easy
                          // target rather than a speck beside the text.
                          metrics: MochiCloseButtonMetrics(diameter: m.height - 8, iconSize: m.iconSize),
                          onPress: _clear,
                        ),
                      ?widget.suffix,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final interactive = MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.text : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: IgnorePointer(
        ignoring: !widget.enabled,
        child: _gestures.buildGestureDetector(behavior: HitTestBehavior.translucent, child: box),
      ),
    );

    final error = widget.error;
    final description = widget.description;
    final below = error != null || description != null || maxLength != null;
    final small = theme.typography.body.xs;

    return Opacity(
      opacity: widget.enabled ? 1 : 0.4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: g.space.xs2,
        children: [
          if (widget.label case final label?)
            DefaultTextStyle.merge(
              style: theme.typography.body.sm.withWeight(FontWeight.w600).copyWith(color: colors.foreground),
              child: label,
            ),
          interactive,
          if (below)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: g.space.xs,
              children: [
                Expanded(
                  child: error != null
                      ? Text(error, style: small.copyWith(color: danger.onSoft))
                      : DefaultTextStyle.merge(
                          style: small.copyWith(color: colors.mutedForeground),
                          child: description ?? const SizedBox.shrink(),
                        ),
                ),
                if (maxLength != null)
                  Text(
                    "${text.characters.length}/$maxLength",
                    style: small.copyWith(color: colors.mutedForeground),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  void _requestKeyboard() => _editable?.requestKeyboard();
}

class _GestureBuilder extends TextSelectionGestureDetectorBuilder {
  _GestureBuilder(this._state) : super(delegate: _state);

  final _MochiTextFieldState _state;

  @override
  void onSingleTapUp(TapDragUpDetails details) {
    super.onSingleTapUp(details);
    _state._requestKeyboard();
  }
}

/// Right click on desktop, a long press on touch: cut, copy, paste and select all, in a
/// [MochiMenu] on a [MochiPopoverSurface] at the pointer.
class _TextContextMenu extends StatelessWidget {
  const _TextContextMenu({required this.editable});

  final EditableTextState editable;

  @override
  Widget build(BuildContext context) {
    final strings = MochiTheme.maybeRead(context)?.strings ?? MochiStrings.standard;
    final offered = {for (final item in editable.contextMenuButtonItems) item.type: item};
    // The four edits always appear, in the same order, greyed out when they don't apply (nothing
    // selected to cut or copy): a menu whose rows come and go with the selection is harder to
    // learn than one that says what isn't possible right now. Anything else the platform offers
    // follows them.
    final items = [
      for (final (type, label) in [
        (ContextMenuButtonType.cut, strings.cut),
        (ContextMenuButtonType.copy, strings.copy),
        (ContextMenuButtonType.paste, strings.paste),
        (ContextMenuButtonType.selectAll, strings.selectAll),
      ])
        MochiMenuItem(title: Text(label), closeOnPress: false, onPress: offered[type]?.onPressed),
      for (final item in editable.contextMenuButtonItems)
        if (item.type == ContextMenuButtonType.custom && item.label != null)
          MochiMenuItem(title: Text(item.label!), closeOnPress: false, onPress: item.onPressed),
    ];

    // In the same tap region group as the field, so pressing an item doesn't count as a tap
    // outside it and take its focus away first. A tap anywhere else puts the menu away.
    return TextFieldTapRegion(
      onTapOutside: (_) => ContextMenuController.removeAny(),
      child: CustomSingleChildLayout(
        delegate: DesktopTextSelectionToolbarLayoutDelegate(
          anchor: editable.contextMenuAnchors.primaryAnchor,
        ),
        child: MochiPopoverSurface(child: MochiMenu(minWidth: 140, children: items)),
      ),
    );
  }
}

final _selectionControls = _MochiSelectionControls();

/// The touch selection handles: a dot hanging below each end of the selection.
class _MochiSelectionControls extends TextSelectionControls with TextSelectionHandleControls {
  static const _size = 18.0;

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) {
    final color =
        MochiTheme.maybeRead(context)?.colors.of(MochiIntent.primary).base ?? const Color(0xFF1E66F5);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: SizedBox.square(
        dimension: _size,
        child: DecoratedBox(
          decoration: ShapeDecoration(color: color, shape: const CircleBorder()),
        ),
      ),
    );
  }

  // The dot's top centre touches the bottom of the line it marks.
  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) => const Offset(_size / 2, 0);

  @override
  Size getHandleSize(double textLineHeight) => const Size.square(_size);
}
