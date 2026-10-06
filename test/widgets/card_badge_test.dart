import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  // The tests run on a touch platform, where layering is tonal; these are about the outlined look.
  Widget app(Widget child) => MochiApp(
    themeMode: MochiThemeMode.light,
    lightTheme: MochiTheme.light.copyWith(defaults: const MochiDefaults(layering: .outlined)),
    home: Center(child: child),
  );

  ShapeDecoration decoration(WidgetTester tester, Type of) =>
      tester
              .widget<DecoratedBox>(
                find.descendant(of: find.byType(of), matching: find.byType(DecoratedBox)).first,
              )
              .decoration
          as ShapeDecoration;

  group("card", () {
    testWidgets("the clip is the card's own outline, not the content's", (tester) async {
      await tester.pumpWidget(
        app(
          const MochiCard(
            padding: EdgeInsets.all(10),
            child: SizedBox(
              width: 200,
              height: 80,
              child: Align(alignment: Alignment.topLeft, child: Text("9 / 28")),
            ),
          ),
        ),
      );

      final card = tester.getRect(find.byType(MochiCard));
      final clip = tester.getRect(
        find.descendant(of: find.byType(MochiCard), matching: find.byType(ClipRSuperellipse)).first,
      );

      // Inside the padding, the clip would round the *content's* corners by the card's radius and
      // bite a piece out of anything in one of them — a date in the top left corner, say.
      expect(clip, card);
      expect(tester.getRect(find.text("9 / 28")).left - card.left, greaterThanOrEqualTo(10));
    });

    testWidgets("a chosen card wears the intent, the way a chosen radio card does", (tester) async {
      await tester.pumpWidget(app(const MochiCard(child: Text("Body"))));
      final plain = decoration(tester, MochiCard);

      await tester.pumpWidget(
        app(const MochiCard(selected: true, intent: MochiIntent.primary, child: Text("Body"))),
      );
      await tester.pumpAndSettle();
      final chosen = decoration(tester, MochiCard);

      final tone = MochiColors.light.of(MochiIntent.primary);
      expect((chosen.shape as RoundedSuperellipseBorder).side.color, tone.base);
      expect((plain.shape as RoundedSuperellipseBorder).side.color, MochiColors.light.border);
      // Tinted over the card's own ground, not the page's: the same fill a chosen radio card takes.
      expect(chosen.color, MochiColors.light.softOn(tone, MochiColors.light.surface));
    });

    testWidgets("a title is a heading in the title typeface, with its own two ends", (tester) async {
      await tester.pumpWidget(
        app(
          MochiCard(
            title: const Text("Session"),
            titlePrefix: Icon(MochiIcons.standard.search),
            titleSuffix: const Text("12"),
            child: const Text("Body"),
          ),
        ),
      );

      final style = tester.widget<DefaultTextStyle>(
        find.ancestor(of: find.text("Session"), matching: find.byType(DefaultTextStyle)).first,
      );
      // The title typeface, not body at a heavier weight — the rule the whole kit follows.
      expect(
        style.style.fontVariations?.first.value,
        MochiTypography.standard.title.sm.fontVariations?.first.value,
      );

      final title = tester.getRect(find.text("Session"));
      expect(tester.getRect(find.byIcon(MochiIcons.standard.search)).right, lessThanOrEqualTo(title.left));
      expect(tester.getRect(find.text("12")).left, greaterThanOrEqualTo(title.right));
      expect(tester.getRect(find.text("Body")).top, greaterThan(title.bottom));
    });

    testWidgets("titleGap sets the room between the title's line and the content", (tester) async {
      // The title's line is a ConstrainedBox at least an xs button tall; the gap is measured from it.
      Future<double> gap(double? titleGap) async {
        await tester.pumpWidget(
          app(MochiCard(title: const Text("Session"), titleGap: titleGap, child: const Text("Body"))),
        );
        final line = find.ancestor(of: find.text("Session"), matching: find.byType(ConstrainedBox)).first;
        return tester.getRect(find.text("Body")).top - tester.getRect(line).bottom;
      }

      expect(await gap(null), MochiGeometry.standard.space.sm);
      expect(await gap(0), 0);
      expect(await gap(20), 20);
    });

    testWidgets("the title row is a button tall, so putting one there moves nothing", (tester) async {
      Future<double> title(Widget? suffix) async {
        await tester.pumpWidget(
          MochiApp(
            themeMode: MochiThemeMode.light,
            touch: false,
            home: Center(
              child: SizedBox(
                width: 300,
                child: MochiCard(
                  title: const Text("Records"),
                  titleSuffix: suffix,
                  child: const Text("Body"),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        return tester.getRect(find.text("Body")).top - tester.getRect(find.text("Records")).top;
      }

      final plain = await title(null);
      final withBar = await title(
        MochiActionBar(size: MochiSize.xs, [
          MochiAction(icon: MochiIcons.standard.more, label: "More", onPress: () {}),
        ]),
      );

      // The row already has the room, so the bar costs nothing — and the button keeps a target
      // worth aiming at, which is what a row the height of a line of text cannot give it.
      expect(withBar, plain);
      expect(
        tester.getSize(find.byType(MochiButton)).height,
        MochiButtonMetrics.of(MochiSize.xs, touch: false).height,
      );
    });

    testWidgets("uses the surface color and an elevation shadow", (tester) async {
      await tester.pumpWidget(app(const MochiCard(child: Text("Body"))));

      final d = decoration(tester, MochiCard);
      expect(d.color, MochiColors.light.surface);
      expect(d.shadows, isNotEmpty);
    });

    testWidgets("an outlined card is a line with the ground showing through, and no shadow", (tester) async {
      await tester.pumpWidget(
        app(const MochiCard(appearance: MochiCardAppearance.outlined, child: Text("Body"))),
      );

      final d = decoration(tester, MochiCard);
      expect(d.color!.a, 0);
      expect(d.shadows, isNull, reason: "a shadow under a transparent card shows through it");
      expect((d.shape as RoundedSuperellipseBorder).side.color, MochiColors.light.border);
    });

    testWidgets("a soft card takes its intent's soft fill, and no shadow", (tester) async {
      await tester.pumpWidget(
        app(
          const MochiCard(
            appearance: MochiCardAppearance.soft,
            intent: MochiIntent.success,
            child: Text("Body"),
          ),
        ),
      );

      final d = decoration(tester, MochiCard);
      expect(d.color, MochiColors.light.of(MochiIntent.success).soft);
      expect(d.shadows, isNull);
    });

    testWidgets("a chosen outlined card still wears the intent", (tester) async {
      await tester.pumpWidget(
        app(
          const MochiCard(
            appearance: MochiCardAppearance.outlined,
            selected: true,
            intent: MochiIntent.danger,
            child: Text("Body"),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final d = decoration(tester, MochiCard);
      final tone = MochiColors.light.of(MochiIntent.danger);
      expect((d.shape as RoundedSuperellipseBorder).side.color, tone.base);
      expect(d.color!.a, greaterThan(0), reason: "tinted, over whatever the card sits on");
      expect(d.color!.a, lessThan(1));
    });

    testWidgets("is tappable and tints on hover when onPress is set", (tester) async {
      var pressed = 0;
      await tester.pumpWidget(app(MochiCard(onPress: () => pressed++, child: const Text("Body"))));

      await tester.tap(find.byType(MochiCard));
      expect(pressed, 1);

      // Tests default to a touch platform, where hover highlights are suppressed.
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.byType(MochiCard)));
      await tester.pumpAndSettle();
      expect(decoration(tester, MochiCard).color, isNot(MochiColors.light.surface));
      await gesture.removePointer();
    });
  });

  group("badge", () {
    testWidgets("appearances pick their tone colors", (tester) async {
      final danger = MochiColors.light.danger;

      await tester.pumpWidget(
        app(const MochiBadge(intent: MochiIntent.danger, appearance: .solid, child: Text("DNF"))),
      );
      expect(decoration(tester, MochiBadge).color, danger.base);

      await tester.pumpWidget(
        app(const MochiBadge(intent: MochiIntent.danger, appearance: .soft, child: Text("DNF"))),
      );
      expect(decoration(tester, MochiBadge).color, danger.soft);

      await tester.pumpWidget(
        app(const MochiBadge(intent: MochiIntent.danger, appearance: .outlined, child: Text("DNF"))),
      );
      final outlined = decoration(tester, MochiBadge);
      expect(outlined.color!.a, 0);
      expect((outlined.shape as RoundedSuperellipseBorder).side.color, danger.base);
    });
  });
}
