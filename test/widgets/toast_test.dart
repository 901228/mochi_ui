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

    // Only the ones standing in the stack: the queue behind them is drawn smaller on purpose.
    final widths = {
      for (final title in ["Hi", "A much longer message, number 2", "A much longer message, number 3"])
        tester.getRect(find.ancestor(of: find.text(title), matching: find.byType(MochiToast))).width,
    };
    expect(widths, hasLength(1), reason: "a ragged stack has nothing for the deck to line up with");
    expect(widths.single, MochiGeometry.standard.toastWidth);
  });

  testWidgets("the stack takes the width it was given", (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(800, 600)),
        child: MochiApp(
          themeMode: MochiThemeMode.light,
          toastWidth: 280,
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
    expect(tester.getRect(find.byType(MochiToast)).width, 280);
  });

  testWidgets("a place closes as the next toast comes up at the end of the stack", (tester) async {
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
                  // Five: three up, one to take the place of the one that leaves, and one left
                  // queued behind it.
                  for (var i = 1; i <= 5; i++) {
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
    await tester.pump();
    // Settled, but not so far that the 500ms toast has gone.
    await tester.pump(const Duration(milliseconds: 450));
    final places = [for (var i = 1; i <= 3; i++) tester.getRect(find.text("Message $i"))];

    // While it slides clear the stack is untouched, and the next toast has come out of the deck
    // to stand where that deck's front card was: a card's width, peeking past the end of the
    // stack, so what the one on its way out uncovers is the new toast rather than a blank card.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getRect(find.text("Message 1")), places[0]);
    expect(tester.getRect(find.text("Message 3")), places[2]);

    final last = tester.getRect(find.ancestor(of: find.text("Message 3"), matching: find.byType(MochiToast)));
    final next = tester.getRect(find.ancestor(of: find.text("Message 4"), matching: find.byType(MochiToast)));
    expect(next.bottom, greaterThan(last.bottom), reason: "peeking past the end of the stack");
    expect(next.bottom - last.bottom, lessThan(12), reason: "no more than a card's edge");
    expect(next.width, lessThan(last.width), reason: "a card's width, not a toast's");
    // The queue behind it holds its places until this one moves up: with the front place taken,
    // the one still waiting is a place further back than the promoted toast, not level with it.
    final queued = tester.getRect(
      find.ancestor(of: find.text("Message 5"), matching: find.byType(MochiToast)),
    );
    expect(queued.width, lessThan(next.width), reason: "holding its place until the front one moves up");
    expect(
      tester
          .widget<Opacity>(find.ancestor(of: find.text("Message 4"), matching: find.byType(Opacity)).first)
          .opacity,
      1,
      reason: "standing there in full, not fading in, or the slide uncovers nothing",
    );

    // Then its place closes while the next one comes up at the end of the stack: what was below
    // the gap moves up by exactly what the new one takes at the bottom, and what was above it
    // does not move at all.
    await tester.pumpAndSettle();
    expect(find.text("Message 2"), findsNothing);
    expect(tester.getRect(find.text("Message 1")), places[0], reason: "above the gap, untouched");
    expect(tester.getRect(find.text("Message 3")), places[1], reason: "moved up into the gap");
    expect(tester.getRect(find.text("Message 4")), places[2], reason: "came up at the end");
  });

  testWidgets("several leaving at once each come up from their own place in the queue", (tester) async {
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
                  // Three up, three queued, and all three up leave together.
                  for (var i = 1; i <= 6; i++) {
                    showMochiToast(
                      context,
                      title: Text("Message $i"),
                      closeable: false,
                      duration: i <= 3 ? const Duration(milliseconds: 500) : const Duration(minutes: 1),
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    // All three start leaving together, so all three queued are promoted at once — each from the
    // place it was standing at, not all from the front.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 16));
    final widths = [
      for (var i = 4; i <= 6; i++)
        tester.getRect(find.ancestor(of: find.text("Message $i"), matching: find.byType(MochiToast))).width,
    ];
    expect(widths[0], greaterThan(widths[1]), reason: "each from its own place, not piled on one");
    expect(widths[1], greaterThan(widths[2]));

    await tester.pumpAndSettle();
    expect(find.text("Message 1"), findsNothing);
    final settled = {
      for (var i = 4; i <= 6; i++)
        tester.getRect(find.ancestor(of: find.text("Message $i"), matching: find.byType(MochiToast))).width,
    };
    expect(settled, hasLength(1), reason: "all three came up into the stack");
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

    // Waiting its turn: in the deck past the end of the stack, where only its edge shows.
    final third = tester.getRect(
      find.ancestor(of: find.text("Message 3"), matching: find.byType(MochiToast)),
    );
    final fourth = tester.getRect(
      find.ancestor(of: find.text("Message 4"), matching: find.byType(MochiToast)),
    );
    expect(fourth.width, lessThan(third.width), reason: "in the deck, drawn smaller than the stack");

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text("Message 1"), findsNothing);
    expect(
      tester.getRect(find.ancestor(of: find.text("Message 4"), matching: find.byType(MochiToast))).width,
      third.width,
      reason: "came up into the stack, at the stack's width",
    );
  });
}
