import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  group("radius presets", () {
    test("run from square to round, and full stays full", () {
      expect(MochiRadius.sharp.md, BorderRadius.zero);
      expect(MochiRadius.subtle.md, const BorderRadius.all(Radius.circular(5)));
      expect(MochiRadius.standard, const MochiRadius());
      expect(MochiRadius.rounded.md, const BorderRadius.all(Radius.circular(15)));
      expect(MochiRadius.pill.md, MochiRadius.standard.full);
      for (final preset in [MochiRadius.sharp, MochiRadius.subtle, MochiRadius.rounded, MochiRadius.pill]) {
        expect(preset.full, MochiRadius.standard.full);
      }
    });

    test("theme.copyWith(radius:) replaces only the corners", () {
      final theme = MochiTheme.light.copyWith(radius: MochiRadius.sharp);
      expect(theme.geometry.radius, MochiRadius.sharp);
      expect(theme.geometry.space, MochiTheme.light.geometry.space);
    });
  });

  group("density", () {
    test("scales spacing and page padding, not lines or corners", () {
      final theme = MochiTheme.light.copyWith(density: 0.5);
      final g = theme.geometry;
      expect(g.space.md, 8);
      expect(g.pagePadding, MochiGeometry.standard.pagePadding * 0.5);
      expect(g.borderWidth, MochiGeometry.standard.borderWidth);
      expect(g.radius, MochiGeometry.standard.radius);
    });

    test("is applied once, however many copies are made", () {
      final theme = MochiTheme.light
          .copyWith(density: 0.5)
          .copyWith(radius: MochiRadius.sharp)
          .copyWith(touch: true);
      expect(theme.geometry.space.md, 8);
    });

    test("scales control heights, not their icons or text", () {
      final normal = MochiButtonMetrics.of(MochiSize.md, touch: false);
      final compact = MochiButtonMetrics.of(MochiSize.md, touch: false, density: 0.5);
      expect(compact.height, normal.height / 2);
      expect(compact.horizontalPadding, normal.horizontalPadding / 2);
      expect(compact.iconSize, normal.iconSize);

      expect(
        MochiBadgeMetrics.of(MochiSize.sm, touch: false, density: 1.5).height,
        MochiBadgeMetrics.of(MochiSize.sm, touch: false).height * 1.5,
      );
      expect(
        MochiCloseButtonMetrics.of(MochiSize.md, touch: false, density: 0.5).diameter,
        MochiCloseButtonMetrics.of(MochiSize.md, touch: false).diameter / 2,
      );
    });

    test("takes part in value equality, and switches immediately in a lerp", () {
      final light = MochiTheme.light;
      expect(light.copyWith(density: 1), light);
      expect(light.copyWith(density: 0.9), isNot(light));
      expect(MochiTheme.lerp(light, light.copyWith(density: 0.9), 0).density, 0.9);
    });
  });

  group("MochiApp", () {
    Widget app({MochiRadius? radius, double? density, double textScale = 1, required Widget home}) =>
        MochiApp(
          themeMode: MochiThemeMode.light,
          touch: false,
          radius: radius,
          density: density,
          textScale: textScale,
          home: Center(child: home),
        );

    testWidgets("radius: reaches the components", (tester) async {
      await tester.pumpWidget(
        app(
          radius: MochiRadius.sharp,
          home: MochiButton(onPress: () {}, child: const Text("Go")),
        ),
      );

      final shape =
          (tester
                          .widget<Container>(
                            find
                                .descendant(of: find.byType(MochiButton), matching: find.byType(Container))
                                .first,
                          )
                          .decoration!
                      as ShapeDecoration)
                  .shape
              as RoundedSuperellipseBorder;
      expect(shape.borderRadius, BorderRadius.zero);
    });

    testWidgets("density: packs controls tighter", (tester) async {
      await tester.pumpWidget(
        app(
          home: MochiButton(onPress: () {}, child: const Text("Go")),
        ),
      );
      final normal = tester.getSize(find.byType(MochiButton)).height;

      await tester.pumpWidget(
        app(
          density: 0.75,
          home: MochiButton(onPress: () {}, child: const Text("Go")),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(MochiButton)).height, normal * 0.75);
    });

    testWidgets("textScale: multiplies the system's text scaling", (tester) async {
      late TextScaler scaler;
      Widget probe() => Builder(
        builder: (context) {
          scaler = MediaQuery.textScalerOf(context);
          return const SizedBox();
        },
      );

      await tester.pumpWidget(app(textScale: 1.2, home: probe()));
      expect(scaler.scale(10), closeTo(12, 1e-9));

      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(app(textScale: 1.2, home: probe()));
      expect(scaler.scale(10), closeTo(18, 1e-9));
    });
  });
}
