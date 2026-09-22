import "package:flutter/rendering.dart";
import "package:flutter/scheduler.dart";
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
  bool _zh = false;
  var _look = const _Look();

  @override
  Widget build(BuildContext context) {
    return MochiApp(
      title: "Mochi UI Preview",
      themeMode: _mode,
      touch: _touch,
      strings: _zh ? MochiStrings.zhHant : MochiStrings.en,
      radius: _look.radius.value,
      density: _look.density,
      textScale: _look.textScale,
      home: _Gallery(
        look: _look,
        onLookChanged: (look) => setState(() => _look = look),
        mode: _mode,
        onModeChanged: (mode) => setState(() => _mode = mode),
        touch: _touch,
        onTouchChanged: (touch) => setState(() => _touch = touch),
        zh: _zh,
        onZhChanged: (zh) => setState(() => _zh = zh),
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
    required this.zh,
    required this.onZhChanged,
    required this.look,
    required this.onLookChanged,
  });

  final _Look look;
  final ValueChanged<_Look> onLookChanged;

  final MochiThemeMode mode;
  final ValueChanged<MochiThemeMode> onModeChanged;
  final bool touch;
  final ValueChanged<bool> onTouchChanged;
  final bool zh;
  final ValueChanged<bool> onZhChanged;

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
                tooltip: "Watch sizes ease between the two scales",
                onPress: () => Navigator.of(context).push(
                  MochiPageRoute<void>(
                    builder: (_) => _SizingPage(onTouchChanged: onTouchChanged, onModeChanged: onModeChanged),
                  ),
                ),
                prefix: const Icon(TablerIcons.ruler),
                child: const Text("sizing"),
              ),
              const SizedBox(width: 8),
              MochiButton(
                intent: MochiIntent.neutral,
                appearance: MochiButtonAppearance.ghost,
                selected: touch,
                tooltip: "Touch-first sizing",
                onPress: () => onTouchChanged(!touch),
                prefix: const Icon(TablerIcons.handFinger),
                child: const Text("touch"),
              ),
              const SizedBox(width: 8),
              MochiButton(
                intent: MochiIntent.neutral,
                appearance: MochiButtonAppearance.ghost,
                selected: zh,
                tooltip: "MochiStrings.zhHant: the words components say themselves",
                onPress: () => onZhChanged(!zh),
                prefix: const Icon(TablerIcons.language),
                child: const Text("中文"),
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
          const SizedBox(height: 12),
          _LookBar(look: look, onChanged: onLookChanged),
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
          const _ThemedText("transitions", .section),
          const SizedBox(height: 12),
          const _TransitionSample(),
          const SizedBox(height: 32),
          const _ThemedText("text field", .section),
          const SizedBox(height: 12),
          const _TextFieldSample(),
          const SizedBox(height: 32),
          const _ThemedText("checkbox", .section),
          const SizedBox(height: 12),
          const _CheckboxSample(),
          const SizedBox(height: 32),
          const _ThemedText("radio", .section),
          const SizedBox(height: 12),
          const _RadioSample(),
          const SizedBox(height: 32),
          const _ThemedText("stepper", .section),
          const SizedBox(height: 12),
          const _StepperSample(),
          const SizedBox(height: 32),
          const _ThemedText("select", .section),
          const SizedBox(height: 12),
          const _SelectSample(),
          const SizedBox(height: 32),
          const _ThemedText("autocomplete", .section),
          const SizedBox(height: 12),
          const _AutocompleteSample(),
          const SizedBox(height: 32),
          const _ThemedText("otp field", .section),
          const SizedBox(height: 12),
          const _OtpSample(),
          const SizedBox(height: 32),
          const _ThemedText("search bar", .section),
          const SizedBox(height: 12),
          const _SearchSample(),
          const SizedBox(height: 32),
          const _ThemedText("slider", .section),
          const SizedBox(height: 12),
          const _SliderSample(),
          const SizedBox(height: 32),
          const _ThemedText("segmented control", .section),
          const SizedBox(height: 12),
          const _SegmentedSample(),
          const SizedBox(height: 32),
          const _ThemedText("sidebar", .section),
          const SizedBox(height: 12),
          const _SidebarSample(),
          const SizedBox(height: 32),
          const _ThemedText("bottom nav", .section),
          const SizedBox(height: 12),
          const _BottomNavSample(),
          const SizedBox(height: 32),
          const _ThemedText("breadcrumb + pagination", .section),
          const SizedBox(height: 12),
          const _TrailSample(),
          const SizedBox(height: 32),
          const _ThemedText("menubar", .section),
          const SizedBox(height: 12),
          const _MenubarSample(),
          const SizedBox(height: 32),
          const _ThemedText("tree", .section),
          const SizedBox(height: 12),
          const _TreeSample(),
          const SizedBox(height: 32),
          const _ThemedText("popover", .section),
          const SizedBox(height: 12),
          const _PopoverSample(),
          const SizedBox(height: 32),
          const _ThemedText("menu", .section),
          const SizedBox(height: 12),
          const _MenuSample(),
          const SizedBox(height: 32),
          const _ThemedText("dialog", .section),
          const SizedBox(height: 12),
          const _DialogSample(),
          const SizedBox(height: 32),
          const _ThemedText("sheet", .section),
          const SizedBox(height: 12),
          const _SheetSample(),
          const SizedBox(height: 32),
          const _ThemedText("toast", .section),
          const SizedBox(height: 12),
          const _ToastSample(),
          const SizedBox(height: 32),
          const _ThemedText("scaffold + header", .section),
          const SizedBox(height: 12),
          const _ScaffoldSample(),
          const SizedBox(height: 32),
          const _ThemedText("tiles", .section),
          const SizedBox(height: 12),
          const _TileSample(),
          const SizedBox(height: 32),
          const _ThemedText("scroll area", .section),
          const SizedBox(height: 12),
          const _ScrollAreaSample(),
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
  final _tags = ["3x3", "OH", "BLD", "FMC"];

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
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: g.space.md,
          children: [
            const SizedBox(
              width: 260,
              child: MochiCard.collapsible(
                title: Text("Session stats"),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text("Best  9.87"),
                    Text("ao5  12.34"),
                    Text("ao12  12.81"),
                    Text("Solves  142"),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 260,
              child: MochiCard.collapsible(
                title: const Text("Scramble"),
                initiallyExpanded: true,
                child: const Text("R U R' U' F2 D L2 B' U2 R2 F' L D2"),
              ),
            ),
          ],
        ),
        Row(
          spacing: g.space.md,
          children: [
            for (final size in MochiSize.values) MochiCloseButton(size: size, onPress: () {}),
            for (final size in MochiSize.values)
              MochiCloseButton(size: size, shape: MochiCloseButtonShape.circle, onPress: () {}),
            MochiCloseButton(tooltip: "With a tooltip", onPress: () {}),
            const MochiCloseButton(onPress: null),
            IconTheme.merge(
              data: IconThemeData(color: context.colors.of(MochiIntent.danger).onSoft),
              child: MochiCloseButton(onPress: () {}),
            ),
          ],
        ),
        // Badge sizes, each as a pill and as a rounded tag.
        Row(
          spacing: g.space.xs,
          children: [
            for (final size in MochiSize.values)
              MochiBadge(size: size, intent: MochiIntent.primary, child: Text(size.name)),
            const SizedBox(width: 8),
            for (final size in MochiSize.values)
              MochiBadge(
                size: size,
                shape: MochiBadgeShape.rounded,
                appearance: MochiBadgeAppearance.outlined,
                child: Text(size.name),
              ),
          ],
        ),
        // Deletable tags, and tags joined into one.
        Row(
          spacing: g.space.xs,
          children: [
            for (final tag in _tags)
              MochiBadge(
                shape: MochiBadgeShape.rounded,
                onDelete: () => setState(() => _tags.remove(tag)),
                child: Text(tag),
              ),
            if (_tags.length < 4)
              MochiButton(
                size: MochiSize.xs,
                appearance: MochiButtonAppearance.text,
                onPress: () => setState(
                  () => _tags
                    ..clear()
                    ..addAll(["3x3", "OH", "BLD", "FMC"]),
                ),
                child: const Text("reset"),
              ),
            const SizedBox(width: 16),
            const MochiBadgeGroup(
              children: [
                MochiBadge(appearance: .solid, child: Text("ao5")),
                MochiBadge(intent: MochiIntent.success, child: Text("12.34")),
              ],
            ),
            const MochiBadgeGroup(
              children: [
                MochiBadge(appearance: .outlined, shape: MochiBadgeShape.rounded, child: Text("session")),
                MochiBadge(appearance: .outlined, shape: MochiBadgeShape.rounded, child: Text("3x3")),
                MochiBadge(
                  intent: MochiIntent.danger,
                  appearance: .outlined,
                  shape: MochiBadgeShape.rounded,
                  child: Text("DNF"),
                ),
              ],
            ),
            MochiBadgeGroup(
              children: [
                const MochiBadge(appearance: .solid, intent: MochiIntent.info, child: Text("tag")),
                MochiBadge(intent: MochiIntent.info, onDelete: () {}, child: const Text("removable")),
              ],
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
            for (final size in MochiSize.values) MochiCircularProgress(size: size),
            const MochiCircularProgress(value: 0.3),
            const MochiCircularProgress(size: MochiSize.lg, value: 0.75),
            MochiButton(
              appearance: MochiButtonAppearance.soft,
              onPress: () {},
              prefix: const MochiCircularProgress(size: MochiSize.sm),
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
                  for (final size in MochiSize.values) MochiLinearProgress(size: size, value: _progress),
                  const _ThemedText("sizes xs – lg", .muted),
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
              size: MochiSize.xs,
              appearance: MochiButtonAppearance.outlined,
              onPress: () => setState(() => _progress = (_progress - 0.2).clamp(0.0, 1.0)),
              child: const Text("-20%"),
            ),
            MochiButton(
              size: MochiSize.xs,
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

class _TransitionSample extends StatelessWidget {
  const _TransitionSample();

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Row(
      spacing: g.space.sm,
      children: [
        for (final transition in MochiTransition.values)
          MochiButton(
            appearance: MochiButtonAppearance.outlined,
            size: MochiSize.sm,
            onPress: () => Navigator.of(context).push(
              MochiPageRoute<void>(
                transition: transition,
                builder: (context) => MochiScaffold(
                  header: MochiHeader(
                    variant: MochiHeaderVariant.bordered,
                    title: Text("Pushed with ${transition.name}"),
                    prefixes: [MochiHeaderAction.back(onPress: () => Navigator.of(context).pop())],
                  ),
                  child: const Center(child: Text("Press back to return")),
                ),
              ),
            ),
            child: Text(transition.name),
          ),
      ],
    );
  }
}

class _PopoverSample extends StatelessWidget {
  const _PopoverSample();

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Wrap(
      spacing: g.space.sm,
      runSpacing: g.space.sm,
      children: [
        for (final side in MochiPopoverSide.values)
          MochiPopover(
            side: side,
            popoverBuilder: (context) => SizedBox(
              width: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Opens on the ${side.name}"),
                  SizedBox(height: g.space.xs),
                  const Text("Flips when there is no room, and stays inside the window."),
                ],
              ),
            ),
            builder: (context, anchor, _) => MochiButton(
              appearance: MochiButtonAppearance.outlined,
              size: MochiSize.sm,
              focusNode: anchor.focusNode,
              onPress: anchor.toggle,
              child: Text(side.name),
            ),
          ),
        for (final align in MochiPopoverAlign.values)
          MochiPopover(
            align: align,
            popoverBuilder: (context) => SizedBox(width: 220, child: Text("Aligned ${align.name}")),
            builder: (context, anchor, _) => MochiButton(
              appearance: MochiButtonAppearance.soft,
              size: MochiSize.sm,
              focusNode: anchor.focusNode,
              onPress: anchor.toggle,
              child: Text("align ${align.name}"),
            ),
          ),
        // Opened at the pointer rather than against an edge: the shape a context menu takes
        // once MochiContextMenu lands.
        MochiPopover(
          align: MochiPopoverAlign.start,
          // Its anchor only opens, so pressing it again has to be what closes it.
          closeOnAnchorPress: true,
          popoverBuilder: (context) => const SizedBox(width: 160, child: Text("Opened at the pointer")),
          builder: (context, anchor, _) => GestureDetector(
            onSecondaryTapUp: (details) => anchor.open(position: details.localPosition),
            child: MochiCard(
              padding: EdgeInsets.symmetric(horizontal: g.space.sm, vertical: g.space.xs),
              child: const Text("right click me"),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuSample extends StatefulWidget {
  const _MenuSample();

  @override
  State<_MenuSample> createState() => _MenuSampleState();
}

class _MenuSampleState extends State<_MenuSample> {
  String _chosen = "nothing yet";
  String _penalty = "none";
  bool _archived = false;

  List<Widget> _items(BuildContext context) => [
    const MochiMenuLabel(child: Text("Session")),
    MochiMenuItem(
      prefix: const Icon(TablerIcons.pencil),
      title: const Text("Rename"),
      suffix: const Text("F2"),
      onPress: () => setState(() => _chosen = "rename"),
    ),
    MochiMenuItem(
      prefix: Icon(_archived ? TablerIcons.archiveOff : TablerIcons.archive),
      title: Text(_archived ? "Unarchive" : "Archive"),
      onPress: () => setState(() {
        _archived = !_archived;
        _chosen = _archived ? "archive" : "unarchive";
      }),
    ),
    MochiMenuItem(
      prefix: const Icon(TablerIcons.star),
      title: const Text("Selected row"),
      selected: true,
      onPress: () => setState(() => _chosen = "selected row"),
    ),
    const MochiMenuItem(prefix: Icon(TablerIcons.ban), title: Text("Disabled row")),
    MochiSubmenu(
      prefix: const Icon(TablerIcons.gavel),
      title: const Text("Penalty"),
      menuBuilder: (context) => [
        for (final penalty in const ["none", "DNF", "+2"])
          MochiMenuItem(
            title: Text(penalty),
            selected: _penalty == penalty,
            onPress: () => setState(() {
              _penalty = penalty;
              _chosen = "penalty $penalty";
            }),
          ),
      ],
    ),
    const MochiMenuDivider(),
    MochiMenuItem(
      intent: MochiIntent.danger,
      prefix: const Icon(TablerIcons.trash),
      title: const Text("Delete"),
      onPress: () => setState(() => _chosen = "delete"),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Wrap(
      spacing: g.space.md,
      runSpacing: g.space.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        MochiPopoverMenu(
          menuBuilder: _items,
          builder: (context, anchor, _) => MochiButton(
            appearance: MochiButtonAppearance.outlined,
            size: MochiSize.sm,
            focusNode: anchor.focusNode,
            onPress: anchor.toggle,
            suffix: const Icon(TablerIcons.chevronDown),
            child: const Text("popover menu"),
          ),
        ),
        MochiPopoverMenu(
          menuBuilder: _items,
          builder: (context, anchor, _) => MochiButton.icon(
            appearance: MochiButtonAppearance.ghost,
            size: MochiSize.sm,
            focusNode: anchor.focusNode,
            onPress: anchor.toggle,
            icon: const Icon(TablerIcons.dotsVertical),
          ),
        ),
        MochiContextMenu(
          menuBuilder: _items,
          child: MochiCard(
            padding: EdgeInsets.symmetric(horizontal: g.space.md, vertical: g.space.sm),
            child: const Text("right click or long press me"),
          ),
        ),
        _ThemedText("chose: $_chosen", .muted),
      ],
    );
  }
}

class _DialogSample extends StatefulWidget {
  const _DialogSample();

  @override
  State<_DialogSample> createState() => _DialogSampleState();
}

class _DialogSampleState extends State<_DialogSample> {
  String _answer = "nothing yet";
  String _session = "3x3";

  Future<void> _confirm(BuildContext context) async {
    final answer = await showMochiDialog<bool>(
      context,
      builder: (context) => MochiDialog(
        title: const Text("Delete record?"),
        body: const Text("This record will be permanently deleted. There is no undo yet."),
        actions: [
          MochiButton(
            appearance: MochiButtonAppearance.outlined,
            onPress: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          MochiButton(
            intent: MochiIntent.danger,
            onPress: () => Navigator.of(context).pop(true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    setState(
      () => _answer = switch (answer) {
        true => "deleted",
        false => "cancelled",
        null => "dismissed",
      },
    );
  }

  Future<void> _modal(BuildContext context) async {
    final answer = await showMochiModal<bool>(
      context,
      title: const Text("Move to session?"),
      body: const Text("Narrow the window to a phone width and this becomes a sheet."),
      actions: [
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          onPress: () => Navigator.of(context).pop(false),
          child: const Text("Cancel"),
        ),
        MochiButton(onPress: () => Navigator.of(context).pop(true), child: const Text("Move")),
      ],
    );
    if (!context.mounted) return;
    setState(
      () => _answer = switch (answer) {
        true => "moved",
        false => "cancelled",
        null => "dismissed",
      },
    );
  }

  Future<void> _long(BuildContext context) => showMochiDialog<void>(
    context,
    builder: (context) => MochiDialog(
      title: const Text("A long body scrolls"),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (var i = 1; i <= 40; i++) Text("Line $i of a body that outgrows the screen.")],
      ),
      actions: [MochiButton(onPress: () => Navigator.of(context).pop(), child: const Text("Close"))],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Wrap(
      spacing: g.space.md,
      runSpacing: g.space.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          size: MochiSize.sm,
          onPress: () => _confirm(context),
          child: const Text("confirm"),
        ),
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          size: MochiSize.sm,
          onPress: () => _long(context),
          child: const Text("long body"),
        ),
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          size: MochiSize.sm,
          onPress: () async {
            final yes = await showMochiConfirm(
              context,
              title: "Delete record?",
              message: "This record will be permanently deleted. There is no undo yet.",
              confirmLabel: "Delete",
              destructive: true,
            );
            if (!context.mounted) return;
            setState(() => _answer = yes ? "deleted" : "kept");
          },
          child: const Text("confirm helper"),
        ),
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          size: MochiSize.sm,
          onPress: () async {
            final picked = await showMochiChoice<String>(
              context,
              title: "Move to session",
              message: "Records move with the session they belong to.",
              selected: _session,
              choices: const [
                MochiChoice(value: "3x3", label: "3x3", icon: TablerIcons.cube),
                MochiChoice(value: "4x4", label: "4x4", description: "Bigger cube", icon: TablerIcons.cube),
                MochiChoice(value: "skewb", label: "Skewb", icon: TablerIcons.triangle, enabled: false),
              ],
            );
            if (!context.mounted || picked == null) return;
            setState(() {
              _session = picked;
              _answer = "moved to $picked";
            });
          },
          child: const Text("choice helper"),
        ),
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          size: MochiSize.sm,
          onPress: () async {
            await showMochiAlert(context, title: "Import finished", message: "42 records added.");
            if (!context.mounted) return;
            setState(() => _answer = "acknowledged");
          },
          child: const Text("alert helper"),
        ),
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          size: MochiSize.sm,
          onPress: () async {
            final name = await showMochiPrompt(
              context,
              title: "Rename session",
              initialValue: "3x3 main",
              maxLength: 24,
              validate: (value) => value.trim().isEmpty ? "A name can't be empty." : null,
            );
            if (!context.mounted) return;
            setState(() => _answer = name == null ? "kept the old name" : "renamed to $name");
          },
          child: const Text("prompt helper"),
        ),
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          size: MochiSize.sm,
          tooltip: "Dialog on a wide window, bottom sheet once it is phone-sized",
          onPress: () => _modal(context),
          child: const Text("adaptive modal"),
        ),
        _ThemedText("answer: $_answer", .muted),
      ],
    );
  }
}

class _SheetSample extends StatelessWidget {
  const _SheetSample();

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Wrap(
      spacing: g.space.sm,
      runSpacing: g.space.sm,
      children: [
        for (final side in MochiSheetSide.values)
          MochiButton(
            appearance: MochiButtonAppearance.outlined,
            size: MochiSize.sm,
            onPress: () => showMochiSheet<void>(
              context,
              side: side,
              builder: (context) => MochiSheet(
                side: side,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: g.space.sm,
                  children: [
                    Text("From the ${side.name}"),
                    const Text("Drag it towards its own edge to dismiss it, or press the barrier."),
                    MochiButton(
                      appearance: MochiButtonAppearance.soft,
                      onPress: () => Navigator.of(context).pop(),
                      child: const Text("Close"),
                    ),
                  ],
                ),
              ),
            ),
            child: Text(side.name),
          ),
      ],
    );
  }
}

class _ToastSample extends StatelessWidget {
  const _ToastSample();

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Wrap(
      spacing: g.space.sm,
      runSpacing: g.space.sm,
      children: [
        for (final intent in [
          MochiIntent.neutral,
          MochiIntent.success,
          MochiIntent.warning,
          MochiIntent.danger,
        ])
          MochiButton(
            appearance: MochiButtonAppearance.outlined,
            size: MochiSize.sm,
            onPress: () => showMochiToast(
              context,
              intent: intent,
              title: Text(switch (intent) {
                MochiIntent.success => "Saved",
                MochiIntent.warning => "Check your connection",
                MochiIntent.danger => "Could not save",
                _ => "Nothing to report",
              }),
            ),
            child: Text(intent.name),
          ),
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          size: MochiSize.sm,
          tooltip: "Hover it and it waits for you",
          onPress: () {
            late final MochiToastHandle handle;
            handle = showMochiToast(
              context,
              intent: MochiIntent.danger,
              icon: const Icon(TablerIcons.trash),
              title: const Text("Record deleted"),
              description: const Text("It is gone from this session."),
              action: MochiButton(
                appearance: MochiButtonAppearance.text,
                size: MochiSize.xs,
                onPress: () => handle.dismiss(),
                child: const Text("Undo"),
              ),
            );
          },
          child: const Text("with undo"),
        ),
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          size: MochiSize.sm,
          onPress: () {
            for (var i = 1; i <= 6; i++) {
              showMochiToast(context, title: Text("Message $i"), duration: const Duration(seconds: 3));
            }
          },
          child: const Text("six at once"),
        ),
      ],
    );
  }
}

/// A page with only the widgets whose size depends on `touch`, so the size transition can be
/// watched without the rest of the gallery rebuilding along with it.
class _SizingPage extends StatelessWidget {
  const _SizingPage({required this.onTouchChanged, required this.onModeChanged});

  final ValueChanged<bool> onTouchChanged;
  final ValueChanged<MochiThemeMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;

    return MochiScaffold(
      header: MochiHeader(
        variant: MochiHeaderVariant.bordered,
        title: const Text("sizing"),
        prefixes: [MochiHeaderAction.back(onPress: () => Navigator.of(context).pop())],
        suffixes: [
          MochiButton(
            appearance: MochiButtonAppearance.ghost,
            size: MochiSize.sm,
            selected: theme.touch,
            onPress: () => onTouchChanged(!theme.touch),
            prefix: const Icon(TablerIcons.handFinger),
            child: const Text("touch"),
          ),
          // Both animations are worth watching on a page this quiet: the scale eases, the colors
          // fade, and neither has the rest of the gallery rebuilding alongside it.
          MochiButton(
            appearance: MochiButtonAppearance.ghost,
            size: MochiSize.sm,
            onPress: () => onModeChanged(switch (theme.colors.brightness) {
              .light => MochiThemeMode.dark,
              .dark => MochiThemeMode.light,
            }),
            prefix: Icon(switch (theme.colors.brightness) {
              .light => TablerIcons.moon,
              .dark => TablerIcons.sun,
            }),
            child: Text(switch (theme.colors.brightness) {
              .light => "dark",
              .dark => "light",
            }),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(g.space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: g.space.lg,
          children: [
            const _ThemedText("Toggle touch and watch the numbers ease.", .muted),
            Wrap(
              spacing: g.space.md,
              runSpacing: g.space.md,
              children: [
                for (final size in MochiSize.values)
                  _Measured(
                    label: size.name,
                    child: MochiButton(size: size, onPress: () {}, child: Text(size.name)),
                  ),
                _Measured(
                  label: "icon",
                  child: MochiButton.icon(onPress: () {}, icon: const Icon(TablerIcons.heart)),
                ),
                _Measured(
                  label: "switch",
                  child: MochiSwitch(value: true, onChanged: (_) {}),
                ),
              ],
            ),
            SizedBox(
              width: 320,
              child: _Measured(
                label: "tiles",
                child: MochiTileGroup(
                  children: [
                    MochiTile(
                      prefix: const Icon(TablerIcons.bell),
                      title: const Text("With an icon"),
                      onPress: () {},
                    ),
                    MochiTile(title: const Text("Without one"), onPress: () {}),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows its child's live height, so a transition can be read off the number as well as seen.
class _Measured extends StatefulWidget {
  const _Measured({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  State<_Measured> createState() => _MeasuredState();
}

class _MeasuredState extends State<_Measured> {
  final _height = ValueNotifier<double>(0);

  @override
  void dispose() {
    _height.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: context.theme.geometry.space.xs2,
    children: [
      _MeasureSize(height: _height, child: widget.child),
      ValueListenableBuilder(
        valueListenable: _height,
        builder: (context, height, _) =>
            _ThemedText("${widget.label} · ${height.toStringAsFixed(1)}", .muted),
      ),
    ],
  );
}

class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.height, required super.child});

  final ValueNotifier<double> height;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMeasureSize(height);

  @override
  void updateRenderObject(BuildContext context, _RenderMeasureSize renderObject) =>
      renderObject.height = height;
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.height);

  ValueNotifier<double> height;

  @override
  void performLayout() {
    super.performLayout();

    // Notifying during layout would rebuild the listener in the same frame it is laid out in.
    if (height.value != size.height) {
      final measured = size.height;
      SchedulerBinding.instance.addPostFrameCallback((_) => height.value = measured);
    }
  }
}

class _ScaffoldSample extends StatelessWidget {
  const _ScaffoldSample();

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    Widget page(String label, Widget scaffold) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: g.space.xs,
      children: [
        SizedBox(
          width: 300,
          height: 180,
          child: MochiCard(padding: EdgeInsets.zero, child: scaffold),
        ),
        _ThemedText(label, .muted),
      ],
    );

    return Wrap(
      spacing: g.space.lg,
      runSpacing: g.space.md,
      children: [
        page(
          "title start",
          MochiScaffold(
            safeArea: false,
            background: const Color(0x00000000),
            header: MochiHeader(
              variant: MochiHeaderVariant.bordered,
              title: const Text("Records"),
              suffixes: [
                MochiHeaderAction(icon: const Icon(TablerIcons.search), onPress: () {}, tooltip: "Search"),
                MochiHeaderAction(icon: const Icon(TablerIcons.dots), onPress: () {}, tooltip: "More"),
              ],
            ),
            footer: Padding(
              padding: EdgeInsets.all(g.space.sm),
              child: MochiButton(size: MochiSize.sm, onPress: () {}, child: const Text("Add solve")),
            ),
            child: const Align(alignment: .topLeft, child: Text("content")),
          ),
        ),
        page(
          "floating",
          MochiScaffold(
            safeArea: false,
            background: const Color(0x00000000),
            header: MochiHeader(
              variant: MochiHeaderVariant.floating,
              title: const Text("Sessions"),
              suffixes: [MochiHeaderAction(icon: const Icon(TablerIcons.plus), onPress: () {})],
            ),
            child: const Align(alignment: .topLeft, child: Text("content")),
          ),
        ),
        page(
          "title center, back action",
          MochiScaffold(
            safeArea: false,
            background: const Color(0x00000000),
            header: MochiHeader(
              alignment: MochiHeaderAlignment.center,
              title: const Text("Settings"),
              prefixes: [MochiHeaderAction.back(onPress: () {})],
              suffixes: [MochiHeaderAction.close(onPress: () {})],
            ),
            child: const Align(alignment: .topLeft, child: Text("content")),
          ),
        ),
      ],
    );
  }
}

class _TileSample extends StatefulWidget {
  const _TileSample();

  @override
  State<_TileSample> createState() => _TileSampleState();
}

class _TileSampleState extends State<_TileSample> {
  bool _inspection = true;
  int _selected = 1;

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;
    final icons = context.theme.icons;

    return Wrap(
      spacing: g.space.md,
      runSpacing: g.space.sm,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        SizedBox(
          width: 320,
          child: MochiTileGroup(
            label: const Text("Timer (reservePrefix)"),
            reservePrefix: true,
            description: const Text("Applies to new solves"),
            children: [
              MochiTile(
                prefix: const Icon(TablerIcons.hourglass),
                title: const Text("Inspection"),
                subtitle: const Text("15 second countdown"),
                suffix: MochiSwitch(value: _inspection, onChanged: (v) => setState(() => _inspection = v)),
              ),
              MochiTile(
                prefix: const Icon(TablerIcons.bell),
                title: const Text("Alert type"),
                details: const Text("Beep"),
                suffix: Icon(icons.chevronRight),
                onPress: () {},
              ),
              MochiTile(
                title: const Text("Start delay"),
                subtitle: const Text("No icon on this row"),
                details: const Text("0.3s"),
                onPress: () {},
              ),
              MochiTile(
                prefix: const Icon(TablerIcons.trash),
                title: const Text("Clear session"),
                intent: MochiIntent.danger,
                enabled: false,
                onPress: () {},
              ),
            ],
          ),
        ),
        SizedBox(
          width: 280,
          child: MochiTileGroup(
            label: const Text("Sessions (divider: indented)"),
            divider: MochiTileDivider.indented,
            children: [
              for (final (index, name) in ["3x3 main", "3x3 OH", "Megaminx"].indexed)
                MochiTile(
                  title: Text(name),
                  details: Text("${(index + 1) * 37} solves"),
                  selected: index == _selected,
                  onPress: () => setState(() => _selected = index),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScrollAreaSample extends StatelessWidget {
  const _ScrollAreaSample();

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Row(
      spacing: g.space.lg,
      children: [
        SizedBox(
          width: 260,
          height: 160,
          child: MochiCard(
            padding: EdgeInsets.zero,
            child: MochiScrollArea(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (var i = 1; i <= 12; i++)
                    MochiTile(title: Text("Solve $i"), details: Text("${10 + i}.${i}4"), onPress: () {}),
                ],
              ),
            ),
          ),
        ),
        const _ThemedText("fades at whichever end can still scroll", .muted),
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
        for (final size in MochiSize.values)
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

enum _RadiusPreset {
  sharp,
  subtle,
  standard,
  rounded,
  pill;

  MochiRadius get value => switch (this) {
    .sharp => MochiRadius.sharp,
    .subtle => MochiRadius.subtle,
    .standard => MochiRadius.standard,
    .rounded => MochiRadius.rounded,
    .pill => MochiRadius.pill,
  };
}

/// The three app-wide appearance knobs: corners, density and text size.
@immutable
class _Look {
  const _Look({this.radius = _RadiusPreset.standard, this.density = 1, this.textScale = 1});

  final _RadiusPreset radius;
  final double density;
  final double textScale;

  _Look copyWith({_RadiusPreset? radius, double? density, double? textScale}) => _Look(
    radius: radius ?? this.radius,
    density: density ?? this.density,
    textScale: textScale ?? this.textScale,
  );
}

class _LookBar extends StatelessWidget {
  const _LookBar({required this.look, required this.onChanged});

  final _Look look;
  final ValueChanged<_Look> onChanged;

  Widget _choice(String label, bool selected, VoidCallback onPress) => MochiButton(
    intent: MochiIntent.neutral,
    appearance: MochiButtonAppearance.ghost,
    size: MochiSize.xs,
    selected: selected,
    onPress: onPress,
    child: Text(label),
  );

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      const _ThemedText("radius", .muted),
      for (final preset in _RadiusPreset.values)
        _choice(preset.name, look.radius == preset, () => onChanged(look.copyWith(radius: preset))),
      const SizedBox(width: 16),
      const _ThemedText("density", .muted),
      for (final (label, value) in [("compact", 0.85), ("default", 1.0), ("spacious", 1.15)])
        _choice(label, look.density == value, () => onChanged(look.copyWith(density: value))),
      const SizedBox(width: 16),
      const _ThemedText("text", .muted),
      for (final (label, value) in [("0.9×", 0.9), ("1×", 1.0), ("1.2×", 1.2)])
        _choice(label, look.textScale == value, () => onChanged(look.copyWith(textScale: value))),
    ],
  );
}

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
          Row(
            spacing: g.space.xs,
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
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: g.space.sm,
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
        Row(
          spacing: g.space.md,
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
        Row(
          spacing: g.space.md,
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
          Row(
            spacing: g.space.xs,
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
        Row(
          spacing: g.space.md,
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
        Row(
          spacing: g.space.md,
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
          Row(
            spacing: g.space.xs,
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
          Row(
            spacing: g.space.xs,
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
          Row(
            spacing: g.space.xs,
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

class _SidebarSample extends StatefulWidget {
  const _SidebarSample();

  @override
  State<_SidebarSample> createState() => _SidebarSampleState();
}

class _SidebarSampleState extends State<_SidebarSample> {
  String _page = "timer";
  bool _railed = false;
  bool _sessionsOpen = true;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;

    Widget item(String value, IconData icon, String label, {Widget? trailing}) => MochiSidebarItem(
      icon: Icon(icon),
      label: Text(label),
      trailing: trailing,
      selected: _page == value,
      onPress: () => setState(() => _page = value),
    );

    return SizedBox(
      height: 420,
      width: 640,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: theme.colors.background,
          shape: RoundedSuperellipseBorder(
            borderRadius: g.radius.md,
            side: BorderSide(color: theme.colors.border, width: g.borderWidth),
          ),
        ),
        child: ClipRSuperellipse(
          borderRadius: g.radius.md,
          child: Row(
            children: [
              MochiSidebar(
                collapsed: _railed,
                header: MochiSidebarHeading(
                  const Text("Mochi Timer"),
                  collapsedChild: const Text("M"),
                  trailing: MochiButton.icon(
                    size: MochiSize.sm,
                    appearance: MochiButtonAppearance.ghost,
                    intent: MochiIntent.neutral,
                    scaleOnPress: false,
                    tooltip: _railed ? "Expand" : "Collapse",
                    onPress: () => setState(() => _railed = !_railed),
                    icon: Icon(
                      _railed
                          ? TablerIcons.layoutSidebarRightCollapse
                          : TablerIcons.layoutSidebarLeftCollapse,
                    ),
                  ),
                ),
                children: [
                  item("timer", TablerIcons.clock, "Timer"),
                  item(
                    "stats",
                    TablerIcons.chartBar,
                    "Statistics",
                    trailing: const MochiBadge(child: Text("12")),
                  ),
                  item("settings", TablerIcons.settings, "Settings"),
                  MochiSidebarGroup(
                    label: const Text("Sessions"),
                    collapsible: true,
                    expanded: _sessionsOpen,
                    onExpandedChanged: (open) => setState(() => _sessionsOpen = open),
                    children: [
                      item("3x3", TablerIcons.box, "3x3 main"),
                      item("oh", TablerIcons.handStop, "3x3 OH"),
                      item("mega", TablerIcons.diamond, "Megaminx"),
                    ],
                  ),
                  MochiSidebarGroup(
                    label: const Text("Archive"),
                    children: [item("old", TablerIcons.archive, "Last year")],
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(g.space.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: g.space.sm,
                    children: [
                      _ThemedText(_page, .section),
                      const _ThemedText("the page the sidebar points at", .muted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavSample extends StatefulWidget {
  const _BottomNavSample();

  @override
  State<_BottomNavSample> createState() => _BottomNavSampleState();
}

class _BottomNavSampleState extends State<_BottomNavSample> {
  String _page = "timer";
  String _bare = "timer";

  List<MochiBottomNavItem<String>> get _items => [
    const MochiBottomNavItem(value: "timer", icon: Icon(TablerIcons.clock), label: Text("Timer")),
    const MochiBottomNavItem(
      value: "stats",
      icon: Icon(TablerIcons.chartBar),
      label: Text("Statistics"),
      badge: MochiBadge(intent: MochiIntent.danger, appearance: MochiBadgeAppearance.solid, child: Text("3")),
    ),
    const MochiBottomNavItem(value: "sessions", icon: Icon(TablerIcons.box), label: Text("Sessions")),
    const MochiBottomNavItem(value: "settings", icon: Icon(TablerIcons.settings), label: Text("Settings")),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;

    Widget phone(Widget bar, String page) => SizedBox(
      width: 280,
      height: 200,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: theme.colors.background,
          shape: RoundedSuperellipseBorder(
            borderRadius: g.radius.lg,
            side: BorderSide(color: theme.colors.border, width: g.borderWidth),
          ),
        ),
        child: ClipRSuperellipse(
          borderRadius: g.radius.lg,
          child: Column(
            children: [
              Expanded(child: Center(child: _ThemedText(page, .muted))),
              bar,
            ],
          ),
        ),
      ),
    );

    return Row(
      spacing: g.space.lg,
      children: [
        phone(
          MochiBottomNav<String>(
            value: _page,
            items: _items,
            onChanged: (value) => setState(() => _page = value),
          ),
          _page,
        ),
        // Labels only under the one you are on.
        phone(
          MochiBottomNav<String>(
            value: _bare,
            items: _items,
            showLabels: false,
            intent: MochiIntent.success,
            onChanged: (value) => setState(() => _bare = value),
          ),
          _bare,
        ),
      ],
    );
  }
}

class _TrailSample extends StatefulWidget {
  const _TrailSample();

  @override
  State<_TrailSample> createState() => _TrailSampleState();
}

class _TrailSampleState extends State<_TrailSample> {
  String _went = "—";
  int _page = 1;
  int _far = 10;

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    MochiBreadcrumbItem step(String label, {IconData? icon, bool last = false}) => MochiBreadcrumbItem(
      label: Text(label),
      icon: icon == null ? null : Icon(icon),
      onPress: last ? null : () => setState(() => _went = label),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: g.space.md,
      children: [
        MochiBreadcrumb(
          items: [
            step("Sessions", icon: TablerIcons.home),
            step("3x3 main"),
            step("12 July", last: true),
          ],
        ),
        // Folded: the middle steps live in the … menu.
        MochiBreadcrumb(
          maxItems: 3,
          items: [
            step("Sessions", icon: TablerIcons.home),
            step("2026"),
            step("July"),
            step("12 July"),
            step("Solve 42", last: true),
          ],
        ),
        _ThemedText("went to: $_went", .muted),
        const MochiDivider(),
        MochiPagination(page: _page, pages: 5, onChanged: (page) => setState(() => _page = page)),
        MochiPagination(
          page: _far,
          pages: 20,
          around: 2,
          intent: MochiIntent.neutral,
          onChanged: (page) => setState(() => _far = page),
        ),
        const MochiPagination(page: 2, pages: 4, onChanged: null),
      ],
    );
  }
}

class _MenubarSample extends StatefulWidget {
  const _MenubarSample();

  @override
  State<_MenubarSample> createState() => _MenubarSampleState();
}

class _MenubarSampleState extends State<_MenubarSample> {
  String _last = "—";

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;

    MochiMenuItem row(String label, {String? shortcut}) => MochiMenuItem(
      title: Text(label),
      suffix: shortcut == null ? null : Text(shortcut),
      onPress: () => setState(() => _last = label),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: g.space.sm,
      children: [
        DecoratedBox(
          decoration: ShapeDecoration(
            color: theme.colors.surface,
            shape: RoundedSuperellipseBorder(
              borderRadius: g.radius.md,
              side: BorderSide(color: theme.colors.border, width: g.borderWidth),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(g.space.xs2),
            child: MochiMenubar(
              menus: [
                MochiMenubarMenu(
                  title: const Text("File"),
                  menuBuilder: (context) => [
                    row("New session", shortcut: "⌘N"),
                    row("Import…"),
                    const MochiMenuDivider(),
                    MochiSubmenu(
                      title: const Text("Export as"),
                      menuBuilder: (context) => [row("CSV"), row("JSON")],
                    ),
                  ],
                ),
                MochiMenubarMenu(
                  title: const Text("Session"),
                  menuBuilder: (context) => [
                    row("Rename", shortcut: "F2"),
                    row("Clear solves"),
                    const MochiMenuDivider(),
                    MochiMenuItem(
                      title: const Text("Delete session"),
                      intent: MochiIntent.danger,
                      onPress: () => setState(() => _last = "Delete session"),
                    ),
                  ],
                ),
                MochiMenubarMenu(
                  title: const Text("View"),
                  menuBuilder: (context) => [row("Zoom in"), row("Zoom out")],
                ),
                const MochiMenubarMenu(title: Text("Disabled"), enabled: false, menuBuilder: _none),
              ],
            ),
          ),
        ),
        _ThemedText("chose: $_last  (open one, then hover the next)", .muted),
      ],
    );
  }
}

List<Widget> _none(BuildContext context) => const [];

class _TreeSample extends StatefulWidget {
  const _TreeSample();

  @override
  State<_TreeSample> createState() => _TreeSampleState();
}

class _TreeSampleState extends State<_TreeSample> {
  String? _selected = "main";

  static const _nodes = [
    MochiTreeNode(
      value: "sessions",
      label: Text("Sessions"),
      icon: Icon(TablerIcons.folder),
      children: [
        MochiTreeNode(
          value: "3x3",
          label: Text("3x3"),
          icon: Icon(TablerIcons.box),
          children: [
            MochiTreeNode(value: "main", label: Text("main"), trailing: Text("482")),
            MochiTreeNode(value: "oh", label: Text("OH"), trailing: Text("96")),
            MochiTreeNode(value: "bld", label: Text("BLD"), enabled: false),
          ],
        ),
        MochiTreeNode(
          value: "mega",
          label: Text("Megaminx"),
          icon: Icon(TablerIcons.diamond),
          children: [MochiTreeNode(value: "mega-main", label: Text("main"), trailing: Text("31"))],
        ),
      ],
    ),
    MochiTreeNode(
      value: "archive",
      label: Text("Archive"),
      icon: Icon(TablerIcons.archive),
      children: [MochiTreeNode(value: "2025", label: Text("2025"))],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: g.space.lg,
      children: [
        SizedBox(
          width: 280,
          child: MochiCard(
            child: MochiTree<String>(
              nodes: _nodes,
              selected: _selected,
              initiallyExpanded: const {"sessions", "3x3"},
              onSelected: (value) => setState(() => _selected = value),
            ),
          ),
        ),
        // Without the indent lines, and wider steps.
        SizedBox(
          width: 240,
          child: MochiCard(
            child: MochiTree<String>(
              nodes: _nodes,
              showLines: false,
              indent: 24,
              intent: MochiIntent.success,
              initiallyExpanded: const {"sessions"},
            ),
          ),
        ),
        _ThemedText("chose: ${_selected ?? "—"}", .muted),
      ],
    );
  }
}
