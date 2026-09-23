import "package:flutter/widgets.dart";

import "../theme/responsive.dart";
import "../theme/size.dart";
import "../theme/styles/button_style.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "calendar.dart";
import "field_frame.dart";
import "focus_ring.dart";
import "popover.dart";
import "sheet.dart";
import "state_transition.dart";
import "tappable.dart";
import "value_transition.dart";

/// A field that opens a [MochiCalendar]: the date on a solve, the week a statistic covers.
///
/// Where the calendar opens depends on the room: a popover under the field on a desktop-sized
/// screen, a sheet up from the bottom on a phone — the same rule `showMochiModal` follows, and
/// for the same reason. What adapts is where it is shown, not what it is.
///
/// Looks like a [MochiTextField] of the same size, so a date and a name line up in one form.
///
/// ```dart
/// MochiDatePicker.single(
///   label: const Text("Session started"),
///   value: started,
///   onChanged: (day) => setState(() => started = day),
/// )
/// ```
class MochiDatePicker extends StatefulWidget {
  /// One day.
  const MochiDatePicker.single({
    super.key,
    DateTime? value,
    ValueChanged<DateTime>? onChanged,
    this.format,
    this.label,
    this.hint,
    this.description,
    this.error,
    this.first,
    this.last,
    this.enabledDay,
    this.firstDayOfWeek = DateTime.monday,
    this.intent = MochiIntent.primary,
    this.size = MochiSize.md,
    this.enabled = true,
    this.autofocus = false,
  }) : _day = value,
       _range = null,
       _onDay = onChanged,
       _onRange = null;

  /// A run of days, which the calendar takes in two presses or one drag.
  const MochiDatePicker.range({
    super.key,
    MochiDateRange? value,
    ValueChanged<MochiDateRange>? onChanged,
    this.format,
    this.label,
    this.hint,
    this.description,
    this.error,
    this.first,
    this.last,
    this.enabledDay,
    this.firstDayOfWeek = DateTime.monday,
    this.intent = MochiIntent.primary,
    this.size = MochiSize.md,
    this.enabled = true,
    this.autofocus = false,
  }) : _day = null,
       _range = value,
       _onDay = null,
       _onRange = onChanged;

  final DateTime? _day;
  final MochiDateRange? _range;
  final ValueChanged<DateTime>? _onDay;
  final ValueChanged<MochiDateRange>? _onRange;

  /// How a day is written in the field. Defaults to `strings.date`.
  final String Function(DateTime day)? format;

  final Widget? label;

  /// Shown while nothing is picked. Defaults to `strings.pickDate`.
  final String? hint;

  final Widget? description;
  final String? error;

  /// Passed through to the calendar.
  final DateTime? first;
  final DateTime? last;
  final bool Function(DateTime day)? enabledDay;
  final int firstDayOfWeek;

  final MochiIntent intent;

  /// Matches [MochiTextField.size].
  final MochiSize size;

  final bool enabled;
  final bool autofocus;

  bool get _isRange => _onRange != null || _range != null;

  @override
  State<MochiDatePicker> createState() => _MochiDatePickerState();
}

class _MochiDatePickerState extends State<MochiDatePicker> {
  bool _open = false;

  String _say(BuildContext context, DateTime day) {
    if (widget.format case final format?) return format(day);

    final strings = context.theme.strings;
    return strings.date(day.day, strings.months[day.month - 1], day.year);
  }

  /// What the field reads while it is shut.
  String? _text(BuildContext context) {
    if (widget._isRange) {
      final range = widget._range;
      if (range == null) return null;
      final end = range.end;

      // Whatever the two ends share is written once: two full dates side by side don't fit a
      // field, and an ellipsis in the middle of a date says nothing at all.
      if (end == null) return _say(context, range.start);
      if (widget.format case final format?) return "${format(range.start)} – ${format(end)}";

      final strings = context.theme.strings;
      return strings.dateRange(range.start, end, strings.monthsShort);
    }

    return widget._day == null ? null : _say(context, widget._day!);
  }

  Widget _calendar({required VoidCallback close}) => widget._isRange
      ? MochiCalendar.range(
          value: widget._range,
          first: widget.first,
          last: widget.last,
          enabledDay: widget.enabledDay,
          firstDayOfWeek: widget.firstDayOfWeek,
          intent: widget.intent,
          onChanged: (range) {
            widget._onRange?.call(range);
            // A half-made range stays open for its second end; a finished one has said all it
            // has to say.
            if (range.complete) close();
          },
        )
      : MochiCalendar.single(
          value: widget._day,
          first: widget.first,
          last: widget.last,
          enabledDay: widget.enabledDay,
          firstDayOfWeek: widget.firstDayOfWeek,
          intent: widget.intent,
          autofocus: true,
          onChanged: (day) {
            widget._onDay?.call(day);
            close();
          },
        );

  Future<void> _openSheet() async {
    setState(() => _open = true);
    await showMochiSheet(
      context,
      // The route carries a sheet the same way a dialog route carries a dialog: the panel is the
      // builder's to return.
      builder: (context) => MochiSheet(
        padding: EdgeInsets.all(context.theme.geometry.space.md),
        child: _calendar(close: () => Navigator.of(context).pop()),
      ),
    );
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final target = MochiButtonMetrics.of(widget.size, touch: theme.touch, density: theme.density);
    // A phone has no room beside the field for a panel, so the calendar comes up from the bottom
    // instead; anything wider gets a popover, which leaves the field in view.
    final sheet = context.responsive(mobile: true, tablet: false);

    return MochiFieldFrame(
      label: widget.label,
      description: widget.description,
      error: widget.error,
      enabled: widget.enabled,
      child: MochiValueTransition(
        value: target,
        lerp: MochiButtonMetrics.lerp,
        duration: theme.motion.sizeDuration,
        curve: theme.motion.sizeCurve,
        builder: (context, m, _) => sheet
            ? _Field(
                text: _text(context),
                hint: widget.hint,
                maxLines: widget._isRange ? 2 : 1,
                metrics: m,
                open: _open,
                error: widget.error != null,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                onPress: _openSheet,
              )
            : MochiPopover(
                side: MochiPopoverSide.bottom,
                align: MochiPopoverAlign.start,
                onOpen: () => setState(() => _open = true),
                onClose: () => setState(() => _open = false),
                popoverBuilder: (context) => SizedBox(
                  width: 300,
                  child: _calendar(close: () => MenuController.maybeOf(context)?.close()),
                ),
                builder: (context, anchor, _) => _Field(
                  text: _text(context),
                  hint: widget.hint,
                  maxLines: widget._isRange ? 2 : 1,
                  metrics: m,
                  open: _open,
                  error: widget.error != null,
                  enabled: widget.enabled,
                  autofocus: widget.autofocus,
                  focusNode: anchor.focusNode,
                  onPress: anchor.toggle,
                ),
              ),
      ),
    );
  }
}

/// The box that opens it: a text field's look, with a calendar at its end.
class _Field extends StatelessWidget {
  const _Field({
    required this.text,
    required this.hint,
    required this.maxLines,
    required this.metrics,
    required this.open,
    required this.error,
    required this.enabled,
    required this.autofocus,
    required this.onPress,
    this.focusNode,
  });

  final String? text;
  final String? hint;

  /// One line for a day, two for a run of them: a range that spans two years has nothing left to
  /// shorten, and a date cut off by an ellipsis says nothing at all.
  final int maxLines;

  final MochiButtonMetrics metrics;
  final bool open;
  final bool error;
  final bool enabled;
  final bool autofocus;
  final VoidCallback onPress;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;
    final primary = colors.of(MochiIntent.primary);
    final danger = colors.of(MochiIntent.danger);
    final radius = metrics.radius(g.radius);
    final text = this.text;

    return MochiTappable(
      enabled: enabled,
      focusNode: focusNode,
      autofocus: autofocus,
      // A field, not a button: it tints its border rather than growing.
      scaleOnPress: false,
      onPress: onPress,
      semanticLabel: text,
      builder: (context, states, _) => MochiStateTransition(
        states: {...states, if (open) WidgetState.selected, if (error) WidgetState.error},
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
              constraints: BoxConstraints(minHeight: metrics.height),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.horizontalPadding,
                  vertical: metrics.gap / 2,
                ),
                child: Row(
                  spacing: metrics.gap,
                  children: [
                    Expanded(
                      child: Text(
                        text ?? hint ?? theme.strings.pickDate,
                        maxLines: maxLines,
                        overflow: TextOverflow.ellipsis,
                        style: metrics
                            .textStyle(theme.typography)
                            .copyWith(color: text == null ? colors.mutedForeground : colors.foreground),
                      ),
                    ),
                    Icon(theme.icons.calendar, size: metrics.iconSize, color: colors.mutedForeground),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
