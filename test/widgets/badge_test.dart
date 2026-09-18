import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child, {bool touch = false, MochiStrings? strings}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: touch,
    strings: strings,
    home: Center(child: child),
  );

  ShapeDecoration decorationOf(WidgetTester tester, Finder badge) =>
      tester.widget<Container>(find.descendant(of: badge, matching: find.byType(Container)).first).decoration!
          as ShapeDecoration;

  BorderRadiusGeometry radiusOf(WidgetTester tester, Finder badge) =>
      (decorationOf(tester, badge).shape as RoundedSuperellipseBorder).borderRadius;

  const radius = MochiRadius();

  group("size", () {
    for (final (size, desktop) in [
      (MochiSize.xs, 16.0),
      (MochiSize.sm, 20.0),
      (MochiSize.md, 24.0),
      (MochiSize.lg, 28.0),
    ]) {
      testWidgets("${size.name} is ${desktop.toInt()} tall, four more on touch", (tester) async {
        await tester.pumpWidget(app(MochiBadge(size: size, child: const Text("PB"))));
        expect(tester.getSize(find.byType(MochiBadge)).height, desktop);

        await tester.pumpWidget(app(MochiBadge(size: size, child: const Text("PB")), touch: true));
        await tester.pumpAndSettle();
        expect(tester.getSize(find.byType(MochiBadge)).height, desktop + 4);
      });
    }

    testWidgets("defaults to sm", (tester) async {
      await tester.pumpWidget(app(const MochiBadge(child: Text("PB"))));
      expect(tester.getSize(find.byType(MochiBadge)).height, 20);
    });

    testWidgets("keeps to its content's width rather than filling the parent", (tester) async {
      await tester.pumpWidget(app(const MochiBadge(child: Text("PB"))));
      expect(tester.getSize(find.byType(MochiBadge)).width, lessThan(100));
    });
  });

  group("shape", () {
    testWidgets("a pill is fully round, rounded takes the radius token", (tester) async {
      await tester.pumpWidget(app(const MochiBadge(child: Text("PB"))));
      expect(radiusOf(tester, find.byType(MochiBadge)), radius.full);

      await tester.pumpWidget(app(const MochiBadge(shape: MochiBadgeShape.rounded, child: Text("PB"))));
      expect(radiusOf(tester, find.byType(MochiBadge)), radius.xs);

      await tester.pumpWidget(
        app(const MochiBadge(shape: MochiBadgeShape.rounded, size: MochiSize.lg, child: Text("PB"))),
      );
      await tester.pumpAndSettle();
      expect(radiusOf(tester, find.byType(MochiBadge)), radius.sm);
    });
  });

  group("onDelete", () {
    testWidgets("adds a × that calls it", (tester) async {
      var deleted = 0;
      await tester.pumpWidget(app(MochiBadge(onDelete: () => deleted++, child: const Text("3x3"))));

      expect(find.byType(MochiCloseButton), findsOneWidget);
      await tester.tap(find.byType(MochiCloseButton));
      expect(deleted, 1);
    });

    testWidgets("no × without it", (tester) async {
      await tester.pumpWidget(app(const MochiBadge(child: Text("3x3"))));
      expect(find.byType(MochiCloseButton), findsNothing);
    });

    testWidgets("the × sits concentric with the badge's end", (tester) async {
      await tester.pumpWidget(app(MochiBadge(onDelete: () {}, child: const Text("3x3"))));

      final badge = tester.getRect(find.byType(MochiBadge));
      final close = tester.getRect(find.byType(MochiCloseButton));
      expect(close.height, badge.height - 4);
      expect(badge.right - close.right, 2);
      expect(close.center.dy, badge.center.dy);
    });

    testWidgets("takes the badge's text colour", (tester) async {
      await tester.pumpWidget(
        app(
          MochiBadge(
            intent: MochiIntent.danger,
            appearance: MochiBadgeAppearance.solid,
            onDelete: () {},
            child: const Text("DNF"),
          ),
        ),
      );

      final icon = tester.widget<Icon>(
        find.descendant(of: find.byType(MochiCloseButton), matching: find.byType(Icon)),
      );
      expect(icon.color!.withValues(alpha: 1), MochiColors.light.danger.onBase);
    });

    testWidgets("screen readers hear MochiStrings.remove", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          MochiBadge(onDelete: () {}, child: const Text("3x3")),
          strings: MochiStrings.zhHant,
        ),
      );

      expect(find.bySemanticsLabel("移除"), findsOneWidget);
      handle.dispose();
    });
  });

  group("MochiBadgeGroup", () {
    Widget three({MochiBadgeAppearance appearance = MochiBadgeAppearance.solid}) => app(
      MochiBadgeGroup(
        children: [
          MochiBadge(appearance: appearance, child: const Text("a")),
          MochiBadge(appearance: appearance, intent: MochiIntent.primary, child: const Text("b")),
          MochiBadge(appearance: appearance, intent: MochiIntent.success, child: const Text("c")),
        ],
      ),
    );

    testWidgets("only the outer ends keep their corners", (tester) async {
      await tester.pumpWidget(three());
      final badges = find.byType(MochiBadge);
      const round = Radius.circular(9999);

      expect(
        radiusOf(tester, badges.at(0)),
        const BorderRadiusDirectional.only(topStart: round, bottomStart: round),
      );
      expect(radiusOf(tester, badges.at(1)), BorderRadius.zero);
      expect(
        radiusOf(tester, badges.at(2)),
        const BorderRadiusDirectional.only(topEnd: round, bottomEnd: round),
      );
    });

    testWidgets("neighbours share one border", (tester) async {
      await tester.pumpWidget(three(appearance: MochiBadgeAppearance.outlined));
      final badges = find.byType(MochiBadge);
      final width = MochiGeometry.standard.borderWidth;

      final first = tester.getRect(find.descendant(of: badges.at(0), matching: find.byType(Container)).first);
      final second = tester.getRect(
        find.descendant(of: badges.at(1), matching: find.byType(Container)).first,
      );
      expect(second.left, first.right - width);
    });

    testWidgets("a badge alone in a group is a whole badge", (tester) async {
      await tester.pumpWidget(app(const MochiBadgeGroup(children: [MochiBadge(child: Text("a"))])));
      expect(radiusOf(tester, find.byType(MochiBadge)), radius.full);
    });

    testWidgets("mirrors in right-to-left text", (tester) async {
      await tester.pumpWidget(
        app(
          const Directionality(
            textDirection: TextDirection.rtl,
            child: MochiBadgeGroup(
              children: [
                MochiBadge(appearance: MochiBadgeAppearance.outlined, child: Text("a")),
                MochiBadge(appearance: MochiBadgeAppearance.outlined, child: Text("b")),
              ],
            ),
          ),
        ),
      );
      final badges = find.byType(MochiBadge);
      final width = MochiGeometry.standard.borderWidth;

      final first = tester.getRect(find.descendant(of: badges.at(0), matching: find.byType(Container)).first);
      final second = tester.getRect(
        find.descendant(of: badges.at(1), matching: find.byType(Container)).first,
      );
      expect(second.right, first.left + width);
    });
  });

  test("metrics have value equality", () {
    expect(MochiBadgeMetrics.of(MochiSize.md, touch: true), MochiBadgeMetrics.of(MochiSize.md, touch: true));
    expect(
      MochiBadgeMetrics.of(MochiSize.md, touch: true),
      isNot(MochiBadgeMetrics.of(MochiSize.md, touch: false)),
    );
  });
}
