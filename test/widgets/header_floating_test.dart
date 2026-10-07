import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

import "../support/surface.dart";

void main() {
  const statusBar = 44.0;

  Widget app({required bool touch, MochiHeaderVariant? variant}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: touch,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(padding: const EdgeInsets.only(top: statusBar)),
        child: Align(
          alignment: Alignment.topCenter,
          child: MochiHeader(variant: variant, title: const Text("Records")),
        ),
      ),
    ),
  );

  final g = MochiGeometry.standard;
  Finder header() => find.byType(MochiHeader);
  Rect bar(WidgetTester tester) =>
      tester.getRect(find.descendant(of: header(), matching: find.byType(Container)).first);

  testWidgets("a raised theme floats it: clear of the edges, rounded, lifted, no line", (tester) async {
    await tester.pumpWidget(app(touch: true));
    await tester.pumpAndSettle();

    final page = tester.getRect(header());
    expect(bar(tester).left, page.left + g.space.md);
    expect(bar(tester).right, page.right - g.space.md);
    // Under the status bar, not behind it.
    expect(bar(tester).top, page.top + statusBar + g.space.xs);

    final surface = surfaceOf(tester, header());
    expect(surface.color, MochiColors.light.overlay);
    final shape = surface.shape as OutlinedBorder;
    expect(shape.side.color.a, 0);
    expect((shape as dynamic).borderRadius, g.radius.xl);
    expect(shadowsOf(tester, header()), isNotEmpty);
  });

  testWidgets("an outlined theme keeps it plain", (tester) async {
    await tester.pumpWidget(app(touch: false));
    await tester.pumpAndSettle();
    final container = tester.widget<Container>(
      find.descendant(of: header(), matching: find.byType(Container)).first,
    );
    expect(container.decoration, isNull);
    expect(bar(tester), tester.getRect(header()));
  });

  testWidgets("a variant asked for is kept whatever the layering", (tester) async {
    await tester.pumpWidget(app(touch: true, variant: MochiHeaderVariant.bordered));
    await tester.pumpAndSettle();
    expect(bar(tester), tester.getRect(header()));

    // Floating on an outlined theme: its line, no shadow.
    await tester.pumpWidget(app(touch: false, variant: MochiHeaderVariant.floating));
    await tester.pumpAndSettle();
    final shape = surfaceOf(tester, header()).shape as OutlinedBorder;
    expect(shape.side.color, MochiColors.light.border);
    expect(shadowsOf(tester, header()), isNull);
  });
}
