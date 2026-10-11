import "package:flutter/gestures.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child, {MochiStrings? strings}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: false,
    strings: strings ?? MochiStrings.en,
    home: Center(child: SizedBox(width: 300, child: child)),
  );

  Future<void> type(WidgetTester tester, String text) async {
    await tester.tap(find.byType(MochiSearchBar), kind: PointerDeviceKind.mouse);
    await tester.pump();
    tester.testTextInput.enterText(text);
    await tester.pump();
  }

  testWidgets("the magnifier and the hint from the strings", (tester) async {
    await tester.pumpWidget(app(const MochiSearchBar()));
    expect(find.byIcon(MochiIcons.standard.search), findsOneWidget);
    expect(find.text("Search"), findsOneWidget);

    await tester.pumpWidget(app(const MochiSearchBar(), strings: MochiStrings.zhHant));
    expect(find.text("搜尋"), findsOneWidget);
  });

  testWidgets("onSearch waits for the typing to stop; onChanged doesn't", (tester) async {
    final typed = <String>[];
    final searched = <String>[];
    await tester.pumpWidget(app(MochiSearchBar(onChanged: typed.add, onSearch: searched.add)));

    await type(tester, "me");
    await tester.pump(const Duration(milliseconds: 200));
    await type(tester, "mega");
    expect(typed, ["me", "mega"]);
    expect(searched, isEmpty, reason: "the second keystroke put the clock back");

    await tester.pump(const Duration(milliseconds: 300));
    expect(searched, ["mega"]);
  });

  testWidgets("a debounce of zero searches with every keystroke", (tester) async {
    final searched = <String>[];
    await tester.pumpWidget(app(MochiSearchBar(debounce: Duration.zero, onSearch: searched.add)));

    await type(tester, "m");
    await type(tester, "me");
    expect(searched, ["m", "me"]);
  });

  testWidgets("emptying the field searches at once", (tester) async {
    final searched = <String>[];
    await tester.pumpWidget(app(MochiSearchBar(onSearch: searched.add)));

    await type(tester, "meg");
    await tester.pump(const Duration(milliseconds: 400));
    expect(searched, ["meg"]);

    await type(tester, "");
    expect(searched, ["meg", ""], reason: "no wait before showing everything again");
  });

  testWidgets("a query nobody searched for needs no undoing", (tester) async {
    final searched = <String>[];
    await tester.pumpWidget(app(MochiSearchBar(onSearch: searched.add)));

    // Typed and taken back within the debounce: the results never changed.
    await type(tester, "meg");
    await type(tester, "");
    await tester.pump(const Duration(milliseconds: 400));
    expect(searched, isEmpty);
  });

  testWidgets("submitting searches at once, and only once", (tester) async {
    final searched = <String>[];
    final submitted = <String>[];
    await tester.pumpWidget(app(MochiSearchBar(onSearch: searched.add, onSubmitted: submitted.add)));

    await type(tester, "mega");
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(searched, ["mega"]);
    expect(submitted, ["mega"]);

    await tester.pump(const Duration(milliseconds: 400));
    expect(searched, ["mega"], reason: "the pending timer was cancelled");
  });

  testWidgets("the × clears it and searches at once", (tester) async {
    final searched = <String>[];
    await tester.pumpWidget(app(MochiSearchBar(onSearch: searched.add)));

    await type(tester, "mega");
    await tester.pump(const Duration(milliseconds: 400));
    expect(searched, ["mega"]);

    await tester.tap(find.byType(MochiCloseButton), kind: PointerDeviceKind.mouse);
    await tester.pump();
    expect(searched, ["mega", ""]);
    expect(find.text("Search"), findsOneWidget, reason: "the hint is back");
  });

  testWidgets("loading puts a spinner where the × goes", (tester) async {
    await tester.pumpWidget(app(const MochiSearchBar(initialValue: "mega", loading: true)));
    expect(find.byType(MochiCircularProgress), findsOneWidget);
    expect(find.byType(MochiCloseButton), findsNothing);

    await tester.pumpWidget(app(const MochiSearchBar(initialValue: "mega")));
    await tester.pumpAndSettle();
    expect(find.byType(MochiCircularProgress), findsNothing);
    expect(find.byType(MochiCloseButton), findsOneWidget);
  });

  testWidgets("a pending search doesn't outlive the bar", (tester) async {
    final searched = <String>[];
    await tester.pumpWidget(app(MochiSearchBar(onSearch: searched.add)));
    await type(tester, "mega");

    await tester.pumpWidget(app(const SizedBox.shrink()));
    await tester.pump(const Duration(milliseconds: 400));
    expect(searched, isEmpty);
  });
}
