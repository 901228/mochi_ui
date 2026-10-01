import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child) => MochiApp(themeMode: MochiThemeMode.light, home: child);

  testWidgets("header, padded content and footer stack top to bottom", (tester) async {
    await tester.pumpWidget(
      app(
        const MochiScaffold(
          header: MochiHeader(title: Text("Records")),
          footer: SizedBox(height: 40, child: Text("footer")),
          child: Text("body"),
        ),
      ),
    );

    final header = tester.getRect(find.text("Records"));
    final body = tester.getRect(find.text("body"));
    final footer = tester.getRect(find.text("footer"));
    expect(header.bottom, lessThan(body.top));
    expect(body.bottom, lessThan(footer.top));

    // Content is inset by the page padding.
    expect(body.left, greaterThan(MochiGeometry.standard.pagePadding.left - 1));
  });

  testWidgets("header actions sit on either side of the title", (tester) async {
    var back = 0;
    await tester.pumpWidget(
      app(
        MochiScaffold(
          header: MochiHeader(
            title: const Text("Settings"),
            prefixes: [MochiAction.back(onPress: () => back++)],
            suffixes: [MochiAction.close(onPress: () {})],
          ),
          child: const SizedBox(),
        ),
      ),
    );

    final title = tester.getRect(find.text("Settings"));
    // One bar either side of the title, each with its own button in it.
    expect(find.byType(MochiActionBar), findsNWidgets(2));
    expect(tester.getRect(find.byType(MochiActionBar).first).right, lessThan(title.left));
    expect(tester.getRect(find.byType(MochiActionBar).last).left, greaterThan(title.right));

    await tester.tap(find.byType(MochiActionBar).first);
    expect(back, 1);
  });

  testWidgets("the title can be centered", (tester) async {
    await tester.pumpWidget(
      app(
        MochiScaffold(
          header: MochiHeader(
            alignment: MochiHeaderAlignment.center,
            title: const Text("Settings"),
            prefixes: [MochiAction.back(onPress: () {})],
          ),
          child: const SizedBox(),
        ),
      ),
    );

    final title = tester.getCenter(find.text("Settings"));
    final header = tester.getRect(find.byType(MochiHeader));
    expect(title.dx, moreOrLessEquals(header.center.dx));
  });

  group("a centred title", () {
    MochiAction action(int at) => MochiAction(icon: TablerIcons.star, label: "Action $at", onPress: () {});

    Widget page(String title, {int prefixes = 1, int suffixes = 0, TextDirection? direction}) {
      Widget scaffold = MochiScaffold(
        header: MochiHeader(
          alignment: MochiHeaderAlignment.center,
          title: Text(title),
          prefixes: [for (var at = 0; at < prefixes; at++) action(at)],
          suffixes: [for (var at = 0; at < suffixes; at++) action(10 + at)],
          maxVisibleActions: 4,
        ),
        child: const SizedBox(),
      );
      if (direction != null) scaffold = Directionality(textDirection: direction, child: scaffold);
      return app(scaffold);
    }

    testWidgets("stays in the middle of the bar however many actions either side has", (tester) async {
      for (final suffixes in [0, 1, 3]) {
        await tester.pumpWidget(page("Records", suffixes: suffixes));
        final header = tester.getRect(find.byType(MochiHeader));
        expect(
          tester.getCenter(find.text("Records")).dx,
          moreOrLessEquals(header.center.dx),
          reason: "one action before it and $suffixes after",
        );
      }
    });

    testWidgets("a long one slides clear of the wider group instead of running into it", (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(page("A title a little too long to sit centred", prefixes: 1, suffixes: 3));

      final title = tester.getRect(find.byType(Text).first);
      final trailing = tester.getRect(find.byType(MochiActionBar).last);
      final leading = tester.getRect(find.byType(MochiActionBar).first);
      expect(title.right, lessThanOrEqualTo(trailing.left));
      expect(title.left, greaterThanOrEqualTo(leading.right));
      expect(tester.takeException(), isNull);
    });

    testWidgets("mirrors in right-to-left", (tester) async {
      await tester.pumpWidget(page("Records", suffixes: 3, direction: TextDirection.rtl));

      final header = tester.getRect(find.byType(MochiHeader));
      expect(tester.getCenter(find.text("Records")).dx, moreOrLessEquals(header.center.dx));
      expect(
        tester.getRect(find.byType(MochiActionBar).first).left,
        greaterThan(header.center.dx),
        reason: "the leading group is on the right",
      );
    });
  });

  testWidgets("the title sits on the leading side", (tester) async {
    await tester.pumpWidget(
      app(
        const MochiScaffold(
          header: MochiHeader(title: Text("Timer")),
          child: SizedBox(),
        ),
      ),
    );

    // The title fills the space between the actions, so compare its left edge, not its center.
    final title = tester.getRect(find.text("Timer"));
    final header = tester.getRect(find.byType(MochiHeader));
    expect(title.left - header.left, lessThan(MochiGeometry.standard.space.md + 1));
  });
}
