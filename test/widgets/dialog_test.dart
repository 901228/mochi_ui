import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app({bool touch = false, ValueChanged<bool?>? onResult}) => MediaQuery(
    data: const MediaQueryData(size: Size(800, 600)),
    child: MochiApp(
      themeMode: MochiThemeMode.light,
      touch: touch,
      home: Builder(
        builder: (context) => Center(
          child: MochiButton(
            onPress: () async {
              final answer = await showMochiDialog<bool>(
                context,
                builder: (context) => MochiDialog(
                  title: const Text("Delete record?"),
                  body: const Text("This record will be permanently deleted."),
                  actions: [
                    MochiButton(
                      appearance: MochiButtonAppearance.outlined,
                      onPress: () => Navigator.of(context).pop(false),
                      child: const Text("Cancel"),
                    ),
                    MochiButton(
                      intent: MochiIntent.danger,
                      onPress: () => Navigator.of(context).pop(true),
                      child: const Text("Delete"),
                    ),
                  ],
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

  testWidgets("opens over the page and returns what it was popped with", (tester) async {
    bool? result;
    await tester.pumpWidget(app(onResult: (value) => result = value));

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
    expect(find.text("Delete record?"), findsOneWidget);

    await tester.tap(find.text("Delete"));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(find.text("Delete record?"), findsNothing);
  });

  testWidgets("the barrier dismisses it with null", (tester) async {
    var called = false;
    bool? result;
    await tester.pumpWidget(
      app(
        onResult: (value) {
          called = true;
          result = value;
        },
      ),
    );

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(called, isTrue);
    expect(result, isNull);
    expect(find.text("Delete record?"), findsNothing);
  });

  testWidgets("escape closes it", (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text("Delete record?"), findsNothing);
  });

  testWidgets("barrierDismissible: false keeps it open", (tester) async {
    await tester.pumpWidget(
      MochiApp(
        themeMode: MochiThemeMode.light,
        home: Builder(
          builder: (context) => Center(
            child: MochiButton(
              onPress: () => showMochiDialog<void>(
                context,
                barrierDismissible: false,
                builder: (context) => const MochiDialog(title: Text("Working")),
              ),
              child: const Text("open"),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text("Working"), findsOneWidget);
  });

  testWidgets("actions sit in a row on desktop and stack on touch", (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text("Cancel")).dy, tester.getTopLeft(find.text("Delete")).dy);

    await tester.tap(find.text("Cancel"));
    await tester.pumpAndSettle();

    await tester.pumpWidget(app(touch: true));
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text("Delete")).dy, greaterThan(tester.getTopLeft(find.text("Cancel")).dy));
  });

  testWidgets("a long body scrolls instead of overflowing", (tester) async {
    await tester.pumpWidget(
      MochiApp(
        themeMode: MochiThemeMode.light,
        home: Builder(
          builder: (context) => Center(
            child: MochiButton(
              onPress: () => showMochiDialog<void>(
                context,
                builder: (context) => MochiDialog(
                  title: const Text("Long"),
                  body: Column(children: [for (var i = 0; i < 60; i++) Text("line $i")]),
                ),
              ),
              child: const Text("open"),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsWidgets);
  });
}
