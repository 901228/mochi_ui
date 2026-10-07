part of "../main.dart";

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

    return Wrap(
      spacing: g.space.lg,
      runSpacing: g.space.lg,
      children: [
        // A phone's bar: on a wide screen the same list goes in a MochiSidebar instead.
        const SizedBox(
          width: double.infinity,
          child: _ThemedText("A phone's bar — a wide screen puts these in a sidebar instead.", .muted),
        ),
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

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.start,
      spacing: g.space.lg,
      runSpacing: g.space.lg,
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
              // More than the bar has slots for, so the last ones fold into the …: on a phone
              // that is two, from tablet width up four. Export is a menu: a dropdown while it is a
              // button, a submenu once it has been folded.
              suffixes: [
                MochiAction(icon: TablerIcons.search, label: "Search", onPress: () {}),
                MochiAction(icon: TablerIcons.filter, label: "Filter", onPress: () {}),
                MochiAction.menu(
                  icon: TablerIcons.download,
                  label: "Export",
                  children: [
                    MochiAction(icon: TablerIcons.fileTypeCsv, label: "CSV", onPress: () {}),
                    MochiAction(icon: TablerIcons.json, label: "JSON", onPress: () {}),
                    MochiAction(icon: TablerIcons.fileTypePdf, label: "PDF", onPress: () {}),
                  ],
                ),
                MochiAction(
                  icon: TablerIcons.trash,
                  label: "Delete",
                  intent: MochiIntent.danger,
                  onPress: () {},
                ),
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
              suffixes: [MochiAction(icon: TablerIcons.plus, label: "Add", onPress: () {})],
            ),
            child: const Align(alignment: .topLeft, child: Text("content")),
          ),
        ),
        // Taller, so there is a list to scroll behind the bars.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: g.space.xs,
          children: [
            SizedBox(
              width: 300,
              height: 360,
              child: MochiCard(
                padding: EdgeInsets.zero,
                child: MochiScaffold(
                  safeArea: false,
                  extendBody: true,
                  padding: EdgeInsets.zero,
                  background: const Color(0x00000000),
                  header: MochiHeader(variant: MochiHeaderVariant.bordered, title: const Text("Solves")),
                  footer: MochiBottomNav<String>(
                    value: "timer",
                    onChanged: (_) {},
                    items: const [
                      MochiBottomNavItem(value: "timer", icon: Icon(TablerIcons.clock), label: Text("Timer")),
                      MochiBottomNavItem(
                        value: "stats",
                        icon: Icon(TablerIcons.chartBar),
                        label: Text("Stats"),
                      ),
                    ],
                  ),
                  child: ListView(
                    children: [
                      for (var i = 1; i <= 30; i++)
                        MochiTile(title: Text("Solve $i"), details: Text("${10 + i % 7}.${i}4")),
                    ],
                  ),
                ),
              ),
            ),
            const _ThemedText("extendBody: the list scrolls behind both bars", .muted),
          ],
        ),
        page(
          "title center, back action",
          MochiScaffold(
            safeArea: false,
            background: const Color(0x00000000),
            header: MochiHeader(
              alignment: MochiHeaderAlignment.center,
              title: const Text("Settings"),
              prefixes: [MochiAction.back(onPress: () {})],
              suffixes: [MochiAction.close(onPress: () {})],
            ),
            child: const Align(alignment: .topLeft, child: Text("content")),
          ),
        ),
      ],
    );
  }
}
