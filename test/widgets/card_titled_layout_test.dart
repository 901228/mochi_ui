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

    testWidgets("a footer stands at the bottom of a card given more height than it needs", (tester) async {
      await tester.pumpWidget(
        app(
          Center(
            child: SizedBox(
              width: 200,
              height: 300,
              child: MochiCard(
                padding: EdgeInsets.zero,
                title: const Text("Best Ao5"),
                footer: const Text("Updated today"),
                child: const Text("12.34"),
              ),
            ),
          ),
        ),
      );

      final line = MochiGeometry.standard.borderWidth;
      final card = tester.getRect(find.byType(MochiCard));
      final value = tester.getRect(find.text("12.34"));
      final footer = tester.getRect(find.text("Updated today"));

      // Inside the card's own line.
      expect(footer.bottom, closeTo(card.bottom - line, 0.01));
      expect(footer.top, greaterThan(value.bottom + 50), reason: "pushed down, not under the content");
    });

    testWidgets("a footer without a title sits a gap under the content, and the card is no taller", (
      tester,
    ) async {
      Future<(Rect, Rect, Rect)> measure({double? gap}) async {
        await tester.pumpWidget(
          app(
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 200,
                child: MochiCard(
                  padding: EdgeInsets.zero,
                  footer: const Text("Updated today"),
                  footerGap: gap,
                  child: const Text("12.34"),
                ),
              ),
            ),
          ),
        );
        return (
          tester.getRect(find.byType(MochiCard)),
          tester.getRect(find.text("12.34")),
          tester.getRect(find.text("Updated today")),
        );
      }

      final (card, value, footer) = await measure(gap: 0);
      expect(footer.top, closeTo(value.bottom, 0.5));
      expect(footer.bottom, closeTo(card.bottom - MochiGeometry.standard.borderWidth, 0.5));

      final (bigCard, _, bigFooter) = await measure(gap: 20);
      expect(bigCard.height - card.height, closeTo(20, 0.5), reason: "the gap is the only thing that moved");
      expect(bigFooter.bottom, closeTo(bigCard.bottom - MochiGeometry.standard.borderWidth, 0.5));
    });

    testWidgets("a footer in a scroll view takes its own height and does not throw", (tester) async {
      await tester.pumpWidget(
        app(
          const SingleChildScrollView(
            child: MochiCard(footer: Text("Updated today"), child: Text("12.34")),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text("Updated today"), findsOneWidget);
    });
  });
}
