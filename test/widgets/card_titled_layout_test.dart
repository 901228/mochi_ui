import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child) => MochiApp(themeMode: MochiThemeMode.light, home: child);

  group("titled card", () {
    testWidgets("given a height, centres its content in the room under the title", (tester) async {
      await tester.pumpWidget(
        app(
          Center(
            child: SizedBox(
              width: 200,
              height: 300,
              child: MochiCard(
                padding: EdgeInsets.zero,
                title: const Text("Best Ao5"),
                child: const Center(child: Text("12.34")),
              ),
            ),
          ),
        ),
      );

      final card = tester.getRect(find.byType(MochiCard));
      final title = tester.getRect(find.text("Best Ao5"));
      final value = tester.getRect(find.text("12.34"));

      expect(card.height, 300);
      // Centred in what is left under the title, so well below the title's own line.
      expect(value.center.dy, greaterThan(title.bottom + 50));
      expect(value.bottom, lessThan(card.bottom));
    });

    testWidgets("in a scroll view, takes the content's own height and does not throw", (tester) async {
      await tester.pumpWidget(
        app(
          SingleChildScrollView(
            child: MochiCard(
              padding: EdgeInsets.zero,
              title: const Text("Title"),
              child: const Center(child: SizedBox(height: 40, width: 40)),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final card = tester.getRect(find.byType(MochiCard));
      final title = tester.getRect(find.text("Title"));
      expect(card.height, lessThan(title.height + 40 + 60));
    });

    testWidgets("merely bounded, as in a Center, it stays as short as its content", (tester) async {
      await tester.pumpWidget(
        app(
          Center(
            child: SizedBox(
              width: 200,
              child: MochiCard(
                title: const Text("Title"),
                child: const Center(child: Text("12.34")),
              ),
            ),
          ),
        ),
      );

      final card = tester.getRect(find.byType(MochiCard));
      expect(card.height, lessThan(150), reason: "not the whole screen");
    });

    testWidgets("stretched under IntrinsicHeight, matches its taller neighbour", (tester) async {
      await tester.pumpWidget(
        app(
          Center(
            child: SizedBox(
              width: 400,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: MochiCard(
                        title: const Text("Short"),
                        child: const Center(child: Text("1")),
                      ),
                    ),
                    const Expanded(child: SizedBox(height: 250)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final card = tester.getRect(find.byType(MochiCard));
      expect(card.height, 250);
      expect(
        tester.getRect(find.text("1")).center.dy,
        greaterThan(tester.getRect(find.text("Short")).bottom + 30),
      );
    });
  });
}
