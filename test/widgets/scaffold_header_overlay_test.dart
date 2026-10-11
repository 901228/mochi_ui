import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(
    Widget child, {
    MochiScreenSize size = MochiScreenSize.tablet,
    TextDirection direction = TextDirection.ltr,
    bool animate = true,
  }) => MochiApp(
    themeMode: MochiThemeMode.light,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: !animate),
        child: Directionality(
          textDirection: direction,
          child: ResponsiveScope(size: size, child: child),
        ),
      ),
    ),
  );

  const overlayKey = Key("overlay");

  Widget scaffold({
    double sidebarWidth = 200,
    Widget? overlay,
    bool shown = true,
    VoidCallback? onBodyPress,
  }) => MochiScaffold(
    header: const MochiHeader(title: Text("Home")),
    sidebar: SizedBox(width: sidebarWidth, child: const Text("sidebar")),
    drawer: const Text("drawer"),
    headerOverlay: shown ? overlay ?? const SizedBox(key: overlayKey, child: Text("overlay")) : null,
    child: Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(onTap: onBodyPress, child: const Text("body")),
    ),
  );

  testWidgets("spans the content beside the sidebar, at least as tall as the header", (tester) async {
    await tester.pumpWidget(app(scaffold()));
    await tester.pumpAndSettle();
    final overlay = tester.getRect(find.byKey(overlayKey));
    final header = tester.getRect(find.byType(MochiHeader));
    expect(overlay, header);
    expect(overlay.left, 200);
  });

  testWidgets("follows the sidebar down to a rail and out of sight", (tester) async {
    await tester.pumpWidget(app(scaffold(sidebarWidth: 64)));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(overlayKey)).left, 64);

    await tester.pumpWidget(app(scaffold(sidebarWidth: 64), size: MochiScreenSize.mobile));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(overlayKey)).left, 0);
    expect(tester.getRect(find.byKey(overlayKey)).width, 800);
  });

  testWidgets("sits on the sidebar's far side in right-to-left", (tester) async {
    await tester.pumpWidget(app(scaffold(), direction: TextDirection.rtl));
    await tester.pumpAndSettle();
    final overlay = tester.getRect(find.byKey(overlayKey));
    expect(overlay.left, 0);
    expect(overlay.right, 600);
  });

  testWidgets("grows past the header when its content is taller", (tester) async {
    await tester.pumpWidget(app(scaffold(overlay: const SizedBox(key: overlayKey, height: 300))));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(overlayKey)).height, 300);
  });

  testWidgets("covers the header, and the drawer covers it", (tester) async {
    await tester.pumpWidget(
      app(
        scaffold(
          overlay: const ColoredBox(key: overlayKey, color: Color(0xFF000000)),
        ),
        size: MochiScreenSize.mobile,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Home").hitTestable(), findsNothing);
    expect(find.byKey(overlayKey).hitTestable(), findsOneWidget);

    tester.state<MochiScaffoldState>(find.byType(MochiScaffold)).openDrawer();
    await tester.pumpAndSettle();
    expect(find.text("drawer").hitTestable(), findsOneWidget);
    expect(find.byKey(overlayKey).hitTestable(), findsNothing);
  });

  testWidgets("presses outside its box reach the page", (tester) async {
    var pressed = 0;
    await tester.pumpWidget(app(scaffold(onBodyPress: () => pressed++)));
    await tester.pumpAndSettle();
    await tester.tap(find.text("body"));
    expect(pressed, 1);
  });

  testWidgets("slides in, and out again before it goes", (tester) async {
    await tester.pumpWidget(app(scaffold(shown: false)));
    await tester.pumpAndSettle();
    expect(find.byKey(overlayKey), findsNothing);

    await tester.pumpWidget(app(scaffold()));
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getRect(find.byKey(overlayKey)).left, lessThan(200));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(overlayKey)).left, 200);

    await tester.pumpWidget(app(scaffold(shown: false)));
    await tester.pump(const Duration(milliseconds: 30));
    // Still drawn on its way out, but nothing to press.
    expect(tester.getRect(find.byKey(overlayKey)).left, lessThan(200));
    expect(find.byKey(overlayKey).hitTestable(), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byKey(overlayKey), findsNothing);
  });

  testWidgets("comes in from the right in right-to-left", (tester) async {
    await tester.pumpWidget(app(scaffold(shown: false), direction: TextDirection.rtl));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app(scaffold(), direction: TextDirection.rtl));
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getRect(find.byKey(overlayKey)).left, greaterThan(0));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(overlayKey)).left, 0);
  });

  testWidgets("with animations off it comes and goes at once", (tester) async {
    await tester.pumpWidget(app(scaffold(shown: false), animate: false));
    await tester.pumpWidget(app(scaffold(), animate: false));
    await tester.pump();
    expect(tester.getRect(find.byKey(overlayKey)).left, 200);
    await tester.pumpWidget(app(scaffold(shown: false), animate: false));
    await tester.pump();
    expect(find.byKey(overlayKey), findsNothing);
  });

  testWidgets("a press on it while it arrives reaches neither it nor the header", (tester) async {
    var overlayPresses = 0;
    var headerPresses = 0;
    Widget page({required bool shown}) => MochiScaffold(
      header: GestureDetector(onTap: () => headerPresses++, child: const SizedBox(height: 56)),
      headerOverlay: shown
          ? GestureDetector(
              key: overlayKey,
              onTap: () => overlayPresses++,
              child: const ColoredBox(color: Color(0xFF000000), child: SizedBox(height: 56)),
            )
          : null,
      child: const SizedBox(),
    );

    await tester.pumpWidget(app(page(shown: false), size: MochiScreenSize.mobile));
    await tester.pumpWidget(app(page(shown: true), size: MochiScreenSize.mobile));
    await tester.pump(const Duration(milliseconds: 60));
    final rect = tester.getRect(find.byKey(overlayKey));
    expect(rect.left, lessThan(0));
    await tester.tapAt(Offset(rect.right - 10, 20));
    expect(overlayPresses, 0);
    expect(headerPresses, 0);

    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(100, 20));
    expect(overlayPresses, 1);
    expect(headerPresses, 0);
  });

  testWidgets("leaves by the screen's edge rather than stopping at the sidebar's", (tester) async {
    await tester.pumpWidget(app(scaffold()));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app(scaffold(shown: false)));
    var right = double.infinity;
    while (find.byKey(overlayKey).evaluate().isNotEmpty) {
      right = tester.getRect(find.byKey(overlayKey)).right;
      await tester.pump(const Duration(milliseconds: 8));
    }
    // Drawn over the sidebar, so the last frame it shows in must already be nearly off screen.
    expect(right, lessThan(50));
  });
}
