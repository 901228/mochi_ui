import "package:flutter/widgets.dart";

import "../theme/responsive.dart";
import "../theme/size.dart";
import "../theme/styles/button_style.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "calendar.dart";
import "field_frame.dart";
import "picker_field.dart";
import "picker_sheet.dart";
import "popover.dart";
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

  /// The calendar, taking the value it shows and where a press goes as parameters: a popover
  /// shows the picker's own value and reports straight back, a sheet shows its draft.
  Widget _calendar({
    required DateTime? day,
    required MochiDateRange? range,
    required ValueChanged<DateTime> onDay,
    required ValueChanged<MochiDateRange> onRange,
  }) => widget._isRange
      ? MochiCalendar.range(
          value: range,
          first: widget.first,
          last: widget.last,
          enabledDay: widget.enabledDay,
          firstDayOfWeek: widget.firstDayOfWeek,
          intent: widget.intent,
          onChanged: onRange,
        )
      : MochiCalendar.single(
          value: day,
          first: widget.first,
          last: widget.last,
          enabledDay: widget.enabledDay,
          firstDayOfWeek: widget.firstDayOfWeek,
          intent: widget.intent,
          autofocus: true,
          onChanged: onDay,
        );

  /// What a popover does with a press: report it, and close once there is nothing left to pick.
  Widget _livePopoverCalendar(VoidCallback close) => _calendar(
    day: widget._day,
    range: widget._range,
    onDay: (day) {
      widget._onDay?.call(day);
      close();
    },
    onRange: (range) {
      widget._onRange?.call(range);
      // A half-made range stays open for its second end; a finished one has said all it has to
      // say.
      if (range.complete) close();
    },
  );

  Future<void> _openSheet() async {
    setState(() => _open = true);

    // A sheet keeps its own draft and hands it back on OK; see showPickerSheet.
    if (widget._isRange) {
      final picked = await showPickerSheet<MochiDateRange?>(
        context,
        initial: widget._range,
        intent: widget.intent,
        answered: (range) => range?.complete ?? false,
        body: (context, range, set) => _calendar(day: null, range: range, onDay: (_) {}, onRange: set),
      );
      if (picked != null) widget._onRange?.call(picked);
    } else {
      final picked = await showPickerSheet<DateTime?>(
        context,
        initial: widget._day,
        intent: widget.intent,
        answered: (day) => day != null,
        body: (context, day, set) => _calendar(day: day, range: null, onDay: set, onRange: (_) {}),
      );
      if (picked != null) widget._onDay?.call(picked);
    }

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
            ? PickerField(
                text: _text(context) ?? widget.hint ?? theme.strings.pickDate,
                icon: theme.icons.calendar,
                empty: _text(context) == null,
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
                  child: _livePopoverCalendar(() => MenuController.maybeOf(context)?.close()),
                ),
                builder: (context, anchor, _) => PickerField(
                  text: _text(context) ?? widget.hint ?? theme.strings.pickDate,
                  icon: theme.icons.calendar,
                  empty: _text(context) == null,
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
