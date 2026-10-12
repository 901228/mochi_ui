import "package:flutter/gestures.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child, {MochiScreenSize size = MochiScreenSize.mobile, bool animate = true}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: true,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: !animate),
        child: ResponsiveScope(size: size, child: child),
      ),
    ),
  );

  final footer = MochiBottomNav<String>(
    value: "a",
    onChanged: (_) {},
    items: [
      MochiBottomNavItem(value: "a", icon: Icon(MochiIcons.standard.check), label: const Text("Timer")),
      MochiBottomNavItem(value: "b", icon: Icon(MochiIcons.standard.info), label: const Text("Stats")),
    ],
  );
  const sidebar = SizedBox(width: 200, child: Text("sidebar"));
  const drawer = Text("drawer");

  Widget scaffold({Widget? child, Widget? header}) => MochiScaffold(
    header: header ?? const MochiHeader(title: Text("Home")),
    sidebar: sidebar,
    drawer: drawer,
    footer: footer,
    child: child ?? const Text("page"),
  );

  bool showing(WidgetTester tester, String text) => find.text(text).hitTestable().evaluate().isNotEmpty;

  testWidgets("a phone gets the footer and a drawer; a tablet gets the sidebar", (tester) async {
    await tester.pumpWidget(app(scaffold()));
    await tester.pumpAndSettle();
    expect(showing(tester, "Timer"), isTrue);
    expect(showing(tester, "sidebar"), isFalse);
    expect(find.byIcon(MochiIcons.standard.menu), findsOneWidget);

    await tester.pumpWidget(app(scaffold(), size: MochiScreenSize.tablet));
    await tester.pumpAndSettle();
    expect(showing(tester, "sidebar"), isTrue);
    expect(showing(tester, "Timer"), isFalse);
    // No drawer to open beside a sidebar, so no button for one.
    expect(find.byIcon(MochiIcons.standard.menu), findsNothing);
  });

  testWidgets("crossing the breakpoint slides one in as the other goes, and the page keeps its state", (
    tester,
  ) async {
    final controller = TextEditingController(text: "half typed");
    addTearDown(controller.dispose);
    final page = MochiTextField(controller: controller);

    await tester.pumpWidget(app(scaffold(child: page)));
    await tester.pumpAndSettle();
    final field = tester.state(find.byType(EditableText));

    await tester.pumpWidget(app(scaffold(child: page), size: MochiScreenSize.tablet));
    await tester.pump(const Duration(milliseconds: 60));
    // Mid-way: the sidebar part of the way in from off the edge, the page not yet all the way over.
    final side = tester.getRect(find.text("sidebar"));
    expect(side.left, lessThan(0));
    expect(side.right, greaterThan(0));

    await tester.pumpAndSettle();
    expect(tester.getRect(find.text("sidebar")).left, 0);
    expect(tester.getRect(find.byType(MochiTextField)).left, greaterThanOrEqualTo(200));
    // The same field, not a new one: nothing above it changed shape.
    expect(tester.state(find.byType(EditableText)), same(field));
    expect(controller.text, "half typed");
  });

  testWidgets("with animations off it changes at once", (tester) async {
    await tester.pumpWidget(app(scaffold(), animate: false));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app(scaffold(), size: MochiScreenSize.tablet, animate: false));
    await tester.pump();
    expect(tester.getRect(find.text("sidebar")).left, 0);
  });

  testWidgets("the header's button opens the drawer, and the page behind closes it", (tester) async {
    await tester.pumpWidget(app(scaffold()));
    await tester.pumpAndSettle();
    expect(showing(tester, "drawer"), isFalse);

    await tester.tap(find.byIcon(MochiIcons.standard.menu));
    await tester.pumpAndSettle();
    expect(showing(tester, "drawer"), isTrue);
    expect(MochiScaffold.of(tester.element(find.text("page"))).isDrawerOpen, isTrue);

    await tester.tapAt(const Offset(780, 300));
    await tester.pumpAndSettle();
    expect(showing(tester, "drawer"), isFalse);
  });

  testWidgets("of(context) opens and closes it, and does nothing where there is none", (tester) async {
    await tester.pumpWidget(app(scaffold()));
    await tester.pumpAndSettle();
    final state = MochiScaffold.of(tester.element(find.text("page")));

    state.openDrawer();
    await tester.pumpAndSettle();
    expect(showing(tester, "drawer"), isTrue);
    state.closeDrawer();
    await tester.pumpAndSettle();
    expect(showing(tester, "drawer"), isFalse);

    await tester.pumpWidget(app(scaffold(), size: MochiScreenSize.tablet));
    await tester.pumpAndSettle();
    expect(state.hasDrawer, isFalse);
    state.openDrawer();
    await tester.pumpAndSettle();
    expect(showing(tester, "drawer"), isFalse);
  });

  testWidgets("a header given its own prefixes keeps them", (tester) async {
    await tester.pumpWidget(
      app(
        scaffold(
          header: MochiHeader(
            title: const Text("Home"),
            prefixes: [MochiAction.close(onPress: () {})],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(MochiIcons.standard.menu), findsNothing);
    expect(find.byIcon(MochiIcons.standard.close), findsOneWidget);
  });

  testWidgets("a drag from the leading edge pulls the drawer out on a root page", (tester) async {
    await tester.pumpWidget(app(scaffold()));
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(const Offset(4, 300), kind: PointerDeviceKind.touch);
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(showing(tester, "drawer"), isTrue);
  });

  testWidgets("the first page's route leaves its edge to the drawer", (tester) async {
    // As a router builds a home page on iOS: a sliding MochiPageRoute, with nothing under it to go back to.
    await tester.pumpWidget(
      app(
        Navigator(
          onGenerateRoute: (_) =>
              MochiPageRoute<void>(transition: MochiTransition.slide, builder: (_) => scaffold()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(const Offset(4, 300), kind: PointerDeviceKind.touch);
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(showing(tester, "drawer"), isTrue);
  });

  testWidgets("on a pushed page the edge is the back drag's, not the drawer's", (tester) async {
    await tester.pumpWidget(app(const Text("root")));
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(MochiPageRoute<void>(builder: (_) => scaffold()));
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(const Offset(4, 300), kind: PointerDeviceKind.touch);
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(showing(tester, "drawer"), isFalse);
  });

  testWidgets("a sidebar in the drawer fills under the system's insets, and its rows stay clear", (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(padding: const EdgeInsets.only(top: 40, bottom: 30)),
            child: MochiScaffold(
              header: const MochiHeader(title: Text("Home")),
              drawer: MochiSidebar(
                children: [
                  MochiSidebarItem(
                    icon: Icon(MochiIcons.standard.check),
                    label: const Text("row"),
                    onPress: () {},
                  ),
                ],
              ),
              child: const Text("page"),
            ),
          ),
        ),
      ),
    );
    MochiScaffold.of(tester.element(find.text("page"))).openDrawer();
    await tester.pumpAndSettle();

    final screen = tester.getSize(find.byType(MochiScaffold));
    final sidebar = tester.getRect(find.byType(MochiSidebar));
    expect(sidebar.top, 0);
    expect(sidebar.bottom, screen.height);
    expect(tester.getRect(find.text("row")).top, greaterThanOrEqualTo(40));
  });

  testWidgets("hidden parts take no focus", (tester) async {
    await tester.pumpWidget(app(scaffold()));
    await tester.pumpAndSettle();
    // The sidebar is on the tree on a phone, but nothing in it can be reached with Tab.
    final hidden = find
        .ancestor(
          of: find.text("sidebar", skipOffstage: false),
          matching: find.byType(ExcludeFocus, skipOffstage: false),
        )
        .first;
    expect(tester.widget<ExcludeFocus>(hidden).excluding, isTrue);
  });
}
