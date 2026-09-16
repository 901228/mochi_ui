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

  testWidgets("dragToDismiss: false ignores the drag", (tester) async {
    await tester.pumpWidget(app(dragToDismiss: false));
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(MochiSheet), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(find.byType(MochiSheet), findsOneWidget);
  });
}
