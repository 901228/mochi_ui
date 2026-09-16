import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int value = 0;

  @override
  Widget build(BuildContext context) => SizedBox.square(dimension: 20, child: Text("$value"));
}

void main() {
  Finder ring() => find.byWidgetPredicate(
    (w) =>
        w is DecoratedBox &&
        w.decoration is ShapeDecoration &&
        (w.decoration as ShapeDecoration).shape is RoundedSuperellipseBorder &&
        ((w.decoration as ShapeDecoration).shape as RoundedSuperellipseBorder).side ==
            BorderSide(
              color: MochiColors.light.focusRing,
              width: MochiGeometry.standard.focusRingWidth,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
  );

  Widget app(Widget child, {MochiGeometry geometry = MochiGeometry.standard}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: false,
    lightTheme: MochiTheme.light.copyWith(geometry: geometry),
    home: Center(child: child),
  );

  testWidgets("keyboard focus shows the ring outside the button without changing its size", (tester) async {
    await tester.pumpWidget(app(MochiButton(onPress: () {}, child: const Text("Save"))));
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    final size = tester.getSize(find.byType(MochiButton));
    expect(ring(), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(ring(), findsOneWidget);
    expect(tester.getSize(find.byType(MochiButton)), size);

    final g = MochiGeometry.standard;
    final outset = g.focusRingGap + g.focusRingWidth;
    expect(tester.getSize(ring()), Size(size.width + 2 * outset, size.height + 2 * outset));

    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  testWidgets("toggling the ring keeps the child's state", (tester) async {
    Widget ringed(bool visible) =>
        app(MochiFocusRing(visible: visible, radius: BorderRadius.zero, child: const _Counter()));

    await tester.pumpWidget(ringed(false));
    tester.state<_CounterState>(find.byType(_Counter)).value = 42;

    await tester.pumpWidget(ringed(true));
    expect(tester.state<_CounterState>(find.byType(_Counter)).value, 42);
  });

  testWidgets("button radius comes from the theme geometry", (tester) async {
    const geometry = MochiGeometry(radius: MochiRadius(sm: BorderRadius.all(Radius.circular(3))));
    await tester.pumpWidget(
      app(
        MochiButton(onPress: () {}, child: const Text("Save")),
        geometry: geometry,
      ),
    );

    final surface = tester.widget<Container>(
      find.descendant(of: find.byType(MochiButton), matching: find.byType(Container)).first,
    );
    final shape = (surface.decoration! as ShapeDecoration).shape as RoundedSuperellipseBorder;
    expect(shape.borderRadius, geometry.radius.sm);
  });
}
