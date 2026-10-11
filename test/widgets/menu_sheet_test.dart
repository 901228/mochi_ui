import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  late List<String> events;

  setUp(() => events = []);

  Widget app(Widget child, {MochiScreenSize size = MochiScreenSize.mobile}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: true,
    home: ResponsiveScope(
      size: size,
      child: Center(child: child),
    ),
  );

  List<Widget> items(BuildContext context) => [
    MochiMenuItem(title: const Text("Rename"), onPress: () => events.add("rename")),
    MochiSubmenu(
      title: const Text("Move to"),
      menuBuilder: (context) => [
        MochiMenuItem(title: const Text("Session 2"), onPress: () => events.add("session 2")),
      ],
    ),
  ];

  Widget dropdown({bool? sheet}) => MochiPopoverMenu(
    sheet: sheet,
    menuBuilder: items,
    builder: (context, anchor, _) =>
        MochiButton(focusNode: anchor.focusNode, onPress: anchor.toggle, child: const Text("More")),
  );

  testWidgets("on a phone a dropdown comes up in a sheet, and a row closes it", (tester) async {
    await tester.pumpWidget(app(dropdown()));
    await tester.tap(find.text("More"));
    await tester.pumpAndSettle();
    expect(find.byType(MochiSheet), findsOneWidget);
    expect(find.byType(MochiPopoverSurface), findsNothing);

    await tester.tap(find.text("Rename"));
    await tester.pumpAndSettle();
    expect(events, ["rename"]);
    expect(find.byType(MochiSheet), findsNothing);
  });

  testWidgets("a submenu in a sheet opens in place, and its row closes the whole sheet", (tester) async {
    await tester.pumpWidget(app(dropdown()));
    await tester.tap(find.text("More"));
    await tester.pumpAndSettle();
    expect(find.text("Session 2"), findsNothing);

    await tester.tap(find.text("Move to"));
    await tester.pumpAndSettle();
    // Under its row, in the same sheet: no second panel, no second sheet.
    expect(find.byType(MochiSheet), findsOneWidget);
    expect(find.byType(MochiPopoverSurface), findsNothing);
    expect(
      tester.getTopLeft(find.text("Session 2")).dy,
      greaterThan(tester.getTopLeft(find.text("Move to")).dy),
    );

    await tester.tap(find.text("Session 2"));
    await tester.pumpAndSettle();
    expect(events, ["session 2"]);
    expect(find.byType(MochiSheet), findsNothing);
  });

  testWidgets("a long press on a phone opens the context menu in a sheet", (tester) async {
    await tester.pumpWidget(
      app(
        MochiContextMenu(
          menuBuilder: items,
          child: const SizedBox(width: 200, height: 80, child: Text("Solve 12")),
        ),
      ),
    );
    await tester.longPress(find.text("Solve 12"));
    await tester.pumpAndSettle();
    expect(find.byType(MochiSheet), findsOneWidget);
  });

  testWidgets("from tablet width up, and when told not to, it stays a panel", (tester) async {
    await tester.pumpWidget(app(dropdown(), size: MochiScreenSize.tablet));
    await tester.tap(find.text("More"));
    await tester.pumpAndSettle();
    expect(find.byType(MochiPopoverSurface), findsOneWidget);
    expect(find.byType(MochiSheet), findsNothing);

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app(dropdown(sheet: false)));
    await tester.tap(find.text("More"));
    await tester.pumpAndSettle();
    expect(find.byType(MochiPopoverSurface), findsOneWidget);
    expect(find.byType(MochiSheet), findsNothing);
  });

  testWidgets("a menubar stays a row of panels on a phone", (tester) async {
    await tester.pumpWidget(
      app(
        MochiMenubar(
          menus: [MochiMenubarMenu(title: const Text("File"), menuBuilder: items)],
        ),
      ),
    );
    await tester.tap(find.text("File"));
    await tester.pumpAndSettle();
    expect(find.byType(MochiPopoverSurface), findsOneWidget);
    expect(find.byType(MochiSheet), findsNothing);
  });
}
