import "package:flutter/gestures.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child, {MochiStrings? strings}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: false,
    strings: strings,
    home: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(width: 300, child: child),
    ),
  );

  ShapeDecoration boxOf(WidgetTester tester) =>
      tester
              .widget<DecoratedBox>(
                find.descendant(of: find.byType(MochiTextField), matching: find.byType(DecoratedBox)).first,
              )
              .decoration
          as ShapeDecoration;

  Color borderOf(WidgetTester tester) => (boxOf(tester).shape as RoundedSuperellipseBorder).side.color;

  testWidgets("typing reaches the controller and onChanged", (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final changes = <String>[];
    await tester.pumpWidget(app(MochiTextField(controller: controller, onChanged: changes.add)));

    await tester.enterText(find.byType(EditableText), "3x3 main");
    expect(controller.text, "3x3 main");
    expect(changes.last, "3x3 main");
  });

  testWidgets("keeps its own text from initialValue", (tester) async {
    await tester.pumpWidget(app(const MochiTextField(initialValue: "abc")));
    expect(find.text("abc"), findsOneWidget);
  });

  testWidgets("the hint shows only while it is empty", (tester) async {
    await tester.pumpWidget(app(const MochiTextField(hint: "Session name")));
    expect(find.text("Session name"), findsOneWidget);

    await tester.enterText(find.byType(EditableText), "x");
    await tester.pump();
    expect(find.text("Session name"), findsNothing);
  });

  testWidgets("label above, description below, error in its place", (tester) async {
    await tester.pumpWidget(
      app(const MochiTextField(label: Text("Name"), description: Text("Shown in the list."))),
    );
    expect(find.text("Name"), findsOneWidget);
    expect(find.text("Shown in the list."), findsOneWidget);
    final normal = borderOf(tester);

    await tester.pumpWidget(
      app(
        const MochiTextField(
          label: Text("Name"),
          description: Text("Shown in the list."),
          error: "Required.",
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Required."), findsOneWidget);
    expect(find.text("Shown in the list."), findsNothing);
    expect(borderOf(tester), isNot(normal));
    expect(borderOf(tester), MochiColors.light.danger.base);
  });

  testWidgets("focus turns the border to the primary tone", (tester) async {
    await tester.pumpWidget(app(const MochiTextField()));
    await tester.tap(find.byType(MochiTextField));
    await tester.pumpAndSettle();
    expect(borderOf(tester), MochiColors.light.primary.base);
  });

  testWidgets("a tap on the padding still focuses the field", (tester) async {
    await tester.pumpWidget(app(const MochiTextField()));
    final box = tester.getRect(find.byType(MochiTextField));
    await tester.tapAt(box.centerLeft + const Offset(3, 0));
    await tester.pump();
    expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isTrue);
  });

  testWidgets("clearable: a × while there is text, which empties it", (tester) async {
    final changes = <String>[];
    await tester.pumpWidget(app(MochiTextField(clearable: true, onChanged: changes.add)));
    expect(find.byType(MochiCloseButton), findsNothing);

    await tester.enterText(find.byType(EditableText), "R U R'");
    await tester.pump();
    await tester.tap(find.byType(MochiCloseButton));
    await tester.pump();
    expect(find.text("R U R'"), findsNothing);
    expect(changes.last, "");
    expect(find.byType(MochiCloseButton), findsNothing);
  });

  testWidgets("maxLength stops input and counts", (tester) async {
    await tester.pumpWidget(app(const MochiTextField(maxLength: 5)));
    expect(find.text("0/5"), findsOneWidget);

    await tester.enterText(find.byType(EditableText), "abcdefgh");
    await tester.pump();
    expect(find.text("abcde"), findsOneWidget);
    expect(find.text("5/5"), findsOneWidget);
  });

  testWidgets("disabled can't be focused or typed into", (tester) async {
    await tester.pumpWidget(app(const MochiTextField(initialValue: "fixed", enabled: false)));
    await tester.tap(find.byType(MochiTextField), warnIfMissed: false);
    await tester.pump();
    expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isFalse);
    expect(tester.widget<EditableText>(find.byType(EditableText)).readOnly, isTrue);
  });

  testWidgets("as tall as a button of the same size", (tester) async {
    for (final size in MochiSize.values) {
      await tester.pumpWidget(
        app(
          Row(
            children: [
              Expanded(child: MochiTextField(size: size)),
              MochiButton(size: size, onPress: () {}, child: const Text("Go")),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(MochiTextField)).height,
        tester.getSize(find.byType(MochiButton)).height,
        reason: size.name,
      );
    }
  });

  testWidgets("multiline starts at minLines and grows with its content", (tester) async {
    await tester.pumpWidget(app(const MochiTextField.multiline(minLines: 2)));
    final empty = tester.getSize(find.byType(MochiTextField)).height;

    await tester.enterText(find.byType(EditableText), "1\n2\n3\n4\n5");
    await tester.pump();
    expect(tester.getSize(find.byType(MochiTextField)).height, greaterThan(empty));
  });

  testWidgets("submits on Enter", (tester) async {
    String? submitted;
    await tester.pumpWidget(app(MochiTextField(onSubmitted: (value) => submitted = value)));
    await tester.enterText(find.byType(EditableText), "done");
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(submitted, "done");
  });

  group("context menu", () {
    Future<void> rightClick(WidgetTester tester) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(EditableText)),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets("right click opens Mochi's menu, in the app's words", (tester) async {
      await tester.pumpWidget(
        app(const MochiTextField(initialValue: "3x3 main"), strings: MochiStrings.zhHant),
      );
      await rightClick(tester);

      expect(find.byType(MochiPopoverSurface), findsOneWidget);
      expect(find.text("全選"), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

    testWidgets("choosing an item runs it and puts the menu away", (tester) async {
      final controller = TextEditingController(text: "3x3 main");
      addTearDown(controller.dispose);
      await tester.pumpWidget(app(MochiTextField(controller: controller)));
      await rightClick(tester);

      await tester.tap(find.text("Select all"));
      await tester.pumpAndSettle();
      expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 8));
      expect(find.byType(MochiPopoverSurface), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

    testWidgets("copy puts the selection on the clipboard", (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == "Clipboard.setData") copied = (call.arguments as Map)["text"] as String?;
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final controller = TextEditingController(text: "3x3 main");
      addTearDown(controller.dispose);
      await tester.pumpWidget(app(MochiTextField(controller: controller)));
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 3);
      await tester.pump();
      // A right click moves the caret to where it lands on Linux, so open the menu directly.
      tester.state<EditableTextState>(find.byType(EditableText)).showToolbar();
      await tester.pumpAndSettle();

      await tester.tap(find.text("Copy"));
      await tester.pumpAndSettle();
      expect(copied, isNotNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
  });
}
