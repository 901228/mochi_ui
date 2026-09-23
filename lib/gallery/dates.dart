part of "../main.dart";

class _CalendarSample extends StatefulWidget {
  const _CalendarSample();

  @override
  State<_CalendarSample> createState() => _CalendarSampleState();
}

class _CalendarSampleState extends State<_CalendarSample> {
  DateTime? _day = DateTime.now();
  Set<DateTime> _days = {};
  MochiDateRange? _range;

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;
    final today = DateTime.now();

    Widget framed(String label, Widget calendar, String value) => SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: g.space.xs,
        children: [
          _ThemedText(label, .muted),
          MochiCard(child: calendar),
          _ThemedText(value, .muted),
        ],
      ),
    );

    String day(DateTime? date) => date == null
        ? "—"
        : "${date.year}-${date.month.toString().padLeft(2, "0")}-${date.day.toString().padLeft(2, "0")}";

    return Wrap(
      spacing: g.space.lg,
      runSpacing: g.space.lg,
      children: [
        framed(
          "one day",
          MochiCalendar.single(value: _day, onChanged: (value) => setState(() => _day = value)),
          day(_day),
        ),
        framed(
          "several days",
          MochiCalendar.multiple(
            values: _days,
            intent: MochiIntent.success,
            onChanged: (values) => setState(() => _days = values),
          ),
          _days.isEmpty ? "—" : (_days.toList()..sort()).map(day).join(", "),
        ),
        framed(
          "a run of days",
          MochiCalendar.range(value: _range, onChanged: (value) => setState(() => _range = value)),
          _range == null ? "—" : "${day(_range!.start)} → ${day(_range!.end)}",
        ),
        framed(
          "this month only, weekends out, Sunday first",
          MochiCalendar.single(
            firstDayOfWeek: DateTime.sunday,
            first: DateTime(today.year, today.month),
            last: DateTime(today.year, today.month + 1, 0),
            enabledDay: (d) => d.weekday != DateTime.saturday && d.weekday != DateTime.sunday,
            intent: MochiIntent.warning,
            onChanged: (_) {},
          ),
          "bounded to this month",
        ),
      ],
    );
  }
}

class _DatePickerSample extends StatefulWidget {
  const _DatePickerSample();

  @override
  State<_DatePickerSample> createState() => _DatePickerSampleState();
}

class _DatePickerSampleState extends State<_DatePickerSample> {
  DateTime? _started;
  MochiDateRange? _window;

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: g.space.md,
      children: [
        SizedBox(
          width: 320,
          child: MochiDatePicker.single(
            label: const Text("Session started"),
            description: const Text("Opens under the field; on a phone it comes up as a sheet."),
            value: _started,
            last: today,
            onChanged: (day) => setState(() => _started = day),
          ),
        ),
        SizedBox(
          width: 320,
          child: MochiDatePicker.range(
            label: const Text("Statistics over"),
            hint: "Any time",
            intent: MochiIntent.success,
            value: _window,
            onChanged: (range) => setState(() => _window = range),
          ),
        ),
        Wrap(
          spacing: g.space.xs,
          runSpacing: g.space.xs,
          children: [
            for (final size in MochiSize.values)
              SizedBox(
                width: 150,
                child: MochiDatePicker.single(size: size, onChanged: (_) {}),
              ),
          ],
        ),
        const SizedBox(
          width: 320,
          child: MochiDatePicker.single(enabled: false, error: "Pick a day.", onChanged: null),
        ),
      ],
    );
  }
}

class _TimePickerSample extends StatefulWidget {
  const _TimePickerSample();

  @override
  State<_TimePickerSample> createState() => _TimePickerSampleState();
}

class _TimePickerSampleState extends State<_TimePickerSample> {
  MochiTime? _starts;
  MochiTime _reminder = const MochiTime(hour: 20, minute: 30);
  MochiTime _wheel = const MochiTime(hour: 9, minute: 5, second: 30);

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: g.space.md,
      children: [
        Wrap(
          spacing: g.space.md,
          runSpacing: g.space.md,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            SizedBox(
              width: 220,
              child: MochiTimePicker(
                label: const Text("Session starts"),
                value: _starts,
                onChanged: (time) => setState(() => _starts = time),
              ),
            ),
            SizedBox(
              width: 220,
              child: MochiTimePicker(
                label: const Text("Remind me"),
                description: const Text("Quarter hours, twelve-hour clock."),
                value: _reminder,
                minuteStep: 15,
                use24HourFormat: false,
                intent: MochiIntent.success,
                onChanged: (time) => setState(() => _reminder = time),
              ),
            ),
          ],
        ),
        // The wheels on their own, which is what a sheet or a settings page would hold.
        SizedBox(
          width: 260,
          child: MochiCard(
            child: MochiTimeWheel(
              value: _wheel,
              showSeconds: true,
              onChanged: (time) => setState(() => _wheel = time),
            ),
          ),
        ),
        _ThemedText(
          "wheel: ${_wheel.hour.toString().padLeft(2, "0")}:${_wheel.minute.toString().padLeft(2, "0")}:${_wheel.second.toString().padLeft(2, "0")}",
          .muted,
        ),
      ],
    );
  }
}

class _DateTimePickerSample extends StatefulWidget {
  const _DateTimePickerSample();

  @override
  State<_DateTimePickerSample> createState() => _DateTimePickerSampleState();
}

class _DateTimePickerSampleState extends State<_DateTimePickerSample> {
  DateTime? _starts;
  DateTime _deadline = DateTime(2026, 7, 12, 17, 30);

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Wrap(
      spacing: g.space.md,
      runSpacing: g.space.md,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        SizedBox(
          width: 280,
          child: MochiDateTimePicker(
            label: const Text("Competition starts"),
            description: const Text("Pick a day, then the time."),
            value: _starts,
            onChanged: (at) => setState(() => _starts = at),
          ),
        ),
        SizedBox(
          width: 280,
          child: MochiDateTimePicker(
            label: const Text("Entries close"),
            value: _deadline,
            minuteStep: 15,
            use24HourFormat: false,
            intent: MochiIntent.warning,
            onChanged: (at) => setState(() => _deadline = at),
          ),
        ),
      ],
    );
  }
}

/// The page's knobs, made visible: the three fields at the size, intent and enabled state the bar
/// is set to.
class _DateKnobs extends StatelessWidget {
  const _DateKnobs();

  @override
  Widget build(BuildContext context) {
    final knobs = _Knobs.of(context);
    final g = context.theme.geometry;
    final day = DateTime(2026, 7, 12, 9, 30);

    return Wrap(
      spacing: g.space.md,
      runSpacing: g.space.md,
      children: [
        SizedBox(
          width: 220,
          child: MochiDatePicker.single(
            size: knobs.size,
            intent: knobs.intent,
            enabled: knobs.enabled,
            value: day,
            onChanged: (_) {},
          ),
        ),
        SizedBox(
          width: 180,
          child: MochiTimePicker(
            size: knobs.size,
            intent: knobs.intent,
            enabled: knobs.enabled,
            value: const MochiTime(hour: 9, minute: 30),
            onChanged: (_) {},
          ),
        ),
        SizedBox(
          width: 260,
          child: MochiDateTimePicker(
            size: knobs.size,
            intent: knobs.intent,
            enabled: knobs.enabled,
            value: day,
            onChanged: (_) {},
          ),
        ),
      ],
    );
  }
}
