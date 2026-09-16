import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child, {bool touch = false}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: touch,
    home: Center(child: SizedBox(width: 320, child: child)),
  );

  Color background(WidgetTester tester) => tester
      .widget<ColoredBox>(find.descendant(of: find.byType(MochiTile), matching: find.byType(ColoredBox)))
      .color;

  testWidgets("leading dividers clear the prefix column for every row in the group", (tester) async {
    Future<List<double>> lefts(List<Widget> children) async {
      await tester.pumpWidget(app(MochiTileGroup(children: children)));
      return [
        for (var i = 0; i < children.length - 1; i++)
          tester
              .getRect(
                find.descendant(of: find.byType(MochiDivider).at(i), matching: find.byType(ColoredBox)),
              )
              .left,
      ];
    }

    // Mixed rows: every line starts at the same place, past the prefix column.
    final mixed = await lefts(const [
      MochiTile(title: Text("A")),
      MochiTile(prefix: Icon(IconData(0x41)), title: Text("B")),
      MochiTile(title: Text("C")),
    ]);
    expect(mixed.first, mixed.last);

    // A group with no prefixes only clears the padding, so its lines start further left.
    final plain = await lefts(const [MochiTile(title: Text("A")), MochiTile(title: Text("B"))]);
    expect(plain.first, lessThan(mixed.first));
  });

  testWidgets("renders title, subtitle, details and both ends", (tester) async {
    await tester.pumpWidget(
      app(
        const MochiTile(
          prefix: Icon(IconData(0x41)),
          title: Text("Inspection"),
          subtitle: Text("Default 15 seconds"),
          details: Text("15s"),
          suffix: Icon(IconData(0x42)),
        ),
      ),
    );

    expect(find.text("Inspection"), findsOneWidget);
    expect(find.text("Default 15 seconds"), findsOneWidget);
    expect(find.text("15s"), findsOneWidget);
    expect(find.byType(Icon), findsNWidgets(2));
  });

  testWidgets("selected takes the intent's soft color, plain rows the surface", (tester) async {
    await tester.pumpWidget(app(const MochiTile(title: Text("Row"))));
    await tester.pumpAndSettle();
    expect(background(tester), MochiColors.light.surface);

    await tester.pumpWidget(app(const MochiTile(title: Text("Row"), selected: true)));
    await tester.pumpAndSettle();
    // Mixed over the group's surface rather than the page, so it stays visible on a card.
    expect(
      background(tester),
      MochiColors.light.softOn(MochiColors.light.primary, MochiColors.light.surface),
    );
  });

  testWidgets("press and disabled", (tester) async {
    var presses = 0;
    await tester.pumpWidget(app(MochiTile(title: const Text("Row"), onPress: () => presses++)));
    await tester.tap(find.byType(MochiTile));
    expect(presses, 1);

    await tester.pumpWidget(
      app(MochiTile(title: const Text("Row"), enabled: false, onPress: () => presses++)),
    );
    await tester.tap(find.byType(MochiTile));
    await tester.pumpAndSettle();
    expect(presses, 1);
    expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 0.4);
  });

  testWidgets("touch rows are taller", (tester) async {
    await tester.pumpWidget(app(const MochiTile(title: Text("Row"))));
    final desktop = tester.getSize(find.byType(MochiTile)).height;

    await tester.pumpWidget(app(const MochiTile(title: Text("Row")), touch: true));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MochiTile)).height, greaterThan(desktop));
  });

  group("group", () {
    testWidgets("divider variants", (tester) async {
      Widget group(MochiTileDivider divider) => app(
        MochiTileGroup(
          divider: divider,
          children: const [
            MochiTile(title: Text("A")),
            MochiTile(title: Text("B")),
          ],
        ),
      );

      await tester.pumpWidget(group(MochiTileDivider.none));
      expect(find.byType(MochiDivider), findsNothing);

      await tester.pumpWidget(group(MochiTileDivider.indented));
      final indented = tester.getRect(
        find.descendant(of: find.byType(MochiDivider), matching: find.byType(ColoredBox)),
      );
      final box = tester.getRect(find.byType(MochiTileGroup));
      expect(indented.left, greaterThan(box.left));
      expect(indented.right, lessThan(box.right));

      await tester.pumpWidget(group(MochiTileDivider.full));
      final groupRect = tester.getRect(find.byType(MochiTileGroup));
      final line = tester.getRect(find.byType(MochiDivider));
      expect(line.width, moreOrLessEquals(groupRect.width, epsilon: 2));
    });

    testWidgets("puts a divider between rows but not around them", (tester) async {
      await tester.pumpWidget(
        app(
          const MochiTileGroup(
            label: Text("Timer"),
            description: Text("Applies to new solves"),
            children: [
              MochiTile(title: Text("A")),
              MochiTile(title: Text("B")),
              MochiTile(title: Text("C")),
            ],
          ),
        ),
      );

      expect(find.byType(MochiDivider), findsNWidgets(2));
      // Leading by default: the line starts past the padding and runs to the group's edge.
      final group = tester.getRect(find.byType(MochiTileGroup));
      final line = tester.getRect(
        find.descendant(of: find.byType(MochiDivider).first, matching: find.byType(ColoredBox)),
      );
      expect(line.left, greaterThan(group.left));
      expect(line.right, moreOrLessEquals(group.right, epsilon: 1));
      expect(find.text("Timer"), findsOneWidget);
      expect(find.text("Applies to new solves"), findsOneWidget);
    });
  });
}
