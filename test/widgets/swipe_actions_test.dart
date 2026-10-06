import "package:flutter/rendering.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  late List<String> events;

  setUp(() => events = []);

  Widget app(Widget child, {bool touch = true, TextDirection direction = TextDirection.ltr}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: touch,
    home: Directionality(
      textDirection: direction,
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: 300, child: child),
      ),
    ),
  );

  Widget row(String name, {bool fullSwipe = false, bool? enabled}) => MochiSwipeActions(
    fullSwipe: fullSwipe,
    enabled: enabled,
    leading: [MochiAction(icon: TablerIcons.pin, label: "Pin", onPress: () => events.add("pin $name"))],
    trailing: [
      MochiAction(icon: TablerIcons.share, label: "Share", onPress: () => events.add("share $name")),
      MochiAction(
        icon: TablerIcons.trash,
        label: "Delete",
        intent: MochiIntent.danger,
        onPress: () => events.add("delete $name"),
      ),
    ],
    child: SizedBox(
      height: 48,
      child: MochiTile(title: Text(name), onPress: () => events.add("open $name")),
    ),
  );

  Offset rowCenter(WidgetTester tester, String name) =>
      tester.getCenter(find.ancestor(of: find.text(name), matching: find.byType(MochiSwipeActions))) -
      const Offset(60, 0);

  double offsetOf(WidgetTester tester, String name) =>
      tester.getTopLeft(find.text(name)).dx - tester.getTopLeft(find.byType(MochiSwipeActions).first).dx;

  Future<void> drag(WidgetTester tester, String name, double dx) async {
    // In small steps: one long jump would cross the slop and the whole distance in one event.
    // From the row's own middle, which is still on screen once it has slid aside.
    final gesture = await tester.startGesture(rowCenter(tester, name));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(Offset(dx / 10, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets("past half its actions it stays open, short of that it springs back", (tester) async {
    await tester.pumpWidget(app(row("12.34")));
    final rest = offsetOf(tester, "12.34");

    await drag(tester, "12.34", -50);
    expect(offsetOf(tester, "12.34"), rest);

    await drag(tester, "12.34", -100);
    expect(offsetOf(tester, "12.34"), rest - 144);
    expect(find.text("Delete"), findsOneWidget);
  });

  testWidgets("pressing an action runs it and closes the row", (tester) async {
    await tester.pumpWidget(app(row("12.34")));
    final rest = offsetOf(tester, "12.34");
    await drag(tester, "12.34", -100);

    await tester.tap(find.text("Delete"));
    await tester.pumpAndSettle();
    expect(events, ["delete 12.34"]);
    expect(offsetOf(tester, "12.34"), rest);
  });

  testWidgets("pressing an open row closes it and does nothing else", (tester) async {
    await tester.pumpWidget(app(row("12.34")));
    final rest = offsetOf(tester, "12.34");
    await drag(tester, "12.34", -100);

    await tester.tapAt(rowCenter(tester, "12.34"));
    await tester.pumpAndSettle();
    expect(events, isEmpty);
    expect(offsetOf(tester, "12.34"), rest);
  });

  testWidgets("a full swipe runs the outermost action, and only when asked for", (tester) async {
    await tester.pumpWidget(app(row("12.34")));
    await drag(tester, "12.34", -240);
    expect(events, isEmpty);

    await tester.pumpWidget(app(row("12.34", fullSwipe: true)));
    await drag(tester, "12.34", -240);
    expect(events, ["delete 12.34"]);
  });

  testWidgets("opening one row closes the other", (tester) async {
    await tester.pumpWidget(app(Column(children: [row("A"), row("B")])));
    final rest = offsetOf(tester, "A");

    await drag(tester, "A", -100);
    expect(tester.getTopLeft(find.text("A")).dx, lessThan(tester.getTopLeft(find.text("B")).dx));

    await drag(tester, "B", -100);
    expect(
      tester.getTopLeft(find.text("A")).dx - tester.getTopLeft(find.byType(MochiSwipeActions).first).dx,
      rest,
    );
  });

  testWidgets("a mouse has no swipe: on a desktop theme it does not move", (tester) async {
    await tester.pumpWidget(app(row("12.34"), touch: false));
    final rest = offsetOf(tester, "12.34");
    await drag(tester, "12.34", -100);
    expect(offsetOf(tester, "12.34"), rest);
  });

  testWidgets("right to left, trailing actions are revealed by dragging right", (tester) async {
    await tester.pumpWidget(app(row("12.34"), direction: TextDirection.rtl));
    final rest = offsetOf(tester, "12.34");
    await drag(tester, "12.34", 100);
    expect(offsetOf(tester, "12.34"), rest + 144);
    expect(find.text("Delete"), findsOneWidget);
  });

  testWidgets("its actions are offered to a screen reader without a swipe", (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app(row("12.34")));

    final node = tester.getSemantics(find.byType(MochiSwipeActions));
    final delete = node
        .getSemanticsData()
        .customSemanticsActionIds!
        .map(CustomSemanticsAction.getAction)
        .firstWhere((action) => action?.label == "Delete");
    node.owner!.performAction(
      node.id,
      SemanticsAction.customAction,
      CustomSemanticsAction.getIdentifier(delete!),
    );
    expect(events, ["delete 12.34"]);
    handle.dispose();
  });

  testWidgets("past the full-swipe line the outermost action takes all the room, and gives it back", (
    tester,
  ) async {
    await tester.pumpWidget(app(row("12.34", fullSwipe: true)));
    double widthOf(String label) =>
        tester.getSize(find.ancestor(of: find.text(label), matching: find.byType(SizedBox)).first).width;

    final gesture = await tester.startGesture(rowCenter(tester, "12.34"));
    Future<void> move(double dx) async {
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(Offset(dx / 10, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pumpAndSettle();
    }

    // Short of the line: past their own width the extra all goes to Delete, at the edge.
    await move(-185);
    expect(widthOf("Share"), 72);
    expect(widthOf("Delete"), greaterThan(72));

    // Past it: Delete is the whole of what shows, which is what a release would run.
    await move(-40);
    expect(widthOf("Share"), 0);

    // Back short of it: the two share again, and letting go now runs nothing.
    await move(60);
    expect(widthOf("Share"), 72);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(events, isEmpty);
  });
}
