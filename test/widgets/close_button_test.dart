import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child, {bool touch = false, MochiStrings? strings}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: touch,
    strings: strings,
    home: Center(child: child),
  );

  testWidgets("pressing it calls onPress", (tester) async {
    var pressed = 0;
    await tester.pumpWidget(app(MochiCloseButton(onPress: () => pressed++)));

    await tester.tap(find.byType(MochiCloseButton));
    expect(pressed, 1);
  });

  testWidgets("sizes follow size and touch", (tester) async {
    await tester.pumpWidget(app(MochiCloseButton(onPress: () {}, size: MochiSize.xs)));
    expect(tester.getSize(find.byType(MochiCloseButton)), const Size(16, 16));

    await tester.pumpWidget(app(MochiCloseButton(onPress: () {})));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MochiCloseButton)), const Size(28, 28));

    await tester.pumpWidget(app(MochiCloseButton(onPress: () {}), touch: true));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MochiCloseButton)), const Size(32, 32));
  });

  testWidgets("takes its colour from the ambient icon theme", (tester) async {
    const red = Color(0xFFFF0000);
    await tester.pumpWidget(
      app(
        IconTheme(
          data: const IconThemeData(color: red),
          child: MochiCloseButton(onPress: () {}),
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.color!.r, red.r);
    expect(icon.color!.a, lessThan(1), reason: "quiet at rest");
  });

  testWidgets("screen readers hear MochiStrings.close", (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app(MochiCloseButton(onPress: () {}), strings: MochiStrings.zhHant));

    expect(find.bySemanticsLabel("關閉"), findsOneWidget);
    handle.dispose();
  });

  testWidgets("disabled with no onPress", (tester) async {
    await tester.pumpWidget(app(const MochiCloseButton(onPress: null)));

    final opacity = tester.widget<Opacity>(
      find.descendant(of: find.byType(MochiCloseButton), matching: find.byType(Opacity)).first,
    );
    expect(opacity.opacity, 0.4);
  });

  test("metrics have value equality", () {
    expect(
      MochiCloseButtonMetrics.of(MochiSize.md, touch: false),
      const MochiCloseButtonMetrics(diameter: 28, iconSize: 14),
    );
  });

  testWidgets("rounded by default, like an icon button; circle on request", (tester) async {
    BorderRadiusGeometry corners() =>
        ((tester
                            .widget<Container>(
                              find.descendant(
                                of: find.byType(MochiCloseButton),
                                matching: find.byType(Container),
                              ),
                            )
                            .decoration!
                        as ShapeDecoration)
                    .shape
                as RoundedSuperellipseBorder)
            .borderRadius;
    const radius = MochiRadius();

    await tester.pumpWidget(app(MochiCloseButton(onPress: () {})));
    expect(corners(), radius.sm);

    await tester.pumpWidget(app(MochiCloseButton(size: MochiSize.xs, onPress: () {})));
    expect(corners(), radius.xs);

    await tester.pumpWidget(app(MochiCloseButton(shape: MochiCloseButtonShape.circle, onPress: () {})));
    expect(corners(), radius.full);
  });
}
