import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  const tabular = FontFeature.tabularFigures();

  List<TextStyle> stepsOf(MochiTypeface face) => [
    face.xs3,
    face.xs2,
    face.xs,
    face.sm,
    face.md,
    face.lg,
    face.xl,
    face.xl2,
    face.xl3,
    face.xl4,
    face.xl5,
    face.xl6,
    face.xl7,
    face.xl8,
  ];

  test("a typeface's features are on every step of its scale", () {
    final face = MochiTypeface(fontFamily: "Rubik", fontFeatures: const [tabular]);

    for (final style in stepsOf(face)) {
      expect(style.fontFeatures, const [tabular], reason: "${style.fontSize} missed them");
    }
  });

  test("a typeface given none carries none", () {
    for (final style in stepsOf(MochiTypeface(fontFamily: "Comfortaa"))) {
      expect(style.fontFeatures, isNull);
    }
  });

  test("scaling keeps the features and changes only the size", () {
    final face = MochiTypeface(fontFamily: "Rubik", fontFeatures: const [tabular]);
    final bigger = face.scale(2);

    expect(bigger.fontFeatures, const [tabular]);
    for (final style in stepsOf(bigger)) {
      expect(style.fontFeatures, const [tabular]);
    }
    expect(bigger.md.fontSize, face.md.fontSize! * 2);
  });
}
