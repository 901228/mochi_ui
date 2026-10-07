import "dart:math" as math;

import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";

import "../theme/responsive.dart";
import "../theme/size.dart";
import "../theme/styles/button_style.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "../theme/typography.dart";
import "badge.dart";
import "field_frame.dart";
import "focus_ring.dart";
import "menu.dart";
import "menu_host.dart";
import "picker_sheet.dart";
import "popover.dart";
import "sheet.dart";
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
  /// On a phone: the same rows in a sheet. Choosing one is the whole errand, so a row both answers
  /// and puts the sheet away, as it does in the popover.
  Future<void> _showSheet(MochiSelectOption<T>? chosen, T? focusValue) async {
    setState(() => _open = true);
    final keyboard = _keyboard;
    await showMochiSheet<void>(
      context,
      builder: (context) => MochiSheet(
        title: widget.label,
        child: MenuHost(
          close: () => Navigator.of(context).pop(),
          child: MochiMenu(
            minWidth: 0,
            children: [
              for (final option in widget.options)
                _row(
                  context,
                  option,
                  selected: option == chosen,
                  autofocus: keyboard && option.value == focusValue,
                  closeOnPress: true,
                  onPress: () {
                    if (option != chosen) widget.onChanged?.call(option.value);
                  },
                ),
            ],
          ),
        ),
      ),
    );
    if (mounted) setState(() => _open = false);
  }

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
      onOpenSheet: () => _showSheet(chosen, focusValue),
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

/// How a [MochiMultiSelect] writes its choices in the box.
enum MochiMultiSelectDisplay {
  /// One badge per choice, each with a × that takes it out; the box grows as they wrap.
  badges,

  /// The labels on one line, joined by `strings.listSeparator` and cut with an ellipsis: the box
  /// stays one line tall, for a toolbar or a filter row where a growing field would shove
  /// everything around it. Taking a choice out is then the list's job alone.
  text,
}

/// Several choices from a list that drops down under a field, shown in the field as badges.
///
/// The list stays open while options are ticked and unticked; a badge's × takes its option out
/// without opening it. Otherwise it behaves like [MochiSelect], and grows taller as the badges
/// wrap onto more lines — or pass [display] `.text` for one line of labels instead.
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
    this.display = MochiMultiSelectDisplay.badges,
  });

  /// The chosen options' values.
  final Set<T> values;

  /// Badges, or one line of labels.
  final MochiMultiSelectDisplay display;

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
  /// On a phone: the same rows in a sheet, ticked into a draft that only leaves through OK — a
  /// sheet is a route and builds once, so it could not follow the parent's set as it changed, and
  /// a sheet covers the page, so it is answered rather than glanced at. Dragging it away drops it.
  Future<void> _showSheet(T? focusValue) async {
    setState(() => _open = true);
    final keyboard = _keyboard;
    final picked = await showPickerSheet<Set<T>>(
      context,
      title: widget.label,
      initial: widget.values,
      // The picker sheet centres its panel, which suits a calendar; rows run edge to edge.
      body: (context, draft, set) => SizedBox(
        width: double.infinity,
        child: MochiMenu(
          minWidth: 0,
          children: [
            for (final option in widget.options)
              _row(
                context,
                option,
                selected: draft.contains(option.value),
                autofocus: keyboard && option.value == focusValue,
                closeOnPress: false,
                onPress: () => set(
                  draft.contains(option.value)
                      ? ({...draft}..remove(option.value))
                      : {...draft, option.value},
                ),
              ),
          ],
        ),
      ),
    );
    if (picked != null && !setEquals(picked, widget.values)) widget.onChanged?.call(picked);
    if (mounted) setState(() => _open = false);
  }

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

    final asText = widget.display == MochiMultiSelectDisplay.text;
    final separator = context.theme.strings.listSeparator;

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
      semanticValue: chosen.map((o) => o.label).join(separator),
      // As text, the field is as wide as its longest label and the rest is ellipsized: one wide
      // enough for every label at once would be a toolbar's worth.
      widest: [
        ?widget.hint,
        if (asText)
          for (final option in options) option.label,
      ],
      widestBadges: [
        if (!asText)
          for (final option in options) option.label,
      ],
      anyBadgePrefix: !asText && options.any((o) => o.prefix != null),
      anyPrefix: false,
      badges: !asText && chosen.isNotEmpty,
      onPointerDown: pointerDown,
      onPointerUp: pointerUp,
      onOpenRequested: openRequested,
      onOpen: () => setState(() => _open = true),
      onClose: () => setState(() => _open = false),
      onOpenSheet: () => _showSheet(focusValue),
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
      content: (context, m) => switch (widget.display) {
        _ when chosen.isEmpty => _Hint(widget.hint, m),
        .text => Text(
          chosen.map((o) => o.label).join(separator),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // The badges' × are for the pointer; from the keyboard the list does the same.
        .badges => ExcludeFocus(
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
      },
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
    required this.onOpenSheet,
    required this.rows,
    required this.content,
    this.widestBadges = const [],
    this.anyBadgePrefix = false,
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

  /// Every label the box may show as a badge, which is wider than the same words as text: a
  /// multi-select sized from the text alone puts each badge on a line of its own and still
  /// overflows.
  final List<String> widestBadges;

  /// Whether a badge may carry an option's prefix, which widens it by an icon and a gap.
  final bool anyBadgePrefix;
  final bool anyPrefix;

  /// Whether [content] is a wrap of badges, which sits closer to the box's edges than text.
  final bool badges;

  final VoidCallback onPointerDown;
  final VoidCallback onPointerUp;
  final VoidCallback onOpenRequested;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  /// Shows the rows in a sheet instead, which is what a phone gets.
  final VoidCallback onOpenSheet;
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
    // A phone has no room under the field for a list, so the rows come up from the bottom
    // instead — the same breakpoint the date picker uses; anything wider keeps the field in view.
    final sheet = context.responsive(mobile: true, tablet: false);

    Widget field({FocusNode? focusNode, required VoidCallback onPress, required VoidCallback onKeys}) =>
        CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowDown): onKeys,
            const SingleActivator(LogicalKeyboardKey.arrowUp): onKeys,
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
                focusNode: focusNode,
                autofocus: autofocus,
                // A field, not a button: it tints its border rather than growing.
                scaleOnPress: false,
                onPress: onPress,
                builder: (context, states, _) => _box(context, theme, m, states),
              ),
            ),
          ),
        );

    void showSheet() {
      if (open) return;
      onOpenRequested();
      onOpenSheet();
    }

    final select = sheet
        ? field(onPress: showSheet, onKeys: showSheet)
        : MochiPopoverMenu(
            // The field opens its own sheet on a phone, with a draft for a multi-select.
            sheet: false,
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

              return field(focusNode: anchor.focusNode, onPress: show, onKeys: showFromKeys);
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
    double widestOf(List<String> labels, TextStyle style) {
      var widest = 0.0;
      for (final label in labels) {
        painter
          ..text = TextSpan(text: label, style: style)
          ..layout();
        if (painter.width > widest) widest = painter.width;
      }
      return widest;
    }

    final border = theme.geometry.borderWidth;
    final text = widestOf(widest, m.textStyle(theme.typography));
    final b = MochiBadgeMetrics.of(_badgeSize(size), touch: theme.touch, density: theme.density);
    final badgeText = widestOf(widestBadges, b.textStyle(theme.typography).withWeight(FontWeight.w600));
    painter.dispose();

    // The same sums [_box] and [MochiBadge] lay out: text sits between the box's paddings, a badge
    // starts at the badge inset and carries its own padding, border and ×.
    final asText = m.horizontalPadding + text + (anyPrefix ? m.iconSize + m.gap : 0);
    final asBadge = widestBadges.isEmpty
        ? 0.0
        : ((m.height - b.height) / 2 - border).clamp(0.0, double.infinity) +
              2 * border +
              b.horizontalPadding +
              (anyBadgePrefix ? b.iconSize + b.gap : 0) +
              badgeText +
              b.gap +
              b.close.diameter +
              (b.height - b.close.diameter) / 2 -
              border;

    return math.max(asText, asBadge) +
        m.horizontalPadding +
        2 * border +
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
            shape: g.shape(
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
