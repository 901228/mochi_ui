import "package:flutter/rendering.dart";
import "package:flutter/widgets.dart";

/// Tucks its child under the previous one by [by], at the start edge: a negative margin, which
/// neither `Padding` nor a `Row`'s spacing allows — and `Padding` refuses outright, since its
/// insets must be positive.
///
/// Shared by the two things that overlap: a joined group of badges, whose neighbours share a
/// border, and a stack of avatars.
class Overlap extends SingleChildRenderObjectWidget {
  const Overlap({super.key, required this.by, super.child});

  final double by;

  @override
  RenderOverlap createRenderObject(BuildContext context) =>
      RenderOverlap(by: by, textDirection: Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, RenderOverlap renderObject) {
    renderObject
      ..by = by
      ..textDirection = Directionality.of(context);
  }
}

class RenderOverlap extends RenderShiftedBox {
  RenderOverlap({required this._by, required this._textDirection}) : super(null);

  double _by;
  set by(double value) {
    if (value == _by) return;
    _by = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child!;
    child.layout(constraints.loosen(), parentUsesSize: true);
    size = constraints.constrain(Size(child.size.width - _by, child.size.height));
    (child.parentData! as BoxParentData).offset = Offset(_textDirection == TextDirection.ltr ? -_by : 0, 0);
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      (super.computeMinIntrinsicWidth(height) - _by).clamp(0, double.infinity);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      (super.computeMaxIntrinsicWidth(height) - _by).clamp(0, double.infinity);
}
