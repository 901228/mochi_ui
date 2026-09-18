import "package:flutter/gestures.dart";

import "dart:ui" show Tristate;

import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child, {bool disableAnimations = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: MochiApp(
      themeMode: MochiThemeMode.light,
      touch: false,
      home: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: 300, child: child),
      ),
    ),
  );

  const body = SizedBox(height: 100, child: Text("Body"));

  group("MochiCollapsible", () {
    testWidgets("starts closed, opens and closes on the header", (tester) async {
      await tester.pumpWidget(app(const MochiCollapsible(title: Text("Title"), child: body)));
      expect(find.text("Body"), findsNothing);

      await tester.tap(find.text("Title"));
      await tester.pumpAndSettle();
      expect(find.text("Body"), findsOneWidget);
      final open = tester.getSize(find.byType(MochiCollapsible)).height;

      await tester.tap(find.text("Title"));
      await tester.pumpAndSettle();
      expect(find.text("Body"), findsNothing);
      expect(tester.getSize(find.byType(MochiCollapsible)).height, lessThan(open - 90));
    });

    testWidgets("grows over time rather than jumping", (tester) async {
      await tester.pumpWidget(app(const MochiCollapsible(title: Text("Title"), child: body)));
      final closed = tester.getSize(find.byType(MochiCollapsible)).height;

      await tester.tap(find.text("Title"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final midway = tester.getSize(find.byType(MochiCollapsible)).height;
      expect(midway, greaterThan(closed));
      expect(midway, lessThan(closed + 100));
    });

    testWidgets("jumps under disableAnimations", (tester) async {
      await tester.pumpWidget(
        app(const MochiCollapsible(title: Text("Title"), child: body), disableAnimations: true),
      );
      final closed = tester.getSize(find.byType(MochiCollapsible)).height;

      await tester.tap(find.text("Title"));
      await tester.pump();
      expect(tester.getSize(find.byType(MochiCollapsible)).height, closed + 100);
    });

    testWidgets("initiallyExpanded starts open", (tester) async {
      await tester.pumpWidget(
        app(const MochiCollapsible(title: Text("Title"), initiallyExpanded: true, child: body)),
      );
      expect(find.text("Body"), findsOneWidget);
    });

    testWidgets("controlled: a press only asks, and it follows what it is rebuilt with", (tester) async {
      final asked = <bool>[];
      Widget build(bool expanded) => app(
        MochiCollapsible(
          title: const Text("Title"),
          expanded: expanded,
          onExpandedChanged: asked.add,
          child: body,
        ),
      );

      await tester.pumpWidget(build(false));
      await tester.tap(find.text("Title"));
      await tester.pumpAndSettle();
      expect(asked, [true]);
      expect(find.text("Body"), findsNothing, reason: "the parent hasn't said yes");

      await tester.pumpWidget(build(true));
      await tester.pumpAndSettle();
      expect(find.text("Body"), findsOneWidget);
    });

    testWidgets("maintainState keeps a closed body's state", (tester) async {
      await tester.pumpWidget(
        app(const MochiCollapsible(title: Text("Title"), maintainState: true, child: _Counter())),
      );
      await tester.tap(find.text("Title"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("count 0"));
      await tester.pump();

      await tester.tap(find.text("Title"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Title"));
      await tester.pumpAndSettle();
      expect(find.text("count 1"), findsOneWidget);
    });

    testWidgets("a closed body can't be tabbed into", (tester) async {
      final inner = FocusNode();
      addTearDown(inner.dispose);
      await tester.pumpWidget(
        app(
          MochiCollapsible(
            title: const Text("Title"),
            maintainState: true,
            child: MochiButton(focusNode: inner, onPress: () {}, child: const Text("inner")),
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(inner.hasFocus, isFalse);
    });

    testWidgets("the keyboard opens it", (tester) async {
      await tester.pumpWidget(app(const MochiCollapsible(title: Text("Title"), child: body)));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text("Body"), findsOneWidget);
    });

    testWidgets("tells screen readers whether it is open", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app(const MochiCollapsible(title: Text("Title"), child: body)));
      SemanticsNode node() => tester.getSemantics(find.byType(MochiTappable));
      expect(node().flagsCollection.isButton, isTrue);
      expect(node().flagsCollection.isExpanded, Tristate.isFalse);

      await tester.tap(find.text("Title"));
      await tester.pumpAndSettle();
      expect(node().flagsCollection.isExpanded, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets("the header stays square at the bottom until the body has gone", (tester) async {
      const radius = BorderRadius.all(Radius.circular(10));
      await tester.pumpWidget(
        app(
          const MochiCollapsible(title: Text("Title"), initiallyExpanded: true, radius: radius, child: body),
        ),
      );
      BorderRadiusGeometry corners() =>
          ((tester
                              .widget<DecoratedBox>(
                                find
                                    .descendant(
                                      of: find.byType(MochiTappable),
                                      matching: find.byType(DecoratedBox),
                                    )
                                    .first,
                              )
                              .decoration
                          as ShapeDecoration)
                      .shape
                  as RoundedSuperellipseBorder)
              .borderRadius;
      const top = BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10));
      expect(corners(), top);

      await tester.tap(find.text("Title"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(corners(), top, reason: "still closing");

      await tester.pumpAndSettle();
      expect(corners(), radius);
    });

    testWidgets("disabled does nothing", (tester) async {
      await tester.pumpWidget(app(const MochiCollapsible(title: Text("Title"), enabled: false, child: body)));
      await tester.tap(find.text("Title"));
      await tester.pumpAndSettle();
      expect(find.text("Body"), findsNothing);
    });

    testWidgets("the header tints under the pointer", (tester) async {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);
      await tester.pumpWidget(app(const MochiCollapsible(title: Text("Title"), child: body)));

      Color fill() =>
          (tester
                      .widget<DecoratedBox>(
                        find
                            .descendant(
                              of: find.byType(MochiCollapsible),
                              matching: find.byType(DecoratedBox),
                            )
                            .first,
                      )
                      .decoration
                  as ShapeDecoration)
              .color!;
      expect(fill().a, 0);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text("Title")));
      await tester.pumpAndSettle();
      expect(fill().a, greaterThan(0));
      await gesture.removePointer();
    });
  });

  group("MochiCard.collapsible", () {
    testWidgets("shows its title, and its body once opened", (tester) async {
      await tester.pumpWidget(app(const MochiCard.collapsible(title: Text("Stats"), child: body)));
      expect(find.text("Stats"), findsOneWidget);
      expect(find.text("Body"), findsNothing);

      await tester.tap(find.text("Stats"));
      await tester.pumpAndSettle();
      expect(find.text("Body"), findsOneWidget);
    });

    testWidgets("the title row reaches the card's edges, the body keeps the padding", (tester) async {
      await tester.pumpWidget(
        app(const MochiCard.collapsible(title: Text("Stats"), initiallyExpanded: true, child: body)),
      );
      final card = tester.getRect(find.byType(MochiCard));
      final header = tester.getRect(
        find.descendant(of: find.byType(MochiCollapsible), matching: find.byType(DecoratedBox)).first,
      );
      final content = tester.getRect(find.text("Body"));

      expect(header.left - card.left, lessThanOrEqualTo(1), reason: "only the border in between");
      final rule = tester.getRect(find.byType(MochiDivider));
      expect(rule.top, header.bottom, reason: "the title row's hover fill stops at the rule");
      expect(
        content.top - rule.bottom,
        greaterThanOrEqualTo(16),
        reason: "and the content keeps its padding",
      );
      expect(content.left - card.left, greaterThan(16));
      expect(card.bottom - content.bottom, greaterThan(16));
    });
  });
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  var _count = 0;

  @override
  Widget build(BuildContext context) =>
      GestureDetector(onTap: () => setState(() => _count++), child: Text("count $_count"));
}
