import "package:flutter/gestures.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: false,
    home: Center(child: child),
  );

  Widget pagination({
    int page = 1,
    int pages = 20,
    int around = 1,
    ValueChanged<int>? onChanged,
    bool showArrows = true,
  }) => app(
    MochiPagination(page: page, pages: pages, around: around, showArrows: showArrows, onChanged: onChanged),
  );

  List<String> numbers(WidgetTester tester) => tester
      .widgetList<Text>(find.descendant(of: find.byType(MochiPagination), matching: find.byType(Text)))
      .map((t) => t.data!)
      .toList();

  testWidgets("every page is written out while they fit", (tester) async {
    await tester.pumpWidget(pagination(pages: 4, onChanged: (_) {}));
    await tester.pumpAndSettle();
    expect(numbers(tester), ["1", "2", "3", "4"]);
  });

  testWidgets("a long run keeps the ends and folds the rest into gaps", (tester) async {
    await tester.pumpWidget(pagination(page: 10, pages: 20, onChanged: (_) {}));
    await tester.pumpAndSettle();
    expect(numbers(tester), ["1", "…", "9", "10", "11", "…", "20"]);
  });

  testWidgets("a gap of exactly one page is that page, not a …", (tester) async {
    await tester.pumpWidget(pagination(page: 3, pages: 5, onChanged: (_) {}));
    await tester.pumpAndSettle();
    expect(numbers(tester), ["1", "2", "3", "4", "5"]);
  });

  testWidgets("around widens what is written out", (tester) async {
    await tester.pumpWidget(pagination(page: 10, pages: 20, around: 2, onChanged: (_) {}));
    await tester.pumpAndSettle();
    expect(numbers(tester), ["1", "…", "8", "9", "10", "11", "12", "…", "20"]);
  });

  testWidgets("pressing a number goes there; pressing the current one does nothing", (tester) async {
    final seen = <int>[];
    await tester.pumpWidget(pagination(page: 10, pages: 20, onChanged: seen.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text("11"));
    expect(seen, [11]);

    await tester.tap(find.text("10"));
    expect(seen, [11]);
  });

  testWidgets("the arrows step, and stop at the ends", (tester) async {
    final seen = <int>[];
    await tester.pumpWidget(pagination(page: 1, pages: 3, onChanged: seen.add));
    await tester.pumpAndSettle();

    Finder arrow(IconData icon) => find.ancestor(of: find.byIcon(icon), matching: find.byType(MochiButton));
    expect(tester.widget<MochiButton>(arrow(MochiIcons.standard.chevronLeft)).enabled, isFalse);

    await tester.tap(arrow(MochiIcons.standard.chevronRight));
    expect(seen, [2]);

    await tester.pumpWidget(pagination(page: 3, pages: 3, onChanged: seen.add));
    await tester.pumpAndSettle();
    expect(tester.widget<MochiButton>(arrow(MochiIcons.standard.chevronRight)).enabled, isFalse);
  });

  testWidgets("the current page is the solid one", (tester) async {
    await tester.pumpWidget(pagination(page: 2, pages: 3, onChanged: (_) {}));
    await tester.pumpAndSettle();

    MochiButton buttonFor(String label) =>
        tester.widget<MochiButton>(find.ancestor(of: find.text(label), matching: find.byType(MochiButton)));
    expect(buttonFor("2").appearance, MochiButtonAppearance.solid);
    expect(buttonFor("1").appearance, MochiButtonAppearance.ghost);
  });

  testWidgets("no arrows when they are turned off, and null onChanged disables it", (tester) async {
    await tester.pumpWidget(pagination(pages: 3, showArrows: false, onChanged: (_) {}));
    await tester.pumpAndSettle();
    expect(find.byIcon(MochiIcons.standard.chevronRight), findsNothing);

    await tester.pumpWidget(pagination(page: 2, pages: 3, onChanged: null));
    await tester.pumpAndSettle();
    final buttons = tester.widgetList<MochiButton>(find.byType(MochiButton));
    expect(buttons.every((b) => !b.enabled), isTrue);
  });

  testWidgets("the row keeps its width whatever page it is on", (tester) async {
    final widths = <double>[];
    final counts = <int>{};
    for (final page in [1, 2, 3, 5, 10, 16, 18, 19, 20]) {
      await tester.pumpWidget(pagination(page: page, pages: 20, onChanged: (_) {}));
      await tester.pumpAndSettle();
      widths.add(tester.getSize(find.byType(MochiPagination)).width);
      counts.add(numbers(tester).length);
    }
    expect(counts.length, 1, reason: "the same number of slots on every page: $counts");
    expect(widths.toSet().length, 1, reason: "and so the same width: $widths");
  });

  testWidgets("the window grows at the ends to fill the room a gap gives back", (tester) async {
    await tester.pumpWidget(pagination(page: 2, pages: 20, onChanged: (_) {}));
    await tester.pumpAndSettle();
    expect(numbers(tester), ["1", "2", "3", "4", "5", "…", "20"]);

    await tester.pumpWidget(pagination(page: 19, pages: 20, onChanged: (_) {}));
    await tester.pumpAndSettle();
    expect(numbers(tester), ["1", "…", "16", "17", "18", "19", "20"]);
  });

  testWidgets("a narrow row gives up the pages either side before it runs off the page", (tester) async {
    // The ends, the gaps and the page you are on are what it cannot do without.
    Future<void> show(double width) async {
      await tester.pumpWidget(
        MochiApp(
          themeMode: MochiThemeMode.light,
          touch: false,
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: MochiPagination(page: 10, pages: 20, around: 2, onChanged: (_) {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await show(600);
    expect(find.text("8"), findsOneWidget, reason: "two either side, with room to spare");

    await show(200);
    expect(tester.takeException(), isNull);
    expect(find.text("8"), findsNothing, reason: "the window gave way first");
    expect(find.text("10"), findsOneWidget, reason: "the page you are on stays");
    expect(find.text("1"), findsOneWidget);
    expect(find.text("20"), findsOneWidget);
  });

  group("the … is the way back to the pages it hides", () {
    Future<void> open(WidgetTester tester) async {
      await tester.tap(find.text("…").first, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
    }

    Future<void> type(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(MochiTextField), text);
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pumpAndSettle();
    }

    testWidgets("typing a page goes to it", (tester) async {
      int? asked;
      await tester.pumpWidget(pagination(page: 10, pages: 20, onChanged: (next) => asked = next));
      await tester.pumpAndSettle();

      await open(tester);
      expect(find.byType(MochiTextField), findsOneWidget);

      await type(tester, "17");
      expect(asked, 17);
      expect(find.byType(MochiTextField), findsNothing, reason: "asked and answered");
    });

    testWidgets("a page outside the run lands on the nearest end", (tester) async {
      int? asked;
      await tester.pumpWidget(pagination(page: 10, pages: 20, onChanged: (next) => asked = next));
      await tester.pumpAndSettle();

      await open(tester);
      await type(tester, "99");
      expect(asked, 20);
    });

    testWidgets("nothing typed is nothing asked", (tester) async {
      int? asked;
      await tester.pumpWidget(pagination(page: 10, pages: 20, onChanged: (next) => asked = next));
      await tester.pumpAndSettle();

      await open(tester);
      await type(tester, "");
      expect(asked, isNull, reason: "a blank field is not an instruction to go anywhere");
    });

    testWidgets("a row that cannot be paged has nothing to jump to either", (tester) async {
      await tester.pumpWidget(pagination(page: 10, pages: 20, onChanged: null));
      await tester.pumpAndSettle();

      await tester.tap(find.text("…").first, kind: PointerDeviceKind.mouse, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(MochiTextField), findsNothing);
    });

    testWidgets("turning it off leaves the … as it was", (tester) async {
      await tester.pumpWidget(app(MochiPagination(page: 10, pages: 20, jumpable: false, onChanged: (_) {})));
      await tester.pumpAndSettle();

      await tester.tap(find.text("…").first, kind: PointerDeviceKind.mouse, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(MochiTextField), findsNothing);
    });

    testWidgets("it costs the row no width", (tester) async {
      await tester.pumpWidget(pagination(page: 10, pages: 20, onChanged: (_) {}));
      await tester.pumpAndSettle();
      final jumpable = tester.getSize(find.byType(MochiPagination)).width;

      await tester.pumpWidget(app(MochiPagination(page: 10, pages: 20, jumpable: false, onChanged: (_) {})));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(MochiPagination)).width, jumpable);
    });
  });
}
