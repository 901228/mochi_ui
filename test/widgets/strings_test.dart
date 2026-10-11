import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget host({MochiStrings? strings, required Future<void> Function(BuildContext context) onPress}) =>
      MediaQuery(
        data: const MediaQueryData(size: Size(1000, 700)),
        child: MochiApp(
          themeMode: MochiThemeMode.light,
          strings: strings,
          home: Builder(
            builder: (context) => Center(
              child: MochiButton(onPress: () => onPress(context), child: const Text("open")),
            ),
          ),
        ),
      );

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
  }

  testWidgets("the helpers speak English by default", (tester) async {
    await tester.pumpWidget(host(onPress: (context) => showMochiConfirm(context, title: "Sure?")));
    await open(tester);

    expect(find.text("OK"), findsOneWidget);
    expect(find.text("Cancel"), findsOneWidget);
  });

  testWidgets("MochiApp(strings:) puts them in the app's language", (tester) async {
    await tester.pumpWidget(
      host(
        strings: MochiStrings.zhHant,
        onPress: (context) => showMochiConfirm(context, title: "Sure?"),
      ),
    );
    await open(tester);

    expect(find.text("確定"), findsOneWidget);
    expect(find.text("取消"), findsOneWidget);
  });

  testWidgets("a label passed in wins over the strings", (tester) async {
    await tester.pumpWidget(
      host(
        strings: MochiStrings.zhHant,
        onPress: (context) => showMochiConfirm(context, title: "Sure?", confirmLabel: "Delete"),
      ),
    );
    await open(tester);

    expect(find.text("Delete"), findsOneWidget);
    expect(find.text("確定"), findsNothing);
    expect(find.text("取消"), findsOneWidget);
  });

  testWidgets("alert and choice take theirs from the strings too", (tester) async {
    await tester.pumpWidget(
      host(
        strings: MochiStrings.zhHant,
        onPress: (context) => showMochiAlert(context, title: "Saved"),
      ),
    );
    await open(tester);
    expect(find.text("確定"), findsOneWidget);

    await tester.tap(find.text("確定"));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      host(
        strings: MochiStrings.zhHant,
        onPress: (context) => showMochiChoice<int>(
          context,
          title: "Pick",
          choices: const [MochiChoice(value: 1, label: "One")],
        ),
      ),
    );
    await open(tester);
    expect(find.text("取消"), findsOneWidget);
  });

  testWidgets("the barrier is named from the strings", (tester) async {
    await tester.pumpWidget(
      host(
        strings: MochiStrings.zhHant,
        onPress: (context) =>
            showMochiDialog<void>(context, builder: (context) => const MochiDialog(title: Text("Hi"))),
      ),
    );
    await open(tester);

    final route = ModalRoute.of(tester.element(find.text("Hi")))! as MochiDialogRoute<void>;
    expect(route.barrierLabel, "關閉");
  });

  testWidgets("the header's built-in actions take their tooltips from the strings", (tester) async {
    await tester.pumpWidget(
      MochiApp(
        themeMode: MochiThemeMode.light,
        strings: MochiStrings.zhHant,
        home: MochiActionBar([MochiAction.back(onPress: () {})]),
      ),
    );

    final tooltip = tester.widget<MochiButton>(find.byType(MochiButton)).tooltip;
    expect(tooltip, "返回");
  });

  test("strings take part in the theme's value equality", () {
    final a = MochiTheme.light;
    expect(a.copyWith(strings: MochiStrings.en), a);
    expect(a.copyWith(strings: MochiStrings.zhHant), isNot(a));
    expect(MochiStrings.en.copyWith(ok: "Okay"), isNot(MochiStrings.en));
  });
}
