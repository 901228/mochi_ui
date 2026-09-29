import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child) => MochiApp(
    themeMode: MochiThemeMode.light,
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

    testWidgets("uses the surface color and an elevation shadow", (tester) async {
      await tester.pumpWidget(app(const MochiCard(child: Text("Body"))));

      final d = decoration(tester, MochiCard);
      expect(d.color, MochiColors.light.surface);
      expect(d.shadows, isNotEmpty);
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
