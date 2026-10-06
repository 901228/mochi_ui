import "package:flutter/gestures.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: false,
    home: Align(
      alignment: Alignment.topCenter,
      child: Padding(padding: const EdgeInsets.all(40), child: child),
    ),
  );

  const options = [
    MochiSelectOption(value: "beep", label: "Beep"),
    MochiSelectOption(value: "voice", label: "Voice"),
    MochiSelectOption(value: "off", label: "Nothing at all"),
    MochiSelectOption(value: "gone", label: "Gone", enabled: false),
  ];

  Widget single(List<String> seen, {String? start, bool enabled = true}) {
    var value = start;
    return StatefulBuilder(
      builder: (context, setState) => app(
        SizedBox(
          width: 240,
          child: MochiSelect<String>(
            value: value,
            hint: "Pick one",
            options: options,
            onChanged: enabled
                ? (next) => setState(() {
                    seen.add(next);
                    value = next;
                  })
                : null,
          ),
        ),
      ),
    );
  }

  Widget multi(List<Set<String>> seen, {Set<String> start = const {}}) {
    var values = start;
    return StatefulBuilder(
      builder: (context, setState) => app(
        SizedBox(
          width: 240,
          child: MochiMultiSelect<String>(
            values: values,
            hint: "Pick some",
            options: options,
            onChanged: (next) => setState(() {
              seen.add(next);
              values = next;
            }),
          ),
        ),
      ),
    );
  }

  Finder field() => find.byType(MochiTappable).first;

  Future<void> click(WidgetTester tester, Finder finder) async {
    await tester.tap(finder, kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
  }

  testWidgets("shows the hint, then the chosen option", (tester) async {
    final seen = <String>[];
    await tester.pumpWidget(single(seen));
    expect(find.text("Pick one"), findsOneWidget);

    await click(tester, field());
    expect(find.byType(MochiMenu), findsOneWidget);
    await click(tester, find.text("Voice"));

    expect(seen, ["voice"]);
    expect(find.byType(MochiMenu), findsNothing, reason: "choosing closes the list");
    expect(find.text("Voice"), findsOneWidget);
    expect(find.text("Pick one"), findsNothing);
  });

  testWidgets("the chosen row is ticked, and choosing it again changes nothing", (tester) async {
    final seen = <String>[];
    await tester.pumpWidget(single(seen, start: "beep"));
    await click(tester, field());

    final item = tester.widget<MochiMenuItem>(
      find.ancestor(of: find.text("Beep").last, matching: find.byType(MochiMenuItem)),
    );
    expect(item.selected, isTrue);

    await click(tester, find.text("Beep").last);
    expect(seen, isEmpty);
  });

  testWidgets("a disabled option can't be chosen", (tester) async {
    final seen = <String>[];
    await tester.pumpWidget(single(seen));
    await click(tester, field());
    await tester.tap(find.text("Gone"), kind: PointerDeviceKind.mouse, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(seen, isEmpty);
  });

  testWidgets("the list is at least as wide as the field", (tester) async {
    await tester.pumpWidget(single([]));
    await click(tester, field());
    expect(
      tester.getSize(find.byType(MochiPopoverSurface)).width,
      greaterThanOrEqualTo(tester.getSize(field()).width),
    );
  });

  testWidgets("as tall as a button of the same size", (tester) async {
    for (final size in MochiSize.values) {
      await tester.pumpWidget(
        app(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MochiSelect<String>(value: "beep", size: size, options: options, onChanged: (_) {}),
              MochiButton(size: size, onPress: () {}, child: const Text("Go")),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(MochiSelect<String>)).height,
        tester.getSize(find.byType(MochiButton)).height,
        reason: size.name,
      );
    }
  });

  testWidgets("unbounded, it keeps the width of its longest option", (tester) async {
    Widget row(String value) => app(
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [MochiSelect<String>(value: value, options: options, onChanged: (_) {})],
      ),
    );
    await tester.pumpWidget(row("beep"));
    final narrow = tester.getSize(find.byType(MochiSelect<String>)).width;
    await tester.pumpWidget(row("off"));
    expect(tester.getSize(find.byType(MochiSelect<String>)).width, narrow);
    expect(find.text("Nothing at all"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("unbounded, a multi-select is wide enough for its widest badge", (tester) async {
    await tester.pumpWidget(
      app(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Short labels, where a badge's padding and × outweigh the words: a filter's "none",
            // "plus" and "dnf" each landed on a line of their own and ran off the end.
            MochiMultiSelect<String>(
              values: const {"none", "plus", "dnf"},
              options: const [
                MochiSelectOption(value: "none", label: "none", prefix: Icon(TablerIcons.check)),
                MochiSelectOption(value: "plus", label: "plus", prefix: Icon(TablerIcons.plus)),
                MochiSelectOption(value: "dnf", label: "dnf", prefix: Icon(TablerIcons.x)),
              ],
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final field = tester.getRect(find.byType(MochiMultiSelect<String>));
    final badge = tester.getRect(find.widgetWithText(MochiBadge, "plus"));
    expect(badge.right, lessThanOrEqualTo(field.right));
  });

  testWidgets("as text, the choices are one ellipsized line and the box doesn't grow", (tester) async {
    Widget field(Set<String> values) => app(
      SizedBox(
        width: 160,
        child: MochiMultiSelect<String>(
          values: values,
          display: MochiMultiSelectDisplay.text,
          options: options,
          onChanged: (_) {},
        ),
      ),
    );

    await tester.pumpWidget(field(const {"beep"}));
    final one = tester.getSize(find.byType(MochiMultiSelect<String>)).height;

    await tester.pumpWidget(field(const {"beep", "voice", "off"}));
    expect(find.byType(MochiBadge), findsNothing);
    final text = tester.widget<Text>(find.text("Beep, Voice, Nothing at all"));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.getSize(find.byType(MochiMultiSelect<String>)).height, one);
    expect(tester.takeException(), isNull);
  });

  testWidgets("from the keyboard: arrow down opens on the chosen row, Enter picks", (tester) async {
    final seen = <String>[];
    await tester.pumpWidget(single(seen, start: "voice"));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.byType(MochiMenu), findsOneWidget);
    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(
      (focused.findAncestorWidgetOfExactType<MochiMenuItem>()!.title as Text).data,
      "Voice",
      reason: "the chosen row takes focus",
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(seen, ["off"]);
    expect(find.byType(MochiMenu), findsNothing);
  });

  testWidgets("a click leaves focus on the field, not on a row", (tester) async {
    await tester.pumpWidget(single([], start: "voice"));
    await click(tester, field());
    expect(
      FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<MochiMenuItem>(),
      isNull,
    );
  });

  testWidgets("disabled without onChanged", (tester) async {
    await tester.pumpWidget(single([], enabled: false));
    await tester.tap(field(), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(MochiMenu), findsNothing);
  });

  testWidgets("an error replaces the description and colours the border", (tester) async {
    await tester.pumpWidget(
      app(
        SizedBox(
          width: 240,
          child: MochiSelect<String>(
            value: null,
            options: options,
            description: const Text("How you'll hear it"),
            error: "Pick one",
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text("How you'll hear it"), findsNothing);
    expect(find.text("Pick one"), findsOneWidget);
  });

  group("multi", () {
    testWidgets("rows toggle and the list stays open", (tester) async {
      final seen = <Set<String>>[];
      await tester.pumpWidget(multi(seen));
      expect(find.text("Pick some"), findsOneWidget);

      await click(tester, field());
      await click(tester, find.text("Voice"));
      await click(tester, find.text("Beep").last);
      expect(find.byType(MochiMenu), findsOneWidget);
      expect(seen, [
        {"voice"},
        {"voice", "beep"},
      ]);

      await click(tester, find.text("Voice").last);
      expect(seen.last, {"beep"});
    });

    testWidgets("badges in list order, and a badge's × removes it without opening", (tester) async {
      final seen = <Set<String>>[];
      await tester.pumpWidget(multi(seen, start: {"off", "beep"}));

      final badges = tester.widgetList<MochiBadge>(find.byType(MochiBadge)).toList();
      expect(badges.map((b) => (b.child as Text).data), ["Beep", "Nothing at all"]);

      await click(
        tester,
        find.descendant(of: find.byType(MochiBadge).first, matching: find.byType(MochiCloseButton)),
      );
      expect(seen, [
        {"off"},
      ]);
      expect(find.byType(MochiMenu), findsNothing);
    });

    testWidgets("grows as badges wrap", (tester) async {
      await tester.pumpWidget(multi([], start: {"beep"}));
      final one = tester.getSize(field()).height;
      await tester.pumpWidget(multi([], start: {"beep", "voice", "off"}));
      await tester.pumpAndSettle();
      expect(tester.getSize(field()).height, greaterThan(one));
    });
  });

  group("on a phone", () {
    Widget phone(Widget child) => MochiApp(
      themeMode: MochiThemeMode.light,
      touch: true,
      home: ResponsiveScope(
        size: MochiScreenSize.mobile,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: SizedBox(width: 240, child: child),
          ),
        ),
      ),
    );

    testWidgets("a select opens a sheet, and choosing a row answers and closes it", (tester) async {
      final seen = <String>[];
      String? value;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => phone(
            MochiSelect<String>(
              value: value,
              hint: "Pick one",
              label: const Text("Alert"),
              options: options,
              onChanged: (next) => setState(() {
                seen.add(next);
                value = next;
              }),
            ),
          ),
        ),
      );
      await tester.tap(find.text("Pick one"));
      await tester.pumpAndSettle();
      expect(find.byType(MochiSheet), findsOneWidget);
      expect(find.byType(MochiPopoverSurface), findsNothing);

      await tester.tap(find.text("Voice"));
      await tester.pumpAndSettle();
      expect(seen, ["voice"]);
      expect(find.byType(MochiSheet), findsNothing);
    });

    testWidgets("a multi-select keeps its ticks in a draft until OK", (tester) async {
      final seen = <Set<String>>[];
      var values = <String>{};
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => phone(
            MochiMultiSelect<String>(
              values: values,
              hint: "Pick some",
              options: options,
              onChanged: (next) => setState(() {
                seen.add(next);
                values = next;
              }),
            ),
          ),
        ),
      );

      // Dismissed: the draft goes with it.
      await tester.tap(find.text("Pick some"));
      await tester.pumpAndSettle();
      // The rows run the sheet's width, as a single select's do.
      expect(
        tester.getSize(find.byType(MochiMenu)).width,
        tester.getSize(find.byType(MochiSheet)).width - 2 * MochiTheme.light.geometry.space.md,
      );
      await tester.tap(find.text("Beep"));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(seen, isEmpty);

      // Confirmed: the whole set, once.
      await tester.tap(find.text("Pick some"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Beep"));
      await tester.pump();
      await tester.tap(find.text("Voice"));
      await tester.pumpAndSettle();
      expect(seen, isEmpty);
      await tester.tap(find.text(MochiStrings.standard.ok));
      await tester.pumpAndSettle();
      expect(seen, [
        {"beep", "voice"},
      ]);
      expect(find.byType(MochiSheet), findsNothing);
    });
  });
}
