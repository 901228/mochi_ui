import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child) => MochiApp(
    themeMode: MochiThemeMode.light,
    home: Center(child: SizedBox(width: 200, child: child)),
  );

  testWidgets("horizontal divider fills its width with the border color", (tester) async {
    await tester.pumpWidget(app(const MochiDivider()));

    expect(tester.getSize(find.byType(MochiDivider)), Size(200, MochiGeometry.standard.borderWidth));
    final line = find.descendant(of: find.byType(MochiDivider), matching: find.byType(ColoredBox));
    expect(tester.widget<ColoredBox>(line).color, MochiColors.light.border);
  });

  testWidgets("vertical divider and indents", (tester) async {
    await tester.pumpWidget(
      app(
        // A vertical divider needs a loose width, so it sits in a Row.
        const SizedBox(
          height: 100,
          child: Row(children: [MochiDivider(axis: Axis.vertical, thickness: 2, indent: 10, endIndent: 20)]),
        ),
      ),
    );

    final size = tester.getSize(find.byType(MochiDivider));
    expect(size.width, 2);
    expect(size.height, 100);
    expect(
      tester
          .getSize(find.descendant(of: find.byType(MochiDivider), matching: find.byType(ColoredBox)))
          .height,
      70,
    );
  });

  testWidgets("gap pads perpendicularly and indent defaults to symmetric", (tester) async {
    await tester.pumpWidget(app(const Column(children: [MochiDivider(thickness: 2, gap: 5, indent: 20)])));

    final dividerSize = tester.getSize(find.byType(MochiDivider));
    expect(dividerSize.width, 200);
    expect(dividerSize.height, 12); // thickness 2 + gap 5*2

    final line = tester.getSize(
      find.descendant(of: find.byType(MochiDivider), matching: find.byType(ColoredBox)),
    );
    expect(line.width, 160); // 200 - indent 20 - endIndent 20
    expect(line.height, 2);
  });
}
