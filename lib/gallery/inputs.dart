part of "../main.dart";

class _TextFieldSample extends StatefulWidget {
  const _TextFieldSample();

  @override
  State<_TextFieldSample> createState() => _TextFieldSampleState();
}

class _TextFieldSampleState extends State<_TextFieldSample> {
  // Starts invalid, so the error state shows until a number is typed.
  String _inspection = "abc";

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;
    Widget column(double width, Widget child) => SizedBox(width: width, child: child);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: g.space.lg,
      children: [
        Wrap(
          spacing: g.space.lg,
          runSpacing: g.space.lg,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            column(
              240,
              MochiTextField(
                label: const Text("Session name"),
                hint: "e.g. 3x3 main",
                description: const Text("Shown in the session list."),
              ),
            ),
            column(
              240,
              MochiTextField(
                label: const Text("Inspection"),
                initialValue: "abc",
                error: int.tryParse(_inspection.trim()) == null ? "Seconds must be a number." : null,
                onChanged: (value) => setState(() => _inspection = value),
                description: const Text("Seconds before the timer starts."),
              ),
            ),
            column(
              240,
              const MochiTextField(
                label: Text("Search"),
                hint: "Scramble, comment…",
                prefix: Icon(TablerIcons.search),
                clearable: true,
                initialValue: "R U R'",
              ),
            ),
            column(
              240,
              const MochiTextField(label: Text("Comment"), hint: "Up to 40 characters", maxLength: 40),
            ),
            column(
              240,
              const MochiTextField(label: Text("Disabled"), initialValue: "Can't touch this", enabled: false),
            ),
            column(
              240,
              const MochiTextField(label: Text("Password"), obscureText: true, initialValue: "hunter2"),
            ),
          ],
        ),
        // Fields and buttons of one size share a height.
        for (final size in MochiSize.values)
          Wrap(
            spacing: g.space.xs,
            runSpacing: g.space.xs,
            children: [
              SizedBox(
                width: 200,
                child: MochiTextField(size: size, hint: "size ${size.name}"),
              ),
              MochiButton(size: size, onPress: () {}, child: const Text("Save")),
            ],
          ),
        column(
          500,
          const MochiTextField.multiline(
            label: Text("Scramble"),
            hint: "Paste or type a scramble",
            description: Text("Grows with its content."),
          ),
        ),
      ],
    );
  }
}

class _CheckboxSample extends StatefulWidget {
  const _CheckboxSample();

  @override
  State<_CheckboxSample> createState() => _CheckboxSampleState();
}

class _CheckboxSampleState extends State<_CheckboxSample> {
  final _events = {"3x3": true, "OH": false, "BLD": true};
  bool _inspection = true;
  bool _danger = false;

  // All, none, or some: the parent of a list of checkboxes.
  bool? get _all => _events.values.every((on) => on) ? true : (_events.values.any((on) => on) ? null : false);

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Wrap(
      spacing: g.space.xl,
      runSpacing: g.space.lg,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: g.space.xs,
          children: [
            MochiCheckbox(
              value: _all,
              tristate: true,
              label: const Text("All events"),
              onChanged: (value) => setState(() {
                // From "some", a press checks everything.
                final next = _all != true;
                for (final event in _events.keys) {
                  _events[event] = next;
                }
              }),
            ),
            for (final event in _events.keys)
              Padding(
                padding: EdgeInsets.only(left: g.space.lg),
                child: MochiCheckbox(
                  value: _events[event]!,
                  label: Text(event),
                  onChanged: (value) => setState(() => _events[event] = value!),
                ),
              ),
          ],
        ),
        SizedBox(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: g.space.sm,
            children: [
              MochiCheckbox(
                value: _inspection,
                label: const Text("Inspection"),
                description: const Text("Count down 15 seconds before each solve starts."),
                onChanged: (value) => setState(() => _inspection = value!),
              ),
              MochiCheckbox(
                value: _danger,
                intent: MochiIntent.danger,
                label: const Text("Delete solves with the session"),
                onChanged: (value) => setState(() => _danger = value!),
              ),
              const MochiCheckbox(value: true, label: Text("Disabled, checked"), onChanged: null),
              const MochiCheckbox(value: false, label: Text("Disabled"), onChanged: null),
            ],
          ),
        ),
        Wrap(
          spacing: g.space.sm,
          runSpacing: g.space.sm,
          children: [
            MochiCheckbox(value: _inspection, onChanged: (value) => setState(() => _inspection = value!)),
            const _ThemedText("no label", .muted),
          ],
        ),
      ],
    );
  }
}

enum _Alert { beep, voice, vibrate, none }

class _RadioSample extends StatefulWidget {
  const _RadioSample();

  @override
  State<_RadioSample> createState() => _RadioSampleState();
}

class _RadioSampleState extends State<_RadioSample> {
  _Alert _alert = _Alert.beep;
  String _layout = "list";

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Wrap(
      spacing: g.space.xl,
      runSpacing: g.space.lg,
      children: [
        MochiRadioGroup<_Alert>(
          value: _alert,
          onChanged: (value) => setState(() => _alert = value!),
          children: const [
            MochiRadio(value: _Alert.beep, label: Text("Beep")),
            MochiRadio(value: _Alert.voice, label: Text("Voice"), description: Text("Reads the time aloud.")),
            MochiRadio(value: _Alert.vibrate, label: Text("Vibrate")),
            MochiRadio(value: _Alert.none, label: Text("None")),
          ],
        ),
        SizedBox(
          width: 520,
          child: MochiRadioGroup<String>(
            value: _layout,
            appearance: MochiRadioAppearance.card,
            axis: Axis.horizontal,
            onChanged: (value) => setState(() => _layout = value!),
            children: const [
              MochiRadio(
                value: "list",
                icon: Icon(TablerIcons.list),
                label: Text("List"),
                description: Text("One solve per row."),
              ),
              MochiRadio(
                value: "grid",
                icon: Icon(TablerIcons.layoutGrid),
                label: Text("Grid"),
                description: Text("Times only, packed tight."),
              ),
              MochiRadio(
                value: "chart",
                icon: Icon(TablerIcons.chartLine),
                label: Text("Chart"),
                description: Text("Times over the session."),
                enabled: false,
              ),
            ],
          ),
        ),
        const MochiRadioGroup<int>(
          value: 1,
          onChanged: null,
          children: [
            MochiRadio(value: 1, label: Text("Disabled group")),
            MochiRadio(value: 2, label: Text("Can't pick this")),
          ],
        ),
      ],
    );
  }
}

class _StepperSample extends StatefulWidget {
  const _StepperSample();

  @override
  State<_StepperSample> createState() => _StepperSampleState();
}

class _StepperSampleState extends State<_StepperSample> {
  int _inspection = 15;
  int _average = 5;
  final _bySize = <MochiSize, int>{};

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
          children: [
            MochiStepper(
              value: _inspection,
              min: 0,
              max: 60,
              format: (value) => "${value}s",
              semanticLabel: "Inspection",
              onChanged: (value) => setState(() => _inspection = value),
            ),
            const _ThemedText("inspection, 0–60s (hold to repeat, or press the number to type)", .muted),
          ],
        ),
        Wrap(
          spacing: g.space.md,
          runSpacing: g.space.md,
          children: [
            MochiStepper(
              value: _average,
              min: 3,
              max: 1000,
              semanticLabel: "Average of",
              onChanged: (value) => setState(() => _average = value),
            ),
            _ThemedText("ao$_average", .muted),
          ],
        ),
        // Lines up with fields and buttons of the same size.
        for (final size in MochiSize.values)
          Wrap(
            spacing: g.space.xs,
            runSpacing: g.space.xs,
            children: [
              MochiStepper(
                value: _bySize[size] ?? 3,
                size: size,
                onChanged: (value) => setState(() => _bySize[size] = value),
              ),
              SizedBox(
                width: 120,
                child: MochiTextField(size: size, hint: size.name),
              ),
              MochiButton(size: size, onPress: () {}, child: const Text("Save")),
            ],
          ),
        Wrap(
          spacing: g.space.md,
          runSpacing: g.space.md,
          children: [
            MochiStepper(
              value: _average,
              min: 3,
              max: 1000,
              editable: false,
              onChanged: (value) => setState(() => _average = value),
            ),
            const _ThemedText("editable: false — buttons and keyboard only", .muted),
          ],
        ),
        const MochiStepper(value: 7, onChanged: null),
      ],
    );
  }
}

class _SelectSample extends StatefulWidget {
  const _SelectSample();

  @override
  State<_SelectSample> createState() => _SelectSampleState();
}

class _SelectSampleState extends State<_SelectSample> {
  String? _alert = "beep";
  String? _puzzle;
  final _bySize = <MochiSize, String>{};
  Set<String> _events = {"333", "444"};

  static const _alerts = [
    MochiSelectOption(value: "beep", label: "Beep", prefix: Icon(TablerIcons.bell)),
    MochiSelectOption(value: "voice", label: "Voice", prefix: Icon(TablerIcons.microphone)),
    MochiSelectOption(value: "vibrate", label: "Vibrate", prefix: Icon(TablerIcons.deviceMobileVibration)),
    MochiSelectOption(value: "off", label: "Nothing", prefix: Icon(TablerIcons.bellOff)),
  ];

  static const _puzzles = [
    MochiSelectOption(value: "222", label: "2×2"),
    MochiSelectOption(value: "333", label: "3×3"),
    MochiSelectOption(value: "444", label: "4×4"),
    MochiSelectOption(value: "555", label: "5×5"),
    MochiSelectOption(value: "666", label: "6×6"),
    MochiSelectOption(value: "777", label: "7×7"),
    MochiSelectOption(value: "pyra", label: "Pyraminx"),
    MochiSelectOption(value: "mega", label: "Megaminx"),
    MochiSelectOption(value: "sq1", label: "Square-1"),
    MochiSelectOption(value: "clock", label: "Clock", enabled: false),
  ];

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: g.space.md,
      children: [
        SizedBox(
          width: 320,
          child: MochiSelect<String>(
            label: const Text("Alert type"),
            description: const Text("What happens when inspection runs out."),
            value: _alert,
            options: _alerts,
            onChanged: (value) => setState(() => _alert = value),
          ),
        ),
        SizedBox(
          width: 320,
          child: MochiSelect<String>(
            label: const Text("Puzzle"),
            hint: "Choose a puzzle",
            error: _puzzle == null ? "Pick one to start a session." : null,
            value: _puzzle,
            options: _puzzles,
            onChanged: (value) => setState(() => _puzzle = value),
          ),
        ),
        SizedBox(
          width: 320,
          child: MochiMultiSelect<String>(
            label: const Text("Events"),
            hint: "None",
            values: _events,
            options: _puzzles,
            onChanged: (values) => setState(() => _events = values),
          ),
        ),
        // Unbounded: as wide as the longest option, beside a label.
        Wrap(
          spacing: g.space.md,
          runSpacing: g.space.md,
          children: [
            const _ThemedText("in a row", .muted),
            MochiSelect<String>(
              value: _alert,
              size: MochiSize.sm,
              options: _alerts,
              onChanged: (value) => setState(() => _alert = value),
            ),
            MochiSelect<String>(value: "333", options: _puzzles, onChanged: null),
          ],
        ),
        for (final size in MochiSize.values)
          Wrap(
            spacing: g.space.xs,
            runSpacing: g.space.xs,
            children: [
              MochiSelect<String>(
                value: _bySize[size] ?? "beep",
                size: size,
                options: _alerts,
                onChanged: (value) => setState(() => _bySize[size] = value),
              ),
              MochiButton(size: size, onPress: () {}, child: const Text("Save")),
            ],
          ),
      ],
    );
  }
}

class _AutocompleteSample extends StatefulWidget {
  const _AutocompleteSample();

  @override
  State<_AutocompleteSample> createState() => _AutocompleteSampleState();
}

class _AutocompleteSampleState extends State<_AutocompleteSample> {
  static const _sessions = [
    "3x3 main",
    "3x3 OH",
    "3x3 BLD",
    "3x3 feet",
    "2x2 main",
    "4x4 main",
    "Megaminx",
    "Pyraminx",
    "Square-1",
    "Skewb",
  ];

  String? _moved;

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: g.space.md,
      children: [
        SizedBox(
          width: 320,
          child: MochiAutocomplete<String>(
            label: const Text("Move to session"),
            description: Text(_moved == null ? "Type to search, or write a new name." : "Moved to $_moved."),
            hint: "Session",
            prefix: const Icon(TablerIcons.search),
            clearable: true,
            optionsBuilder: (value) => value.text.isEmpty
                ? const <String>[]
                : _sessions.where((s) => s.toLowerCase().contains(value.text.toLowerCase())),
            onSelected: (session) => setState(() => _moved = session),
          ),
        ),
        // Every session, so the list runs past its height and scrolls.
        SizedBox(
          width: 320,
          child: MochiAutocomplete<String>(
            label: const Text("All of them"),
            hint: "Anything",
            maxListHeight: 160,
            optionsBuilder: (value) =>
                _sessions.where((s) => s.toLowerCase().contains(value.text.toLowerCase())),
          ),
        ),
        SizedBox(
          width: 320,
          child: MochiAutocomplete<String>(
            label: const Text("Disabled"),
            hint: "Session",
            enabled: false,
            optionsBuilder: (value) => _sessions,
          ),
        ),
      ],
    );
  }
}

class _OtpSample extends StatefulWidget {
  const _OtpSample();

  @override
  State<_OtpSample> createState() => _OtpSampleState();
}

class _OtpSampleState extends State<_OtpSample> {
  String? _code;
  bool _wrong = false;

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: g.space.md,
      children: [
        MochiOtpField(
          label: const Text("Code from the email"),
          description: Text(_code == null ? "Six digits." : "Sent $_code."),
          error: _wrong ? "That code is wrong." : null,
          onChanged: (_) => setState(() => _wrong = false),
          // 000000 is the wrong one, to see the error state.
          onCompleted: (code) => setState(() {
            _wrong = code == "000000";
            _code = _wrong ? null : code;
          }),
        ),
        const MochiOtpField(label: Text("PIN"), length: 4, obscure: true),
        const MochiOtpField(label: Text("Letters too"), length: 5, digitsOnly: false),
        for (final size in MochiSize.values)
          Wrap(
            spacing: g.space.xs,
            runSpacing: g.space.xs,
            children: [
              MochiOtpField(length: 3, size: size),
              MochiButton(size: size, onPress: () {}, child: const Text("Verify")),
            ],
          ),
        const MochiOtpField(length: 4, enabled: false, initialValue: "12"),
      ],
    );
  }
}

class _SearchSample extends StatefulWidget {
  const _SearchSample();

  @override
  State<_SearchSample> createState() => _SearchSampleState();
}

class _SearchSampleState extends State<_SearchSample> {
  static const _solves = ["8.12", "9.04", "10.56", "11.73", "12.05", "13.41"];

  String _query = "";
  String _searched = "";
  bool _loading = false;

  void _search(String query) async {
    setState(() {
      _loading = true;
      _searched = query;
    });
    // Stands in for a query that takes a moment.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;
    final results = _loading ? const <String>[] : _solves.where((s) => s.contains(_searched)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: g.space.md,
      children: [
        SizedBox(
          width: 320,
          child: MochiSearchBar(
            description: Text(_query.isEmpty ? "Waits 300ms before searching." : "Typing: $_query"),
            loading: _loading,
            onChanged: (query) => setState(() => _query = query),
            onSearch: _search,
          ),
        ),
        _ThemedText(_loading ? "searching…" : "${results.length} solves: ${results.join(", ")}", .muted),
        // Every keystroke, for a list already in memory.
        SizedBox(
          width: 320,
          child: MochiSearchBar(
            hint: "Filter as I type",
            debounce: Duration.zero,
            size: MochiSize.sm,
            onSearch: (query) => setState(() => _searched = query),
          ),
        ),
        const SizedBox(width: 320, child: MochiSearchBar(enabled: false)),
      ],
    );
  }
}

class _SliderSample extends StatefulWidget {
  const _SliderSample();

  @override
  State<_SliderSample> createState() => _SliderSampleState();
}

class _SliderSampleState extends State<_SliderSample> {
  double _volume = 0.6;
  double _inspection = 15;
  double _weight = 3;
  final _bySize = <MochiSize, double>{};

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: g.space.md,
      children: [
        SizedBox(
          width: 320,
          child: MochiSlider(
            value: _volume,
            label: const Text("Alert volume"),
            valueLabel: (value) => "${(value * 100).round()}%",
            onChanged: (value) => setState(() => _volume = value),
          ),
        ),
        SizedBox(
          width: 320,
          child: MochiSlider(
            value: _inspection,
            min: 0,
            max: 60,
            divisions: 12,
            label: const Text("Inspection"),
            valueLabel: (value) => "${value.round()}s",
            description: const Text("Snaps to five seconds."),
            onChanged: (value) => setState(() => _inspection = value),
          ),
        ),
        SizedBox(
          width: 320,
          child: MochiSlider(
            value: _weight,
            min: 1,
            max: 5,
            divisions: 4,
            intent: MochiIntent.warning,
            valueLabel: (value) => "weight ${value.round()}",
            onChanged: (value) => setState(() => _weight = value),
          ),
        ),
        // Every size, and one disabled.
        for (final size in MochiSize.values)
          SizedBox(
            width: 220,
            child: MochiSlider(
              value: _bySize[size] ?? 0.4,
              size: size,
              onChanged: (value) => setState(() => _bySize[size] = value),
            ),
          ),
        const SizedBox(width: 220, child: MochiSlider(value: 0.3, onChanged: null)),
      ],
    );
  }
}

class _SegmentedSample extends StatefulWidget {
  const _SegmentedSample();

  @override
  State<_SegmentedSample> createState() => _SegmentedSampleState();
}

class _SegmentedSampleState extends State<_SegmentedSample> {
  String _average = "ao5";
  String _tab = "times";
  String _view = "list";
  final _bySize = <MochiSize, String>{};

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: g.space.md,
      children: [
        SizedBox(
          width: 320,
          child: MochiSegmentedControl<String>(
            value: _average,
            onChanged: (value) => setState(() => _average = value),
            children: const [
              MochiSegment(value: "ao5", label: Text("ao5")),
              MochiSegment(value: "ao12", label: Text("ao12")),
              MochiSegment(value: "chart", label: Text("Chart")),
            ],
          ),
        ),
        // Tabs over their own content, which the app switches itself.
        SizedBox(
          width: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MochiSegmentedControl<String>(
                value: _tab,
                appearance: MochiSegmentedAppearance.underline,
                onChanged: (value) => setState(() => _tab = value),
                children: const [
                  MochiSegment(value: "times", label: Text("Times")),
                  MochiSegment(value: "stats", label: Text("Stats")),
                  MochiSegment(value: "scramble", label: Text("Scramble"), enabled: false),
                ],
              ),
              const MochiDivider(),
              Padding(
                padding: EdgeInsets.all(g.space.sm),
                child: _ThemedText(_tab == "times" ? "8.12  9.04  10.56" : "mean 9.24, best 8.12", .muted),
              ),
            ],
          ),
        ),
        // Icons only, and sized to their content.
        MochiSegmentedControl<String>(
          value: _view,
          expanded: false,
          size: MochiSize.sm,
          intent: MochiIntent.primary,
          onChanged: (value) => setState(() => _view = value),
          children: const [
            MochiSegment(value: "list", icon: Icon(TablerIcons.list), semanticLabel: "List"),
            MochiSegment(value: "grid", icon: Icon(TablerIcons.layoutGrid), semanticLabel: "Grid"),
            MochiSegment(value: "board", icon: Icon(TablerIcons.layoutBoard), semanticLabel: "Board"),
          ],
        ),
        for (final size in MochiSize.values)
          Wrap(
            spacing: g.space.xs,
            runSpacing: g.space.xs,
            children: [
              MochiSegmentedControl<String>(
                value: _bySize[size] ?? "a",
                size: size,
                expanded: false,
                onChanged: (value) => setState(() => _bySize[size] = value),
                children: const [
                  MochiSegment(value: "a", label: Text("One")),
                  MochiSegment(value: "b", label: Text("Two")),
                ],
              ),
              MochiButton(size: size, onPress: () {}, child: const Text("Save")),
            ],
          ),
        const SizedBox(
          width: 220,
          child: MochiSegmentedControl<String>(
            value: "a",
            onChanged: null,
            children: [
              MochiSegment(value: "a", label: Text("One")),
              MochiSegment(value: "b", label: Text("Two")),
            ],
          ),
        ),
      ],
    );
  }
}

/// The page's knobs, made visible: one of each control at the size, intent and enabled state the
/// bar is set to.
class _InputKnobs extends StatefulWidget {
  const _InputKnobs();

  @override
  State<_InputKnobs> createState() => _InputKnobsState();
}

class _InputKnobsState extends State<_InputKnobs> {
  double _slider = 0.4;
  int _steps = 3;
  String _segment = "list";

  @override
  Widget build(BuildContext context) {
    final knobs = _Knobs.of(context);
    final g = context.theme.geometry;

    return Wrap(
      spacing: g.space.md,
      runSpacing: g.space.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 200,
          child: MochiTextField(size: knobs.size, enabled: knobs.enabled, hint: "Session name"),
        ),
        SizedBox(
          width: 180,
          child: MochiSelect<String>(
            size: knobs.size,
            enabled: knobs.enabled,
            value: "333",
            options: _SelectSampleState._puzzles,
            onChanged: (_) {},
          ),
        ),
        MochiStepper(
          size: knobs.size,
          value: _steps,
          onChanged: knobs.enabled ? (value) => setState(() => _steps = value) : null,
        ),
        SizedBox(
          width: 180,
          child: MochiSlider(
            size: knobs.size,
            intent: knobs.intent,
            enabled: knobs.enabled,
            value: _slider,
            onChanged: (value) => setState(() => _slider = value),
          ),
        ),
        MochiSegmentedControl<String>(
          size: knobs.size,
          intent: knobs.intent,
          enabled: knobs.enabled,
          value: _segment,
          onChanged: (value) => setState(() => _segment = value),
          expanded: false,
          children: const [
            MochiSegment(value: "list", label: Text("List")),
            MochiSegment(value: "grid", label: Text("Grid")),
          ],
        ),
        MochiCheckbox(
          intent: knobs.intent,
          value: true,
          label: const Text("Checkbox"),
          onChanged: knobs.enabled ? (_) {} : null,
        ),
      ],
    );
  }
}
