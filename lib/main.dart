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
          const _ThemedText("transitions", .section),
          const SizedBox(height: 12),
          const _TransitionSample(),
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
            size: MochiButtonSize.sm,
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
              size: MochiButtonSize.sm,
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
              size: MochiButtonSize.sm,
              focusNode: anchor.focusNode,
              onPress: anchor.toggle,
              child: Text("align ${align.name}"),
            ),
          ),
        // Opened at the pointer rather than against an edge: the shape a context menu takes
        // once MochiContextMenu lands.
        MochiPopover(
          align: MochiPopoverAlign.start,
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

    return Row(
      spacing: g.space.md,
      children: [
        MochiPopoverMenu(
          menuBuilder: _items,
          builder: (context, anchor, _) => MochiButton(
            appearance: MochiButtonAppearance.outlined,
            size: MochiButtonSize.sm,
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
            size: MochiButtonSize.sm,
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

    return Row(
      spacing: g.space.md,
      children: [
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          size: MochiButtonSize.sm,
          onPress: () => _confirm(context),
          child: const Text("confirm"),
        ),
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          size: MochiButtonSize.sm,
          onPress: () => _long(context),
          child: const Text("long body"),
        ),
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          size: MochiButtonSize.sm,
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
            size: MochiButtonSize.sm,
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
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          size: MochiButtonSize.sm,
          onPress: () => showMochiToast(
            context,
            title: const Text("Saved"),
            icon: const Icon(TablerIcons.check),
            intent: MochiIntent.success,
          ),
          child: const Text("plain"),
        ),
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          size: MochiButtonSize.sm,
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
                size: MochiButtonSize.xs,
                onPress: () => handle.dismiss(),
                child: const Text("Undo"),
              ),
            );
          },
          child: const Text("with undo"),
        ),
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          size: MochiButtonSize.sm,
          onPress: () {
            for (var i = 1; i <= 4; i++) {
              showMochiToast(context, title: Text("Message $i"), duration: const Duration(seconds: 6));
            }
          },
          child: const Text("four at once"),
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
            size: MochiButtonSize.sm,
            selected: theme.touch,
            onPress: () => onTouchChanged(!theme.touch),
            prefix: const Icon(TablerIcons.handFinger),
            child: const Text("touch"),
          ),
          // Both animations are worth watching on a page this quiet: the scale eases, the colors
          // fade, and neither has the rest of the gallery rebuilding alongside it.
          MochiButton(
            appearance: MochiButtonAppearance.ghost,
            size: MochiButtonSize.sm,
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
                for (final size in MochiButtonSize.values)
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
              child: MochiButton(size: MochiButtonSize.sm, onPress: () {}, child: const Text("Add solve")),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: g.space.lg,
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
