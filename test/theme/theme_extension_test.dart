import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

class _CubeColors extends MochiThemeExtension<_CubeColors> {
  const _CubeColors(this.face);
  final Color face;

  @override
  _CubeColors lerp(_CubeColors other, double t) => _CubeColors(Color.lerp(face, other.face, t)!);

  @override
  bool operator ==(Object other) => other is _CubeColors && other.face == face;

  @override
  int get hashCode => face.hashCode;
}

class _Spacing extends MochiThemeExtension<_Spacing> {
  const _Spacing(this.page);
  final double page;

  @override
  _Spacing lerp(_Spacing other, double t) => t < 0.5 ? this : other;
}

void main() {
  const black = Color(0xFF000000);
  const white = Color(0xFFFFFFFF);

  test("lookup by type", () {
    final theme = MochiTheme.light.copyWith(extensions: [const _CubeColors(black), const _Spacing(12)]);
    expect(theme.extension<_CubeColors>().face, black);
    expect(theme.extension<_Spacing>().page, 12);
    expect(MochiTheme.light.maybeExtension<_Spacing>(), isNull);
  });

  test("copyWith merges extensions by type", () {
    final theme = MochiTheme.light
        .copyWith(extensions: [const _CubeColors(black), const _Spacing(12)])
        .copyWith(extensions: [const _CubeColors(white)]);
    expect(theme.extension<_CubeColors>().face, white);
    expect(theme.extension<_Spacing>().page, 12);
  });

  test("value equality", () {
    final a = MochiTheme.light.copyWith(touch: true, extensions: [const _CubeColors(black)]);
    final b = MochiTheme.light.copyWith(touch: true, extensions: [const _CubeColors(black)]);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(a.copyWith(touch: false)));
  });

  testWidgets("extensions animate with the theme", (tester) async {
    Color? face;
    Widget app(MochiThemeMode mode) => MochiApp(
      themeMode: mode,
      lightTheme: MochiTheme.light.copyWith(extensions: [const _CubeColors(black)]),
      darkTheme: MochiTheme.dark.copyWith(extensions: [const _CubeColors(white)]),
      home: Builder(
        builder: (context) {
          face = context.theme.extension<_CubeColors>().face;
          return const SizedBox();
        },
      ),
    );

    await tester.pumpWidget(app(MochiThemeMode.light));
    expect(face, black);

    await tester.pumpWidget(app(MochiThemeMode.dark));
    await tester.pump(const Duration(milliseconds: 100));
    expect(face, isNot(anyOf(black, white)));

    await tester.pumpAndSettle();
    expect(face, white);
  });

  testWidgets("rebuilding MochiApp with an equal theme does not start an animation", (tester) async {
    Widget app() => MochiApp(themeMode: MochiThemeMode.light, touch: true, home: const SizedBox());
    await tester.pumpWidget(app());
    await tester.pumpWidget(app());
    expect(tester.hasRunningAnimations, isFalse);
  });
}
