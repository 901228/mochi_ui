import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  late MochiStrings seen;

  Widget app({Locale? locale, MochiStrings? strings, MochiTheme? theme}) => MochiApp(
    themeMode: MochiThemeMode.light,
    locale: locale,
    supportedLocales: const [Locale("en"), Locale("zh")],
    strings: strings,
    lightTheme: theme,
    home: Builder(
      builder: (context) {
        seen = context.theme.strings;
        return const SizedBox();
      },
    ),
  );

  testWidgets("the components speak the language of the app", (tester) async {
    await tester.pumpWidget(app(locale: const Locale("zh", "TW")));
    expect(seen, MochiStrings.zhHant);

    await tester.pumpWidget(app(locale: const Locale("en")));
    await tester.pumpAndSettle();
    expect(seen, MochiStrings.en);
  });

  testWidgets("what the app gives is kept over the language", (tester) async {
    await tester.pumpWidget(app(locale: const Locale("zh"), strings: MochiStrings.en));
    expect(seen, MochiStrings.en);
  });

  testWidgets("so are the words a theme brought", (tester) async {
    final own = MochiStrings.zhHant.copyWith(ok: "好");
    await tester.pumpWidget(
      app(
        locale: const Locale("en"),
        theme: MochiTheme.light.copyWith(strings: own),
      ),
    );
    expect(seen, own);
  });
}
