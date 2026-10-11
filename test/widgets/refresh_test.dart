import "dart:async";

import "package:flutter/gestures.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app({required Future<void> Function() onRefresh, bool enabled = true, bool mouseDrags = true}) =>
      MochiApp(
        themeMode: MochiThemeMode.light,
        touch: true,
        home: SizedBox(
          height: 400,
          child: MochiRefresh(
            onRefresh: onRefresh,
            enabled: enabled,
            mouseDrags: mouseDrags,
            child: ListView(
              children: [for (var i = 0; i < 12; i++) SizedBox(height: 60, child: Text("row $i"))],
            ),
          ),
        ),
      );

  /// Pulls the list down by [pixels] and lets go, the way a finger does: in steps, so the
  /// overscroll is reported more than once.
  Future<void> pull(
    WidgetTester tester,
    double pixels, {
    bool release = true,
    PointerDeviceKind kind = PointerDeviceKind.touch,
  }) async {
    final gesture = await tester.startGesture(tester.getCenter(find.byType(ListView)), kind: kind);
    for (var moved = 0.0; moved < pixels; moved += 20) {
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
    }
    if (release) {
      await gesture.up();
      await tester.pump();
    }
  }

  double? ringValue(WidgetTester tester) =>
      tester.widget<MochiCircularProgress>(find.byType(MochiCircularProgress)).value;

  testWidgets("a short pull asks for nothing", (tester) async {
    var asked = 0;
    await tester.pumpWidget(app(onRefresh: () async => asked++));
    await tester.pumpAndSettle();

    await pull(tester, 60);
    await tester.pumpAndSettle();
    expect(asked, 0, reason: "the trigger is further than that");
    expect(find.byType(MochiCircularProgress), findsNothing, reason: "and the indicator went home");
  });

  testWidgets("a pull past the trigger asks, and is held until the answer comes", (tester) async {
    final done = Completer<void>();
    var asked = 0;
    await tester.pumpWidget(
      app(
        onRefresh: () {
          asked++;
          return done.future;
        },
      ),
    );
    await tester.pumpAndSettle();

    await pull(tester, 220);
    await tester.pump(const Duration(milliseconds: 400));

    expect(asked, 1);
    expect(find.byType(MochiCircularProgress), findsOneWidget);
    expect(ringValue(tester), isNull, reason: "how long an errand takes is nobody's to say");

    done.complete();
    await tester.pumpAndSettle();
    expect(find.byType(MochiCircularProgress), findsNothing);
  });

  testWidgets("the ring fills as the pull goes on", (tester) async {
    await tester.pumpWidget(app(onRefresh: () async {}));
    await tester.pumpAndSettle();

    await pull(tester, 60, release: false);
    final early = ringValue(tester)!;
    await pull(tester, 20, release: false);
    expect(ringValue(tester)!, greaterThan(early));

    await tester.pumpAndSettle();
  });

  testWidgets("a pull while the errand runs does not ask again", (tester) async {
    final done = Completer<void>();
    var asked = 0;
    await tester.pumpWidget(
      app(
        onRefresh: () {
          asked++;
          return done.future;
        },
      ),
    );
    await tester.pumpAndSettle();

    await pull(tester, 220);
    await tester.pump(const Duration(milliseconds: 400));
    await pull(tester, 220);
    await tester.pump(const Duration(milliseconds: 400));

    expect(asked, 1);
    done.complete();
    await tester.pumpAndSettle();
  });

  testWidgets("an errand that throws still gives the list back", (tester) async {
    await tester.pumpWidget(app(onRefresh: () async => throw StateError("no network")));
    await tester.pumpAndSettle();

    await pull(tester, 220);
    await tester.pumpAndSettle();

    expect(find.byType(MochiCircularProgress), findsNothing);
    expect(tester.takeException(), isStateError);
  });

  testWidgets("disabled never asks", (tester) async {
    var asked = 0;
    await tester.pumpWidget(app(onRefresh: () async => asked++, enabled: false));
    await tester.pumpAndSettle();

    await pull(tester, 220);
    await tester.pumpAndSettle();
    expect(asked, 0);
    expect(find.byType(MochiCircularProgress), findsNothing);
  });

  testWidgets("pulling from further down the list does nothing", (tester) async {
    var asked = 0;
    await tester.pumpWidget(app(onRefresh: () async => asked++));
    await tester.pumpAndSettle();

    // Away from the top: there is nothing to pull back to.
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    await pull(tester, 120);
    await tester.pumpAndSettle();

    expect(asked, 0);
  });

  testWidgets("a mouse can pull it too, which on a desktop is the only thing that can", (tester) async {
    // A scrollable refuses a mouse drag on a desktop platform unless it is told otherwise, and a
    // wheel at the top of a list reports no overscroll: without this there is no gesture at all.
    var asked = 0;
    await tester.pumpWidget(app(onRefresh: () async => asked++));
    await tester.pumpAndSettle();

    await pull(tester, 220, kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(asked, 1);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets("a list that should not be dragged by a mouse can say so", (tester) async {
    var asked = 0;
    await tester.pumpWidget(app(onRefresh: () async => asked++, mouseDrags: false));
    await tester.pumpAndSettle();

    await pull(tester, 220, kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(asked, 0);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
