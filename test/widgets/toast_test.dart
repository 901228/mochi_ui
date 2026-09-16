import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  late List<String> events;

  setUp(() => events = []);

  Widget app({
    Duration duration = const Duration(seconds: 4),
    bool withAction = false,
    void Function(MochiToastHandle handle)? onRaised,
  }) => MediaQuery(
    data: const MediaQueryData(size: Size(800, 600)),
    child: MochiApp(
      themeMode: MochiThemeMode.light,
      home: Builder(
        builder: (context) => Center(
          child: MochiButton(
            onPress: () {
              final handle = showMochiToast(
                context,
                title: const Text("Record deleted"),
                description: const Text("It is gone from this session."),
                duration: duration,
                action: withAction
                    ? MochiButton(
                        appearance: MochiButtonAppearance.text,
                        size: MochiButtonSize.xs,
                        onPress: () => events.add("undo"),
                        child: const Text("Undo"),
                      )
                    : null,
              );
              onRaised?.call(handle);
            },
            child: const Text("raise"),
          ),
        ),
      ),
    ),
  );

  testWidgets("appears over the page and goes away on its own", (tester) async {
    await tester.pumpWidget(app(duration: const Duration(seconds: 2)));
    await tester.tap(find.text("raise"));
    await tester.pumpAndSettle();
    expect(find.text("Record deleted"), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text("Record deleted"), findsNothing);
  });

  testWidgets("the close button takes it away", (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text("raise"));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(MochiButton).last);
    await tester.pumpAndSettle();
    expect(find.text("Record deleted"), findsNothing);
  });

  testWidgets("the handle takes it away early", (tester) async {
    MochiToastHandle? handle;
    await tester.pumpWidget(app(onRaised: (value) => handle = value));
    await tester.tap(find.text("raise"));
    await tester.pumpAndSettle();

    handle!.dismiss();
    await tester.pumpAndSettle();
    expect(find.text("Record deleted"), findsNothing);
  });

  testWidgets("an action runs and the toast can then be dismissed", (tester) async {
    MochiToastHandle? handle;
    await tester.pumpWidget(app(withAction: true, onRaised: (value) => handle = value));
    await tester.tap(find.text("raise"));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Undo"));
    await tester.pumpAndSettle();
    expect(events, ["undo"]);

    handle!.dismiss();
    await tester.pumpAndSettle();
    expect(find.text("Record deleted"), findsNothing);
  });

  testWidgets("hovering holds it open", (tester) async {
    await tester.pumpWidget(app(duration: const Duration(seconds: 2)));
    await tester.tap(find.text("raise"));
    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text("Record deleted")));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text("Record deleted"), findsOneWidget);

    await mouse.moveTo(Offset.zero);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text("Record deleted"), findsNothing);
  });

  testWidgets("the close button sits against the right edge", (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text("raise"));
    await tester.pumpAndSettle();

    final toast = tester.getRect(find.byType(MochiToast));
    final close = tester.getRect(find.byType(MochiButton).last);
    expect(toast.right - close.right, lessThan(24), reason: "against the edge, not trailing the text");
  });

  testWidgets("only the newest few stay up", (tester) async {
    await tester.pumpWidget(app());
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text("raise"));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    expect(find.text("Record deleted"), findsNWidgets(3));
  });
}
