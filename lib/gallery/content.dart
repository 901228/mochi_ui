part of "../main.dart";

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

    return Wrap(
      spacing: g.space.lg,
      runSpacing: g.space.lg,
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

/// Rows that slide aside: a pin behind the start, a share and a delete behind the end. Dragging
/// follows touch, so turn it on in the top bar; deleting takes the row out, and the last one
/// brings them all back.
class _SwipeSample extends StatefulWidget {
  const _SwipeSample();

  @override
  State<_SwipeSample> createState() => _SwipeSampleState();
}

class _SwipeSampleState extends State<_SwipeSample> {
  static const _all = ["12.34", "11.02", "13.87", "10.56"];
  var _times = [..._all];
  final _pinned = <String>{};

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: MochiTileGroup(
        children: [
          for (final time in _times)
            MochiSwipeActions(
              key: ValueKey(time),
              fullSwipe: true,
              leading: [
                MochiAction(
                  icon: TablerIcons.pin,
                  label: _pinned.contains(time) ? "Unpin" : "Pin",
                  intent: MochiIntent.info,
                  onPress: () =>
                      setState(() => _pinned.contains(time) ? _pinned.remove(time) : _pinned.add(time)),
                ),
              ],
              trailing: [
                MochiAction(
                  icon: TablerIcons.share,
                  label: "Share",
                  intent: MochiIntent.primary,
                  onPress: () {},
                ),
                MochiAction(
                  icon: TablerIcons.trash,
                  label: "Delete",
                  intent: MochiIntent.danger,
                  onPress: () => setState(() {
                    _times = [..._times]..remove(time);
                    if (_times.isEmpty) _times = [..._all];
                  }),
                ),
              ],
              child: MochiTile(
                prefix: _pinned.contains(time) ? const Icon(TablerIcons.pin) : null,
                title: Text(time),
                details: const Text("3x3"),
                onPress: () {},
              ),
            ),
        ],
      ),
    );
  }
}

class _AccordionSample extends StatefulWidget {
  const _AccordionSample();

  @override
  State<_AccordionSample> createState() => _AccordionSampleState();
}

class _AccordionSampleState extends State<_AccordionSample> {
  bool _multiple = false;

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: g.space.sm,
      children: [
        MochiCheckbox(
          value: _multiple,
          label: const Text("More than one at a time"),
          onChanged: (value) => setState(() => _multiple = value ?? false),
        ),
        SizedBox(
          width: 420,
          child: MochiCard(
            padding: EdgeInsets.symmetric(horizontal: g.space.sm, vertical: g.space.xs2),
            child: MochiAccordion(
              multiple: _multiple,
              initiallyExpanded: const {0},
              items: const [
                MochiAccordionItem(
                  title: Text("Inspection"),
                  child: Text("15 seconds, with a warning at 8 and 12."),
                ),
                MochiAccordionItem(
                  title: Text("Display"),
                  child: Text("Hide the time while solving, show it to two decimals after."),
                ),
                MochiAccordionItem(
                  title: Text("Advanced"),
                  child: Text("Manual entry, scramble filters, everything you can break."),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A bare collapsible whose body is a tile group: the group's shadow reaches past the body's
/// box, so this is where a clip at the box's edge shows.
class _CollapsibleSample extends StatelessWidget {
  const _CollapsibleSample();

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return SizedBox(
      width: 320,
      child: MochiCollapsible(
        expanded: const .managed(initial: true),
        title: const Text("Inspection"),
        radius: g.radius.md,
        headerPadding: EdgeInsets.symmetric(vertical: g.space.xs),
        bodyPadding: EdgeInsets.only(top: g.space.sm),
        child: MochiTileGroup(
          children: [
            MochiTile(title: const Text("Duration"), details: const Text("15s"), onPress: () {}),
            MochiTile(title: const Text("Warnings"), details: const Text("8s, 12s"), onPress: () {}),
          ],
        ),
      ),
    );
  }
}

class _RevealSample extends StatefulWidget {
  const _RevealSample();

  @override
  State<_RevealSample> createState() => _RevealSampleState();
}

class _RevealSampleState extends State<_RevealSample> {
  bool _inspection = true;

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    // What opens it is a switch in another row, so there is no header of its own to press.
    return SizedBox(
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MochiTileGroup(
            children: [
              MochiTile(
                prefix: const Icon(TablerIcons.hourglass),
                title: const Text("Inspection"),
                suffix: MochiSwitch(value: _inspection, onChanged: (v) => setState(() => _inspection = v)),
              ),
            ],
          ),
          MochiReveal(
            expanded: _inspection,
            child: Padding(
              padding: EdgeInsets.only(top: g.space.sm),
              child: MochiTileGroup(
                children: [
                  MochiTile(title: const Text("Duration"), details: const Text("15s"), onPress: () {}),
                  MochiTile(title: const Text("Warnings"), details: const Text("8s, 12s"), onPress: () {}),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarSample extends StatelessWidget {
  const _AvatarSample();

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: g.space.md,
      children: [
        Wrap(
          spacing: g.space.sm,
          runSpacing: g.space.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final size in MochiSize.values) MochiAvatar(initials: "Harry Shih", size: size),
            const MochiAvatar(),
            const MochiAvatar(initials: "3x3", shape: MochiAvatarShape.rounded),
            const MochiAvatar(icon: Icon(TablerIcons.box), shape: MochiAvatarShape.rounded),
          ],
        ),
        Wrap(
          spacing: g.space.sm,
          runSpacing: g.space.sm,
          children: [
            for (final intent in MochiIntent.values)
              MochiAvatar(initials: intent.name, intent: intent, size: MochiSize.sm),
          ],
        ),
        const MochiAvatarGroup(
          max: 4,
          size: MochiSize.sm,
          children: [
            MochiAvatar(initials: "A", intent: MochiIntent.primary),
            MochiAvatar(initials: "B", intent: MochiIntent.success),
            MochiAvatar(initials: "C", intent: MochiIntent.warning),
            MochiAvatar(initials: "D", intent: MochiIntent.danger),
            MochiAvatar(initials: "E"),
            MochiAvatar(initials: "F"),
          ],
        ),
      ],
    );
  }
}

class _SkeletonSample extends StatelessWidget {
  const _SkeletonSample();

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Wrap(
      spacing: g.space.md,
      runSpacing: g.space.md,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        // What a row of content looks like before it arrives: the same shapes, at the same sizes.
        SizedBox(
          width: 320,
          child: MochiCard(
            child: Row(
              spacing: g.space.md,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MochiSkeleton.circle(size: 40),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MochiSkeleton(width: 120, height: 14),
                      SizedBox(height: 12),
                      MochiSkeleton.text(lines: 3),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: g.space.sm,
            children: [
              const _ThemedText("shimmer", .muted),
              const MochiSkeleton(height: 56),
              const _ThemedText("pulse", .muted),
              const MochiSkeleton(height: 56, effect: MochiSkeletonEffect.pulse),
              const _ThemedText("none", .muted),
              const MochiSkeleton(height: 56, effect: MochiSkeletonEffect.none),
            ],
          ),
        ),
      ],
    );
  }
}

class _SortableSample extends StatefulWidget {
  const _SortableSample();

  @override
  State<_SortableSample> createState() => _SortableSampleState();
}

class _SortableSampleState extends State<_SortableSample> {
  final _steps = ["Cross", "F2L", "OLL", "PLL", "Inspection"];

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Wrap(
      spacing: g.space.md,
      runSpacing: g.space.md,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        SizedBox(
          width: 320,
          height: 5 * 52,
          child: MochiSortable(
            itemCount: _steps.length,
            spacing: g.space.xs2,
            onReorder: (from, to) => setState(() => _steps.insert(to, _steps.removeAt(from))),
            itemBuilder: (context, index) => MochiCard(
              key: ValueKey(_steps[index]),
              padding: EdgeInsets.symmetric(horizontal: g.space.md, vertical: g.space.sm),
              child: Row(
                children: [
                  Expanded(child: Text(_steps[index])),
                  MochiSortableHandle(index: index),
                ],
              ),
            ),
          ),
        ),
        _ThemedText(_steps.join(" → "), .muted),
      ],
    );
  }
}

class _RefreshSample extends StatefulWidget {
  const _RefreshSample();

  @override
  State<_RefreshSample> createState() => _RefreshSampleState();
}

class _RefreshSampleState extends State<_RefreshSample> {
  int _round = 1;

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return SizedBox(
      width: 320,
      height: 260,
      child: MochiCard(
        padding: EdgeInsets.zero,
        child: MochiRefresh(
          onRefresh: () async {
            await Future<void>.delayed(const Duration(milliseconds: 1200));
            if (mounted) setState(() => _round++);
          },
          child: ListView(
            padding: EdgeInsets.all(g.space.sm),
            children: [
              for (var i = 0; i < 8; i++)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: g.space.xs2),
                  child: Text("solve ${_round * 10 + i}"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResizableSample extends StatefulWidget {
  const _ResizableSample();

  @override
  State<_ResizableSample> createState() => _ResizableSampleState();
}

class _ResizableSampleState extends State<_ResizableSample> {
  List<double> _split = const [0.3, 0.7];

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;
    final colors = context.colors;

    Widget panel(String label) => ColoredBox(
      color: colors.surface,
      child: Padding(padding: EdgeInsets.all(g.space.md), child: _ThemedText(label, .muted)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: g.space.sm,
      children: [
        SizedBox(
          width: 560,
          height: 220,
          child: MochiCard(
            padding: EdgeInsets.zero,
            child: MochiResizable(
              onChanged: (fractions) => setState(() => _split = fractions),
              panes: [
                MochiResizablePane(initialFraction: 0.3, minSize: 120, child: panel("sessions")),
                MochiResizablePane(
                  minSize: 200,
                  child: MochiResizable(
                    axis: Axis.vertical,
                    panes: [
                      MochiResizablePane(initialFraction: 0.6, minSize: 60, child: panel("solves")),
                      MochiResizablePane(minSize: 60, child: panel("statistics")),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _ThemedText(_split.map((f) => f.toStringAsFixed(2)).join(" / "), .muted),
      ],
    );
  }
}
