import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  // A phone's insets: a status bar on top, a home indicator below.
  const insets = EdgeInsets.only(top: 44, bottom: 34);

  // Inside home: a MediaQuery around MochiApp is replaced by the one WidgetsApp installs.
  Widget app(Widget child) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: true,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(padding: insets, viewPadding: insets),
        child: child,
      ),
    ),
  );

  const content = Key("content");

  final header = MochiHeader(variant: MochiHeaderVariant.bordered, title: const Text("Records"));
  final footer = MochiBottomNav<String>(
    value: "a",
    onChanged: (_) {},
    items: [
      MochiBottomNavItem(value: "a", icon: Icon(MochiIcons.standard.check), label: const Text("Timer")),
      MochiBottomNavItem(value: "b", icon: Icon(MochiIcons.standard.info), label: const Text("Stats")),
    ],
  );

  EdgeInsets? seen;
  Widget probe() => Builder(
    builder: (context) {
      seen = MediaQuery.paddingOf(context);
      return const SizedBox.expand(key: content);
    },
  );

  setUp(() => seen = null);

  testWidgets("the content fills the page and is told how tall the bars are", (tester) async {
    await tester.pumpWidget(
      app(
        MochiScaffold(
          extendBody: true,
          padding: EdgeInsets.zero,
          header: header,
          footer: footer,
          child: probe(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final page = tester.getRect(find.byType(MochiScaffold));
    expect(tester.getRect(find.byKey(content)), page);

    // The bars themselves reach the screen's edges and clear the insets inside their own fill.
    final bar = tester.getRect(find.byType(MochiHeader));
    final nav = tester.getRect(find.byType(MochiBottomNav<String>));
    expect(bar.top, page.top);
    // Only as tall as the bar, not the page it is laid over.
    expect(bar.height, lessThan(page.height / 4));
    expect(nav.bottom, page.bottom);
    expect(tester.getTopLeft(find.text("Records")).dy, greaterThan(insets.top));

    expect(seen!.top, bar.height);
    expect(seen!.bottom, nav.height);
  });

  testWidgets("a side without a bar keeps the system's inset, and the page padding goes inside", (
    tester,
  ) async {
    await tester.pumpWidget(
      app(MochiScaffold(extendBody: true, padding: const EdgeInsets.all(16), footer: footer, child: probe())),
    );
    await tester.pumpAndSettle();
    final nav = tester.getRect(find.byType(MochiBottomNav<String>));

    expect(seen!.top, insets.top + 16);
    expect(seen!.bottom, nav.height + 16);
    // Only the sides are padded outside the content.
    expect(tester.getRect(find.byKey(content)).left, 16);
  });

  testWidgets("a list's last row scrolls up clear of the footer", (tester) async {
    await tester.pumpWidget(
      app(
        MochiScaffold(
          extendBody: true,
          padding: EdgeInsets.zero,
          header: header,
          footer: footer,
          child: ListView(
            children: [for (var i = 0; i < 40; i++) SizedBox(height: 40, child: Text("row $i"))],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The first row starts under the header rather than behind it.
    expect(tester.getTopLeft(find.text("row 0")).dy, tester.getRect(find.byType(MochiHeader)).bottom);

    await tester.drag(find.byType(ListView), const Offset(0, -4000));
    await tester.pumpAndSettle();
    expect(
      tester.getBottomLeft(find.text("row 39")).dy,
      tester.getRect(find.byType(MochiBottomNav<String>)).top,
    );
  });

  testWidgets("off, the bars cap the content as before", (tester) async {
    await tester.pumpWidget(
      app(MochiScaffold(padding: EdgeInsets.zero, header: header, footer: footer, child: probe())),
    );
    await tester.pumpAndSettle();

    final box = tester.getRect(find.byKey(content));
    expect(box.top, tester.getRect(find.byType(MochiHeader)).bottom);
    expect(box.bottom, tester.getRect(find.byType(MochiBottomNav<String>)).top);
  });
}
