import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: false,
    home: Center(child: child),
  );

  Finder boxes() => find.descendant(of: find.byType(MochiOtpField), matching: find.byType(Container));

  // What the boxes show, an empty string for a box with nothing in it.
  List<String> shown(WidgetTester tester) => [
    for (var i = 0; i < tester.widgetList(boxes()).length; i++)
      tester
              .widgetList<Text>(find.descendant(of: boxes().at(i), matching: find.byType(Text)))
              .firstOrNull
              ?.data ??
          "",
  ];

  Future<void> focusAndType(WidgetTester tester, String text) async {
    await tester.tap(boxes().first);
    await tester.pump();
    tester.testTextInput.enterText(text);
    await tester.pump();
  }

  testWidgets("one box a character, filled from the start", (tester) async {
    final seen = <String>[];
    await tester.pumpWidget(app(MochiOtpField(length: 4, onChanged: seen.add)));
    expect(boxes(), findsNWidgets(4));
    expect(shown(tester), ["", "", "", ""]);

    await focusAndType(tester, "12");
    expect(shown(tester), ["1", "2", "", ""]);
    expect(seen, ["12"]);
  });

  testWidgets("a paste drops the whole code in and reports it complete", (tester) async {
    String? completed;
    await tester.pumpWidget(app(MochiOtpField(length: 6, onCompleted: (code) => completed = code)));

    await focusAndType(tester, "429301");
    expect(shown(tester), ["4", "2", "9", "3", "0", "1"]);
    expect(completed, "429301");
  });

  testWidgets("nothing past the last box", (tester) async {
    await tester.pumpWidget(app(const MochiOtpField(length: 4)));
    await focusAndType(tester, "1234567");
    expect(shown(tester), ["1", "2", "3", "4"]);
  });

  testWidgets("digits only, unless it is told otherwise", (tester) async {
    await tester.pumpWidget(app(const MochiOtpField(length: 4)));
    await focusAndType(tester, "1a2b");
    expect(shown(tester), ["1", "2", "", ""]);

    await tester.pumpWidget(app(const MochiOtpField(length: 4, digitsOnly: false)));
    await focusAndType(tester, "1a2b");
    expect(shown(tester), ["1", "a", "2", "b"]);
  });

  testWidgets("backspace takes the last character out", (tester) async {
    final seen = <String>[];
    await tester.pumpWidget(app(MochiOtpField(length: 4, initialValue: "123", onChanged: seen.add)));
    expect(shown(tester), ["1", "2", "3", ""]);

    await tester.tap(boxes().first);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(shown(tester), ["1", "2", "", ""]);
    expect(seen, ["12"]);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets("the caret sits in the box being filled, and only while focused", (tester) async {
    await tester.pumpWidget(app(const MochiOtpField(length: 4)));
    Finder caretIn(int index) =>
        find.descendant(of: boxes().at(index), matching: find.byType(AnimatedBuilder));
    expect(caretIn(0), findsNothing, reason: "not focused yet");

    await focusAndType(tester, "12");
    expect(caretIn(2), findsOneWidget);
    expect(caretIn(0), findsNothing);
    expect(caretIn(1), findsNothing);

    // A full code has no box waiting for a character.
    await focusAndType(tester, "1234");
    for (var i = 0; i < 4; i++) {
      expect(caretIn(i), findsNothing, reason: "box $i");
    }
  });

  testWidgets("obscure shows a dot in place of the character", (tester) async {
    await tester.pumpWidget(app(const MochiOtpField(length: 4, obscure: true)));
    await focusAndType(tester, "12");
    expect(find.descendant(of: boxes().first, matching: find.byType(Text)), findsNothing);
    expect(shown(tester), ["", "", "", ""]);
  });

  testWidgets("a box is as tall as a button of the same size, and square", (tester) async {
    for (final size in MochiSize.values) {
      await tester.pumpWidget(
        app(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MochiOtpField(length: 3, size: size),
              MochiButton(size: size, onPress: () {}, child: const Text("Go")),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final box = tester.getSize(boxes().first);
      expect(box.height, tester.getSize(find.byType(MochiButton)).height, reason: size.name);
      expect(box.width, box.height, reason: size.name);
    }
  });

  testWidgets("disabled takes no input", (tester) async {
    final seen = <String>[];
    await tester.pumpWidget(app(MochiOtpField(length: 4, enabled: false, onChanged: seen.add)));
    await tester.tap(boxes().first);
    await tester.pump();
    expect(tester.testTextInput.hasAnyClients, isFalse);
    expect(seen, isEmpty);
  });

  testWidgets("an error colours every box and shows under them", (tester) async {
    await tester.pumpWidget(app(const MochiOtpField(length: 3, error: "That code is wrong.")));
    await tester.pumpAndSettle();
    expect(find.text("That code is wrong."), findsOneWidget);

    Color borderOf(int index) =>
        ((tester.widget<Container>(boxes().at(index)).decoration! as ShapeDecoration).shape
                as RoundedSuperellipseBorder)
            .side
            .color;
    for (var i = 0; i < 3; i++) {
      expect(borderOf(i), MochiColors.light.danger.base, reason: "box $i");
    }
  });
}
