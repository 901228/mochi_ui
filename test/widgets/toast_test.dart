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

  testWidgets("stacks against the corner it was given, not the middle", (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(800, 600)),
        child: MochiApp(
          themeMode: MochiThemeMode.light,
          toastAlignment: Alignment.bottomRight,
          home: Builder(
            builder: (context) => Center(
              child: MochiButton(
                onPress: () => showMochiToast(context, title: const Text("Saved")),
                child: const Text("raise"),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("raise"));
    await tester.pumpAndSettle();
    final toast = tester.getRect(find.byType(MochiToast));
    expect(800 - toast.right, lessThan(24), reason: "against the right edge");
    expect(600 - toast.bottom, lessThan(24), reason: "against the bottom edge");
  });

  testWidgets("closing a middle toast holds the ones above it still", (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(800, 600)),
        child: MochiApp(
          themeMode: MochiThemeMode.light,
          toastAlignment: Alignment.bottomRight,
          home: Builder(
            builder: (context) => Center(
              child: MochiButton(
                onPress: () {
                  for (var i = 1; i <= 4; i++) {
                    showMochiToast(
                      context,
                      title: Text("Message $i"),
                      closeable: false,
                      duration: i == 2 ? const Duration(milliseconds: 500) : const Duration(minutes: 1),
                    );
                  }
                },
                child: const Text("raise"),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("raise"));
    await tester.pumpAndSettle();
    final oldest = tester.getRect(find.text("Message 1"));

    // Message 2 leaves and Message 4 comes up in its place; the one above the gap stays put
    // rather than being shoved down and pulled back.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 160));
    expect(tester.getRect(find.text("Message 1")).top, closeTo(oldest.top, 4));

    await tester.pumpAndSettle();
    expect(tester.getRect(find.text("Message 1")).top, closeTo(oldest.top, 1));
    expect(find.text("Message 4"), findsOneWidget);
  });

  testWidgets("every toast in a stack shares a width, which the deck is drawn against", (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(800, 600)),
        child: MochiApp(
          themeMode: MochiThemeMode.light,
          toastAlignment: Alignment.bottomRight,
          home: Builder(
            builder: (context) => Center(
              child: MochiButton(
                onPress: () {
                  showMochiToast(context, title: const Text("Hi"), duration: const Duration(minutes: 1));
                  for (var i = 2; i <= 6; i++) {
                    showMochiToast(
                      context,
                      title: Text("A much longer message, number $i"),
                      duration: const Duration(minutes: 1),
                    );
                  }
                },
                child: const Text("raise"),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("raise"));
    await tester.pumpAndSettle();

    final widths = tester
        .widgetList(find.byType(MochiToast))
        .map((toast) => tester.getRect(find.byWidget(toast)).width)
        .toSet();
    expect(widths, hasLength(1), reason: "a ragged stack has nothing for the deck to line up with");
    expect(widths.single, lessThanOrEqualTo(420));
  });

  testWidgets("the close button sits against the right edge", (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text("raise"));
    await tester.pumpAndSettle();

    final toast = tester.getRect(find.byType(MochiToast));
    final close = tester.getRect(find.byType(MochiButton).last);
    expect(toast.right - close.right, lessThan(24), reason: "against the edge, not trailing the text");
  });

  testWidgets("only a few are up at once, and the rest wait their turn", (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(800, 600)),
        child: MochiApp(
          themeMode: MochiThemeMode.light,
          home: Builder(
            builder: (context) => Center(
              child: MochiButton(
                onPress: () {
                  for (var i = 1; i <= 4; i++) {
                    showMochiToast(context, title: Text("Message $i"), duration: const Duration(seconds: 2));
                  }
                },
                child: const Text("raise"),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("raise"));
    await tester.pumpAndSettle();
    expect(find.text("Message 1"), findsOneWidget, reason: "the first one raised is shown first");
    expect(find.text("Message 3"), findsOneWidget);
    expect(find.text("Message 4"), findsNothing, reason: "waiting, not dropped");

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text("Message 1"), findsNothing);
    expect(find.text("Message 4"), findsOneWidget);
  });
}
