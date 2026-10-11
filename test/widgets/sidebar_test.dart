import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child, {bool touch = false}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: touch,
    home: Row(
      children: [
        child,
        const Expanded(child: SizedBox.shrink()),
      ],
    ),
  );

  Widget sidebar({
    bool collapsed = false,
    List<String> pressed = const [],
    String selected = "timer",
    Widget? header,
    List<Widget> footer = const [],
  }) => app(
    MochiSidebar(
      collapsed: .lifted(value: collapsed, onChanged: (_) {}),
      header: header,
      footer: footer,
      children: [
        MochiSidebarItem(
          icon: Icon(MochiIcons.standard.check),
          label: const Text("Timer"),
          selected: selected == "timer",
          onPress: () => pressed.add("timer"),
        ),
        MochiSidebarItem(
          icon: Icon(MochiIcons.standard.info),
          label: const Text("Statistics"),
          trailing: const Text("12"),
          selected: selected == "stats",
          onPress: () => pressed.add("stats"),
        ),
        MochiSidebarItem(icon: Icon(MochiIcons.standard.close), label: const Text("Nothing here")),
      ],
    ),
  );

  testWidgets("items press, and the chosen one is tinted in the intent", (tester) async {
    final pressed = <String>[];
    await tester.pumpWidget(sidebar(pressed: pressed));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Statistics"));
    expect(pressed, ["stats"]);

    Color fillOf(String label) =>
        (tester
                    .widget<Container>(
                      find
                          .descendant(
                            of: find.ancestor(of: find.text(label), matching: find.byType(MochiSidebarItem)),
                            matching: find.byType(Container),
                          )
                          .first,
                    )
                    .decoration!
                as ShapeDecoration)
            .color!;
    expect(fillOf("Timer"), MochiColors.light.softOn(MochiColors.light.primary, MochiColors.light.surface));
    expect(fillOf("Statistics"), MochiColors.light.surface);
  });

  testWidgets("an item without a handler can't be pressed", (tester) async {
    await tester.pumpWidget(sidebar());
    await tester.pumpAndSettle();

    final tappable = tester.widget<MochiTappable>(
      find.descendant(
        of: find.ancestor(of: find.text("Nothing here"), matching: find.byType(MochiSidebarItem)),
        matching: find.byType(MochiTappable),
      ),
    );
    expect(tappable.interactive, isFalse);
  });

  testWidgets("collapsing narrows it to a rail and takes the labels away", (tester) async {
    await tester.pumpWidget(sidebar());
    await tester.pumpAndSettle();
    final wide = tester.getSize(find.byType(MochiSidebar)).width;
    expect(wide, 240);
    expect(tester.getSize(find.text("Timer")).width, greaterThan(0));

    await tester.pumpWidget(sidebar(collapsed: true));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MochiSidebar)).width, 56);
    // Still in the tree, clipped to nothing: the row keeps one shape the whole way, which is
    // what lets the icon slide to the middle instead of jumping there.
    expect(
      tester
          .getSize(
            find
                .descendant(
                  of: find.ancestor(of: find.text("Timer"), matching: find.byType(MochiSidebarItem)),
                  matching: find.byType(ClipRect),
                )
                .first,
          )
          .width,
      0,
    );
    expect(find.byIcon(MochiIcons.standard.check), findsOneWidget, reason: "the icon stays");
  });

  testWidgets("a rail centres its icons", (tester) async {
    await tester.pumpWidget(sidebar(collapsed: true));
    await tester.pumpAndSettle();

    final bar = tester.getRect(find.byType(MochiSidebar));
    final icon = tester.getRect(find.byIcon(MochiIcons.standard.check));
    expect(icon.center.dx, closeTo(bar.center.dx, 1));
    expect(icon.width, icon.height, reason: "and it is still square");
  });

  testWidgets("the width is animated, not switched", (tester) async {
    await tester.pumpWidget(sidebar());
    await tester.pumpAndSettle();

    await tester.pumpWidget(sidebar(collapsed: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final midway = tester.getSize(find.byType(MochiSidebar)).width;
    expect(midway, lessThan(240));
    expect(midway, greaterThan(56));

    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MochiSidebar)).width, 56);
  });

  testWidgets("the icon slides to the middle of the rail, never jumps or swings past it", (tester) async {
    await tester.pumpWidget(sidebar());
    await tester.pumpAndSettle();
    double iconX() => tester.getRect(find.byIcon(MochiIcons.standard.check)).center.dx;
    final start = iconX();

    await tester.pumpWidget(sidebar(collapsed: true));
    var previous = start;
    var biggestStep = 0.0;
    var wentBack = false;
    for (var frame = 0; frame < 40; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      final now = iconX();
      final step = now - previous;
      if (step.abs() > biggestStep) biggestStep = step.abs();
      if (step < -0.01) wentBack = true;
      previous = now;
    }

    await tester.pumpAndSettle();
    final bar = tester.getRect(find.byType(MochiSidebar));
    expect(iconX(), closeTo(bar.center.dx, 1), reason: "it ends up in the middle");
    expect(biggestStep, lessThan(1), reason: "no frame carries the move on its own");
    // Aiming at the middle of the row it is in — which is still sliding left — would send it out
    // to the right first and bring it back.
    expect(wentBack, isFalse, reason: "it walks one way");
  });

  testWidgets("a collapsed item says its label in a tooltip", (tester) async {
    await tester.pumpWidget(sidebar());
    await tester.pumpAndSettle();
    expect(find.byType(MochiTooltip), findsNothing);

    await tester.pumpWidget(sidebar(collapsed: true));
    await tester.pumpAndSettle();
    final tooltips = tester.widgetList<MochiTooltip>(find.byType(MochiTooltip)).map((t) => t.message);
    expect(tooltips, containsAll(["Timer", "Statistics"]));
  });

  testWidgets("the heading swaps for its short form on a rail", (tester) async {
    // No button of its own, so the short form is what a rail shows.
    Widget heading() =>
        const MochiSidebarHeading(Text("Mochi UI"), collapsedChild: Text("M"), automaticTrailing: false);
    await tester.pumpWidget(sidebar(header: heading()));
    await tester.pumpAndSettle();
    expect(find.text("Mochi UI"), findsOneWidget);
    expect(find.text("M"), findsNothing);

    await tester.pumpWidget(sidebar(collapsed: true, header: heading()));
    await tester.pumpAndSettle();
    expect(find.text("M"), findsOneWidget);
    expect(find.text("Mochi UI"), findsNothing);
  });

  testWidgets("the heading's trailing is what a rail keeps", (tester) async {
    Widget heading() => MochiSidebarHeading(
      const Text("Mochi UI"),
      collapsedChild: const Text("M"),
      trailing: MochiButton.icon(
        onPress: () {},
        icon: Icon(MochiIcons.standard.chevronLeft),
        semanticLabel: "Collapse",
      ),
    );

    await tester.pumpWidget(sidebar(header: heading()));
    await tester.pumpAndSettle();
    expect(find.text("Mochi UI"), findsOneWidget);
    expect(find.byIcon(MochiIcons.standard.chevronLeft), findsOneWidget);

    await tester.pumpWidget(sidebar(collapsed: true, header: heading()));
    await tester.pumpAndSettle();
    // One thing wide, and the one worth keeping is what gets the sidebar back.
    expect(find.byIcon(MochiIcons.standard.chevronLeft), findsOneWidget);
    expect(find.text("M"), findsNothing);
    expect(find.text("Mochi UI"), findsNothing);
  });

  group("groups", () {
    Widget grouped({bool collapsed = false, bool collapsible = false}) => app(
      MochiSidebar(
        collapsed: .lifted(value: collapsed, onChanged: (_) {}),
        children: [
          MochiSidebarGroup(
            label: const Text("Sessions"),
            collapsible: collapsible,
            children: [
              MochiSidebarItem(
                icon: Icon(MochiIcons.standard.check),
                label: const Text("3x3 main"),
                onPress: () {},
              ),
              MochiSidebarItem(
                icon: Icon(MochiIcons.standard.check),
                label: const Text("3x3 OH"),
                onPress: () {},
              ),
            ],
          ),
        ],
      ),
    );

    testWidgets("a heading over its items, gone on a rail", (tester) async {
      await tester.pumpWidget(grouped());
      await tester.pumpAndSettle();
      expect(find.text("Sessions"), findsOneWidget);
      expect(find.text("3x3 main"), findsOneWidget);

      await tester.pumpWidget(grouped(collapsed: true));
      await tester.pumpAndSettle();
      // Folded to nothing rather than taken out, so the column's height changes as smoothly as
      // its width: a heading over icons says nothing, but it has to leave gracefully.
      expect(
        tester
            .getSize(find.ancestor(of: find.text("Sessions"), matching: find.byType(ClipRect)).first)
            .height,
        0,
      );
      expect(find.byType(MochiSidebarItem), findsNWidgets(2));
    });

    testWidgets("collapsible folds its items away", (tester) async {
      await tester.pumpWidget(grouped(collapsible: true));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.text("3x3 main")).height, greaterThan(0));

      await tester.tap(find.text("Sessions"));
      await tester.pumpAndSettle();
      expect(find.text("3x3 main"), findsNothing);

      await tester.tap(find.text("Sessions"));
      await tester.pumpAndSettle();
      expect(find.text("3x3 main"), findsOneWidget);
    });

    testWidgets("a folded group shows its items again on a rail", (tester) async {
      await tester.pumpWidget(grouped(collapsible: true));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Sessions"));
      await tester.pumpAndSettle();
      expect(find.text("3x3 main"), findsNothing);

      await tester.pumpWidget(grouped(collapsed: true, collapsible: true));
      await tester.pumpAndSettle();
      // The heading that folded them is gone, so hiding them would leave no way back.
      expect(find.text("3x3 main"), findsOneWidget);
    });

    testWidgets("the heading's height eases away with the rail", (tester) async {
      await tester.pumpWidget(grouped());
      await tester.pumpAndSettle();
      double headingHeight() => tester
          .getSize(find.ancestor(of: find.text("Sessions"), matching: find.byType(ClipRect)).first)
          .height;
      final full = headingHeight();
      expect(full, greaterThan(0));

      await tester.pumpWidget(grouped(collapsed: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      final midway = headingHeight();
      expect(midway, lessThan(full));
      expect(midway, greaterThan(0), reason: "on its way, not gone");
    });

    testWidgets("the chevron goes with the heading, rather than hanging about unpressable", (tester) async {
      await tester.pumpWidget(grouped(collapsible: true));
      await tester.pumpAndSettle();
      expect(find.byIcon(MochiIcons.standard.chevronDown), findsOneWidget);

      await tester.pumpWidget(grouped(collapsed: true, collapsible: true));
      await tester.pumpAndSettle();
      final header = find
          .ancestor(of: find.byIcon(MochiIcons.standard.chevronDown), matching: find.byType(ClipRect))
          .first;
      expect(tester.getSize(header).height, 0, reason: "folded away with the name it belonged to");
    });
  });

  testWidgets("rows are taller on touch", (tester) async {
    await tester.pumpWidget(sidebar());
    await tester.pumpAndSettle();
    final desktop = tester.getSize(find.byType(MochiSidebarItem).first).height;

    await tester.pumpWidget(app(const SizedBox.shrink()));
    await tester.pumpWidget(
      MochiApp(
        themeMode: MochiThemeMode.light,
        touch: true,
        home: Row(
          children: [
            MochiSidebar(
              children: [
                MochiSidebarItem(
                  icon: Icon(MochiIcons.standard.check),
                  label: const Text("Timer"),
                  onPress: () {},
                ),
              ],
            ),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MochiSidebarItem).first).height, greaterThan(desktop));
  });

  group("footer", () {
    final footer = [
      MochiSidebarItem(icon: Icon(MochiIcons.standard.plus), label: const Text("Account"), onPress: () {}),
      MochiSidebarItem(icon: Icon(MochiIcons.standard.minus), label: const Text("Help"), onPress: () {}),
    ];
    Rect row(WidgetTester tester, String label) =>
        tester.getRect(find.ancestor(of: find.text(label), matching: find.byType(MochiSidebarItem)));

    testWidgets("holds several rows, inset and spaced like the items", (tester) async {
      await tester.pumpWidget(sidebar(footer: footer));
      await tester.pumpAndSettle();
      final g = MochiTheme.light.geometry;
      final bar = tester.getRect(find.byType(MochiSidebar));

      // Lined up with the items rather than running into the sidebar's edge.
      expect(row(tester, "Account").left, row(tester, "Timer").left);
      expect(row(tester, "Account").left - bar.left, g.space.xs2);
      expect(bar.bottom - row(tester, "Help").bottom, g.space.xs2);
      expect(row(tester, "Help").top - row(tester, "Account").bottom, g.space.xs3);
    });

    testWidgets("its icons find the same middle on a rail as the items' do", (tester) async {
      await tester.pumpWidget(sidebar(collapsed: true, footer: footer));
      await tester.pumpAndSettle();
      expect(
        tester.getCenter(find.byIcon(MochiIcons.standard.plus)).dx,
        closeTo(tester.getCenter(find.byIcon(MochiIcons.standard.check)).dx, 0.5),
      );
    });
  });

  group("control", () {
    Widget heading() => const MochiSidebarHeading(Text("Mochi UI"), collapsedChild: Text("M"));
    Widget sidebarWith(MochiControl<bool>? control, {Widget? header}) => app(
      MochiSidebar(
        collapsed: control,
        header: header ?? heading(),
        children: [
          MochiSidebarItem(icon: Icon(MochiIcons.standard.check), label: const Text("Timer"), onPress: () {}),
        ],
      ),
    );
    double width(WidgetTester tester) => tester.getSize(find.byType(MochiSidebar)).width;
    final collapse = find.byIcon(MochiIcons.standard.sidebarCollapse);
    final expand = find.byIcon(MochiIcons.standard.sidebarExpand);

    testWidgets("managed, its heading's button narrows it and widens it again", (tester) async {
      final seen = <bool>[];
      await tester.pumpWidget(sidebarWith(.managed(onChanged: seen.add)));
      await tester.pumpAndSettle();
      expect(width(tester), 240);

      await tester.tap(collapse);
      await tester.pumpAndSettle();
      expect(width(tester), 56);
      // On a rail the button is what the heading keeps: it is the way back.
      expect(find.text("M"), findsNothing);

      await tester.tap(expand);
      await tester.pumpAndSettle();
      expect(width(tester), 240);
      expect(seen, [true, false]);
    });

    testWidgets("managed, it can start as a rail", (tester) async {
      await tester.pumpWidget(sidebarWith(const .managed(initial: true)));
      await tester.pumpAndSettle();
      expect(width(tester), 56);
    });

    testWidgets("lifted, the button only asks; the app decides", (tester) async {
      final seen = <bool>[];
      await tester.pumpWidget(sidebarWith(.lifted(value: false, onChanged: seen.add)));
      await tester.pumpAndSettle();

      await tester.tap(collapse);
      await tester.pumpAndSettle();
      expect(seen, [true]);
      expect(width(tester), 240, reason: "nothing moves until the app rebuilds it");

      await tester.pumpWidget(sidebarWith(.lifted(value: true, onChanged: seen.add)));
      await tester.pumpAndSettle();
      expect(width(tester), 56);
    });

    testWidgets("handed back to the sidebar, it stays where the app left it", (tester) async {
      await tester.pumpWidget(sidebarWith(.lifted(value: true, onChanged: (_) {})));
      await tester.pumpAndSettle();
      await tester.pumpWidget(sidebarWith(const .managed()));
      await tester.pumpAndSettle();
      expect(width(tester), 56);
    });

    testWidgets("collapsed: null keeps it at its full width with no button", (tester) async {
      await tester.pumpWidget(sidebarWith(null));
      await tester.pumpAndSettle();
      expect(width(tester), 240);
      expect(collapse, findsNothing);
    });

    testWidgets("said nothing about, it collapses by itself", (tester) async {
      await tester.pumpWidget(
        app(
          MochiSidebar(
            header: heading(),
            children: [
              MochiSidebarItem(
                icon: Icon(MochiIcons.standard.check),
                label: const Text("Timer"),
                onPress: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(width(tester), 240);
      await tester.tap(collapse);
      await tester.pumpAndSettle();
      expect(width(tester), 56);
    });

    testWidgets("in a scaffold's drawer it is a list, with no rail and no button", (tester) async {
      await tester.pumpWidget(
        MochiApp(
          themeMode: MochiThemeMode.light,
          home: ResponsiveScope(
            size: MochiScreenSize.mobile,
            child: MochiScaffold(
              header: const MochiHeader(title: Text("Home")),
              drawer: MochiSidebar(
                header: heading(),
                children: [
                  MochiSidebarItem(
                    icon: Icon(MochiIcons.standard.check),
                    label: const Text("Timer"),
                    onPress: () {},
                  ),
                ],
              ),
              child: const Text("page"),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      MochiScaffold.of(tester.element(find.text("page"))).openDrawer();
      await tester.pumpAndSettle();
      expect(find.text("Timer"), findsOneWidget);
      expect(collapse, findsNothing);
    });

    testWidgets("a heading with a trailing of its own, or told not to, gets no button", (tester) async {
      await tester.pumpWidget(
        sidebarWith(
          const .managed(),
          header: const MochiSidebarHeading(Text("Mochi UI"), trailing: Text("mine")),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("mine"), findsOneWidget);
      expect(collapse, findsNothing);

      await tester.pumpWidget(
        sidebarWith(
          const .managed(),
          header: const MochiSidebarHeading(Text("Mochi UI"), automaticTrailing: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(collapse, findsNothing);
    });
  });
}
