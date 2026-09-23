import "package:flutter/widgets.dart";

import "../theme/responsive.dart";
import "../theme/size.dart";
import "../theme/styles/button_style.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "button.dart";
import "calendar.dart";
import "divider.dart";
import "field_frame.dart";
import "picker_field.dart";
import "picker_sheet.dart";
import "popover.dart";
import "time_picker.dart";
import "value_transition.dart";

/// A field that picks a day and a time at once: when a session started, when a reminder goes off.
///
/// A [MochiCalendar] over a [MochiTimeWheel] in one panel — a popover from tablet width up, a
/// sheet on a phone, the same rule [MochiDatePicker] and [MochiTimePicker] follow. Unlike those
/// two, it does not close of its own accord: a day on its own is not the answer and neither is a
/// time, so the panel stays until the button under it says the answer is done.
///
/// ```dart
/// MochiDateTimePicker(
///   label: const Text("Starts"),
///   value: starts,
///   onChanged: (at) => setState(() => starts = at),
/// )
/// ```
class MochiDateTimePicker extends StatefulWidget {
  const MochiDateTimePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.format,
    this.label,
    this.hint,
    this.description,
    this.error,
    this.first,
    this.last,
    this.enabledDay,
    this.firstDayOfWeek = DateTime.monday,
    this.showSeconds = false,
    this.use24HourFormat = true,
    this.minuteStep = 1,
    this.intent = MochiIntent.primary,
    this.size = MochiSize.md,
    this.enabled = true,
    this.autofocus = false,
  });

  /// Null leaves the field empty until something is picked.
  final DateTime? value;

  final ValueChanged<DateTime>? onChanged;

  /// How the moment is written in the field. Defaults to the day the way `strings.date` writes it
  /// with the time after it.
  final String Function(DateTime at)? format;

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

  /// Passed through to the wheels.
  final bool showSeconds;
  final bool use24HourFormat;
  final int minuteStep;

  final MochiIntent intent;

  /// Matches [MochiTextField.size].
  final MochiSize size;

  final bool enabled;
  final bool autofocus;

  @override
  State<MochiDateTimePicker> createState() => _MochiDateTimePickerState();
}

class _MochiDateTimePickerState extends State<MochiDateTimePicker> {
  bool _open = false;

  /// What a half-made answer stands on: picking a time before a day means today, and a day before
  /// a time means the top of the working morning. Taken once, so a panel left open overnight
  /// doesn't quietly change which day it is talking about.
  late final DateTime _today = DateTime.now();

  /// The moment a panel opens on: what is already set, or today at the top of the working
  /// morning when nothing is.
  DateTime get _start => widget.value ?? _today.copyWith(hour: 9, minute: 0, second: 0);

  void _emit(DateTime at) => widget.onChanged?.call(at);

  String _say(BuildContext context) {
    final value = widget.value;
    if (value == null) return widget.hint ?? context.theme.strings.pickDate;
    if (widget.format case final format?) return format(value);

    final strings = context.theme.strings;
    final day = strings.date(value.day, strings.months[value.month - 1], value.year);
    final minute = value.minute.toString().padLeft(2, "0");
    final seconds = widget.showSeconds ? ":${value.second.toString().padLeft(2, "0")}" : "";
    final time = widget.use24HourFormat
        ? "${value.hour.toString().padLeft(2, "0")}:$minute$seconds"
        : "${MochiTime.fromDateTime(value).hourOf12}:$minute$seconds "
              "${value.hour >= 12 ? strings.pm : strings.am}";

    return "$day $time";
  }

  /// The calendar over the wheels, taking the moment it shows and where a change goes: a popover
  /// reports straight back, a sheet writes to its draft.
  Widget _body(DateTime value, ValueChanged<DateTime> onChanged) {
    final g = context.theme.geometry;
    final time = MochiTime.fromDateTime(value);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MochiCalendar.single(
          value: value,
          first: widget.first,
          last: widget.last,
          enabledDay: widget.enabledDay,
          firstDayOfWeek: widget.firstDayOfWeek,
          intent: widget.intent,
          autofocus: true,
          // The time it already has, on the day just pressed.
          onChanged: (day) => onChanged(time.onDay(day)),
        ),
        MochiDivider(indent: g.space.sm, endIndent: g.space.sm),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: g.space.sm, vertical: g.space.xs),
          child: MochiTimeWheel(
            value: time,
            showSeconds: widget.showSeconds,
            use24HourFormat: widget.use24HourFormat,
            minuteStep: widget.minuteStep,
            intent: widget.intent,
            onChanged: (next) => onChanged(next.onDay(value)),
          ),
        ),
      ],
    );
  }

  /// The popover's panel: the same body, plus the button that shuts it. A day is not an answer
  /// and neither is a time, so nothing here closes of its own accord.
  Widget _panel(VoidCallback close) {
    final theme = context.theme;
    final g = theme.geometry;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _body(_start, _emit),
        Padding(
          padding: EdgeInsets.fromLTRB(g.space.sm, g.space.xs, g.space.sm, g.space.sm),
          child: SizedBox(
            width: double.infinity,
            child: MochiButton(intent: widget.intent, onPress: close, child: Text(theme.strings.ok)),
          ),
        ),
      ],
    );
  }

  Future<void> _openSheet() async {
    setState(() => _open = true);
    // A sheet keeps its own draft and hands it back on OK; see showPickerSheet.
    final picked = await showPickerSheet<DateTime>(
      context,
      initial: _start,
      intent: widget.intent,
      body: (context, at, set) => _body(at, set),
    );
    if (picked != null) _emit(picked);
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final target = MochiButtonMetrics.of(widget.size, touch: theme.touch, density: theme.density);
    final sheet = context.responsive(mobile: true, tablet: false);
    final enabled = widget.enabled && widget.onChanged != null;

    return MochiFieldFrame(
      label: widget.label,
      description: widget.description,
      error: widget.error,
      enabled: enabled,
      child: MochiValueTransition(
        value: target,
        lerp: MochiButtonMetrics.lerp,
        duration: theme.motion.sizeDuration,
        curve: theme.motion.sizeCurve,
        builder: (context, m, _) => sheet
            ? PickerField(
                text: _say(context),
                icon: theme.icons.calendar,
                empty: widget.value == null,
                metrics: m,
                open: _open,
                error: widget.error != null,
                enabled: enabled,
                autofocus: widget.autofocus,
                onPress: _openSheet,
              )
            : MochiPopover(
                side: MochiPopoverSide.bottom,
                align: MochiPopoverAlign.start,
                onOpen: () => setState(() => _open = true),
                onClose: () => setState(() => _open = false),
                popoverBuilder: (context) =>
                    SizedBox(width: 300, child: _panel(() => MenuController.maybeOf(context)?.close())),
                builder: (context, anchor, _) => PickerField(
                  text: _say(context),
                  icon: theme.icons.calendar,
                  empty: widget.value == null,
                  metrics: m,
                  open: _open,
                  error: widget.error != null,
                  enabled: enabled,
                  autofocus: widget.autofocus,
                  focusNode: anchor.focusNode,
                  onPress: anchor.toggle,
                ),
              ),
      ),
    );
  }
}
