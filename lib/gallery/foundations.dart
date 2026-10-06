part of "../main.dart";

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
        // Flexible, not fixed: at a narrow width a long specimen wraps rather than running off
        // the page.
        Flexible(child: Text(_text, style: style)),
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
        Wrap(
          spacing: g.space.md,
          runSpacing: g.space.md,
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
            // A title of its own, and the two ends of its line.
            SizedBox(
              width: 260,
              child: MochiCard(
                title: const Text("Records"),
                titlePrefix: Icon(TablerIcons.trophy),
                // No size: the title row itself asks for xs, which is the room it has. Still,
                // since growing inside a card's own border reads as the card moving.
                titleSuffix: MochiActionBar(scaleOnPress: false, [
                  MochiAction(icon: TablerIcons.dots, label: "More", onPress: () {}),
                ]),
                child: const Text("A card can carry its own heading."),
              ),
            ),
            // The two states a multi-select is made of.
            for (final chosen in [false, true])
              SizedBox(
                width: 170,
                child: MochiCard(
                  selected: chosen,
                  onPress: () {},
                  child: Text(chosen ? "Selected" : "Not selected"),
                ),
              ),
            // The two other appearances: a line with the page showing through, and a callout.
            SizedBox(
              width: 170,
              child: MochiCard(appearance: .outlined, onPress: () {}, child: const Text("Outlined card")),
            ),
            for (final chosen in [false, true])
              SizedBox(
                width: 170,
                child: MochiCard(
                  appearance: .soft,
                  intent: MochiIntent.info,
                  selected: chosen,
                  onPress: () {},
                  child: Text(chosen ? "Soft, selected" : "Soft card"),
                ),
              ),
          ],
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: g.space.md,
          runSpacing: g.space.md,
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
        Wrap(
          spacing: g.space.md,
          runSpacing: g.space.md,
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
        Wrap(
          spacing: g.space.xs,
          runSpacing: g.space.xs,
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
        Wrap(
          spacing: g.space.xs,
          runSpacing: g.space.xs,
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
        Wrap(
          spacing: g.space.md,
          runSpacing: g.space.md,
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
        Wrap(
          spacing: g.space.md,
          runSpacing: g.space.md,
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
        Wrap(
          spacing: g.space.md,
          runSpacing: g.space.md,
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
        Wrap(
          spacing: g.space.xs,
          runSpacing: g.space.xs,
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
        prefixes: [MochiAction.back(onPress: () => Navigator.of(context).pop())],
        // Two actions that write their labels out: an icon alone would not say which way the
        // switch is about to go.
        suffixes: [
          MochiAction(
            icon: TablerIcons.handFinger,
            label: "touch",
            showLabel: true,
            selected: theme.touch,
            onPress: () => onTouchChanged(!theme.touch),
          ),
          // Both animations are worth watching on a page this quiet: the scale eases, the colors
          // fade, and neither has the rest of the gallery rebuilding alongside it.
          MochiAction(
            icon: switch (theme.colors.brightness) {
              .light => TablerIcons.moon,
              .dark => TablerIcons.sun,
            },
            label: switch (theme.colors.brightness) {
              .light => "dark",
              .dark => "light",
            },
            showLabel: true,
            onPress: () => onModeChanged(switch (theme.colors.brightness) {
              .light => MochiThemeMode.dark,
              .dark => MochiThemeMode.light,
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
