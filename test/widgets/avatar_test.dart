import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

/// An image that never arrives, so the fallback is what shows.
class _BrokenImage extends ImageProvider<_BrokenImage> {
  const _BrokenImage();

  @override
  Future<_BrokenImage> obtainKey(ImageConfiguration configuration) async => this;

  @override
  ImageStreamCompleter loadImage(_BrokenImage key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(Future.error("no such picture"));
}

void main() {
  Widget app(Widget child, {bool touch = false}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: touch,
    home: Center(child: child),
  );

  testWidgets("initials, cut down to two letters and shouted", (tester) async {
    await tester.pumpWidget(app(const MochiAvatar(initials: "harry")));
    await tester.pumpAndSettle();
    expect(find.text("HA"), findsOneWidget);

    await tester.pumpWidget(app(const MochiAvatar(initials: "harry shih")));
    await tester.pumpAndSettle();
    expect(find.text("HS"), findsOneWidget, reason: "one letter from each word");
  });

  testWidgets("no initials leaves the icon", (tester) async {
    await tester.pumpWidget(app(const MochiAvatar()));
    await tester.pumpAndSettle();
    expect(find.byIcon(MochiIcons.standard.user), findsOneWidget);

    await tester.pumpWidget(app(MochiAvatar(icon: Icon(MochiIcons.standard.check))));
    await tester.pumpAndSettle();
    expect(find.byIcon(MochiIcons.standard.check), findsOneWidget);
  });

  testWidgets("a picture that never comes falls back to the initials", (tester) async {
    await tester.pumpWidget(app(const MochiAvatar(image: _BrokenImage(), initials: "HS")));
    await tester.pumpAndSettle();
    expect(find.text("HS"), findsOneWidget);
  });

  testWidgets("sizes, and square whatever the shape", (tester) async {
    for (final (size, across) in [
      (MochiSize.xs, 24.0),
      (MochiSize.sm, 32.0),
      (MochiSize.md, 40.0),
      (MochiSize.lg, 56.0),
    ]) {
      await tester.pumpWidget(app(MochiAvatar(initials: "HS", size: size)));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(MochiAvatar)), Size.square(across), reason: size.name);
    }

    await tester.pumpWidget(app(const MochiAvatar(initials: "HS", diameter: 72)));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MochiAvatar)), const Size.square(72));
  });

  testWidgets("bigger on touch", (tester) async {
    await tester.pumpWidget(app(const MochiAvatar(initials: "HS")));
    await tester.pumpAndSettle();
    final desktop = tester.getSize(find.byType(MochiAvatar)).width;

    await tester.pumpWidget(app(const MochiAvatar(initials: "HS"), touch: true));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MochiAvatar)).width, greaterThan(desktop));
  });

  testWidgets("a circle is round, a rounded one keeps its corners in proportion", (tester) async {
    BorderRadiusGeometry cornersOf(WidgetTester tester) =>
        ((tester
                            .widget<DecoratedBox>(
                              find
                                  .descendant(
                                    of: find.byType(MochiAvatar),
                                    matching: find.byType(DecoratedBox),
                                  )
                                  .first,
                            )
                            .decoration
                        as ShapeDecoration)
                    .shape
                as RoundedSuperellipseBorder)
            .borderRadius;

    await tester.pumpWidget(app(const MochiAvatar(initials: "HS")));
    await tester.pumpAndSettle();
    expect(cornersOf(tester), MochiGeometry.standard.radius.full);

    await tester.pumpWidget(
      app(const MochiAvatar(initials: "HS", shape: MochiAvatarShape.rounded, diameter: 40)),
    );
    await tester.pumpAndSettle();
    expect(cornersOf(tester), const BorderRadius.all(Radius.circular(10)));
  });

  testWidgets("screen readers hear the initials, or what it is told", (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app(const MochiAvatar(initials: "HS")));
    await tester.pumpAndSettle();
    expect(tester.getSemantics(find.byType(MochiAvatar)).label, "HS");

    await tester.pumpWidget(app(const MochiAvatar(initials: "HS", semanticLabel: "Harry")));
    await tester.pumpAndSettle();
    expect(tester.getSemantics(find.byType(MochiAvatar)).label, "Harry");
    handle.dispose();
  });

  group("group", () {
    testWidgets("they overlap, and the ones left out become a +n", (tester) async {
      await tester.pumpWidget(
        app(
          const MochiAvatarGroup(
            max: 3,
            children: [
              MochiAvatar(initials: "A"),
              MochiAvatar(initials: "B"),
              MochiAvatar(initials: "C"),
              MochiAvatar(initials: "D"),
              MochiAvatar(initials: "E"),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("A"), findsOneWidget);
      expect(find.text("D"), findsNothing);
      expect(find.text("+2"), findsOneWidget);

      final first = tester.getRect(find.byType(MochiAvatar).at(0));
      final second = tester.getRect(find.byType(MochiAvatar).at(1));
      expect(second.left, lessThan(first.right), reason: "the next one covers the last");
    });

    testWidgets("with no limit they all show", (tester) async {
      await tester.pumpWidget(
        app(
          const MochiAvatarGroup(
            children: [
              MochiAvatar(initials: "A"),
              MochiAvatar(initials: "B"),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MochiAvatar), findsNWidgets(2));
      expect(find.textContaining("+"), findsNothing);
    });
  });
}
