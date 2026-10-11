import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child, {bool touch = false}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: touch,
    home: Center(child: child),
  );

  Rect thumb(WidgetTester tester) => tester.getRect(find.byType(DecoratedBox).last);

  testWidgets("tapping reports the new value", (tester) async {
    final changes = <bool>[];
    await tester.pumpWidget(app(MochiSwitch(value: false, onChanged: changes.add)));

    await tester.tap(find.byType(MochiSwitch));
    expect(changes, [true]);

    await tester.pumpWidget(app(MochiSwitch(value: true, onChanged: changes.add)));
    await tester.tap(find.byType(MochiSwitch));
    expect(changes, [true, false]);
  });

  testWidgets("the thumb slides from left to right and the track takes the intent color", (tester) async {
    await tester.pumpWidget(app(MochiSwitch(value: false, onChanged: (_) {})));
    await tester.pumpAndSettle();
    final off = thumb(tester);
    final track = tester.getRect(find.byType(MochiSwitch));
    expect(off.left - track.left, lessThan(track.right - off.right));

    await tester.pumpWidget(app(MochiSwitch(value: true, onChanged: (_) {})));
    await tester.pump(const Duration(milliseconds: 40));
    final mid = thumb(tester);
    expect(mid.left, greaterThan(off.left));

    await tester.pumpAndSettle();
    final on = thumb(tester);
    expect(on.right, moreOrLessEquals(track.right - 3, epsilon: 0.01));

    final container = tester.widget<Container>(find.byType(Container).first);
    expect((container.decoration! as ShapeDecoration).color, MochiColors.light.primary.base);
  });

  testWidgets("disabled by a null onChanged", (tester) async {
    await tester.pumpWidget(app(const MochiSwitch(value: false, onChanged: null)));
    await tester.tap(find.byType(MochiSwitch));
    await tester.pumpAndSettle();

    expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 0.4);
  });

  testWidgets("touch sizing is larger", (tester) async {
    await tester.pumpWidget(app(MochiSwitch(value: false, onChanged: (_) {})));
    final desktop = tester.getSize(find.byType(MochiSwitch));

    await tester.pumpWidget(app(MochiSwitch(value: false, onChanged: (_) {}), touch: true));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MochiSwitch)).width, greaterThan(desktop.width));
  });
}
