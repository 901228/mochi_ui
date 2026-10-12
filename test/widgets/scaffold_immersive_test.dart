import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  // A phone's insets: a status bar on top, a home indicator below.
  const insets = EdgeInsets.only(top: 44, bottom: 34);

  // Inside home: a MediaQuery around MochiApp is replaced by the one WidgetsApp installs.
  Widget app(Widget child) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: true,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(padding: insets, viewPadding: insets),
        child: child,
      ),
    ),
  );

  const content = Key("content");
  final header = MochiHeader(variant: MochiHeaderVariant.bordered, title: const Text("Timer"));
  final footer = MochiBottomNav<String>(
    value: "a",
    onChanged: (_) {},
    items: [
      MochiBottomNavItem(value: "a", icon: Icon(MochiIcons.standard.check), label: const Text("Timer")),
      MochiBottomNavItem(value: "b", icon: Icon(MochiIcons.standard.info), label: const Text("Stats")),
    ],
  );
  final sidebar = MochiSidebar(
    children: [
      MochiSidebarItem(icon: Icon(MochiIcons.standard.info), label: const Text("Records"), onPress: () {}),
    ],
  );

  EdgeInsets? seen;
  Widget page({required bool immersive}) => MochiScaffold(
    extendBody: true,
    padding: EdgeInsets.zero,
    immersive: immersive,
    header: header,
    footer: footer,
    sidebar: sidebar,
    child: Builder(
      builder: (context) {
        seen = MediaQuery.paddingOf(context);
        return const _Counter(key: content);
      },
    ),
  );

  Future<void> wide(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets("the bars slide off and the content takes the whole page", (tester) async {
    await wide(tester);
    await tester.pumpWidget(app(page(immersive: false)));
    await tester.pumpAndSettle();
    final full = tester.getRect(find.byType(MochiScaffold));
    expect(tester.getRect(find.byKey(content)).width, lessThan(full.width));
    tester.state<_CounterState>(find.byKey(content)).count = 1;

    await tester.pumpWidget(app(page(immersive: true)));
    await tester.pump(const Duration(milliseconds: 100));
    // Partway: the header is going up and off the page, not just fading.
    expect(tester.getRect(find.byType(MochiHeader)).top, lessThan(full.top));
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byKey(content)), full);
    // Only the system's insets are left to keep clear of.
    expect(seen, insets);
    expect(find.byType(MochiHeader).hitTestable(), findsNothing);
    expect(find.text("Records").hitTestable(), findsNothing);
    // The sidebar leaving does not bring the footer in.
    expect(find.byType(MochiBottomNav<String>).hitTestable(), findsNothing);
    expect(tester.state<_CounterState>(find.byKey(content)).count, 1);

    await tester.pumpWidget(app(page(immersive: false)));
    await tester.pumpAndSettle();
    expect(find.text("Records").hitTestable(), findsOneWidget);
    expect(find.byType(MochiHeader).hitTestable(), findsOneWidget);
    expect(tester.getRect(find.byKey(content)).width, lessThan(full.width));
    expect(tester.state<_CounterState>(find.byKey(content)).count, 1);
  });

  testWidgets("on a phone the footer slides off too", (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(page(immersive: true)));
    await tester.pumpAndSettle();

    final full = tester.getRect(find.byType(MochiScaffold));
    expect(tester.getRect(find.byKey(content)), full);
    expect(seen, insets);
    expect(find.byType(MochiBottomNav<String>).hitTestable(), findsNothing);
  });
}

class _Counter extends StatefulWidget {
  const _Counter({super.key});

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
