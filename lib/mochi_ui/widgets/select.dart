import "dart:math" as math;

import "dart:async";

import "package:flutter/services.dart";
import "package:flutter/widgets.dart";

import "../theme/size.dart";
import "../theme/styles/button_style.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "badge.dart";
import "field_frame.dart";
import "focus_ring.dart";
import "menu.dart";
import "popover.dart";
import "state_transition.dart";
import "tappable.dart";
import "value_transition.dart";

/// One of the choices in a [MochiSelect] or [MochiMultiSelect].
@immutable
class MochiSelectOption<T> {
  const MochiSelectOption({required this.value, required this.label, this.prefix, this.enabled = true});

  final T value;

  /// Shown in the list, and in the field once chosen (as a badge in a [MochiMultiSelect]).
  final String label;

  /// Before the label in the list and in the field: usually an icon.
  final Widget? prefix;

  final bool enabled;
}

/// One choice from a list that drops down under a field: an alert type, a puzzle.
///
/// Looks like a [MochiTextField] of the same [size] — label above, description or error below,
/// the same height as a button — so it lines up with fields and buttons in a form. The list is a
/// [MochiMenu] at least as wide as the field, with a check beside the chosen row. From the
/// keyboard, Enter, Space or an arrow opens it with the chosen row focused.
///
/// Fills the width it is given; with no bound (a row's trailing slot) it is as wide as its
/// longest option, so it doesn't change width as the choice changes.
class MochiSelect<T> extends StatefulWidget {
  const MochiSelect({
    super.key,
    required this.value,
    required this.onChanged,
    required this.options,
    this.label,
    this.hint,
    this.description,
    this.error,
    this.size = MochiSize.md,
    this.enabled = true,
    this.autofocus = false,
    this.maxListHeight = 320,
  });

  /// The chosen option's value, or null for none (the [hint] shows).
  final T? value;

  /// Null disables the select.
  final ValueChanged<T>? onChanged;

  final List<MochiSelectOption<T>> options;
  final Widget? label;
  final String? hint;
  final Widget? description;
  final String? error;
  final MochiSize size;
  final bool enabled;
  final bool autofocus;

  /// The list scrolls past this height.
  final double maxListHeight;

  @override
  State<MochiSelect<T>> createState() => _MochiSelectState<T>();
}

class _MochiSelectState<T> extends State<MochiSelect<T>> with _Opening {
  @override
  Widget build(BuildContext context) {
    final options = widget.options;
    final chosen = options.where((o) => o.value == widget.value).firstOrNull;
    final onChanged = widget.onChanged;
    final enabled = widget.enabled && onChanged != null;
    final focusValue = chosen?.value ?? options.where((o) => o.enabled).firstOrNull?.value;

    return _SelectField(
      label: widget.label,
      description: widget.description,
      error: widget.error,
      size: widget.size,
      enabled: enabled,
      autofocus: widget.autofocus,
      open: _open,
      maxListHeight: widget.maxListHeight,
      semanticValue: chosen?.label,
      widest: [?widget.hint, for (final option in options) option.label],
      anyPrefix: options.any((o) => o.prefix != null),
      onPointerDown: pointerDown,
      onPointerUp: pointerUp,
      onOpenRequested: openRequested,
      onOpen: () => setState(() => _open = true),
      onClose: () => setState(() => _open = false),
      rows: (context) => [
        for (final option in options)
          _row(
            context,
            option,
            selected: option == chosen,
            autofocus: _keyboard && option.value == focusValue,
            closeOnPress: true,
            onPress: () {
              if (option != chosen) onChanged?.call(option.value);
            },
          ),
      ],
      content: (context, m) => chosen == null
          ? _Hint(widget.hint, m)
          : Row(
              spacing: m.gap,
              children: [
                ?chosen.prefix,
                Expanded(child: Text(chosen.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );
  }
}

/// Several choices from a list that drops down under a field, shown in the field as badges.
///
/// The list stays open while options are ticked and unticked; a badge's × takes its option out
/// without opening it. Otherwise it behaves like [MochiSelect], and grows taller as the badges
/// wrap onto more lines.
class MochiMultiSelect<T> extends StatefulWidget {
  const MochiMultiSelect({
    super.key,
    required this.values,
    required this.onChanged,
    required this.options,
    this.label,
    this.hint,
    this.description,
    this.error,
    this.size = MochiSize.md,
    this.enabled = true,
    this.autofocus = false,
    this.maxListHeight = 320,
  });

  /// The chosen options' values.
  final Set<T> values;

  /// Called with the whole new set. Null disables the select.
  final ValueChanged<Set<T>>? onChanged;

  final List<MochiSelectOption<T>> options;
  final Widget? label;
  final String? hint;
  final Widget? description;
  final String? error;
  final MochiSize size;
  final bool enabled;
  final bool autofocus;

  /// The list scrolls past this height.
  final double maxListHeight;

  @override
  State<MochiMultiSelect<T>> createState() => _MochiMultiSelectState<T>();
}

class _MochiMultiSelectState<T> extends State<MochiMultiSelect<T>> with _Opening {
  @override
  Widget build(BuildContext context) {
    final options = widget.options;
    final values = widget.values;
    // In the order of the list, not the order they were picked, so badges don't shuffle.
    final chosen = [
      for (final option in options)
        if (values.contains(option.value)) option,
    ];
    final onChanged = widget.onChanged;
    final enabled = widget.enabled && onChanged != null;
    final focusValue = chosen.firstOrNull?.value ?? options.where((o) => o.enabled).firstOrNull?.value;

    void toggle(T value) =>
        onChanged?.call(values.contains(value) ? ({...values}..remove(value)) : {...values, value});

    return _SelectField(
      label: widget.label,
      description: widget.description,
      error: widget.error,
      size: widget.size,
      enabled: enabled,
      autofocus: widget.autofocus,
      open: _open,
      maxListHeight: widget.maxListHeight,
      semanticValue: chosen.map((o) => o.label).join(", "),
      widest: [?widget.hint, for (final option in options) option.label],
      anyPrefix: false,
      badges: chosen.isNotEmpty,
      onPointerDown: pointerDown,
      onPointerUp: pointerUp,
      onOpenRequested: openRequested,
      onOpen: () => setState(() => _open = true),
      onClose: () => setState(() => _open = false),
      rows: (context) => [
        for (final option in options)
          _row(
            context,
            option,
            selected: values.contains(option.value),
            autofocus: _keyboard && option.value == focusValue,
            closeOnPress: false,
            onPress: () => toggle(option.value),
          ),
      ],
      content: (context, m) => chosen.isEmpty
          ? _Hint(widget.hint, m)
          // The badges' × are for the pointer; from the keyboard the list does the same.
          : ExcludeFocus(
              child: Wrap(
                spacing: context.theme.geometry.space.xs2,
                runSpacing: context.theme.geometry.space.xs2,
                children: [
                  for (final option in chosen)
                    MochiBadge(
                      size: _badgeSize(widget.size),
                      prefix: option.prefix,
                      onDelete: enabled ? () => toggle(option.value) : null,
                      child: Text(option.label),
                    ),
                ],
              ),
            ),
    );
  }
}

/// A step or two under the field, so a badge sits in it with even room around.
MochiSize _badgeSize(MochiSize size) => switch (size) {
  MochiSize.xs || MochiSize.sm => MochiSize.xs,
  MochiSize.md => MochiSize.sm,
  MochiSize.lg => MochiSize.md,
};

/// Whether the list is open, and whether it was opened from the keyboard.
mixin _Opening<W extends StatefulWidget> on State<W> {
  bool _open = false;

  // A pointer press that opens the list leaves focus on the field; one from the keyboard moves it
  // to the chosen row, where the arrows carry on from. Focusing the row after a click would put a
  // focus ring on it for no reason.
  bool _keyboard = false;
  bool _pointer = false;

  void pointerDown() => _pointer = true;

  // After the release has been handled, which is when a tap opens the list: a press that opened
  // nothing (a badge's ×) mustn't count against the next open from the keyboard.
  void pointerUp() => scheduleMicrotask(() => _pointer = false);

  void openRequested() {
    _keyboard = !_pointer;
    _pointer = false;
  }
}

Widget _row<T>(
  BuildContext context,
  MochiSelectOption<T> option, {
  required bool selected,
  required bool autofocus,
  required bool closeOnPress,
  required VoidCallback onPress,
}) {
  return MochiMenuItem(
    prefix: option.prefix,
    title: Text(option.label),
    // Always there, only shown when chosen, so ticking a row can't widen the list.
    suffix: Opacity(opacity: selected ? 1 : 0, child: Icon(context.theme.icons.check)),
    selected: selected,
    enabled: option.enabled,
    autofocus: autofocus,
    closeOnPress: closeOnPress,
    onPress: onPress,
  );
}

class _Hint extends StatelessWidget {
  const _Hint(this.hint, this.metrics);

  final String? hint;
  final MochiButtonMetrics metrics;

  @override
  Widget build(BuildContext context) => Text(
    hint ?? "",
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(color: context.theme.colors.mutedForeground),
  );
}

/// The field both selects share: label, the box that opens the list, and the line below.
class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.description,
    required this.error,
    required this.size,
    required this.enabled,
    required this.autofocus,
    required this.open,
    required this.maxListHeight,
    required this.semanticValue,
    required this.widest,
    required this.anyPrefix,
    required this.onPointerDown,
    required this.onPointerUp,
    required this.onOpenRequested,
    required this.onOpen,
    required this.onClose,
    required this.rows,
    required this.content,
    this.badges = false,
  });

  final Widget? label;
  final Widget? description;
  final String? error;
  final MochiSize size;
  final bool enabled;
  final bool autofocus;
  final bool open;
  final double maxListHeight;
  final String? semanticValue;

  /// Every text the box may show, to size it when its width is unbounded.
  final List<String> widest;
  final bool anyPrefix;

  /// Whether [content] is a wrap of badges, which sits closer to the box's edges than text.
  final bool badges;

  final VoidCallback onPointerDown;
  final VoidCallback onPointerUp;
  final VoidCallback onOpenRequested;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final List<Widget> Function(BuildContext context) rows;
  final Widget Function(BuildContext context, MochiButtonMetrics metrics) content;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final target = MochiButtonMetrics.of(size, touch: theme.touch, density: theme.density);

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
    final select = MochiPopoverMenu(
      side: MochiPopoverSide.bottom,
      align: MochiPopoverAlign.start,
      matchAnchorWidth: true,
      minWidth: 0,
      constraints: BoxConstraints(maxHeight: maxListHeight),
      onOpen: onOpen,
      onClose: onClose,
      menuBuilder: rows,
      builder: (context, anchor, _) {
        void show() {
          if (anchor.isOpen) return anchor.close();
          onOpenRequested();
          anchor.open();
        }

        void showFromKeys() {
          if (anchor.isOpen) return;
          onOpenRequested();
          anchor.open();
        }

        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowDown): showFromKeys,
            const SingleActivator(LogicalKeyboardKey.arrowUp): showFromKeys,
          },
          child: Listener(
            onPointerDown: (_) => onPointerDown(),
            onPointerUp: (_) => onPointerUp(),
            onPointerCancel: (_) => onPointerUp(),
            child: Semantics(
              value: semanticValue,
              expanded: open,
              child: MochiTappable(
                enabled: enabled,
                focusNode: anchor.focusNode,
                autofocus: autofocus,
                // A field, not a button: it tints its border rather than growing.
                scaleOnPress: false,
                onPress: show,
                builder: (context, states, _) => _box(context, theme, m, states),
              ),
            ),
          ),
        );
      },
    );

    Widget frame(Widget box) =>
        MochiFieldFrame(label: label, description: description, error: error, enabled: enabled, child: box);

    // Outside the frame: what is measured here is the room the field has, not what the frame
    // hands down.
    return LayoutBuilder(
      builder: (context, constraints) => constraints.hasBoundedWidth
          ? frame(select)
          : SizedBox(width: _naturalWidth(context, theme, m), child: frame(select)),
    );
  }

  /// Wide enough for the longest text the box may show, and its chevron.
  double _naturalWidth(BuildContext context, MochiTheme theme, MochiButtonMetrics m) {
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    );
    var text = 0.0;
    for (final label in widest) {
      painter
        ..text = TextSpan(text: label, style: m.textStyle(theme.typography))
        ..layout();
      if (painter.width > text) text = painter.width;
    }
    painter.dispose();

    return 2 * m.horizontalPadding +
        2 * theme.geometry.borderWidth +
        text +
        (anyPrefix ? m.iconSize + m.gap : 0) +
        m.gap +
        m.iconSize +
        // Rounding in text layout can otherwise tip the longest label into an ellipsis.
        1;
  }

  Widget _box(BuildContext context, MochiTheme theme, MochiButtonMetrics m, Set<WidgetState> states) {
    final colors = theme.colors;
    final g = theme.geometry;
    final primary = colors.of(MochiIntent.primary);
    final danger = colors.of(MochiIntent.danger);
    final radius = m.radius(g.radius);

    // Badges sit as far from the top and bottom as from the start, so a full row looks even.
    final badgeHeight = MochiBadgeMetrics.of(
      _badgeSize(size),
      touch: theme.touch,
      density: theme.density,
    ).height;
    final badgeInset = ((m.height - badgeHeight) / 2 - g.borderWidth).clamp(0.0, double.infinity);

    return MochiStateTransition(
      states: {...states, if (open) WidgetState.selected, if (error != null) WidgetState.error},
      duration: theme.motion.stateDuration,
      builder: (context, blend) => MochiFocusRing(
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
                    _ when st.contains(WidgetState.selected) => primary.base,
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
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: m.height),
            child: Align(
              heightFactor: 1,
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: badges
                    ? EdgeInsetsDirectional.fromSTEB(badgeInset, badgeInset, m.horizontalPadding, badgeInset)
                    : EdgeInsets.symmetric(horizontal: m.horizontalPadding),
                child: IconTheme.merge(
                  data: IconThemeData(color: colors.mutedForeground, size: m.iconSize),
                  child: DefaultTextStyle(
                    style: m.textStyle(theme.typography).copyWith(color: colors.foreground),
                    child: Row(
                      spacing: m.gap,
                      children: [
                        Expanded(child: content(context, m)),
                        // Turns to point up while the list is open.
                        Transform.rotate(
                          angle: blend.number((st) => st.contains(WidgetState.selected) ? 1 : 0) * math.pi,
                          child: Icon(theme.icons.chevronDown),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
