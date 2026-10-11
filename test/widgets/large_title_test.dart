import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child) => MochiApp(themeMode: MochiThemeMode.light, touch: true, home: child);

  final controller = ScrollController();
  tearDownAll(controller.dispose);

  Widget page({bool extendBody = true, bool large = true}) => MochiScaffold(
    extendBody: extendBody,
    padding: EdgeInsets.zero,
    header: const MochiHeader(title: Text("Records")),
    child: ListView(
      controller: controller,
      children: [
        if (large) const MochiLargeTitle(Text("All records")),
        for (var i = 0; i < 40; i++) SizedBox(height: 40, child: Text("row $i")),
      ],
    ),
  );

  // The header's own title, by the text that is only in the header.
  double barTitleOpacity(WidgetTester tester) {
    final opacity = find.ancestor(of: find.text("Records"), matching: find.byType(Opacity));
    return opacity.evaluate().isEmpty ? 1 : tester.widget<Opacity>(opacity.first).opacity;
  }

  for (final extendBody in [true, false]) {
    testWidgets("the bar's title waits for the large one to scroll under it (extendBody: $extendBody)", (
      tester,
    ) async {
      await tester.pumpWidget(app(page(extendBody: extendBody)));
      await tester.pumpAndSettle();
      expect(find.text("All records"), findsOneWidget);
      expect(barTitleOpacity(tester), 0);

      final height = tester.getSize(find.byType(MochiLargeTitle)).height;

      // A third of the way under: still the large title's turn.
      controller.jumpTo(height / 3);
      await tester.pump();
      expect(barTitleOpacity(tester), 0);

      // Three quarters under: on its way in.
      controller.jumpTo(height * 0.75);
      await tester.pump();
      expect(barTitleOpacity(tester), inExclusiveRange(0, 1));

      // Gone: the bar has it.
      controller.jumpTo(height * 2);
      await tester.pump();
      expect(barTitleOpacity(tester), 1);

      // And back.
      controller.jumpTo(0);
      await tester.pump();
      expect(barTitleOpacity(tester), 0);
    });
  }

  testWidgets("a page without one leaves the bar's title alone", (tester) async {
    await tester.pumpWidget(app(page(large: false)));
    await tester.pumpAndSettle();
    expect(barTitleOpacity(tester), 1);
  });

  testWidgets("a large title that leaves hands the title back", (tester) async {
    await tester.pumpWidget(app(page()));
    await tester.pumpAndSettle();
    expect(barTitleOpacity(tester), 0);

    await tester.pumpWidget(app(page(large: false)));
    await tester.pumpAndSettle();
    expect(barTitleOpacity(tester), 1);
  });

  testWidgets("outside a scaffold it is only a heading", (tester) async {
    await tester.pumpWidget(app(const Center(child: MochiLargeTitle(Text("Alone")))));
    await tester.pumpAndSettle();
    expect(find.text("Alone"), findsOneWidget);
    expect(tester.getSemantics(find.text("Alone")), matchesSemantics(label: "Alone", isHeader: true));
  });
}
