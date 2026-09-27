import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app({
    MochiSheetSide side = MochiSheetSide.bottom,
    bool dragToDismiss = true,
    ValueChanged<String?>? onResult,
  }) => MediaQuery(
    data: const MediaQueryData(size: Size(800, 600)),
    child: MochiApp(
      themeMode: MochiThemeMode.light,
      home: Builder(
        builder: (context) => Center(
          child: MochiButton(
            onPress: () async {
              final answer = await showMochiSheet<String>(
                context,
                side: side,
                dragToDismiss: dragToDismiss,
                builder: (context) => MochiSheet(
                  side: side,
                  child: MochiButton(
                    onPress: () => Navigator.of(context).pop("picked"),
                    child: const Text("pick"),
                  ),
                ),
              );
              onResult?.call(answer);
            },
            child: const Text("open"),
          ),
        ),
      ),
    ),
  );

  testWidgets("slides in from its edge and returns what it was popped with", (tester) async {
    String? result;
    await tester.pumpWidget(app(onResult: (value) => result = value));

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
    final sheet = tester.getRect(find.byType(MochiSheet));
    expect(sheet.bottom, 600, reason: "anchored to the bottom edge");
    expect(sheet.width, 800, reason: "full width across its axis");

    await tester.tap(find.text("pick"));
    await tester.pumpAndSettle();
    expect(result, "picked");
    expect(find.byType(MochiSheet), findsNothing);
  });

  testWidgets("a side sheet runs the full height at the edge it was given", (tester) async {
    await tester.pumpWidget(app(side: MochiSheetSide.right));
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    final sheet = tester.getRect(find.byType(MochiSheet));
    expect(sheet.right, 800);
    expect(sheet.height, 600);
    expect(sheet.width, lessThanOrEqualTo(400));
  });

  testWidgets("the barrier dismisses it", (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(MochiSheet), findsNothing);
  });

  testWidgets("dragging it towards its edge dismisses it", (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(MochiSheet), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(find.byType(MochiSheet), findsNothing);
  });

  testWidgets("a drag that lets go early settles back", (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
    final resting = tester.getRect(find.byType(MochiSheet));

    // Slowly, so the release isn't read as a fling.
    await tester.timedDrag(find.byType(MochiSheet), const Offset(0, 40), const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byType(MochiSheet), findsOneWidget);
    expect(tester.getRect(find.byType(MochiSheet)), resting);
  });

  testWidgets("a short sheet takes a real drag, not a twitch", (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
    final height = tester.getRect(find.byType(MochiSheet)).height;
    expect(height, lessThan(160), reason: "the point of the case: half of this is a twitch");

    // Over half the sheet, but a short distance: it stays.
    await tester.timedDrag(
      find.byType(MochiSheet),
      Offset(0, height * 0.6),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MochiSheet), findsOneWidget);

    // Far enough to mean it. The first 18 pixels or so go to the recognizer's slop.
    await tester.timedDrag(find.byType(MochiSheet), const Offset(0, 120), const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.byType(MochiSheet), findsNothing);
  });

  testWidgets("the handle sits on the edge that faces into the screen", (tester) async {
    final handle = find.byWidgetPredicate((w) => w is SizedBox && w.width == 36 && w.height == 4);

    for (final side in [MochiSheetSide.bottom, MochiSheetSide.top]) {
      await tester.pumpWidget(
        MochiApp(
          themeMode: MochiThemeMode.light,
          touch: true,
          home: Builder(
            builder: (context) => Center(
              child: MochiButton(
                onPress: () => showMochiSheet<void>(
                  context,
                  side: side,
                  builder: (context) => MochiSheet(side: side, child: const Text("body")),
                ),
                child: const Text("open"),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();

      final grab = tester.getCenter(handle).dy;
      final body = tester.getCenter(find.text("body")).dy;
      expect(
        side == MochiSheetSide.bottom ? grab < body : grab > body,
        isTrue,
        reason: "the handle is on the inner edge of a $side sheet",
      );

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
    }
  });

  testWidgets("dragToDismiss: false ignores the drag", (tester) async {
    await tester.pumpWidget(app(dragToDismiss: false));
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(MochiSheet), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(find.byType(MochiSheet), findsOneWidget);
  });

  group("a sheet that refuses to go", () {
    Widget guarded({required bool canPop, required List<bool> refused}) => MediaQuery(
      data: const MediaQueryData(size: Size(800, 600)),
      child: MochiApp(
        themeMode: MochiThemeMode.light,
        home: Builder(
          builder: (context) => Center(
            child: MochiButton(
              onPress: () => showMochiSheet<void>(
                context,
                builder: (context) => PopScope(
                  canPop: canPop,
                  onPopInvokedWithResult: (didPop, _) => refused.add(didPop),
                  child: const MochiSheet(
                    child: SizedBox(height: 200, child: Center(child: Text("form"))),
                  ),
                ),
              ),
              child: const Text("open"),
            ),
          ),
        ),
      ),
    );

    testWidgets("a drag it refuses settles back, and it hears about it", (tester) async {
      final refused = <bool>[];
      await tester.pumpWidget(guarded(canPop: false, refused: refused));
      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();

      final resting = tester.getRect(find.byType(MochiSheet));
      await tester.drag(find.byType(MochiSheet), const Offset(0, 400));
      await tester.pumpAndSettle();

      // Still there, back where it was, and the PopScope was told the gesture happened: that is
      // where an app asks whether to discard what is in the sheet.
      expect(find.text("form"), findsOneWidget);
      expect(tester.getRect(find.byType(MochiSheet)), resting);
      expect(refused, [false]);
    });

    testWidgets("one it allows goes, the same as the barrier", (tester) async {
      final refused = <bool>[];
      await tester.pumpWidget(guarded(canPop: true, refused: refused));
      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(MochiSheet), const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(find.text("form"), findsNothing);
      expect(refused, [true]);
    });
  });
}
