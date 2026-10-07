import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui/widgets/shape_shadow.dart";

/// The superellipse a surface inside [within] is drawn with: its fill and its line.
ShapeDecoration surfaceOf(WidgetTester tester, Finder within) => tester
    .widgetList<Widget>(find.descendant(of: within, matching: find.byWidgetPredicate((_) => true)))
    .map((w) => w is DecoratedBox ? w.decoration : (w is Container ? w.decoration : null))
    .whereType<ShapeDecoration>()
    .first;

/// The shadows a surface inside [within] casts. Never on its [ShapeDecoration]: they go on a
/// rounded rectangle under it, which the web can blur cheaply (see `ShapeShadow`).
List<BoxShadow>? shadowsOf(WidgetTester tester, Finder within) =>
    tester.widget<ShapeShadow>(find.descendant(of: within, matching: find.byType(ShapeShadow)).first).shadows;
