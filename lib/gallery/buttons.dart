part of "../main.dart";

/// The two ways a button waits: the app holding the state, and the button holding it.
class _WaitingSample extends StatefulWidget {
  const _WaitingSample();

  @override
  State<_WaitingSample> createState() => _WaitingSampleState();
}

class _WaitingSampleState extends State<_WaitingSample> {
  bool _saving = false;

  Future<void> _work() => Future<void>.delayed(const Duration(milliseconds: 1200));

  @override
  Widget build(BuildContext context) {
    final knobs = _Knobs.of(context);
    final g = context.theme.geometry;

    return Wrap(
      spacing: g.space.md,
      runSpacing: g.space.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        MochiButton(
          size: knobs.size,
          intent: knobs.intent,
          enabled: knobs.enabled,
          loading: _saving,
          onPress: () async {
            setState(() => _saving = true);
            await _work();
            if (mounted) setState(() => _saving = false);
          },
          child: const Text("app holds it"),
        ),
        MochiButton.async(
          size: knobs.size,
          intent: knobs.intent,
          enabled: knobs.enabled,
          onPress: _work,
          child: const Text("button holds it"),
        ),
        MochiButton.async(
          size: knobs.size,
          intent: MochiIntent.danger,
          enabled: knobs.enabled,
          onPress: () async {
            await _work();
            throw StateError("the errand failed");
          },
          child: const Text("one that fails"),
        ),
        const _ThemedText("the label stays put underneath, so nothing shuffles", .muted),
      ],
    );
  }
}

class _SizeSample extends StatelessWidget {
  const _SizeSample();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        for (final size in MochiSize.values)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: _labelWidth - 12, child: _ThemedText(size.name, .muted)),
              MochiButton(size: size, onPress: () {}, child: const Text("Button")),
              MochiButton(
                size: size,
                appearance: MochiButtonAppearance.outlined,
                onPress: () {},
                prefix: const Icon(TablerIcons.plus),
                suffix: const Icon(TablerIcons.chevronDown),
                child: const Text("Add item"),
              ),
              MochiButton.icon(
                size: size,
                appearance: .soft,
                tooltip: "Settings",
                onPress: () {},
                icon: const Icon(TablerIcons.settings),
              ),
              MochiButton.icon(
                size: size,
                tooltip: "Settings",
                onPress: () {},
                icon: const Icon(TablerIcons.settings),
              ),
            ],
          ),
      ],
    );
  }
}

enum _View { list, grid, board }

class _Playground extends StatefulWidget {
  const _Playground();

  @override
  State<_Playground> createState() => _PlaygroundState();
}

class _PlaygroundState extends State<_Playground> {
  String _event = "-";
  bool _enabled = true;
  _View _view = _View.list;

  void _log(String event) => setState(() => _event = event);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            MochiButton(
              appearance: MochiButtonAppearance.outlined,
              enabled: _enabled,
              prefix: const Icon(TablerIcons.pointer),
              suffix: const Icon(TablerIcons.chevronDown),
              onPress: () => _log("press"),
              onLongPress: () => _log("long press"),
              onDoublePress: () => _log("double press"),
              onSecondaryPress: () => _log("secondary press"),
              onSecondaryLongPress: () => _log("secondary long press"),
              onHoverChange: (v) => _log("hover $v"),
              onFocusChange: (v) => _log("focus $v"),
              child: const Text("Try me"),
            ),
            MochiButton(
              intent: MochiIntent.neutral,
              appearance: MochiButtonAppearance.soft,
              onPress: () => setState(() => _enabled = !_enabled),
              child: Text(_enabled ? "Disable" : "Enable"),
            ),
            _ThemedText("last event: $_event", .muted),
          ],
        ),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final (icon, tip, intent) in const [
              (TablerIcons.pencil, "Edit", MochiIntent.neutral),
              (
                TablerIcons.share,
                "Share with a very long tooltip message that should wrap nicely",
                MochiIntent.neutral,
              ),
              (TablerIcons.trash, "Delete", MochiIntent.danger),
            ])
              MochiButton.icon(intent: intent, tooltip: tip, onPress: () => _log(tip), icon: Icon(icon)),
            const SizedBox(width: 24),
            for (final view in _View.values)
              MochiButton(
                intent: MochiIntent.neutral,
                appearance: MochiButtonAppearance.ghost,
                selected: view == _view,
                onPress: () => setState(() => _view = view),
                prefix: Icon(switch (view) {
                  .list => TablerIcons.list,
                  .grid => TablerIcons.layoutGrid,
                  .board => TablerIcons.layoutKanban,
                }),
                child: Text(view.name),
              ),
          ],
        ),
      ],
    );
  }
}

class _AppearanceTable extends StatelessWidget {
  const _AppearanceTable({required this.appearance});

  final MochiButtonAppearance appearance;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: _labelWidth),
            for (final column in _Column.values)
              SizedBox(width: _cellWidth, child: _ThemedText(column.name, .muted)),
          ],
        ),
        for (final intent in MochiIntent.values)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                SizedBox(width: _labelWidth, child: _ThemedText(intent.name, .muted)),
                for (final column in _Column.values)
                  SizedBox(
                    width: _cellWidth,
                    child: Align(alignment: Alignment.centerLeft, child: _cell(intent, column)),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(MochiIntent intent, _Column column) => switch (column) {
    .live => MochiButton(
      intent: intent,
      appearance: appearance,
      onPress: () {},
      prefix: const Icon(TablerIcons.heart),
      child: const Text("Button"),
    ),
    .disabled => MochiButton(
      intent: intent,
      appearance: appearance,
      enabled: false,
      onPress: () {},
      child: const Text("Button"),
    ),
    _ => _StaticButton(intent: intent, appearance: appearance, states: column.states),
  };
}

/// The page's knobs, made visible: every appearance at the size, intent and enabled state the
/// bar is set to. The samples below it show their own deliberate variations instead.
class _ButtonKnobs extends StatelessWidget {
  const _ButtonKnobs();

  @override
  Widget build(BuildContext context) {
    final knobs = _Knobs.of(context);
    final g = context.theme.geometry;

    return Wrap(
      spacing: g.space.sm,
      runSpacing: g.space.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final appearance in MochiButtonAppearance.values)
          MochiButton(
            intent: knobs.intent,
            appearance: appearance,
            size: knobs.size,
            enabled: knobs.enabled,
            onPress: () {},
            child: Text(appearance.name),
          ),
        MochiButton.icon(
          intent: knobs.intent,
          size: knobs.size,
          enabled: knobs.enabled,
          onPress: () {},
          icon: const Icon(TablerIcons.playerPlay),
        ),
        MochiBadge(intent: knobs.intent, child: Text(knobs.size.name)),
      ],
    );
  }
}
