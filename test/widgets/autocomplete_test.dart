import "package:flutter/gestures.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  const sessions = ["3x3 main", "3x3 OH", "3x3 BLD", "Megaminx", "Pyraminx"];

  Widget app(Widget child) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: false,
    home: Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: SizedBox(width: 260, child: child),
      ),
    ),
  );

  Widget field({
    List<String>? taken,
    List<String>? typed,
    Future<List<String>> Function(String text)? asyncOptions,
    String? label,
    String? description,
  }) => app(
    MochiAutocomplete<String>(
      hint: "Session",
      label: label == null ? null : Text(label),
      description: description == null ? null : Text(description),
      optionsBuilder: (value) =>
          asyncOptions?.call(value.text) ??
          (value.text.isEmpty
              ? const <String>[]
              : sessions.where((s) => s.toLowerCase().contains(value.text.toLowerCase()))),
      onSelected: taken?.add,
      onChanged: typed?.add,
    ),
  );

  Future<void> type(WidgetTester tester, String text) async {
    await tester.tap(find.byType(MochiTextField), kind: PointerDeviceKind.mouse);
    await tester.pump();
    tester.testTextInput.enterText(text);
    await tester.pumpAndSettle();
  }

  Finder rows() => find.byType(MochiMenuItem);

  testWidgets("typing shows the matching options, and nothing matches nothing", (tester) async {
    await tester.pumpWidget(field());
    expect(rows(), findsNothing);

    await type(tester, "3x3");
    expect(rows(), findsNWidgets(3));
    expect(find.text("Megaminx"), findsNothing);

    await type(tester, "zzz");
    expect(rows(), findsNothing);
  });

  testWidgets("pressing an option fills the field and reports it", (tester) async {
    final taken = <String>[];
    await tester.pumpWidget(field(taken: taken));
    await type(tester, "mega");

    await tester.tap(find.text("Megaminx"), kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(taken, ["Megaminx"]);
    expect(rows(), findsNothing, reason: "taking one puts the list away");
    expect(tester.widget<EditableText>(find.byType(EditableText)).controller.text, "Megaminx");
  });

  testWidgets("the arrows move the highlight and Enter takes it", (tester) async {
    final taken = <String>[];
    await tester.pumpWidget(field(taken: taken));
    await type(tester, "3x3");

    bool highlighted(int index) => tester.widget<MochiMenuItem>(rows().at(index)).selected;
    expect(highlighted(0), isTrue, reason: "the first option starts highlighted");

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(highlighted(1), isTrue);
    expect(highlighted(0), isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(highlighted(0), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(taken, ["3x3 OH"]);
  });

  testWidgets("Escape puts the list away, and typing brings it back", (tester) async {
    await tester.pumpWidget(field());
    await type(tester, "3x3");
    expect(rows(), findsNWidgets(3));

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(rows(), findsNothing);

    await type(tester, "3x3 O");
    expect(rows(), findsOneWidget);
  });

  testWidgets("losing focus puts the list away", (tester) async {
    await tester.pumpWidget(field());
    await type(tester, "3x3");
    expect(rows(), findsNWidgets(3));

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(rows(), findsNothing);
  });

  testWidgets("every keystroke is reported, whether or not an option is taken", (tester) async {
    final typed = <String>[];
    await tester.pumpWidget(field(typed: typed));
    await type(tester, "meg");
    expect(typed, ["meg"]);
  });

  testWidgets("options that arrive late still show", (tester) async {
    await tester.pumpWidget(
      field(
        asyncOptions: (text) =>
            Future.delayed(const Duration(milliseconds: 50), () => text.isEmpty ? <String>[] : ["Later"]),
      ),
    );
    await type(tester, "l");
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();
    expect(find.text("Later"), findsOneWidget);
  });

  testWidgets("the list is as wide as the box, and hangs from it rather than from the frame", (tester) async {
    await tester.pumpWidget(field(label: "Move to", description: "Where the solve goes."));
    await type(tester, "3x3");

    final panel = tester.getRect(find.byType(MochiPopoverSurface));
    final box = tester.getRect(find.byType(MochiTextField));
    expect(panel.width, box.width);
    expect(panel.left, box.left);
    expect(panel.top, greaterThanOrEqualTo(box.bottom));
    expect(
      panel.top,
      lessThan(tester.getRect(find.text("Where the solve goes.")).bottom),
      reason: "from the box, not from below the description",
    );
  });
}
