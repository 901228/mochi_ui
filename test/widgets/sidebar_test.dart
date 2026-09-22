import "package:flutter/widgets.dart";
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
    Widget? footer,
  }) => app(
    MochiSidebar(
      collapsed: collapsed,
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
    expect(tester.getSize(find.text("Timer")).width, 0, reason: "clipped away, not unmounted");
    expect(find.byIcon(MochiIcons.standard.check), findsOneWidget, reason: "the icon stays");
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
    Widget heading() => const MochiSidebarHeading(Text("Mochi UI"), collapsedChild: Text("M"));
    await tester.pumpWidget(sidebar(header: heading()));
    await tester.pumpAndSettle();
    expect(find.text("Mochi UI"), findsOneWidget);
    expect(find.text("M"), findsNothing);

    await tester.pumpWidget(sidebar(collapsed: true, header: heading()));
    await tester.pumpAndSettle();
    expect(find.text("M"), findsOneWidget);
    expect(find.text("Mochi UI"), findsNothing);
  });

  group("groups", () {
    Widget grouped({bool collapsed = false, bool collapsible = false}) => app(
      MochiSidebar(
        collapsed: collapsed,
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
      expect(find.text("Sessions"), findsNothing, reason: "a heading over icons says nothing");
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
}
