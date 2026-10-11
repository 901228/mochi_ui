import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child, {MochiScreenSize size = MochiScreenSize.desktop}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: false,
    home: ResponsiveScope(
      size: size,
      child: Align(alignment: Alignment.topLeft, child: child),
    ),
  );

  List<MochiAction> actions(int count, {List<String>? pressed}) => [
    for (var at = 1; at <= count; at++)
      MochiAction(
        icon: MochiIcons.standard.search,
        label: "Action $at",
        onPress: () => pressed?.add("Action $at"),
      ),
  ];

  testWidgets("a row that fits is all buttons and no …", (tester) async {
    await tester.pumpWidget(app(MochiActionBar(actions(4))));

    expect(find.byType(MochiButton), findsNWidgets(4));
    expect(find.byIcon(MochiIcons.standard.more), findsNothing);
  });

  testWidgets("one too many folds the last ones into the …", (tester) async {
    final pressed = <String>[];
    await tester.pumpWidget(app(MochiActionBar(actions(6, pressed: pressed))));

    // Four slots on the desktop scale: three buttons and the … in the last one.
    expect(find.byType(MochiButton), findsNWidgets(4));
    expect(find.byIcon(MochiIcons.standard.more), findsOneWidget);

    await tester.tap(find.byIcon(MochiIcons.standard.more));
    await tester.pumpAndSettle();

    // The ones that did not fit, in the order they were given, and they still work.
    expect(find.text("Action 4"), findsOneWidget);
    expect(find.text("Action 6"), findsOneWidget);
    expect(find.text("Action 3"), findsNothing, reason: "a written-out action is not in the menu too");

    await tester.tap(find.text("Action 5"));
    await tester.pumpAndSettle();
    expect(pressed, ["Action 5"]);
  });

  testWidgets("a phone keeps two slots, a tablet four", (tester) async {
    await tester.pumpWidget(app(MochiActionBar(actions(5)), size: MochiScreenSize.mobile));
    expect(find.byType(MochiButton), findsNWidgets(2), reason: "one action and the …");

    await tester.pumpWidget(app(MochiActionBar(actions(5)), size: MochiScreenSize.tablet));
    await tester.pumpAndSettle();
    expect(find.byType(MochiButton), findsNWidgets(4));
  });

  testWidgets("maxVisible says so itself", (tester) async {
    await tester.pumpWidget(app(MochiActionBar(actions(5), maxVisible: 2)));

    expect(find.byType(MochiButton), findsNWidgets(2));
    expect(find.byIcon(MochiIcons.standard.more), findsOneWidget);
  });

  group("folding from the start", () {
    Widget bar() => MochiActionBar(actions(5), maxVisible: 3, foldFrom: MochiActionFold.start);

    testWidgets("puts the … first and the first ones in it, in order", (tester) async {
      await tester.pumpWidget(app(bar()));

      final buttons = find.byType(MochiButton);
      expect(buttons, findsNWidgets(3));
      expect(
        tester.getCenter(find.byIcon(MochiIcons.standard.more)).dx,
        lessThan(tester.getRect(buttons.at(1)).left),
        reason: "the … is the first slot",
      );

      await tester.tap(find.byIcon(MochiIcons.standard.more));
      await tester.pumpAndSettle();
      for (final label in ["Action 1", "Action 2", "Action 3"]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text("Action 4"), findsNothing, reason: "the last ones stay written out");
      expect(tester.getRect(find.text("Action 1")).top, lessThan(tester.getRect(find.text("Action 3")).top));
    });

    testWidgets("mirrors in right-to-left", (tester) async {
      await tester.pumpWidget(app(Directionality(textDirection: TextDirection.rtl, child: bar())));

      final buttons = find.byType(MochiButton);
      expect(
        tester.getCenter(find.byIcon(MochiIcons.standard.more)).dx,
        greaterThan(tester.getRect(buttons.at(1)).right),
        reason: "the … stands at the right-hand end",
      );
    });

    testWidgets("a header hands it to the group it is asked for", (tester) async {
      await tester.pumpWidget(
        app(
          SizedBox(
            width: 600,
            child: MochiHeader(
              title: const Text("Title"),
              prefixes: actions(5),
              maxVisibleActions: 3,
              prefixFoldFrom: MochiActionFold.start,
            ),
          ),
        ),
      );

      final bar = tester.widget<MochiActionBar>(find.byType(MochiActionBar));
      expect(bar.foldFrom, MochiActionFold.start);
      expect(
        tester.getCenter(find.byIcon(MochiIcons.standard.more)).dx,
        lessThan(tester.getRect(find.byType(MochiButton).at(1)).left),
      );
    });
  });

  testWidgets("an icon action is named by its label, one that shows it writes it out", (tester) async {
    await tester.pumpWidget(
      app(
        MochiActionBar([
          MochiAction(icon: MochiIcons.standard.search, label: "Search", onPress: () {}),
          MochiAction(icon: MochiIcons.standard.check, label: "Done", showLabel: true, onPress: () {}),
          const MochiAction(label: "Words only", showLabel: true, onPress: null),
        ]),
      ),
    );

    // The icon-only one says what it is through its tooltip; the others have said it already.
    final buttons = tester.widgetList<MochiButton>(find.byType(MochiButton)).toList();
    expect(buttons[0].tooltip, "Search");
    expect(find.text("Search"), findsNothing);
    expect(find.text("Done"), findsOneWidget);
    // Null onPress disables it, the same rule as everywhere else.
    expect(buttons[2].enabled, isFalse);
  });

  testWidgets("the built-in actions take their icon and their words from the theme", (tester) async {
    await tester.pumpWidget(
      MochiApp(
        themeMode: MochiThemeMode.light,
        strings: MochiStrings.zhHant,
        home: MochiActionBar([MochiAction.back(onPress: () {}), MochiAction.close(onPress: () {})]),
      ),
    );

    final buttons = tester.widgetList<MochiButton>(find.byType(MochiButton)).toList();
    expect(buttons.map((button) => button.tooltip), ["返回", "關閉"]);
    expect(find.byIcon(MochiIcons.standard.back), findsOneWidget);
    expect(find.byIcon(MochiIcons.standard.close), findsOneWidget);
  });

  testWidgets("a bar can be told not to grow, for one tucked inside something else", (tester) async {
    await tester.pumpWidget(app(MochiActionBar(actions(2), scaleOnPress: false)));

    final buttons = tester.widgetList<MochiButton>(find.byType(MochiButton));
    expect(buttons.every((button) => !button.scaleOnPress), isTrue);

    await tester.pumpWidget(app(MochiActionBar(actions(2))));
    expect(tester.widgetList<MochiButton>(find.byType(MochiButton)).every((b) => b.scaleOnPress), isTrue);
  });

  testWidgets("a press in the bar's own gaps belongs to the bar", (tester) async {
    final pressed = <String>[];

    await tester.pumpWidget(
      MochiApp(
        themeMode: MochiThemeMode.light,
        touch: false,
        home: Center(
          child: SizedBox(
            width: 400,
            child: MochiSearchBar(suffix: MochiActionBar(actions(2, pressed: pressed))),
          ),
        ),
      ),
    );

    final first = tester.getRect(find.byType(MochiButton).first);
    final second = tester.getRect(find.byType(MochiButton).last);
    final field = tester.widget<EditableText>(find.byType(EditableText));

    // The gap between the two buttons is inside the search field's box, whose gesture detector
    // covers the whole of it so a press on the padding puts the caret in the text. A press aimed
    // at a button that landed a pixel wide of one is not that.
    await tester.tapAt(Offset((first.right + second.left) / 2, first.center.dy));
    await tester.pumpAndSettle();
    expect(field.focusNode.hasFocus, isFalse);
    expect(pressed, isEmpty);

    // The buttons themselves still answer, and the text still takes a press of its own.
    await tester.tap(find.byType(MochiButton).first);
    await tester.pumpAndSettle();
    expect(pressed, ["Action 1"]);

    await tester.tapAt(Offset(first.left - 60, first.center.dy));
    await tester.pumpAndSettle();
    expect(field.focusNode.hasFocus, isTrue);
  });

  testWidgets("a dense bar does not make the line it sits in any taller", (tester) async {
    Future<double> title(Widget? suffix) async {
      await tester.pumpWidget(
        MochiApp(
          themeMode: MochiThemeMode.light,
          touch: false,
          home: Center(
            child: SizedBox(
              width: 300,
              child: MochiCard(title: const Text("Records"), titleSuffix: suffix, child: const Text("Body")),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      return tester.getRect(find.text("Body")).top - tester.getRect(find.text("Records")).top;
    }

    final plain = await title(null);
    // A card's title row asks for xs and has the room for it, so a bar that takes the row's word
    // costs nothing; one told to be bigger pushes the body down, and a dense one never does
    // whatever it is told.
    expect(await title(MochiActionBar(actions(1))), plain);
    expect(await title(MochiActionBar(actions(1), size: MochiSize.md)), greaterThan(plain));
    expect(await title(MochiActionBar(actions(1), size: MochiSize.md, dense: true)), plain);
  });

  group("a menu action", () {
    MochiAction sort(List<String> pressed) => MochiAction.menu(
      icon: MochiIcons.standard.check,
      label: "Sort",
      children: [
        MochiAction(icon: MochiIcons.standard.search, label: "By name", onPress: () => pressed.add("name")),
        MochiAction(icon: MochiIcons.standard.search, label: "By date", onPress: () => pressed.add("date")),
      ],
    );

    testWidgets("is a button that opens its rows, and choosing one puts them away", (tester) async {
      final pressed = <String>[];
      await tester.pumpWidget(app(MochiActionBar([sort(pressed)])));

      expect(find.text("By name"), findsNothing);
      await tester.tap(find.byIcon(MochiIcons.standard.check));
      await tester.pumpAndSettle();
      expect(find.text("By date"), findsOneWidget);

      await tester.tap(find.text("By date"));
      await tester.pumpAndSettle();
      expect(pressed, ["date"]);
      expect(find.text("By date"), findsNothing);
    });

    testWidgets("folded into the … it becomes a submenu", (tester) async {
      final pressed = <String>[];
      await tester.pumpWidget(app(MochiActionBar([...actions(1), sort(pressed)], maxVisible: 1)));

      await tester.tap(find.byIcon(MochiIcons.standard.more));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Sort"));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text("By name")).dx,
        greaterThan(tester.getTopRight(find.text("Sort")).dx),
        reason: "beside its row, not in place of it",
      );

      await tester.tap(find.text("By name"));
      await tester.pumpAndSettle();
      expect(pressed, ["name"]);
      expect(find.text("Sort"), findsNothing, reason: "the whole menu closes, not only the submenu");
    });

    testWidgets("with no rows it is disabled, having nothing to open", (tester) async {
      await tester.pumpWidget(
        app(
          MochiActionBar([
            MochiAction.menu(icon: MochiIcons.standard.check, label: "Sort", children: const []),
          ]),
        ),
      );

      expect(tester.widget<MochiButton>(find.byType(MochiButton)).enabled, isFalse);
    });
  });
}
