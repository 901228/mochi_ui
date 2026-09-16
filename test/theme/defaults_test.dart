import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Future<Color> background(WidgetTester tester, {MochiDefaults? defaults, Widget? button}) async {
    await tester.pumpWidget(
      MochiApp(
        themeMode: MochiThemeMode.light,
        lightTheme: defaults == null ? MochiTheme.light : MochiTheme.light.copyWith(defaults: defaults),
        home: Center(
          child: button ?? MochiButton(onPress: () {}, child: const Text("Save")),
        ),
      ),
    );
    // The helper is called twice per test; let the theme animation finish.
    await tester.pumpAndSettle();
    final container = tester.widget<Container>(
      find.descendant(of: find.byType(MochiButton), matching: find.byType(Container)).first,
    );
    return (container.decoration! as ShapeDecoration).color!;
  }

  final primary = MochiColors.light.primary;

  testWidgets("buttons use the theme's default appearance", (tester) async {
    expect(await background(tester), primary.base);
    expect(await background(tester, defaults: const MochiDefaults(buttonAppearance: .soft)), primary.soft);
  });

  testWidgets("an explicit appearance still wins", (tester) async {
    expect(
      await background(
        tester,
        defaults: const MochiDefaults(buttonAppearance: .soft),
        button: MochiButton(appearance: .solid, onPress: () {}, child: const Text("Save")),
      ),
      primary.base,
    );
  });

  test("filled appearances keep a transparent border", () {
    // Stroking the fill color paints the antialiased edge twice and hardens it.
    for (final appearance in [MochiButtonAppearance.solid, MochiButtonAppearance.inverted]) {
      final style = MochiButtonStyle.of(MochiIntent.primary, appearance);
      expect(style.border(MochiColors.light, const {}).a, 0, reason: appearance.name);
    }
    expect(
      MochiButtonStyle.of(
        MochiIntent.primary,
        MochiButtonAppearance.outlined,
      ).border(MochiColors.light, const {}),
      MochiColors.light.primary.base,
    );
  });

  testWidgets("icon buttons have their own default", (tester) async {
    expect(
      await background(
        tester,
        defaults: const MochiDefaults(buttonAppearance: .soft, iconButtonAppearance: .solid),
        button: MochiButton.icon(onPress: () {}, icon: const SizedBox.square(dimension: 8)),
      ),
      primary.base,
    );
  });
}
