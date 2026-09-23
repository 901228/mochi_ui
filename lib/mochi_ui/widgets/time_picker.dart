import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";

import "../theme/responsive.dart";
import "../theme/size.dart";
import "../theme/styles/button_style.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "field_frame.dart";
import "focus_ring.dart";
import "popover.dart";
import "sheet.dart";
import "state_transition.dart";
import "tappable.dart";
import "value_transition.dart";

/// A time of day, to the second.
@immutable
class MochiTime implements Comparable<MochiTime> {
  const MochiTime({required this.hour, this.minute = 0, this.second = 0})
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60),
      assert(second >= 0 && second < 60);

  MochiTime.fromDateTime(DateTime date) : hour = date.hour, minute = date.minute, second = date.second;

  final int hour;
  final int minute;
  final int second;

  /// On a twelve-hour clock, where midnight and noon are both 12.
  int get hourOf12 => hour % 12 == 0 ? 12 : hour % 12;

  bool get isAfternoon => hour >= 12;

  /// The same day at this time.
  DateTime onDay(DateTime day) => DateTime(day.year, day.month, day.day, hour, minute, second);

  MochiTime copyWith({int? hour, int? minute, int? second}) =>
      MochiTime(hour: hour ?? this.hour, minute: minute ?? this.minute, second: second ?? this.second);

  @override
  int compareTo(MochiTime other) =>
      (hour * 3600 + minute * 60 + second).compareTo(other.hour * 3600 + other.minute * 60 + other.second);

  @override
  bool operator ==(Object other) =>
      other is MochiTime && hour == other.hour && minute == other.minute && second == other.second;

  @override
  int get hashCode => Object.hash(hour, minute, second);

  @override
  String toString() => "MochiTime($hour:$minute:$second)";
}

/// The columns you scroll to set a time: hours, minutes, and seconds if they matter.
///
/// The body of [MochiTimePicker], and a thing in its own right inside a sheet or a settings page.
/// Each column snaps to whole numbers and wraps round, so 23 is one notch from 00.
class MochiTimeWheel extends StatefulWidget {
  const MochiTimeWheel({
    super.key,
    required this.value,
    required this.onChanged,
    this.showSeconds = false,
    this.use24HourFormat = true,
    this.minuteStep = 1,
    this.intent = MochiIntent.primary,
    this.visibleRows = 5,
  }) : assert(minuteStep > 0 && 60 % minuteStep == 0, "The minutes have to come out even.");

  final MochiTime value;
  final ValueChanged<MochiTime> onChanged;

  final bool showSeconds;

  /// Off adds a column of [MochiStrings.am] and [MochiStrings.pm] and counts the hours to twelve.
  final bool use24HourFormat;

  /// 1, 5, 15 — whatever the setting is actually worth.
  final int minuteStep;

  final MochiIntent intent;

  /// How many rows are on show at once, the middle one being the chosen value.
  final int visibleRows;

  @override
  State<MochiTimeWheel> createState() => _MochiTimeWheelState();
}

class _MochiTimeWheelState extends State<MochiTimeWheel> {
  late final _hours = FixedExtentScrollController(initialItem: _hourIndex);
  late final _minutes = FixedExtentScrollController(initialItem: widget.value.minute ~/ widget.minuteStep);
  late final _seconds = FixedExtentScrollController(initialItem: widget.value.second);
  late final _halves = FixedExtentScrollController(initialItem: widget.value.isAfternoon ? 1 : 0);

  int get _hourIndex => widget.use24HourFormat ? widget.value.hour : widget.value.hourOf12 - 1;

  /// Set while a column is being put where the value says it belongs. A jump makes the wheel
  /// report a change like any other, and reporting one back to whoever just set the value would
  /// be a rebuild answering a rebuild.
  bool _settling = false;

  @override
  void didUpdateWidget(MochiTimeWheel old) {
    super.didUpdateWidget(old);

    // Follow a value set from outside, but never fight a wheel that is already where it belongs.
    _settle(_hours, _hourIndex);
    _settle(_minutes, widget.value.minute ~/ widget.minuteStep);
    if (widget.showSeconds) _settle(_seconds, widget.value.second);
    if (!widget.use24HourFormat) _settle(_halves, widget.value.isAfternoon ? 1 : 0);
  }

  void _settle(FixedExtentScrollController controller, int item) {
    if (!controller.hasClients || controller.selectedItem == item) return;

    _settling = true;
    // After the frame, not inside it: didUpdateWidget runs during a build, and a jump from there
    // lands a change notification in the middle of one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.hasClients) {
        _settling = false;
        return;
      }

      // A wheel that is still moving is left alone: it is already on its way to the very value
      // that was just reported, and a jump into the middle of that is the wobble.
      final moving = controller.position.isScrollingNotifier.value;
      if (!moving && controller.selectedItem != item) controller.jumpToItem(item);
      _settling = false;
    });
  }

  /// A change the wheel was asked to make is not a change to report back.
  void _report(MochiTime time) {
    if (_settling) return;
    widget.onChanged(time);
  }

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    _seconds.dispose();
    _halves.dispose();

    super.dispose();
  }

  void _setHour(int index) {
    if (widget.use24HourFormat) return _report(widget.value.copyWith(hour: index));

    // On a twelve-hour clock the column says 1 to 12 and the half of the day says the rest.
    final hour = (index + 1) % 12;
    _report(widget.value.copyWith(hour: widget.value.isAfternoon ? hour + 12 : hour));
  }

  void _setHalf(int index) {
    final afternoon = index == 1;
    if (afternoon == widget.value.isAfternoon) return;

    final hour = widget.value.hour % 12;
    _report(widget.value.copyWith(hour: afternoon ? hour + 12 : hour));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;
    final strings = theme.strings;
    final rowHeight = theme.touch ? 40.0 : 32.0;
    final height = rowHeight * widget.visibleRows;

    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The band the chosen row sits in, behind the columns: one mark for the whole time
          // rather than one per column.
          Positioned.fill(
            child: Center(
              child: Container(
                height: rowHeight,
                decoration: ShapeDecoration(
                  color: theme.colors.softOn(theme.colors.of(widget.intent), theme.colors.surface),
                  shape: RoundedSuperellipseBorder(borderRadius: g.radius.sm),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _Column(
                  controller: _hours,
                  rowHeight: rowHeight,
                  count: widget.use24HourFormat ? 24 : 12,
                  label: (index) =>
                      widget.use24HourFormat ? index.toString().padLeft(2, "0") : (index + 1).toString(),
                  onChanged: _setHour,
                ),
              ),
              _Gap(rowHeight: rowHeight),
              Expanded(
                child: _Column(
                  controller: _minutes,
                  rowHeight: rowHeight,
                  count: 60 ~/ widget.minuteStep,
                  label: (index) => (index * widget.minuteStep).toString().padLeft(2, "0"),
                  onChanged: (index) => _report(widget.value.copyWith(minute: index * widget.minuteStep)),
                ),
              ),
              if (widget.showSeconds) ...[
                _Gap(rowHeight: rowHeight),
                Expanded(
                  child: _Column(
                    controller: _seconds,
                    rowHeight: rowHeight,
                    count: 60,
                    label: (index) => index.toString().padLeft(2, "0"),
                    onChanged: (index) => _report(widget.value.copyWith(second: index)),
                  ),
                ),
              ],
              if (!widget.use24HourFormat)
                Expanded(
                  child: _Column(
                    controller: _halves,
                    rowHeight: rowHeight,
                    count: 2,
                    // Two rows don't wrap: there is nowhere to go round to.
                    loop: false,
                    label: (index) => index == 0 ? strings.am : strings.pm,
                    onChanged: _setHalf,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The colon between two columns, which belongs to neither.
class _Gap extends StatelessWidget {
  const _Gap({required this.rowHeight});

  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return SizedBox(
      width: theme.geometry.space.xs,
      child: Center(
        child: Text(":", style: theme.typography.body.md.copyWith(color: theme.colors.mutedForeground)),
      ),
    );
  }
}

/// One scrolling column of numbers.
class _Column extends StatefulWidget {
  const _Column({
    required this.controller,
    required this.rowHeight,
    required this.count,
    required this.label,
    required this.onChanged,
    this.loop = true,
  });

  final FixedExtentScrollController controller;
  final double rowHeight;
  final int count;
  final String Function(int index) label;
  final ValueChanged<int> onChanged;

  /// Whether the column wraps round: 23 is one notch from 00, but PM is not one notch from AM.
  final bool loop;

  @override
  State<_Column> createState() => _ColumnState();
}

class _ColumnState extends State<_Column> {
  /// One notch of the mouse wheel, one row — and no animation to get there.
  ///
  /// Two things would otherwise go wrong. A scroll event carries however many pixels the device
  /// felt like sending (50 on one machine, 120 and accelerating on another), which over rows 32
  /// apart is two or three at a time and a different number on every turn. And a scrollable
  /// wraps its contents in an `IgnorePointer` while it is animating, so a notch arriving during
  /// the journey never reaches this handler at all: it falls through to the native pixel
  /// scrolling, which is the stumble backwards and forwards you see when turning the wheel
  /// quickly. Landing on the row at once leaves no window for either.
  void _turn(int direction) {
    if (!widget.controller.hasClients) return;

    final next = widget.controller.selectedItem + direction;
    if (!widget.loop && (next < 0 || next >= widget.count)) return;

    widget.controller.jumpToItem(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    Widget row(int index) => Listener(
      // The whole row, not only the digits in the middle of it: left to defer to its child, the
      // listener is only hit while the pointer is over the glyphs, and a row sliding past the
      // pointer would hand every other notch back to the scrollable.
      behavior: HitTestBehavior.opaque,
      // On the rows, not around the column: a pointer signal goes to whoever registers for it
      // first, and the scrollable's own handler sits between the two.
      onPointerSignal: (event) {
        if (event is! PointerScrollEvent) return;
        final direction = event.scrollDelta.dy.sign.toInt();
        if (direction == 0) return;

        debugPrint("SIGNAL row");
        GestureBinding.instance.pointerSignalResolver.register(event, (_) {
          debugPrint("SIGNAL won");
          _turn(direction);
        });
      },
      child: Center(
        child: Text(
          widget.label(index % widget.count),
          style: theme.typography.body.md.copyWith(
            color: theme.colors.foreground,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );

    return ScrollConfiguration(
      // A wheel is there to be dragged, and on a desktop platform a mouse is not allowed to drag
      // a scrollable unless it is told it may.
      behavior: ScrollConfiguration.of(context)
          .copyWith(dragDevices: {...ScrollConfiguration.of(context).dragDevices, PointerDeviceKind.mouse}),
      child: ListWheelScrollView.useDelegate(
        controller: widget.controller,
        itemExtent: widget.rowHeight,
        // Flat, not a barrel: a barrel bends the numbers away from the eye at the edges, and
        // these are things to read rather than a wheel to admire.
        diameterRatio: 100,
        perspective: 0.001,
        overAndUnderCenterOpacity: 0.45,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) => widget.onChanged(index % widget.count),
        childDelegate: widget.loop
            ? ListWheelChildLoopingListDelegate(children: [for (var i = 0; i < widget.count; i++) row(i)])
            : ListWheelChildListDelegate(children: [for (var i = 0; i < widget.count; i++) row(i)]),
      ),
    );
  }
}

/// A field that opens a [MochiTimeWheel]: when a session started, when to stop reminding.
///
/// The same shape as [MochiDatePicker] — a popover from tablet width up, a sheet on a phone — so
/// a date and a time sit in one form without looking like two different ideas.
class MochiTimePicker extends StatefulWidget {
  const MochiTimePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.format,
    this.label,
    this.hint,
    this.description,
    this.error,
    this.showSeconds = false,
    this.use24HourFormat = true,
    this.minuteStep = 1,
    this.intent = MochiIntent.primary,
    this.size = MochiSize.md,
    this.enabled = true,
    this.autofocus = false,
  });

  /// Null leaves the field empty until something is picked.
  final MochiTime? value;

  final ValueChanged<MochiTime>? onChanged;

  /// How the time is written in the field. Defaults to `13:05`, or `1:05 PM` on a twelve-hour
  /// clock, with the seconds when they are being picked.
  final String Function(MochiTime time)? format;

  final Widget? label;

  /// Shown while nothing is picked. Defaults to `strings.pickTime`.
  final String? hint;

  final Widget? description;
  final String? error;

  final bool showSeconds;
  final bool use24HourFormat;
  final int minuteStep;
  final MochiIntent intent;

  /// Matches [MochiTextField.size].
  final MochiSize size;

  final bool enabled;
  final bool autofocus;

  @override
  State<MochiTimePicker> createState() => _MochiTimePickerState();
}

class _MochiTimePickerState extends State<MochiTimePicker> {
  bool _open = false;

  /// What the wheels start on when nothing is set yet: the top of the hour, not a random minute.
  MochiTime get _value => widget.value ?? const MochiTime(hour: 9);

  String _say(BuildContext context) {
    final value = widget.value;
    if (value == null) return widget.hint ?? context.theme.strings.pickTime;
    if (widget.format case final format?) return format(value);

    final strings = context.theme.strings;
    final minute = value.minute.toString().padLeft(2, "0");
    final seconds = widget.showSeconds ? ":${value.second.toString().padLeft(2, "0")}" : "";
    if (widget.use24HourFormat) {
      return "${value.hour.toString().padLeft(2, "0")}:$minute$seconds";
    }

    return "${value.hourOf12}:$minute$seconds ${value.isAfternoon ? strings.pm : strings.am}";
  }

  Widget get _wheel => Padding(
    padding: EdgeInsets.all(context.theme.geometry.space.sm),
    child: MochiTimeWheel(
      value: _value,
      showSeconds: widget.showSeconds,
      use24HourFormat: widget.use24HourFormat,
      minuteStep: widget.minuteStep,
      intent: widget.intent,
      onChanged: (time) => widget.onChanged?.call(time),
    ),
  );

  Future<void> _openSheet() async {
    setState(() => _open = true);
    await showMochiSheet(context, builder: (context) => MochiSheet(child: _wheel));
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
            ? _Field(
                text: _say(context),
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
                popoverBuilder: (context) => SizedBox(width: widget.showSeconds ? 240 : 180, child: _wheel),
                builder: (context, anchor, _) => _Field(
                  text: _say(context),
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

/// The box that opens it: a text field's look, with a clock at its end.
class _Field extends StatelessWidget {
  const _Field({
    required this.text,
    required this.empty,
    required this.metrics,
    required this.open,
    required this.error,
    required this.enabled,
    required this.autofocus,
    required this.onPress,
    this.focusNode,
  });

  final String text;
  final bool empty;
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

    return MochiTappable(
      enabled: enabled,
      focusNode: focusNode,
      autofocus: autofocus,
      // A field, not a button: it tints its border rather than growing.
      scaleOnPress: false,
      onPress: onPress,
      semanticLabel: empty ? null : text,
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
                padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
                child: Row(
                  spacing: metrics.gap,
                  children: [
                    Expanded(
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: metrics
                            .textStyle(theme.typography)
                            .copyWith(color: empty ? colors.mutedForeground : colors.foreground),
                      ),
                    ),
                    Icon(theme.icons.clock, size: metrics.iconSize, color: colors.mutedForeground),
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
