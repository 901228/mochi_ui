import "package:flutter/gestures.dart";
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

  group("the wheel", () {
    final outer = ScrollController();
    final inner = ScrollController();

    Widget page({bool contain = true, int rows = 20}) => MochiApp(
      themeMode: MochiThemeMode.light,
      home: ListView(
        controller: outer,
        children: [
          SizedBox(
            height: 100,
            child: MochiScrollArea(
              containScroll: contain,
              child: ListView(
                controller: inner,
                children: [for (var i = 0; i < rows; i++) SizedBox(height: 30, child: Text("row $i"))],
              ),
            ),
          ),
          const SizedBox(height: 2000),
        ],
      ),
    );

    Future<void> wheel(WidgetTester tester, double dy) async {
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(pointer.hover(tester.getCenter(find.byType(MochiScrollArea))));
      await tester.sendEventToBinding(pointer.scroll(Offset(0, dy)));
      await tester.pumpAndSettle();
    }

    testWidgets("stays with the area on desktop too, with its scrollbar", (tester) async {
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      await wheel(tester, 5000);
      expect(inner.offset, inner.position.maxScrollExtent);
      await wheel(tester, 200);
      expect(outer.offset, 0, reason: "the page behind doesn't take over");
    }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

    testWidgets("stays with the area once it reaches its end", (tester) async {
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      await wheel(tester, 5000);
      expect(inner.offset, inner.position.maxScrollExtent);
      expect(outer.offset, 0);

      await wheel(tester, 200);
      expect(outer.offset, 0, reason: "the page behind doesn't take over");
    });

    testWidgets("passes on to the page when containScroll is off", (tester) async {
      await tester.pumpWidget(page(contain: false));
      await tester.pumpAndSettle();

      await wheel(tester, 5000);
      await wheel(tester, 200);
      expect(outer.offset, greaterThan(0));
    });

    testWidgets("passes on when the content fits, so the page can still scroll", (tester) async {
      await tester.pumpWidget(page(rows: 2));
      await tester.pumpAndSettle();

      await wheel(tester, 200);
      expect(outer.offset, greaterThan(0));
    });
  });
}
