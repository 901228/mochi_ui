import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child, {required bool touch}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: touch,
    home: Center(child: child),
  );

  for (final touch in [false, true]) {
    for (final size in MochiSize.values) {
      final expected = MochiButtonMetrics.of(size, touch: touch).height;

      testWidgets("${touch ? "touch" : "desktop"} ${size.name} is $expected tall", (tester) async {
        await tester.pumpWidget(
          app(
            MochiButton(size: size, onPress: () {}, child: const Text("Label")),
            touch: touch,
          ),
        );
        expect(tester.getSize(find.byType(MochiButton)).height, expected);
      });

      testWidgets("${touch ? "touch" : "desktop"} ${size.name} icon button is square", (tester) async {
        await tester.pumpWidget(
          app(
            MochiButton.icon(size: size, onPress: () {}, icon: const SizedBox.square(dimension: 8)),
            touch: touch,
          ),
        );
        expect(tester.getSize(find.byType(MochiButton)), Size.square(expected));
      });
    }
  }

  group("waiting", () {
    Widget app(Widget child) => MochiApp(
      themeMode: MochiThemeMode.light,
      touch: false,
      home: Center(child: child),
    );

    testWidgets("loading keeps the button's width and takes no press", (tester) async {
      var pressed = 0;
      await tester.pumpWidget(app(MochiButton(onPress: () => pressed++, child: const Text("Save"))));
      final resting = tester.getSize(find.byType(MochiButton));

      await tester.pumpWidget(
        app(MochiButton(loading: true, onPress: () => pressed++, child: const Text("Save"))),
      );
      await tester.pump();

      // The label is still laid out under the spinner, so nothing beside the button moves.
      expect(tester.getSize(find.byType(MochiButton)), resting);
      expect(find.byType(MochiCircularProgress), findsOneWidget);
      expect(find.text("Save"), findsOneWidget);

      await tester.tap(find.byType(MochiButton));
      await tester.pump();
      expect(pressed, 0);
    });

    testWidgets("async waits for its future, and one press at a time", (tester) async {
      final finish = Completer<void>();
      var runs = 0;

      await tester.pumpWidget(
        app(
          MochiButton.async(
            onPress: () {
              runs++;
              return finish.future;
            },
            child: const Text("Save"),
          ),
        ),
      );

      await tester.tap(find.byType(MochiButton));
      await tester.pump();
      expect(find.byType(MochiCircularProgress), findsOneWidget);

      // A second press while it is in flight is not a second run.
      await tester.tap(find.byType(MochiButton));
      await tester.pump();
      expect(runs, 1);

      finish.complete();
      await tester.pumpAndSettle();
      expect(find.byType(MochiCircularProgress), findsNothing);
    });

    testWidgets("a future that throws reports it and gives the button back", (tester) async {
      await tester.pumpWidget(
        app(MochiButton.async(onPress: () async => throw StateError("no"), child: const Text("Save"))),
      );

      await tester.tap(find.byType(MochiButton));
      await tester.pump();
      await tester.pumpAndSettle();

      // Reported rather than swallowed, and the label is back rather than a spinner for ever.
      expect(tester.takeException(), isA<StateError>());
      expect(find.byType(MochiCircularProgress), findsNothing);
    });
  });
}
