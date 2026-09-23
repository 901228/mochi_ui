import "package:flutter/services.dart";
import "package:flutter/widgets.dart";

import "../theme/colors.dart";
import "../theme/size.dart";
import "../theme/styles/button_style.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "button.dart";
import "focus_ring.dart";
import "state_transition.dart";
import "tappable.dart";

/// A run of days from [start] to [end], both ends included.
///
/// [end] is null while the second end is still being picked, which is what a calendar shows as a
/// half-made range.
@immutable
class MochiDateRange {
  const MochiDateRange(this.start, [this.end]);

  final DateTime start;
  final DateTime? end;

  bool get complete => end != null;

  /// Whether [day] falls inside the range, ends included.
  bool contains(DateTime day) {
    final end = this.end;
    if (end == null) return _sameDay(day, start);

    final from = start.isBefore(end) ? start : end;
    final to = start.isBefore(end) ? end : start;

    return !day.isBefore(_dayOf(from)) && !day.isAfter(_dayOf(to));
  }

  @override
  bool operator ==(Object other) => other is MochiDateRange && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => "MochiDateRange(${start.toIso8601String()} → ${end?.toIso8601String()})";
}

/// What a calendar is picking.
enum _Pick { single, multiple, range }

/// A month of days to pick from: the body of every date picker here, and a page in its own right
/// when there is room for one.
///
/// Three things it can be asked to pick, one per constructor: a day, a set of days, or a run of
/// them. The month it shows is its own business — the arrows change it — unless [month] is given.
///
/// The keyboard walks it like a grid: the arrows move a day at a time and a week at a time, Page
/// Up and Page Down change the month, Home and End go to the ends of the week, and Enter or Space
/// takes the day it is on.
///
/// ```dart
/// MochiCalendar.single(
///   value: day,
///   onChanged: (next) => setState(() => day = next),
/// )
/// ```
class MochiCalendar extends StatefulWidget {
  /// One day.
  const MochiCalendar.single({
    super.key,
    DateTime? value,
    ValueChanged<DateTime>? onChanged,
    this.month,
    this.onMonthChanged,
    this.first,
    this.last,
    this.enabledDay,
    this.firstDayOfWeek = DateTime.monday,
    this.intent = MochiIntent.primary,
    this.showAdjacentMonths = true,
    this.showClear = true,
    this.autofocus = false,
  }) : _pick = _Pick.single,
       _pickedDay = value,
       _picked = const {},
       _range = null,
       _onDay = onChanged,
       _onDays = null,
       _onRange = null;

  /// Any number of days.
  const MochiCalendar.multiple({
    super.key,
    Set<DateTime> values = const {},
    ValueChanged<Set<DateTime>>? onChanged,
    this.month,
    this.onMonthChanged,
    this.first,
    this.last,
    this.enabledDay,
    this.firstDayOfWeek = DateTime.monday,
    this.intent = MochiIntent.primary,
    this.showAdjacentMonths = true,
    this.showClear = true,
    this.autofocus = false,
  }) : _pick = _Pick.multiple,
       _pickedDay = null,
       _picked = values,
       _range = null,
       _onDay = null,
       _onDays = onChanged,
       _onRange = null;

  /// A run of days: the first press starts it, the second finishes it, and a third starts again.
  const MochiCalendar.range({
    super.key,
    MochiDateRange? value,
    ValueChanged<MochiDateRange>? onChanged,
    this.month,
    this.onMonthChanged,
    this.first,
    this.last,
    this.enabledDay,
    this.firstDayOfWeek = DateTime.monday,
    this.intent = MochiIntent.primary,
    this.showAdjacentMonths = true,
    this.showClear = true,
    this.autofocus = false,
  }) : _pick = _Pick.range,
       _pickedDay = null,
       _picked = const {},
       _range = value,
       _onDay = null,
       _onDays = null,
       _onRange = onChanged;

  final _Pick _pick;
  final DateTime? _pickedDay;
  final Set<DateTime> _picked;
  final MochiDateRange? _range;
  final ValueChanged<DateTime>? _onDay;
  final ValueChanged<Set<DateTime>>? _onDays;
  final ValueChanged<MochiDateRange>? _onRange;

  /// The month on show. Non-null takes ownership: the arrows then only report where they would
  /// have gone.
  final DateTime? month;

  final ValueChanged<DateTime>? onMonthChanged;

  /// Nothing before this day, or after [last], can be picked, and the arrows stop there.
  final DateTime? first;
  final DateTime? last;

  /// A day nobody may pick — a session that hasn't started, a day already booked.
  final bool Function(DateTime day)? enabledDay;

  /// Which day a week starts on, as [DateTime.monday] and its friends count.
  final int firstDayOfWeek;

  final MochiIntent intent;

  /// Whether the days either side of the month are drawn, greyed, or left blank.
  final bool showAdjacentMonths;

  /// Whether a calendar gathering days offers a way to let go of all of them at once. It only
  /// appears once there is something to clear.
  final bool showClear;

  final bool autofocus;

  @override
  State<MochiCalendar> createState() => _MochiCalendarState();
}

class _MochiCalendarState extends State<MochiCalendar> {
  late DateTime _month = _monthOf(widget.month ?? _anchor);
  late DateTime _focused = _anchor;

  final _focusNode = FocusNode(debugLabel: "MochiCalendar");
  final _gridKey = GlobalKey();

  /// The day the finger went down on, which is where a dragged run starts.
  DateTime? _pressedDay;

  /// The end of a dragged run that stays put, kept for the whole gesture.
  DateTime? _dragAnchor;
  bool _focusVisible = false;

  /// Where a calendar opens when nothing says otherwise: what is already picked, else today.
  DateTime get _anchor => switch (widget._pick) {
    _Pick.single => widget._pickedDay ?? _today,
    _Pick.multiple =>
      widget._picked.isEmpty ? _today : widget._picked.reduce((a, b) => a.isBefore(b) ? a : b),
    _Pick.range => widget._range?.start ?? _today,
  };

  DateTime get _shownMonth => widget.month == null ? _month : _monthOf(widget.month!);

  @override
  void didUpdateWidget(MochiCalendar old) {
    super.didUpdateWidget(old);

    if (widget.month case final month? when _monthOf(month) != _monthOf(old.month ?? month)) {
      _month = _monthOf(month);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();

    super.dispose();
  }

  bool _canPick(DateTime day) {
    if (widget.first case final first? when day.isBefore(_dayOf(first))) return false;
    if (widget.last case final last? when day.isAfter(_dayOf(last))) return false;

    return widget.enabledDay?.call(day) ?? true;
  }

  void _showMonth(DateTime month) {
    final next = _monthOf(month);
    if (next == _shownMonth) return;

    widget.onMonthChanged?.call(next);
    if (widget.month == null) setState(() => _month = next);
  }

  /// The month the arrows would go to, or null when there is nothing left that way.
  DateTime? _step(int months) {
    final next = DateTime(_shownMonth.year, _shownMonth.month + months);
    if (months < 0) {
      if (widget.first case final first? when next.isBefore(_monthOf(first))) return null;
    }
    if (months > 0) {
      if (widget.last case final last? when next.isAfter(_monthOf(last))) return null;
    }

    return next;
  }

  void _pick(DateTime day) {
    if (!_canPick(day)) return;

    setState(() => _focused = day);
    switch (widget._pick) {
      case _Pick.single:
        widget._onDay?.call(day);
      case _Pick.multiple:
        final values = {...widget._picked.map(_dayOf)};
        widget._onDays?.call(values.contains(day) ? (values..remove(day)) : (values..add(day)));
      case _Pick.range:
        final range = widget._range;
        // A half-made range takes its second end; a finished one starts again, so a second
        // thought doesn't need an undo first.
        widget._onRange?.call(
          range == null || range.complete
              ? MochiDateRange(day)
              : day.isBefore(_dayOf(range.start))
              ? MochiDateRange(day, _dayOf(range.start))
              : MochiDateRange(_dayOf(range.start), day),
        );
    }
  }

  /// Moves the keyboard's day, following it into the next month when it walks off the edge.
  void _moveFocus(Duration by) {
    final next = _dayOf(_focused.add(by));
    if (widget.first case final first? when next.isBefore(_dayOf(first))) return;
    if (widget.last case final last? when next.isAfter(_dayOf(last))) return;

    setState(() => _focused = next);
    if (_monthOf(next) != _shownMonth) _showMonth(next);
  }

  void _moveMonth(int months) {
    final next = _step(months);
    if (next == null) return;

    _showMonth(next);
    // The day under the keyboard comes along, clamped to a day that month has.
    final day = _focused.day.clamp(1, _daysIn(next));
    setState(() => _focused = DateTime(next.year, next.month, day));
  }

  bool _isSelected(DateTime day) => switch (widget._pick) {
    _Pick.single => widget._pickedDay != null && _sameDay(day, widget._pickedDay!),
    _Pick.multiple => widget._picked.any((value) => _sameDay(day, value)),
    _Pick.range => widget._range?.contains(day) ?? false,
  };

  /// Which end of a range a day is, so the fill can be rounded there and square in between.
  ///
  /// A day picked on its own is both ends of itself: all four corners, and the solid fill a
  /// chosen day gets.
  (bool start, bool end) _rangeEnds(DateTime day) {
    final range = widget._range;
    if (widget._pick != _Pick.range || range == null) return (true, true);

    final from = _dayOf(range.start);
    final to = range.end == null ? from : _dayOf(range.end!);
    final first = from.isBefore(to) ? from : to;
    final last = from.isBefore(to) ? to : from;

    return (_sameDay(day, first), _sameDay(day, last));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;
    final strings = theme.strings;
    final month = _shownMonth;

    return FocusableActionDetector(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onShowFocusHighlight: (visible) => setState(() => _focusVisible = visible),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowLeft): _MoveIntent(days: -1),
        SingleActivator(LogicalKeyboardKey.arrowRight): _MoveIntent(days: 1),
        SingleActivator(LogicalKeyboardKey.arrowUp): _MoveIntent(days: -7),
        SingleActivator(LogicalKeyboardKey.arrowDown): _MoveIntent(days: 7),
        SingleActivator(LogicalKeyboardKey.pageUp): _MoveIntent(months: -1),
        SingleActivator(LogicalKeyboardKey.pageDown): _MoveIntent(months: 1),
        SingleActivator(LogicalKeyboardKey.home): _EdgeIntent(last: false),
        SingleActivator(LogicalKeyboardKey.end): _EdgeIntent(last: true),
        SingleActivator(LogicalKeyboardKey.enter): _TakeIntent(),
        SingleActivator(LogicalKeyboardKey.space): _TakeIntent(),
      },
      actions: {
        _MoveIntent: CallbackAction<_MoveIntent>(
          onInvoke: (intent) {
            if (intent.months != 0) {
              _moveMonth(intent.months);
            } else {
              _moveFocus(Duration(days: intent.days));
            }
            return null;
          },
        ),
        _EdgeIntent: CallbackAction<_EdgeIntent>(
          onInvoke: (intent) {
            final weekday = (_focused.weekday - widget.firstDayOfWeek + 7) % 7;
            _moveFocus(Duration(days: intent.last ? 6 - weekday : -weekday));
            return null;
          },
        ),
        _TakeIntent: CallbackAction<_TakeIntent>(onInvoke: (_) => _pick(_focused)),
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MonthBar(
            label: strings.monthYear(strings.months[month.month - 1], month.year),
            onPrevious: _step(-1) == null ? null : () => _moveMonth(-1),
            onNext: _step(1) == null ? null : () => _moveMonth(1),
          ),
          SizedBox(height: g.space.xs),
          _WeekdayRow(firstDayOfWeek: widget.firstDayOfWeek),
          SizedBox(height: g.space.xs3),
          // A range can be drawn in one gesture as well as picked in two presses; the days keep
          // their own taps, since a drag only wins the arena once it has moved.
          Listener(
            // Where the finger went down, which is where the run starts: by the time a drag
            // begins it has already moved the slop distance, and that is a different day.
            onPointerDown: widget._pick == _Pick.range
                ? (event) => _pressedDay = _dayAt(event.position)
                : null,
            child: GestureDetector(
              onHorizontalDragStart: widget._pick == _Pick.range ? _dragFrom : null,
              onHorizontalDragUpdate: widget._pick == _Pick.range ? _dragTo : null,
              onVerticalDragStart: widget._pick == _Pick.range ? _dragFrom : null,
              onVerticalDragUpdate: widget._pick == _Pick.range ? _dragTo : null,
              child: Column(
                key: _gridKey,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final week in _weeks(month, widget.firstDayOfWeek))
                    Row(
                      children: [
                        for (final day in week)
                          Expanded(
                            child: _Day(
                              day: day,
                              // Days from the months either side are there to fill the grid; they
                              // can be taken, but they read as somewhere else.
                              adjacent: day.month != month.month,
                              hidden: !widget.showAdjacentMonths && day.month != month.month,
                              today: _sameDay(day, _today),
                              selected: _isSelected(day),
                              ends: _rangeEnds(day),
                              enabled: _canPick(day),
                              focused: _focusVisible && _sameDay(day, _focused),
                              intent: widget.intent,
                              onPress: () => _pick(day),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (_canClear)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: MochiButton(
                size: MochiSize.sm,
                appearance: MochiButtonAppearance.text,
                intent: MochiIntent.neutral,
                onPress: () => widget._onDays?.call(const {}),
                child: Text(strings.clear),
              ),
            ),
        ],
      ),
    );
  }

  bool get _canClear => widget.showClear && widget._pick == _Pick.multiple && widget._picked.isNotEmpty;

  /// The day under a point in the grid, or null when the point is outside it.
  DateTime? _dayAt(Offset global) {
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;

    final local = box.globalToLocal(global);
    final weeks = _weeks(_shownMonth, widget.firstDayOfWeek);
    final column = (local.dx / (box.size.width / 7)).floor().clamp(0, 6);
    final row = (local.dy / (box.size.height / weeks.length)).floor().clamp(0, weeks.length - 1);

    return weeks[row][column];
  }

  void _dragFrom(DragStartDetails details) {
    _dragAnchor = null;

    final day = _pressedDay ?? _dayAt(details.globalPosition);
    if (day == null || !_canPick(day)) return;

    // A drag starts a run rather than continuing one: it is one gesture, so it says both ends.
    _dragAnchor = _dayOf(day);
    setState(() => _focused = day);
    widget._onRange?.call(MochiDateRange(day));
  }

  void _dragTo(DragUpdateDetails details) {
    final day = _dayAt(details.globalPosition);
    final anchor = _dragAnchor;
    if (day == null || anchor == null || !_canPick(day)) return;

    // Against the day the gesture started on, not against the range's own start: dragging
    // backwards makes the dragged end the *start*, so reading the anchor back out of the range
    // would move it along with the finger and the run would never grow.
    final next = day.isBefore(anchor) ? MochiDateRange(day, anchor) : MochiDateRange(anchor, day);
    if (next == widget._range) return;

    setState(() => _focused = day);
    widget._onRange?.call(next);
  }
}

/// The month's name between the two arrows.
class _MonthBar extends StatelessWidget {
  const _MonthBar({required this.label, required this.onPrevious, required this.onNext});

  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Row(
      children: [
        MochiButton.icon(
          size: MochiSize.sm,
          appearance: MochiButtonAppearance.ghost,
          intent: MochiIntent.neutral,
          enabled: onPrevious != null,
          onPress: onPrevious,
          icon: Icon(theme.icons.chevronLeft),
          semanticLabel: theme.strings.previousMonth,
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            // One line, always: a wrapped month name would make the calendar taller in some
            // months than others.
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.title.sm.copyWith(color: theme.colors.foreground),
          ),
        ),
        MochiButton.icon(
          size: MochiSize.sm,
          appearance: MochiButtonAppearance.ghost,
          intent: MochiIntent.neutral,
          enabled: onNext != null,
          onPress: onNext,
          icon: Icon(theme.icons.chevronRight),
          semanticLabel: theme.strings.nextMonth,
        ),
      ],
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow({required this.firstDayOfWeek});

  final int firstDayOfWeek;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final weekdays = theme.strings.weekdays;

    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: ExcludeSemantics(
              child: Text(
                // The list runs Monday first; the week may not.
                weekdays[(firstDayOfWeek - DateTime.monday + i) % 7],
                textAlign: TextAlign.center,
                style: theme.typography.title.xs.copyWith(color: theme.colors.mutedForeground),
              ),
            ),
          ),
      ],
    );
  }
}

/// One square in the grid.
class _Day extends StatelessWidget {
  const _Day({
    required this.day,
    required this.adjacent,
    required this.hidden,
    required this.today,
    required this.selected,
    required this.ends,
    required this.enabled,
    required this.focused,
    required this.intent,
    required this.onPress,
  });

  final DateTime day;
  final bool adjacent;
  final bool hidden;
  final bool today;
  final bool selected;
  final (bool start, bool end) ends;
  final bool enabled;
  final bool focused;
  final MochiIntent intent;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;
    final tone = colors.of(intent);
    final side = (theme.touch ? 40.0 : 32.0) * theme.density;

    if (hidden) return SizedBox.square(dimension: side);

    // A run of days is one band: only its ends are rounded, so the middle reads as joined. A day
    // picked on its own is a day, not a band of one, and keeps all four corners.
    final (isStart, isEnd) = ends;
    final end = isStart || isEnd;
    final inBand = selected && !(isStart && isEnd);
    final radius = switch ((inBand, isStart, isEnd)) {
      (true, false, false) => BorderRadius.zero,
      (true, true, false) => BorderRadiusDirectional.horizontal(
        start: g.radius.sm.topLeft,
      ).resolve(Directionality.of(context)),
      (true, false, true) => BorderRadiusDirectional.horizontal(
        end: g.radius.sm.topLeft,
      ).resolve(Directionality.of(context)),
      _ => g.radius.sm,
    };

    return MochiTappable(
      enabled: enabled,
      selected: selected,
      semanticLabel: "${day.year}-${day.month}-${day.day}",
      // A square in a grid: it tints rather than growing.
      scaleOnPress: false,
      onPress: onPress,
      builder: (context, states, _) => MochiStateTransition(
        states: states,
        duration: theme.motion.stateDuration,
        builder: (context, blend) => Opacity(
          opacity: blend.contains(WidgetState.disabled) ? 0.4 : 1,
          child: MochiFocusRing(
            visible: focused,
            radius: g.radius.sm,
            inset: true,
            child: Container(
              height: side,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: blend.color(
                  (st) => switch (st) {
                    // The ends of a run are filled solid and the days between them tinted, so the
                    // two days you chose stand out from the ones that came along with them.
                    _ when st.contains(WidgetState.selected) && end => MochiColors.stateLayer(
                      tone.base,
                      tone.onBase,
                      st,
                    ),
                    _ when st.contains(WidgetState.selected) => MochiColors.stateLayer(
                      colors.softOn(tone, colors.surface),
                      tone.onSoft,
                      st,
                    ),
                    _ => MochiColors.stateLayer(colors.surface.withValues(alpha: 0), colors.foreground, st),
                  },
                ),
                shape: RoundedSuperellipseBorder(
                  borderRadius: radius,
                  // Today keeps a ring around it whether or not it is the day being picked.
                  side: today
                      ? BorderSide(color: selected ? tone.base : colors.border, width: g.borderWidth)
                      : BorderSide.none,
                ),
              ),
              child: Text(
                "${day.day}",
                style: theme.typography.body.sm.copyWith(
                  color: blend.color(
                    (st) => switch (st) {
                      _ when st.contains(WidgetState.selected) && end => tone.onBase,
                      _ when st.contains(WidgetState.selected) => tone.onSoft,
                      _ when adjacent => colors.mutedForeground,
                      _ => colors.foreground,
                    },
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

class _MoveIntent extends Intent {
  const _MoveIntent({this.days = 0, this.months = 0});

  final int days;
  final int months;
}

class _EdgeIntent extends Intent {
  const _EdgeIntent({required this.last});

  final bool last;
}

class _TakeIntent extends Intent {
  const _TakeIntent();
}

DateTime get _today => _dayOf(DateTime.now());

/// Midnight, so two days can be compared without their times getting in the way.
DateTime _dayOf(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _monthOf(DateTime date) => DateTime(date.year, date.month);

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

int _daysIn(DateTime month) => DateTime(month.year, month.month + 1, 0).day;

/// The weeks a month is drawn in, each a full seven days, filled out at both ends from the months
/// either side.
List<List<DateTime>> _weeks(DateTime month, int firstDayOfWeek) {
  final first = DateTime(month.year, month.month);
  final lead = (first.weekday - firstDayOfWeek + 7) % 7;
  final start = first.subtract(Duration(days: lead));
  final weeks = <List<DateTime>>[];

  // Always six, even when the month only needs five: a calendar that changes height as you page
  // through the year shifts whatever is under it.
  for (var week = 0; week < 6; week++) {
    weeks.add([for (var day = 0; day < 7; day++) _dayOf(start.add(Duration(days: week * 7 + day)))]);
  }

  return weeks;
}
