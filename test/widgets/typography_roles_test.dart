import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: false,
    home: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 360, child: child),
    ),
  );

  /// What a variable font actually reads: the axis, not the enum beside it.
  double weightOf(WidgetTester tester, String text) {
    final element = tester.element(find.text(text));
    final style = DefaultTextStyle.of(element).style.merge(tester.widget<Text>(find.text(text)).style);
    final variation = style.fontVariations?.firstWhere((v) => v.axis == "wght");

    return variation?.value ?? (style.fontWeight?.value ?? 400).toDouble();
  }

  const heading = 700.0;

  testWidgets("a collapsible's header is a heading", (tester) async {
    await tester.pumpWidget(
      app(const MochiCollapsible(title: Text("Inspection"), child: Text("Count down first."))),
    );
    await tester.pumpAndSettle();
    expect(weightOf(tester, "Inspection"), heading);
  });

  testWidgets("a toast's title is a heading over its description", (tester) async {
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => MochiButton(
            onPress: () => showMochiToast(
              context,
              title: const Text("Solve saved"),
              description: const Text("12.05 in 3x3 main."),
            ),
            child: const Text("go"),
          ),
        ),
      ),
    );
    await tester.tap(find.text("go"));
    await tester.pumpAndSettle();

    expect(weightOf(tester, "Solve saved"), heading);
    expect(weightOf(tester, "12.05 in 3x3 main."), lessThan(heading));
  });

  testWidgets("the small headings over groups are headings too", (tester) async {
    await tester.pumpWidget(
      app(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MochiTileGroup(
              label: const Text("Timer"),
              children: [MochiTile(title: const Text("Inspection"), onPress: () {})],
            ),
            SizedBox(
              height: 160,
              child: MochiSidebar(
                children: [
                  MochiSidebarGroup(
                    label: const Text("Sessions"),
                    children: [
                      MochiSidebarItem(
                        icon: Icon(MochiIcons.standard.check),
                        label: const Text("3x3"),
                        onPress: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(weightOf(tester, "Timer"), heading, reason: "tile group");
    expect(weightOf(tester, "Sessions"), heading, reason: "sidebar group");
    expect(weightOf(tester, "Inspection"), lessThan(heading), reason: "a row is not a heading");
  });

  testWidgets("a menu's label is a heading, its rows are not", (tester) async {
    await tester.pumpWidget(
      app(
        const MochiMenu(
          children: [
            MochiMenuLabel(child: Text("Record")),
            MochiMenuItem(title: Text("Rename")),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(weightOf(tester, "Record"), heading);
    expect(weightOf(tester, "Rename"), lessThan(heading));
  });

  testWidgets("labels and row titles stay in the body face", (tester) async {
    await tester.pumpWidget(
      app(
        const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MochiTextField(label: Text("Session name")),
            MochiBreadcrumb(items: [MochiBreadcrumbItem(label: Text("Sessions"))]),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // A form label and the place you are: emphasis, not headings.
    expect(weightOf(tester, "Session name"), lessThan(heading));
    expect(weightOf(tester, "Sessions"), lessThan(heading));
  });
}
