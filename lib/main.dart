import "package:flutter/widgets.dart";
import "package:tabler_icons_plus/tabler_icons_plus.dart";

import "mochi_ui.dart";

void main() => runApp(const PreviewApp());

class PreviewApp extends StatefulWidget {
  const PreviewApp({super.key});

  @override
  State<PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<PreviewApp> {
  MochiThemeMode _mode = MochiThemeMode.system;
  bool _touch = MochiTheme.defaultTouch;

  @override
  Widget build(BuildContext context) {
    return MochiApp(
      title: "Mochi UI Preview",
      themeMode: _mode,
      touch: _touch,
      home: _Gallery(
        mode: _mode,
        onModeChanged: (mode) => setState(() => _mode = mode),
        touch: _touch,
        onTouchChanged: (touch) => setState(() => _touch = touch),
      ),
    );
  }
}

enum _Column {
  normal({}),
  hovered({WidgetState.hovered}),
  pressed({WidgetState.pressed}),
  focused({WidgetState.focused}),
  selected({WidgetState.selected}),
  selectedHovered({WidgetState.selected, WidgetState.hovered}),
  disabled({}),
  live({});

  const _Column(this.states);
  final Set<WidgetState> states;
}

const _labelWidth = 96.0;
const _cellWidth = 156.0;

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.mode,
    required this.onModeChanged,
    required this.touch,
    required this.onTouchChanged,
  });

  final MochiThemeMode mode;
  final ValueChanged<MochiThemeMode> onModeChanged;
  final bool touch;
  final ValueChanged<bool> onTouchChanged;

  // Theme-dependent text lives in [_ThemedText] leaves so the gallery itself doesn't
  // rebuild (and rebuild every button) on each frame of a theme animation.
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _ThemedText("Mochi UI", .title),
              const Spacer(),
              MochiButton(
                intent: MochiIntent.neutral,
                appearance: MochiButtonAppearance.ghost,
                selected: touch,
                tooltip: "Touch-first sizing",
                onPress: () => onTouchChanged(!touch),
                prefix: const Icon(TablerIcons.handFinger),
                child: const Text("touch"),
              ),
              const SizedBox(width: 16),
              for (final m in MochiThemeMode.values)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: MochiButton(
                    intent: MochiIntent.neutral,
                    appearance: MochiButtonAppearance.ghost,
                    selected: m == mode,
                    tooltip: switch (m) {
                      .system => "Follow the system theme",
                      .light => "Always light",
                      .dark => "Always dark",
                    },
                    onPress: () => onModeChanged(m),
                    prefix: Icon(switch (m) {
                      .system => TablerIcons.deviceDesktop,
                      .light => TablerIcons.sun,
                      .dark => TablerIcons.moon,
                    }),
                    child: Text(m.name),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          const _ThemedText("typography", .section),
          const SizedBox(height: 12),
          const _TypographySample(),
          const SizedBox(height: 32),
          const _ThemedText("geometry", .section),
          const SizedBox(height: 12),
          const _GeometrySample(),
          const SizedBox(height: 32),
          const _ThemedText("components", .section),
          const SizedBox(height: 12),
          const _ComponentsSample(),
          const SizedBox(height: 32),
          const _ThemedText("button sizes", .section),
          const SizedBox(height: 12),
          const _SizeSample(),
          const SizedBox(height: 32),
          const _ThemedText("button playground", .section),
          const SizedBox(height: 12),
          const _Playground(),
          const SizedBox(height: 32),
          for (final appearance in MochiButtonAppearance.values) ...[
            _ThemedText("button · ${appearance.name}", .section),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // Scroll views clip: reserve room so focus rings aren't cut off.
              padding: EdgeInsets.all(MochiFocusRing.outsetOf(context)),
              child: _AppearanceTable(appearance: appearance),
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }
}

class _TypographySample extends StatelessWidget {
  const _TypographySample();

  static const _text = "Mochi UI 麻糬元件庫 0123";

  @override
  Widget build(BuildContext context) {
    final t = context.theme.typography;
    final muted = context.colors.mutedForeground;

    Widget row(String name, TextStyle style) => Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: _labelWidth,
          child: Text(name, style: t.body.xs.copyWith(color: muted)),
        ),
        Text(_text, style: style),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row("title.xl4", t.title.xl4),
        row("title.xl2", t.title.xl2),
        row("title.lg", t.title.lg),
        row("body.md", t.body.md),
        row("body.sm", t.body.sm),
        row("body.xs", t.body.xs),
        row("w300", t.body.md.withWeight(FontWeight.w300)),
        row("w500", t.body.md.withWeight(FontWeight.w500)),
        row("w700", t.body.md.withWeight(FontWeight.w700)),
      ],
    );
  }
}

class _ComponentsSample extends StatefulWidget {
  const _ComponentsSample();

  @override
  State<_ComponentsSample> createState() => _ComponentsSampleState();
}

class _ComponentsSampleState extends State<_ComponentsSample> {
  bool _on = true;
  double _progress = 0.35;

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: g.space.md,
      children: [
        Row(
          spacing: g.space.md,
          children: [
            // A Row gives its children unbounded width, so the cards get an explicit one.
            SizedBox(
              width: 260,
              child: MochiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: g.space.xs,
                  children: [
                    const Text("3x3 session"),
                    const MochiDivider(),
                    Row(
                      spacing: g.space.xs,
                      children: [
                        const MochiBadge(intent: MochiIntent.success, child: Text("PB")),
                        const MochiBadge(intent: MochiIntent.warning, child: Text("+2")),
                        const MochiBadge(intent: MochiIntent.danger, appearance: .solid, child: Text("DNF")),
                        const MochiBadge(appearance: .outlined, child: Text("ao5")),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 170,
              child: MochiCard(
                elevation: MochiElevation.md,
                onPress: () {},
                child: const Text("Tappable card"),
              ),
            ),
          ],
        ),
        Row(
          spacing: g.space.md,
          children: [
            MochiSwitch(value: _on, onChanged: (v) => setState(() => _on = v)),
            MochiSwitch(value: !_on, intent: MochiIntent.success, onChanged: (v) => setState(() => _on = !v)),
            const MochiSwitch(value: true, onChanged: null),
            const MochiSwitch(value: false, onChanged: null),
            const SizedBox(width: 8),
            const _ThemedText("spinner", .muted),
            const MochiCircularProgress(),
            const MochiCircularProgress(value: 0.3),
            const MochiCircularProgress(size: 32, value: 0.75),
            MochiButton(
              appearance: MochiButtonAppearance.soft,
              onPress: () {},
              prefix: const MochiCircularProgress(size: 14),
              child: const Text("Saving"),
            ),
          ],
        ),
        Row(
          spacing: g.space.md,
          children: [
            SizedBox(width: _labelWidth, child: const _ThemedText("linear", .muted)),
            SizedBox(
              width: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: g.space.xs,
                children: [
                  MochiLinearProgress(value: _progress),
                  const _ThemedText("determinate", .muted),
                  const MochiLinearProgress(intent: MochiIntent.success),
                  const _ThemedText("indeterminate", .muted),
                ],
              ),
            ),
          ],
        ),
        Row(
          spacing: g.space.md,
          children: [
            SizedBox(width: _labelWidth, child: const _ThemedText("divider", .muted)),
            const SizedBox(width: 200, child: MochiDivider()),
            const SizedBox(width: 120, child: MochiDivider(indent: 20, endIndent: 20)),
            SizedBox(
              height: 32,
              child: Row(
                spacing: g.space.sm,
                children: [
                  const MochiDivider(axis: Axis.vertical),
                  const _ThemedText("vertical", .muted),
                  const MochiDivider(axis: Axis.vertical),
                ],
              ),
            ),
          ],
        ),
        Row(
          spacing: g.space.xs,
          children: [
            MochiButton(
              size: MochiButtonSize.xs,
              appearance: MochiButtonAppearance.outlined,
              onPress: () => setState(() => _progress = (_progress - 0.2).clamp(0.0, 1.0)),
              child: const Text("-20%"),
            ),
            MochiButton(
              size: MochiButtonSize.xs,
              appearance: MochiButtonAppearance.outlined,
              onPress: () => setState(() => _progress = (_progress + 0.2).clamp(0.0, 1.0)),
              child: const Text("+20%"),
            ),
          ],
        ),
      ],
    );
  }
}

class _GeometrySample extends StatelessWidget {
  const _GeometrySample();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;
    final colors = theme.colors;

    Widget swatch(String label, BorderRadius radius, {List<BoxShadow>? shadows}) => Column(
      spacing: g.space.xs,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: ShapeDecoration(
            color: colors.overlay,
            shadows: shadows,
            shape: RoundedSuperellipseBorder(
              borderRadius: radius,
              side: BorderSide(color: colors.border, width: g.borderWidth),
            ),
          ),
        ),
        _ThemedText(label, .muted),
      ],
    );

    return Wrap(
      spacing: g.space.lg,
      runSpacing: g.space.md,
      children: [
        swatch("radius.xs", g.radius.xs),
        swatch("radius.sm", g.radius.sm),
        swatch("radius.md", g.radius.md),
        swatch("radius.lg", g.radius.lg),
        swatch("radius.xl", g.radius.xl),
        swatch("radius.full", g.radius.full),
        for (final e in MochiElevation.values)
          swatch("shadow.${e.name}", g.radius.lg, shadows: g.shadows.of(e, colors.shadow)),
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
        for (final size in MochiButtonSize.values)
          Row(
            spacing: 12,
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
        Row(
          spacing: 12,
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
        Row(
          spacing: 4,
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

enum _TextKind { title, section, muted }

class _ThemedText extends StatelessWidget {
  const _ThemedText(this.data, this.kind);

  final String data;
  final _TextKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Text(
      data,
      style: switch (kind) {
        .title => theme.typography.title.xl2,
        .section => theme.typography.title.md,
        .muted => theme.typography.body.xs.copyWith(color: theme.colors.mutedForeground),
      },
    );
  }
}

/// A button frozen in the given states, ignoring real pointer and focus input.
class _StaticButton extends StatefulWidget {
  const _StaticButton({required this.intent, required this.appearance, required this.states});

  final MochiIntent intent;
  final MochiButtonAppearance appearance;
  final Set<WidgetState> states;

  @override
  State<_StaticButton> createState() => _StaticButtonState();
}

class _StaticButtonState extends State<_StaticButton> {
  late final _controller = WidgetStatesController(widget.states);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeFocus(
        child: MochiButton(
          intent: widget.intent,
          appearance: widget.appearance,
          statesController: _controller,
          // MochiTappable owns the selected state, so it must match the frozen states.
          selected: widget.states.contains(WidgetState.selected),
          onPress: () {},
          child: const Text("Button"),
        ),
      ),
    );
  }
}
