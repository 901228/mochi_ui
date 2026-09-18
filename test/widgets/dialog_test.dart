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

  group("showMochiModal", () {
    Widget adaptive({required Size size, MochiModalForm? form, ValueChanged<String?>? onResult}) =>
        MediaQuery(
          data: MediaQueryData(size: size),
          child: MochiApp(
            themeMode: MochiThemeMode.light,
            home: Builder(
              builder: (context) => Center(
                child: MochiButton(
                  onPress: () async {
                    final answer = await showMochiModal<String>(
                      context,
                      form: form,
                      title: const Text("Move to"),
                      body: const Text("Pick a session."),
                      actions: [
                        MochiButton(onPress: () => Navigator.of(context).pop("ok"), child: const Text("OK")),
                      ],
                    );
                    onResult?.call(answer);
                  },
                  child: const Text("open"),
                ),
              ),
            ),
          ),
        );

    testWidgets("is a dialog on a wide screen", (tester) async {
      await tester.pumpWidget(adaptive(size: const Size(1000, 700)));
      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();

      expect(find.byType(MochiDialog), findsOneWidget);
      expect(find.byType(MochiSheet), findsNothing);
    });

    testWidgets("is a bottom sheet on a phone, and still returns its answer", (tester) async {
      String? result;
      await tester.pumpWidget(adaptive(size: const Size(390, 780), onResult: (value) => result = value));
      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();

      expect(find.byType(MochiSheet), findsOneWidget);
      expect(find.byType(MochiDialog), findsNothing);

      await tester.tap(find.text("OK"));
      await tester.pumpAndSettle();
      expect(result, "ok");
    });

    testWidgets("form: overrides the screen", (tester) async {
      await tester.pumpWidget(adaptive(size: const Size(390, 780), form: MochiModalForm.dialog));
      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();

      expect(find.byType(MochiDialog), findsOneWidget);
    });
  });

  group("helpers", () {
    Widget host({required Future<void> Function(BuildContext context) onPress}) => MediaQuery(
      data: const MediaQueryData(size: Size(1000, 700)),
      child: MochiApp(
        themeMode: MochiThemeMode.light,
        home: Builder(
          builder: (context) => Center(
            child: MochiButton(onPress: () => onPress(context), child: const Text("open")),
          ),
        ),
      ),
    );

    testWidgets("showMochiConfirm answers true, false and false again when dismissed", (tester) async {
      bool? answer;
      await tester.pumpWidget(
        host(
          onPress: (context) async {
            answer = await showMochiConfirm(
              context,
              title: "Delete record?",
              message: "This cannot be undone.",
              confirmLabel: "Delete",
              destructive: true,
            );
          },
        ),
      );

      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();
      expect(find.text("This cannot be undone."), findsOneWidget);
      await tester.tap(find.text("Delete"));
      await tester.pumpAndSettle();
      expect(answer, isTrue);

      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Cancel"));
      await tester.pumpAndSettle();
      expect(answer, isFalse);

      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(answer, isFalse, reason: "dismissed is not agreed");
    });

    testWidgets("showMochiChoice returns the option picked, and null when dismissed", (tester) async {
      String? picked = "untouched";
      await tester.pumpWidget(
        host(
          onPress: (context) async {
            picked = await showMochiChoice<String>(
              context,
              title: "Move to",
              selected: "3x3",
              choices: const [
                MochiChoice(value: "3x3", label: "3x3"),
                MochiChoice(value: "4x4", label: "4x4", description: "Bigger cube"),
                MochiChoice(value: "skewb", label: "Skewb", enabled: false),
              ],
            );
          },
        ),
      );

      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();
      expect(find.text("Bigger cube"), findsOneWidget);

      await tester.tap(find.text("4x4"));
      await tester.pumpAndSettle();
      expect(picked, "4x4");

      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Cancel"));
      await tester.pumpAndSettle();
      expect(picked, isNull);
    });

    testWidgets("a disabled choice can not be picked", (tester) async {
      String? picked = "untouched";
      await tester.pumpWidget(
        host(
          onPress: (context) async {
            picked = await showMochiChoice<String>(
              context,
              title: "Move to",
              cancelable: false,
              choices: const [
                MochiChoice(value: "3x3", label: "3x3"),
                MochiChoice(value: "skewb", label: "Skewb", enabled: false),
              ],
            );
          },
        ),
      );

      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Skewb"));
      await tester.pumpAndSettle();
      expect(picked, "untouched", reason: "still open, nothing answered");
      expect(find.text("Move to"), findsOneWidget);
    });

    testWidgets("showMochiAlert closes on its one button", (tester) async {
      var done = false;
      await tester.pumpWidget(
        host(
          onPress: (context) async {
            await showMochiAlert(context, title: "Import finished", message: "42 records added.");
            done = true;
          },
        ),
      );

      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();
      expect(find.text("42 records added."), findsOneWidget);

      await tester.tap(find.text("OK"));
      await tester.pumpAndSettle();
      expect(done, isTrue);
      expect(find.text("Import finished"), findsNothing);
    });
  });
}
