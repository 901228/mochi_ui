import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child) => MochiApp(
    themeMode: MochiThemeMode.light,
    home: Center(child: SizedBox(height: 200, width: 200, child: child)),
  );

  Widget list({ScrollController? controller, int items = 20}) => MochiScrollArea(
    child: ListView(
      controller: controller,
      children: [for (var i = 0; i < items; i++) SizedBox(height: 40, child: Text("row $i"))],
    ),
  );

  testWidgets("no fade when the content fits", (tester) async {
    await tester.pumpWidget(app(list(items: 2)));
    await tester.pumpAndSettle();

    expect(find.byType(ShaderMask), findsNothing);
  });

  testWidgets("fades the end, then both ends, then only the start", (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(app(list(controller: controller)));
    await tester.pumpAndSettle();

    // At the top there is more below, so the mask is on.
    expect(find.byType(ShaderMask), findsOneWidget);

    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.byType(ShaderMask), findsOneWidget);

    controller.jumpTo(controller.position.minScrollExtent);
    await tester.pumpAndSettle();
    expect(find.byType(ShaderMask), findsOneWidget);
  });

  testWidgets("works without a controller of its own", (tester) async {
    await tester.pumpWidget(app(list()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ShaderMask), findsOneWidget);
  });
}
