import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child, {required bool touch}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: touch,
    home: Center(child: child),
  );

  for (final touch in [false, true]) {
    for (final size in MochiSize.values) {
      final expected = MochiButtonMetrics.of(size, touch: touch).height;

      testWidgets("${touch ? "touch" : "desktop"} ${size.name} is $expected tall", (tester) async {
        await tester.pumpWidget(
          app(
            MochiButton(size: size, onPress: () {}, child: const Text("Label")),
            touch: touch,
          ),
        );
        expect(tester.getSize(find.byType(MochiButton)).height, expected);
      });

      testWidgets("${touch ? "touch" : "desktop"} ${size.name} icon button is square", (tester) async {
        await tester.pumpWidget(
          app(
            MochiButton.icon(size: size, onPress: () {}, icon: const SizedBox.square(dimension: 8)),
            touch: touch,
          ),
        );
        expect(tester.getSize(find.byType(MochiButton)), Size.square(expected));
      });
    }
  }
}
