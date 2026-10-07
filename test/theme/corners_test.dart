import "dart:io";

import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app({MochiCorners? corners}) => MochiApp(
    themeMode: MochiThemeMode.light,
    corners: corners,
    home: Center(
      child: MochiCard(
        child: MochiButton(onPress: () {}, child: const Text("Save")),
      ),
    ),
  );

  Iterable<ShapeBorder> shapes(WidgetTester tester) => tester
      .widgetList<Widget>(find.byWidgetPredicate((w) => w is DecoratedBox || w is Container))
      .map((w) => w is DecoratedBox ? w.decoration : (w as Container).decoration)
      .whereType<ShapeDecoration>()
      .map((d) => d.shape);

  test("the platform's own: superellipses off the web", () {
    expect(MochiCorners.platform, MochiCorners.superellipse);
    expect(MochiGeometry.standard.corners, MochiCorners.platform);
  });

  test("corners are part of the geometry's value", () {
    const a = MochiGeometry();
    final b = a.copyWith(corners: MochiCorners.rounded);
    expect(b, isNot(a));
    expect(b, a.copyWith(corners: MochiCorners.rounded));
    expect(b.hashCode, a.copyWith(corners: MochiCorners.rounded).hashCode);
    // Density keeps them.
    expect(b.withDensity(0.85).corners, MochiCorners.rounded);
  });

  testWidgets("circular corners leave no superellipse anywhere, shape or clip", (tester) async {
    await tester.pumpWidget(app(corners: MochiCorners.rounded));
    await tester.pumpAndSettle();
    expect(shapes(tester), isNotEmpty);
    expect(shapes(tester).whereType<RoundedSuperellipseBorder>(), isEmpty);
    expect(shapes(tester).whereType<RoundedRectangleBorder>(), isNotEmpty);
    expect(find.byType(ClipRSuperellipse), findsNothing);
    expect(find.byType(ClipRRect), findsWidgets);

    await tester.pumpWidget(app(corners: MochiCorners.superellipse));
    await tester.pumpAndSettle();
    expect(shapes(tester).whereType<RoundedRectangleBorder>(), isEmpty);
    expect(find.byType(ClipRRect), findsNothing);
  });

  test("no component names a corner shape itself", () {
    // Every corner goes through `geometry.shape` and `MochiClip`, or the token stops reaching it.
    final offenders = <String>[];
    for (final file in Directory("lib/mochi_ui/widgets").listSync().whereType<File>()) {
      if (file.path.endsWith("clip.dart")) continue;
      final lines = file.readAsLinesSync();
      for (final (i, line) in lines.indexed) {
        if (line.trimLeft().startsWith("//")) continue;
        if (line.contains("RoundedSuperellipseBorder(") || line.contains("ClipRSuperellipse(")) {
          offenders.add("${file.path}:${i + 1}");
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
